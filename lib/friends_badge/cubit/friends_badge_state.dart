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
    this.ditherKernel = DitherKernel.atkinson,
  });

  final BadgeImage image;
  final DitherKernel ditherKernel;

  FriendsBadge copyWith({BadgeImage? image, DitherKernel? ditherKernel}) {
    return FriendsBadge(
      image: image ?? this.image,
      ditherKernel: ditherKernel ?? this.ditherKernel,
    );
  }

  @override
  List<Object> get props => [image, ditherKernel];
}
