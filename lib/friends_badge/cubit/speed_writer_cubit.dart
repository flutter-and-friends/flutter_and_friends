import 'dart:async';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_and_friends/friends_badge/cubit/friends_badge_cubit.dart';
import 'package:flutter_and_friends/friends_badge/models/models.dart';
import 'package:flutter_and_friends/friends_badge/services/services.dart';
import 'package:flutter_and_friends/identity/identity.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:friends_badge/friends_badge.dart';
import 'package:image/image.dart' as img;

part 'speed_writer_state.dart';

/// Reads the bytes of a bundled asset. Injectable so tests can compose
/// without the real capybara assets.
typedef AssetLoader = Future<Uint8List> Function(String assetPath);

Future<Uint8List> _loadBundledAsset(String assetPath) async {
  final data = await rootBundle.load(assetPath);
  return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
}

/// Drives the organizers' speed writing mode: walks a roster of people
/// (from a CSV, see [parseBadgeRoster]) and composes a classic-template
/// badge for the current person with a random font and capybara, so that
/// every badge can be flashed before the conference with one tap each.
///
/// Every person gets a fresh badge ID (a UUID standing in for the install
/// ID the owner's own phone would write) so collectors dedupe the badge.
/// After a successful write ([markWritten]) the next person comes up
/// automatically.
class SpeedWriterCubit extends Cubit<SpeedWriterState> {
  SpeedWriterCubit({
    Random? random,
    this._loadAsset = _loadBundledAsset,
    this._generateBadgeId = generateInstallId,
  }) : _random = random ?? Random(),
       super(const SpeedWriterState());

  final Random _random;
  final AssetLoader _loadAsset;
  final String Function() _generateBadgeId;

  /// Decoded capybaras, kept for the session since a roster of hundreds
  /// reuses the 32 assets many times over.
  final Map<String, ui.Image> _sourceImages = {};

  /// Bumped per compose so a stale compose (the user skipped ahead while
  /// one was running) never overwrites a newer badge.
  int _composeSequence = 0;

  /// Replaces the roster with the people in [csv] and shows the first one.
  /// A file without usable rows reports an error and keeps the current
  /// roster.
  Future<void> loadRoster(String csv) async {
    final List<BadgeRosterEntry> entries;
    try {
      entries = parseBadgeRoster(csv);
    } on FormatException catch (e) {
      _fail(e.message);
      return;
    }
    emit(SpeedWriterState(entries: entries));
    await _showPerson(0);
  }

  /// Records the current person's badge as written and moves on to the
  /// next one, or finishes when this was the last.
  Future<void> markWritten() async {
    if (state.current == null) return;
    final written = {...state.writtenIndices, state.index};
    if (state.hasNext) {
      emit(state.copyWith(writtenIndices: written));
      await _showPerson(state.index + 1);
    } else {
      emit(
        state.copyWith(
          status: SpeedWriterStatus.done,
          writtenIndices: written,
        ),
      );
    }
  }

  /// Skips ahead without writing.
  Future<void> next() async {
    if (state.hasNext) await _showPerson(state.index + 1);
  }

  Future<void> previous() async {
    if (state.hasPrevious) await _showPerson(state.index - 1);
  }

  /// Draws a new random font and capybara for the current person.
  Future<void> reroll() async {
    if (state.current != null) await _showPerson(state.index);
  }

  Future<void> _showPerson(int index) async {
    emit(
      state.copyWith(
        status: SpeedWriterStatus.composing,
        index: index,
        font: BadgeFont.values[_random.nextInt(BadgeFont.values.length)],
        asset: kCapybaraAssets[_random.nextInt(kCapybaraAssets.length)],
        badgeId: _generateBadgeId(),
        clearBadge: true,
      ),
    );
    await _compose();
  }

  Future<void> _compose() async {
    final sequence = ++_composeSequence;
    final entry = state.current;
    final asset = state.asset;
    if (entry == null || asset == null) return;
    try {
      final source = await _sourceImage(asset);
      if (isClosed || sequence != _composeSequence) return;
      final rgba = await BadgeComposer.renderRgba(
        sourceImage: source,
        template: BadgeTemplate.classic,
        name: entry.name,
        role: entry.role,
        font: state.font,
      );
      final composed = await Isolate.run(
        () => composeBadge(
          ComposeRequest(
            rgba: rgba,
            kernel: DitherKernel.atkinson,
            includePeeks: false,
          ),
        ),
      );
      if (isClosed || sequence != _composeSequence) return;
      emit(
        state.copyWith(
          status: SpeedWriterStatus.ready,
          badge: FriendsBadge(
            image: composed.image,
            ditherKernel: composed.kernel,
            previewPng: composed.previewPng,
            peekPngs: composed.peekPngs,
          ),
        ),
      );
    } on Exception catch (e) {
      if (isClosed || sequence != _composeSequence) return;
      _fail('Could not compose the badge for ${entry.name}: $e');
    }
  }

  Future<ui.Image> _sourceImage(String asset) async {
    final cached = _sourceImages[asset];
    if (cached != null) return cached;
    final bytes = await _loadAsset(asset);
    final decoded = await Isolate.run(() => img.decodeImage(bytes));
    if (decoded == null) throw FormatException('Could not decode $asset');
    final image = await BadgeComposer.toUiImage(decoded);
    // A reroll may have decoded the same capybara meanwhile; keep the first.
    final raced = _sourceImages[asset];
    if (raced != null || isClosed) {
      image.dispose();
      return raced ?? image;
    }
    return _sourceImages[asset] = image;
  }

  void _fail(String message) {
    emit(state.copyWith(error: message, errorCount: state.errorCount + 1));
  }

  @override
  Future<void> close() async {
    for (final image in _sourceImages.values) {
      image.dispose();
    }
    _sourceImages.clear();
    await super.close();
  }
}
