import 'package:flutter/material.dart';
import 'package:flutter_and_friends/friends_badge/friends_badge.dart';
import 'package:flutter_and_friends/organizers/organizers.dart';
import 'package:flutter_and_friends/settings/settings.dart';
import 'package:flutter_and_friends/theme/theme.dart';
import 'package:flutter_and_friends/updater/updater.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';
import 'package:url_launcher/url_launcher_string.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  static Route<void> route() {
    return MaterialPageRoute(builder: (_) => const SettingsPage());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SettingsCubit(
        updater: context.read<ShorebirdUpdater>(),
      )..init(),
      child: const SettingsView(),
    );
  }
}

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headingStyle = theme.textTheme.titleMedium;
    return BlocListener<UpdaterCubit, UpdaterState>(
      listenWhen: (previous, current) =>
          previous.status != current.status &&
          current.status == UpdaterStatus.idle,
      listener: (context, state) {
        if (!state.updateAvailable) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(content: Text('No update available')),
            );
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          children: [
            Text('Preferences', style: headingStyle),
            const ThemeToggle(),
            const SizedBox(height: 16),
            Text('Extras', style: headingStyle),
            ListTile(
              leading: const Icon(Icons.badge_outlined),
              title: const Text('Friends Badge'),
              subtitle: const Text('Customize your badge'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(FriendsBadgePage.route()),
            ),
            ListTile(
              leading: const Icon(Icons.map),
              title: const Text('Activity Map'),
              subtitle: const Text('View the locations of all activities'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => launchUrlString(
                'https://www.google.com/maps/d/u/0/viewer?mid=102KWzlh5enCfJXbgTu8wN8FSfeOzsMw&femb=1&ll=59.32440113540593%2C18.059913600000016&z=13',
              ),
            ),
            const SizedBox(height: 16),
            Text('Socials', style: headingStyle),
            ListTile(
              leading: const FaIcon(
                FontAwesomeIcons.linkedin,
                color: Colors.indigo,
              ),
              title: const Text('LinkedIn'),
              subtitle: const Text('@flutter-friends'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => launchUrlString(
                'https://www.linkedin.com/company/flutter-friends',
              ),
            ),
            ListTile(
              leading: const FaIcon(FontAwesomeIcons.xTwitter),
              title: const Text('X.com'),
              subtitle: const Text('@FlutterNFriends'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => launchUrlString('https://x.com/FlutterNFriends'),
            ),
            ListTile(
              leading: const FaIcon(
                FontAwesomeIcons.bluesky,
                color: Colors.blueAccent,
              ),
              title: const Text('Bluesky'),
              subtitle: const Text('@flutterfriends.dev'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => launchUrlString(
                'https://bsky.app/profile/flutterfriends.dev',
              ),
            ),
            const SizedBox(height: 16),
            Text('About', style: headingStyle),
            ListTile(
              title: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [Text('Version'), AppVersion()],
              ),
              onTap: () => context.read<UpdaterCubit>().checkForUpdates(),
            ),
            ListTile(
              title: const Text('Website'),
              subtitle: const Text('View the official website'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => launchUrlString(
                'https://www.flutterfriends.dev',
              ),
            ),
            ListTile(
              title: const Text('Organizers'),
              subtitle: const Text('View the conference organizers'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(OrganizersPage.route()),
            ),
            ListTile(
              title: const Text('Source Code'),
              subtitle: const Text('View the full source code on GitHub'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => launchUrlString(
                'https://github.com/felangel/flutter_and_friends',
              ),
            ),
            ListTile(
              title: const Text('Licenses'),
              subtitle: const Text('View the licenses of the libraries used'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => showLicensePage(
                context: context,
                applicationIcon: Image.asset(
                  'assets/logo.png',
                  height: 120,
                ),
                applicationName: 'Flutter & Friends',
              ),
            ),
            ListTile(
              title: const Text('Privacy Policy'),
              subtitle: const Text('View the privacy policy'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => launchUrlString(
                'https://github.com/felangel/flutter_and_friends/blob/main/privacy.md',
              ),
            ),
            ListTile(
              title: const Text('Powered by Shorebird'),
              subtitle: const Text('Learn more about Shorebird'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => launchUrlString('https://shorebird.dev'),
            ),
          ],
        ),
      ),
    );
  }
}

class AppVersion extends StatelessWidget {
  const AppVersion({super.key});

  @override
  Widget build(BuildContext context) {
    final version = context.select((SettingsCubit cubit) {
      final state = cubit.state;
      final packageVersion =
          '''${state.version.major}.${state.version.minor}.${state.version.patch}''';
      final buildNumber = '${state.version.build.singleOrNull ?? 0}';
      final patchNumber = state.patchNumber != null
          ? ' #${state.patchNumber}'
          : '';
      return '$packageVersion ($buildNumber)$patchNumber';
    });
    return Text(version);
  }
}
