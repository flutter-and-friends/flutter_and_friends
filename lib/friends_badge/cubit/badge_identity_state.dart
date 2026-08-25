part of 'badge_identity_cubit.dart';

/// The badge creator's persisted identity fields and choices.
class BadgeIdentityState extends Equatable {
  const BadgeIdentityState({
    this.name = '',
    this.role = '',
    this.url = '',
    this.template = BadgeTemplate.imageOnly,
    this.font = BadgeFont.display,
  });

  final String name;
  final String role;
  final String url;
  final BadgeTemplate template;
  final BadgeFont font;

  BadgeIdentityState copyWith({
    String? name,
    String? role,
    String? url,
    BadgeTemplate? template,
    BadgeFont? font,
  }) {
    return BadgeIdentityState(
      name: name ?? this.name,
      role: role ?? this.role,
      url: url ?? this.url,
      template: template ?? this.template,
      font: font ?? this.font,
    );
  }

  @override
  List<Object> get props => [name, role, url, template, font];
}
