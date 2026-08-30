part of 'badge_identity_cubit.dart';

/// The badge creator's persisted identity fields and choices.
class BadgeIdentityState extends Equatable {
  const BadgeIdentityState({
    this.name = '',
    this.role = '',
    this.url = '',
    this.template = BadgeTemplate.classic,
    this.font = BadgeFont.display,
    this.frame = BadgeFrame.bold,
  });

  final String name;
  final String role;
  final String url;
  final BadgeTemplate template;
  final BadgeFont font;
  final BadgeFrame frame;

  BadgeIdentityState copyWith({
    String? name,
    String? role,
    String? url,
    BadgeTemplate? template,
    BadgeFont? font,
    BadgeFrame? frame,
  }) {
    return BadgeIdentityState(
      name: name ?? this.name,
      role: role ?? this.role,
      url: url ?? this.url,
      template: template ?? this.template,
      font: font ?? this.font,
      frame: frame ?? this.frame,
    );
  }

  @override
  List<Object> get props => [name, role, url, template, font, frame];
}
