import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:friends_badge/friends_badge.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_android.dart';
import 'package:nfc_manager/nfc_manager_ios.dart';

/// How a [BadgeCollectSession] ended.
enum BadgeCollectResult {
  /// A badge was tapped and its person handed to `onCollected`.
  collected,

  /// A tag was tapped, but it was not a readable Friends badge.
  notABadge,

  /// The session ended without a tap: cancelled by the caller, by the user
  /// dismissing the iOS NFC sheet, or by the platform (iOS timeout).
  cancelled,
}

/// A running NFC collect session, see [BadgeCollector.start].
class BadgeCollectSession {
  BadgeCollectSession({
    required this.result,
    required Future<void> Function() onCancel,
  }) : _cancel = onCancel;

  /// Completes once the session has ended. Never completes with an error.
  final Future<BadgeCollectResult> result;

  final Future<void> Function() _cancel;

  /// Stops listening for taps. A no-op if the session already ended.
  Future<void> cancel() => _cancel();
}

/// Reads a person off a tapped badge into the dex.
///
/// "Collecting" is foreground dispatch (see `docs/badge-creator.md` §8.1):
/// while the app holds an NFC session in the foreground, tapping a badge is
/// delivered to the app first, the person is parsed and collected in place
/// instead of the OS opening the badge's URL in a browser.
///
/// Platform shape, via nfc_manager's session API (the same plumbing the
/// badge write flow uses):
///
/// - **Android**: `startSession` enables reader-mode foreground dispatch for
///   the activity. While this session runs, the app wins over the browser
///   for any tapped tag. There is no system UI, so the caller is expected to
///   show its own "hold near a badge" prompt and offer a way to cancel.
/// - **iOS**: holds a Core NFC reader session open; a tap collects in place.
///   The system sheet handles the prompt and the user's cancel.
///
/// Note that `NfcManager.startSession` resolves as soon as the platform
/// session has *begun*, not when it ends. The end of a session is only
/// observable through the tag callback, the iOS error callback, or the
/// caller cancelling, which is what [BadgeCollectSession.result] wraps.
///
/// The [IsoDepTransceiver] construction below mirrors the `friends_badge`
/// package's internal `AndroidNfcImplementation` / `IosNfcImplementation`
/// (see their `common_nfc_implementation.dart`): the package builds these
/// the same way for its own NDEF write path but does not export them, so the
/// app duplicates the thin nfc_manager glue. The NDEF protocol itself
/// (Type 4 SELECT / READ BINARY, message parsing) stays inside the package's
/// [NdefBadgeReader].
class BadgeCollector {
  const BadgeCollector({this._reader = const NdefBadgeReader()});

  final NdefBadgeReader _reader;

  /// Whether NFC is available on this device right now.
  Future<bool> isAvailable() async =>
      (await NfcManager.instance.checkAvailability()) ==
      NfcAvailability.enabled;

  /// Starts an NFC session that ends on the first tapped tag.
  ///
  /// [onCollected] is invoked with the person read off a tapped badge and
  /// the badge's tag UID as lowercase hex (`null` if the platform did not
  /// report one), before the returned session's [BadgeCollectSession.result]
  /// completes with [BadgeCollectResult.collected]. A tag that is not a
  /// readable badge (not ISO-DEP, no NDEF payload, malformed payload) ends
  /// the session with [BadgeCollectResult.notABadge].
  ///
  /// Throws a [StateError] when NFC is unavailable and rethrows the platform
  /// error when the session cannot be started.
  Future<BadgeCollectSession> start({
    required void Function(BadgePerson person, String? badgeId) onCollected,
    String alertMessageIos = 'Hold your device near a badge to collect them',
  }) async {
    final availability = await NfcManager.instance.checkAvailability();
    if (availability != NfcAvailability.enabled) {
      throw StateError('NFC is not available on this device ($availability)');
    }

    final completer = Completer<BadgeCollectResult>();
    var handlingTag = false;

    void finish(BadgeCollectResult result) {
      if (!completer.isCompleted) completer.complete(result);
    }

    Future<void> stop({String? alertMessageIos, String? errorMessageIos}) {
      return NfcManager.instance
          .stopSession(
            alertMessageIos: alertMessageIos,
            errorMessageIos: errorMessageIos,
          )
          .catchError((Object error) {
            debugPrint('Badge collect session stop error: $error');
          });
    }

    await NfcManager.instance.startSession(
      alertMessageIos: alertMessageIos,
      pollingOptions: const {NfcPollingOption.iso14443},
      onDiscovered: (tag) async {
        if (completer.isCompleted || handlingTag) return;
        handlingTag = true;
        final person = await _tryRead(tag);
        if (completer.isCompleted) return;
        if (person == null) {
          await stop(errorMessageIos: 'Not a badge, try another tap');
          finish(BadgeCollectResult.notABadge);
          return;
        }
        onCollected(person, badgeIdFrom(tag));
        await stop(alertMessageIos: 'Collected!');
        finish(BadgeCollectResult.collected);
      },
      onSessionErrorIos: (error) {
        debugPrint('Badge collect session ended: ${error.code}');
        if (!handlingTag) finish(BadgeCollectResult.cancelled);
      },
    );

    return BadgeCollectSession(
      result: completer.future,
      onCancel: () async {
        if (completer.isCompleted) return;
        finish(BadgeCollectResult.cancelled);
        await stop();
      },
    );
  }

