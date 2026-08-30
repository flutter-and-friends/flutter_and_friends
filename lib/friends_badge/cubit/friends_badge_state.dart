part of 'friends_badge_cubit.dart';

enum FriendsBadgeStatus {
  idle,
  loading,
  loaded,
  failed,
}

class FriendsBadgeState extends Equatable {
  const FriendsBadgeState({
    this.badge,
    this.status = FriendsBadgeStatus.idle,
    this.template = BadgeTemplate.classic,
    this.name = '',
    this.role = '',
    this.font = BadgeFont.display,
    this.url = '',
  });

  final FriendsBadge? badge;
  final FriendsBadgeStatus status;
  final BadgeTemplate template;
  final String name;
  final String role;
  final BadgeFont font;

  /// The personal link the user wants on their badge. Collected ahead of
  /// NDEF support landing in `friends_badge`; not yet sent to the badge.
  final String url;

  FriendsBadgeState copyWith({
    FriendsBadge? badge,
    FriendsBadgeStatus? status,
    BadgeTemplate? template,
    String? name,
    String? role,
    BadgeFont? font,
    String? url,
  }) {
    return FriendsBadgeState(
      badge: badge ?? this.badge,
      status: status ?? this.status,
      template: template ?? this.template,
      name: name ?? this.name,
      role: role ?? this.role,
      font: font ?? this.font,
      url: url ?? this.url,
    );
  }

  @override
  List<Object?> get props => [
    badge,
    status,
    template,
    name,
    role,
    font,
    url,
  ];
}

class FriendsBadge extends Equatable {
  const FriendsBadge({
    required this.image,
    required this.previewPng,
    required this.peekPngs,
    this.ditherKernel = DitherKernel.atkinson,
  });

  final BadgeImage image;
  final DitherKernel ditherKernel;

  /// [image] dithered with [ditherKernel] as PNG, encoded off the UI
  /// thread by the compose isolate. Derived from [image] and
  /// [ditherKernel], so it is not part of [props].
  final Uint8List previewPng;

  /// A small PNG of [image] per supported kernel for the kernel carousel,
  /// encoded off the UI thread. Derived from [image], not part of [props].
  final Map<DitherKernel, Uint8List> peekPngs;

  FriendsBadge copyWith({
    BadgeImage? image,
    DitherKernel? ditherKernel,
    Uint8List? previewPng,
    Map<DitherKernel, Uint8List>? peekPngs,
  }) {
    return FriendsBadge(
      image: image ?? this.image,
      ditherKernel: ditherKernel ?? this.ditherKernel,
      previewPng: previewPng ?? this.previewPng,
      peekPngs: peekPngs ?? this.peekPngs,
    );
  }

  @override
  List<Object> get props => [image, ditherKernel];
}
