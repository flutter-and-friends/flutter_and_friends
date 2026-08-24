import 'dart:io';
import 'dart:isolate';

import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_and_friends/friends_badge/models/models.dart';
import 'package:flutter_and_friends/friends_badge/services/services.dart';
import 'package:friends_badge/friends_badge.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:image/image.dart';

part 'friends_badge_state.dart';

class FriendsBadgeCubit extends Cubit<FriendsBadgeState> {
  FriendsBadgeCubit() : super(const FriendsBadgeState());

  /// The decoded source image the badge is composed from.
  ///
  /// Kept out of [state] because it is large and immutable; composition only
  /// needs it on re-render, not on every rebuild. Equatable identity of
  /// [FriendsBadgeState] would also be defeated by embedding the bitmap.
  Image? _sourceImage;

  Future<void> updateImage(File file) async {
    emit(state.copyWith(status: FriendsBadgeStatus.loading));

    try {
      final image = await Isolate.run<Image?>(
        () async => decodeImage(await file.readAsBytes()),
      );

      if (image == null) {
        return emit(state.copyWith(status: FriendsBadgeStatus.failed));
      }

      await _setSourceImage(image);
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

      await _setSourceImage(image);
    } on Exception {
      return emit(state.copyWith(status: FriendsBadgeStatus.failed));
    }
  }

  Future<void> _setSourceImage(Image image) async {
    _sourceImage = image;
    final badge = await _compose(state);
    emit(
      state.copyWith(
        badge: badge,
        status: FriendsBadgeStatus.loaded,
      ),
    );
  }

  void updateDitherKernel(DitherKernel ditherKernel) {
    final badge = state.badge;
    if (badge == null) return;
    emit(state.copyWith(badge: badge.copyWith(ditherKernel: ditherKernel)));
  }

  Future<void> updateTemplate(BadgeTemplate template) async {
    if (state.template == template) return;
    emit(state.copyWith(template: template));
    await _recompose();
  }

  Future<void> updateName(String name) async {
    if (state.name == name) return;
    emit(state.copyWith(name: name));
    await _recompose();
  }

  Future<void> updateRole(String role) async {
    if (state.role == role) return;
    emit(state.copyWith(role: role));
    await _recompose();
  }

  Future<void> updateFont(BadgeFont font) async {
    if (state.font == font) return;
    emit(state.copyWith(font: font));
    await _recompose();
  }

  /// Records the personal link the user wants on their badge's NDEF payload.
  ///
  /// Collected now so it can be passed straight into
  /// `writeToBadge(ndef: ...)` once the `friends_badge` package exposes that
  /// parameter — no NDEF code lives in the app yet.
  void updateUrl(String url) {
    if (state.url == url) return;
    emit(state.copyWith(url: url));
  }

  Future<void> _recompose() async {
    if (_sourceImage == null) return;
    final badge = await _compose(state);
    emit(state.copyWith(badge: badge));
  }

  Future<FriendsBadge> _compose(FriendsBadgeState s) async {
    final image = await BadgeComposer.compose(
      image: _sourceImage!,
      template: s.template,
      name: s.name,
      role: s.role,
      font: s.font,
    );
    return FriendsBadge(
      image: image,
      ditherKernel: s.badge?.ditherKernel ?? DitherKernel.atkinson,
    );
  }
}