  /// Attempts to read a [BadgePerson] off [tag]. Returns `null` when the tag
  /// is not an ISO-DEP badge or carries no parsable NDEF payload.
  Future<BadgePerson?> _tryRead(NfcTag tag) async {
    final IsoDepTransceiver? transceiver;
    try {
      transceiver = _isoDepTransceiverFrom(tag);
    } on Exception {
      return null;
    }
    if (transceiver == null) return null;
    try {
      return BadgePerson.fromNdefMessage(await _reader.read(transceiver));
      // A foreign tag or an unparsable payload must not kill the session,
      // so any error type degrades to "skip this tag".
      // ignore: avoid_catches_without_on_clauses
    } catch (e) {
      debugPrint('Skipping un-collectable tag: $e');
      return null;
    }
  }

  /// The tag UID of [tag] as lowercase hex, or `null` when the platform
  /// reports none. Android exposes it on every tag, iOS on the ISO 7816
  /// technology the badge speaks.
  @visibleForTesting
  static String? badgeIdFrom(NfcTag tag) {
    final Uint8List? id;
    if (Platform.isAndroid) {
      id = NfcTagAndroid.from(tag)?.id;
    } else if (Platform.isIOS) {
      id = Iso7816Ios.from(tag)?.identifier;
    } else {
      id = null;
    }
    if (id == null || id.isEmpty) return null;
    return id.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Builds an [IsoDepTransceiver] over [tag], mirroring the `friends_badge`
  /// package's own construction (see class doc).
  IsoDepTransceiver? _isoDepTransceiverFrom(NfcTag tag) {
    if (Platform.isAndroid) {
      final isoDep = IsoDepAndroid.from(tag);
      return isoDep == null ? null : _IsoDepTransceiverAndroid(isoDep);
    }
    if (Platform.isIOS) {
      final iso7816 = Iso7816Ios.from(tag);
      return iso7816 == null ? null : _IsoDepTransceiverIos(iso7816);
    }
    return null;
  }
}

class _IsoDepTransceiverAndroid implements IsoDepTransceiver {
  const _IsoDepTransceiverAndroid(this._isoDep);

  final IsoDepAndroid _isoDep;

  @override
  Future<Uint8List> transceive(Uint8List commandApdu) {
    // IsoDepAndroid.transceive returns the full R-APDU including SW1-SW2.
    return _isoDep.transceive(commandApdu);
  }
}

class _IsoDepTransceiverIos implements IsoDepTransceiver {
  const _IsoDepTransceiverIos(this._iso7816);

  final Iso7816Ios _iso7816;

  @override
  Future<Uint8List> transceive(Uint8List commandApdu) async {
    final response = await _iso7816.sendCommandRaw(data: commandApdu);
    // Iso7816Ios returns payload and status word separately. Re-attach the
    // status word so NdefBadgeReader can inspect SW1-SW2 uniformly.
    return Uint8List.fromList([
      ...response.payload,
      response.statusWord1,
      response.statusWord2,
    ]);
  }
}
