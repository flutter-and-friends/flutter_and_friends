/// Paths of the bundled capybara template images under
/// `assets/badge_templates/capybaras/`.
///
/// Hand-written and kept in sync with the 32 files downloaded per
/// `docs/badge-creator.md` §3.
const List<String> kCapybaraAssets = [
  'assets/badge_templates/capybaras/angry.jpeg',
  'assets/badge_templates/capybaras/astronaut.jpeg',
  'assets/badge_templates/capybaras/beach_day.jpeg',
  'assets/badge_templates/capybaras/bug_found.jpeg',
  'assets/badge_templates/capybaras/capiguara_libre.jpeg',
  'assets/badge_templates/capybaras/christmas.jpeg',
  'assets/badge_templates/capybaras/coder.jpeg',
  'assets/badge_templates/capybaras/coder_face.jpeg',
  'assets/badge_templates/capybaras/coffee_mode.jpeg',
  'assets/badge_templates/capybaras/dancer.jpeg',
  'assets/badge_templates/capybaras/dj.jpeg',
  'assets/badge_templates/capybaras/gamer.jpeg',
  'assets/badge_templates/capybaras/gamer_front_facing.jpeg',
  'assets/badge_templates/capybaras/grinning.jpeg',
  'assets/badge_templates/capybaras/guitarist.jpeg',
  'assets/badge_templates/capybaras/halloween.jpeg',
  'assets/badge_templates/capybaras/heart_eyes.jpeg',
  'assets/badge_templates/capybaras/hot_spring.jpeg',
  'assets/badge_templates/capybaras/mind_blown.jpeg',
  'assets/badge_templates/capybaras/open_source.jpeg',
  'assets/badge_templates/capybaras/party.jpeg',
  'assets/badge_templates/capybaras/pizza_joy.jpeg',
  'assets/badge_templates/capybaras/rainy_day.jpeg',
  'assets/badge_templates/capybaras/runner.jpeg',
  'assets/badge_templates/capybaras/serious_coder.jpeg',
  'assets/badge_templates/capybaras/sleeping.jpeg',
  'assets/badge_templates/capybaras/sunglasses.jpeg',
  'assets/badge_templates/capybaras/superhero.jpeg',
  'assets/badge_templates/capybaras/tears_of_joy.jpeg',
  'assets/badge_templates/capybaras/wifi_down.jpeg',
  'assets/badge_templates/capybaras/winner.jpeg',
  'assets/badge_templates/capybaras/yoga.jpeg',
];

/// Maps a bundled capybara asset path (e.g.
/// `assets/badge_templates/capybaras/coffee_mode.jpeg`) to its capybara ID
/// (`coffee_mode`) — the value written into the badge's `capy:` NDEF segment.
///
/// Returns `null` for paths that are not bundled capybaras (e.g. gallery
/// picks), which is exactly the `capybaraId` contract for
/// `NdefRecord.badgePerson`.
String? capybaraIdForAsset(String? assetPath) {
  if (assetPath == null || !kCapybaraAssets.contains(assetPath)) return null;
  final fileName = assetPath.split('/').last;
  return fileName.substring(0, fileName.length - '.jpeg'.length);
}
