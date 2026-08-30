import 'package:equatable/equatable.dart';
import 'package:flutter_and_friends/friends_badge/models/models.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

part 'badge_identity_state.dart';

/// Persists the badge creator's identity fields (name, role, link) plus the
/// template/font choices across app restarts, so the user does not retype
/// them every time they open the creator.
///
/// Mirrors the app's hydration pattern (`FavoritesCubit`, `InstallIdCubit`):
/// a small [HydratedCubit] with a fully JSON-serializable state. Saved on
/// change — every mutator emits, and [HydratedCubit] persists each emission.
///
/// Hydration storage key: the default (`BadgeIdentityCubit` runtime type).
class BadgeIdentityCubit extends HydratedCubit<BadgeIdentityState> {
  BadgeIdentityCubit() : super(const BadgeIdentityState());

  void updateName(String name) => emit(state.copyWith(name: name));

  void updateRole(String role) => emit(state.copyWith(role: role));

  void updateUrl(String url) => emit(state.copyWith(url: url));

  void updateTemplate(BadgeTemplate template) =>
      emit(state.copyWith(template: template));

  void updateFont(BadgeFont font) => emit(state.copyWith(font: font));

  void updateFrame(BadgeFrame frame) => emit(state.copyWith(frame: frame));

  @override
  BadgeIdentityState? fromJson(Map<String, dynamic> json) {
    return BadgeIdentityState(
      name: json['name'] as String? ?? '',
      role: json['role'] as String? ?? '',
      url: json['url'] as String? ?? '',
      template:
          BadgeTemplate.values.asNameMap()[json['template']] ??
          BadgeTemplate.classic,
      font: BadgeFont.values.asNameMap()[json['font']] ?? BadgeFont.display,
      frame: BadgeFrame.values.asNameMap()[json['frame']] ?? BadgeFrame.stripe,
    );
  }

  @override
  Map<String, dynamic>? toJson(BadgeIdentityState state) {
    return {
      'name': state.name,
      'role': state.role,
      'url': state.url,
      'template': state.template.name,
      'font': state.font.name,
      'frame': state.frame.name,
    };
  }
}
