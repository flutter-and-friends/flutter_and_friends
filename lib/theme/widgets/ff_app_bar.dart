import 'package:flutter/material.dart';
import 'package:flutter_and_friends/settings/settings.dart';

/// The toolbar is taller than Material's default to fit the logo; see
/// `appBarTheme` in `theme.dart`.
const ffToolbarHeight = kToolbarHeight + 16;

class FFAppBar extends AppBar {
  FFAppBar({super.bottom, super.key})
    : super(title: const _Logo(), actions: [const _SettingsButton()]);
}

/// [FFAppBar] as a sliver for scrolling pages: the logo and the settings
/// button scroll away with the content and float back in on a scroll up,
/// while [bottom] (typically a tab bar) stays pinned at the top.
class FFSliverAppBar extends SliverAppBar {
  const FFSliverAppBar({super.bottom, super.forceElevated, super.key})
    : super(
        title: const _Logo(),
        actions: const [_SettingsButton()],
        toolbarHeight: ffToolbarHeight,
        pinned: true,
        floating: true,
      );
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Image.asset('assets/logo.png', height: kToolbarHeight + 8),
    );
  }
}

class _SettingsButton extends StatelessWidget {
  const _SettingsButton();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.settings),
      onPressed: () => Navigator.of(context).push(SettingsPage.route()),
    );
  }
}
