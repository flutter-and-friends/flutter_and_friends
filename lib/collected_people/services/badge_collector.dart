import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:friends_badge/friends_badge.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_android.dart';
import 'package:nfc_manager/nfc_manager_ios.dart';

/// Reads a person off a tapped badge into the dex.
///
/// "Collecting" is foreground dispatch (see `docs/badge-creator.md` §8.1):
/// while the app holds an NFC session in the foreground, tapping a badge is
/// delivered to the app first — the person is parsed and collected in place
/// instead of the OS opening the badge's URL in a browser.
///
/// Platform shape, via nfc_manager's session API (the same plumbing the
/// badge write flow uses):
///
/// - **Android**: `startSession` enables reader-mode foreground dispatch for
///   the activity — while this session runs, the app wins over the browser
///   for any tapped tag.
/// - **iOS**: holds a Core NFC reader session open; a tap collects in place.
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

  /// Holds an NFC session open and invokes [onCollected] for each badge tap,
  /// until the returned future completes.
  ///
  /// Resolves `true` if at least one badge was collected. Un-collectable
  /// tags (not ISO-DEP, no NDEF payload, malformed payload) are skipped —
  /// the session stays open so the user can tap another badge. Throws when
  /// the session cannot be started (NFC unavailable) or the platform
  /// session errors.
  Future<bool> collectTaps({
    required void Function(BadgePerson person) onCollected,
    String alertMessageIos = 'Hold your device near a badge to collect them',
  }) async {
    final availability = await NfcManager.instance.checkAvailability();
    if (availability != NfcAvailability.enabled) {
      throw StateError('NFC is not available on this device ($availability)');
    }

    final completer = Completer<bool>();
    var collected = false;

    unawaited(
      NfcManager.instance
          .startSession(
            alertMessageIos: alertMessageIos,
            pollingOptions: const {NfcPollingOption.iso14443},
            onDiscovered: (tag) async {
              final person = await _tryRead(tag);
              if (person == null) {
                // Not a collectable badge — keep the session alive for the
                // next tap. Android's reader-mode session ignores this; on
                // iOS it keeps the Core NFC popup open.
                unawaited(
                  NfcManager.instance.stopSession(
                    errorMessageIos: 'Not a badge — try another tap',
                  ),
                );
                return;
              }
              collected = true;
              onCollected(person);
              unawaited(
                NfcManager.instance.stopSession(
                  alertMessageIos: 'Collected!',
                ),
              );
            },
          )
          .then((_) {
            if (!completer.isCompleted) completer.complete(collected);
          })
          .onError((error, stackTrace) {
            debugPrint('Badge collect session error: $error');
            if (!completer.isCompleted) {
              completer.completeError(
                error ?? 'Something went wrong when setting up the NfcManager',
                stackTrace,
              );
            }
          }),
    );

    return completer.future;
  }

  /// Attempts to read a [BadgePerson] off [tag]. Returns `null` when the tag
  /// is not an ISO-DEP badge or carries no parsable NDEF payload.
  Future<BadgePerson?> _tryRead(NfcTag tag) async {
    final IsoDepTransceiver? transceiver;
    try {
      transceiver = _isoDepTransceiverFrom(tag);
    } on Exception {
      return null; // Not an ISO-DEP / ISO 7816 tag at all.
    }
    if (transceiver == null) return null;
    try {
      return BadgePerson.fromNdefMessage(await _reader.read(transceiver));
      // A foreign tag or an unparsable payload must not kill the session,
      // so any error type degrades to "skip this tag".
      // ignore: avoid_catches_without_on_clauses
    } catch (e) {
      // Foreign tag, empty NDEF file (NLEN=0), or unparsable payload —
      // none of these are collectable, but none should kill the session.
      debugPrint('Skipping un-collectable tag: $e');
      return null;
    }
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
