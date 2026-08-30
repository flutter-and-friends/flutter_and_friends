import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_and_friends/friends_badge/cubit/badge_identity_cubit.dart';
import 'package:flutter_and_friends/friends_badge/models/models.dart';
import 'package:flutter_and_friends/friends_badge/services/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:friends_badge/friends_badge.dart';
import 'package:image/image.dart';
import 'package:integral_isolates/integral_isolates.dart';

part 'friends_badge_state.dart';

class FriendsBadgeCubit extends Cubit<FriendsBadgeState> {
  /// Creates the cubit, seeded from [identity] (the hydrated identity
  /// fields — see [BadgeIdentityCubit]). Every identity-affecting mutator
  /// here forwards to [identity], which persists on change.
  FriendsBadgeCubit({required BadgeIdentityCubit identity})
    : _identity = identity,
      super(
        FriendsBadgeState(
          name: identity.state.name,
          role: identity.state.role,
          url: identity.state.url,
          template: identity.state.template,
          font: identity.state.font,
        ),
      );

  final BadgeIdentityCubit _identity;

  /// The user's photo, cached as a [ui.Image] at pick time.
  ///
  /// The raster phase of composition needs a `ui.Image`; converting from the
  /// decoded `img.Image` per compose would re-encode the full-resolution
  /// source on every keystroke, so it happens exactly once here.
  ui.Image? _sourceUiImage;

  /// Long-lived isolate for the second compose phase (RGBA wrap +
  /// [BadgeImage] construction).
  ///
  /// Back-pressure policy: [ReplaceBackpressureStrategy] — a queue of one,
  /// and a new compose request *replaces* the queued one. Keystrokes that
  /// arrive while a compose is running or queued drop the stale request, so
  /// only the latest input ever reaches the expensive img pipeline. Dropped
  /// futures complete with [BackpressureDropException], which the cubit
  /// swallows by design (the preview simply skips intermediate states).
  ///
  /// `autoInit: false` — the isolate is not spawned until the first compose,
  /// so merely opening the creator page costs no isolate.
  final TailoredStatefulIsolate<ComposeRequest, ComposedBadge> _composeIsolate =
      TailoredStatefulIsolate<ComposeRequest, ComposedBadge>(
        backpressureStrategy: ReplaceBackpressureStrategy(),
        autoInit: false,
      );

  /// Tracks whether [_composeIsolate] was ever initialized — its `dispose`
  /// throws a `LateError` when called before `init`, so `close` must skip it
  /// for a cubit that never composed (e.g. page opened and left).
  var _isolateInitialized = false;

  /// Asset path of the bundled capybara the user picked, or `null` for a
  /// gallery pick. Feeds the `capy:` segment of the NDEF person record.
  String? _sourceAsset;

  /// The capybara ID of the picked image (`coffee_mode`, …) or `null` when
  /// the source is the phone gallery. Read by the write flow.
  String? get capybaraId => capybaraIdForAsset(_sourceAsset);

  Future<void> updateImage(File file) async {
    emit(state.copyWith(status: FriendsBadgeStatus.loading));

    try {
      final image = await Isolate.run<Image?>(
        () async => decodeImage(await file.readAsBytes()),
      );

      if (image == null) {
        return emit(state.copyWith(status: FriendsBadgeStatus.failed));
      }

      await _setSourceImage(image, sourceAsset: null);
    } on Exception {
      return emit(state.copyWith(status: FriendsBadgeStatus.failed));
    }
  }

  /// Loads a bundled capybara template image from [assetPath] (see
  /// [kCapybaraAssets]) as the source image.
  Future<void> updateImageFromAsset(String assetPath) async {
    emit(state.copyWith(status: FriendsBadgeStatus.loading));

    try {
      final bytes = await rootBundle.load(assetPath);
      final image = await Isolate.run<Image?>(
        () async => decodeImage(bytes.buffer.asUint8List()),
      );

      if (image == null) {
        return emit(state.copyWith(status: FriendsBadgeStatus.failed));
      }

      await _setSourceImage(image, sourceAsset: assetPath);
    } on Exception {
      return emit(state.copyWith(status: FriendsBadgeStatus.failed));
    }
  }

  Future<void> _setSourceImage(
    Image image, {
    required String? sourceAsset,
  }) async {
    _sourceUiImage = await BadgeComposer.toUiImage(image);
    _sourceAsset = sourceAsset;
    await _recompose();
    if (state.badge != null) {
      emit(state.copyWith(status: FriendsBadgeStatus.loaded));
    }
  }

  /// Switches the preview to [ditherKernel]. The dithered preview is encoded
  /// in a short-lived isolate; the badge is left untouched if a recompose
  /// replaced it in the meantime.
  Future<void> updateDitherKernel(DitherKernel ditherKernel) async {
    final badge = state.badge;
    if (badge == null || badge.ditherKernel == ditherKernel) return;
    final previewPng = await Isolate.run(
      () => encodeBadgePreview(badge.image, ditherKernel),
    );
    if (isClosed || state.badge?.image != badge.image) return;
    emit(
      state.copyWith(
        badge: badge.copyWith(
          ditherKernel: ditherKernel,
          previewPng: previewPng,
        ),
      ),
    );
  }

  Future<void> updateTemplate(BadgeTemplate template) async {
    if (state.template == template) return;
    emit(state.copyWith(template: template));
    _identity.updateTemplate(template);
    await _recompose();
  }

  Future<void> updateName(String name) async {
    if (state.name == name) return;
    emit(state.copyWith(name: name));
    _identity.updateName(name);
    await _recompose();
  }

  Future<void> updateRole(String role) async {
    if (state.role == role) return;
    emit(state.copyWith(role: role));
    _identity.updateRole(role);
    await _recompose();
  }

  Future<void> updateFont(BadgeFont font) async {
    if (state.font == font) return;
    emit(state.copyWith(font: font));
    _identity.updateFont(font);
    await _recompose();
  }

  /// Records the personal link the user wants on their badge's NDEF payload.
  void updateUrl(String url) {
    if (state.url == url) return;
    emit(state.copyWith(url: url));
    _identity.updateUrl(url);
  }

  Future<void> _recompose() async {
    final source = _sourceUiImage;
    if (source == null) return;

    // Phase 1 (root isolate): rasterize. Cheap at 240x416 with a cached
    // source image; dart:ui APIs cannot leave the root isolate.
    final rgba = await BadgeComposer.renderRgba(
      sourceImage: source,
      template: state.template,
      name: state.name,
      role: state.role,
      font: state.font,
    );

    // Phase 2 (background isolate): RGBA wrap, BadgeImage construction and
    // PNG previews. Stale requests dropped by the back-pressure strategy
    // complete with BackpressureDropException — expected, ignore.
    await _composeIsolate.init();
    _isolateInitialized = true;
    try {
      final composed = await _composeIsolate.compute(
        composeBadge,
        ComposeRequest(
          rgba: rgba,
          kernel: state.badge?.ditherKernel ?? DitherKernel.atkinson,
        ),
      );
      if (isClosed) return;
      emit(
        state.copyWith(
          badge: FriendsBadge(
            image: composed.image,
            ditherKernel: composed.kernel,
            previewPng: composed.previewPng,
            peekPngs: composed.peekPngs,
          ),
        ),
      );
    } on BackpressureDropException {
      // A newer compose request superseded this one — its result will
      // arrive shortly. Nothing to do.
    }
  }

  @override
  Future<void> close() async {
    if (_isolateInitialized) await _composeIsolate.dispose();
    _sourceUiImage?.dispose();
    await super.close();
  }
}
