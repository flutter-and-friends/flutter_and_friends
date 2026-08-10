import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_and_friends/config/config.dart';
import 'package:flutter_and_friends/favorites/favorites.dart';
import 'package:flutter_and_friends/launchpad/launchpad.dart';
import 'package:flutter_and_friends/organizers/organizers.dart';
import 'package:flutter_and_friends/schedule/schedule.dart';
import 'package:flutter_and_friends/settings/settings.dart';
import 'package:flutter_and_friends/sponsors/sponsors.dart';
import 'package:flutter_and_friends/theme/theme.dart';
import 'package:flutter_and_friends/updater/updater.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // path_provider has no web implementation; on web HydratedBloc uses
  // browser storage via the `web` sentinel path instead.
  //
  // Deliberately application-*support* directory rather than the temporary
  // directory: the schedule (and favourites, theme, etc.) now persist data
  // worth keeping across app restarts (a fetched schedule, offline
  // availability). The temp directory is OS-evictable under storage
  // pressure and was already being wiped on every debug launch below -
  // both are fine for scratch state but not for "last known good schedule".
  final storageDirectory = kIsWeb
      ? HydratedStorageDirectory.web
      : HydratedStorageDirectory((await getApplicationSupportDirectory()).path);
  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: storageDirectory,
  );
  if (kDebugMode) await HydratedBloc.storage.clear();
  runApp(const App());
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  // Created once and held for the app's lifetime rather than inside build()
  // - the schedule repository's feed URL resolver closes over this same
  // SettingsCubit instance directly (not via context.read, since the
  // repository sits in a RepositoryProvider *above* where SettingsCubit is
  // provided as a bloc) so a debug-only host override takes effect on the
  // very next fetch instead of requiring a rebuild.
  late final _settingsCubit = SettingsCubit()..init();
  late final _scheduleRepository = ScheduleRepository(
    feedUrlResolver: () => kDebugMode && _settingsCubit.state.debugUseLocalFeed
        ? _settingsCubit.state.effectiveFeedUrl
        : scheduleFeedUrl,
  );

  @override
  void dispose() {
    _settingsCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (_) => ShorebirdUpdater()),
        RepositoryProvider.value(value: _scheduleRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: _settingsCubit),
          BlocProvider(create: (_) => ThemeCubit()),
          BlocProvider(
            create: (context) => ScheduleDataCubit(
              repository: context.read<ScheduleRepository>(),
            )..init(),
          ),
          BlocProvider(create: (_) => FavoritesCubit()),
          BlocProvider(
            create: (context) => UpdaterCubit(
              updater: context.read<ShorebirdUpdater>(),
            )..init(),
          ),
          BlocProvider(create: (_) => SponsorsCubit()..init()),
          BlocProvider(create: (_) => OrganizersCubit()..init()),
        ],
        child: const AppView(),
      ),
    );
  }
}

class AppView extends StatelessWidget {
  const AppView({super.key});

  @override
  Widget build(BuildContext context) {
    final themeMode = context.select(
      (ThemeCubit cubit) => cubit.state.toThemeMode(),
    );
    return BlocListener<SettingsCubit, SettingsState>(
      listenWhen: (previous, current) =>
          previous.debugUseLocalFeed != current.debugUseLocalFeed ||
          previous.debugFeedHost != current.debugFeedHost,
      listener: (context, state) {
        // Toggling (or editing) the debug feed override should be visible
        // immediately, not after a restart - re-fetch right away using the
        // now-updated resolver.
        context.read<ScheduleDataCubit>().fetchSchedule();
      },
      child: MaterialApp(
        // Also becomes the browser tab title on web; Flutter overwrites the
        // <title> from index.html with this at runtime.
        title: 'Flutter & Friends',
        debugShowCheckedModeBanner: false,
        home: const UpdateListener(child: LaunchpadPage()),
        themeMode: themeMode,
        theme: lightTheme,
        darkTheme: darkTheme,
      ),
    );
  }
}

extension on ThemeState {
  ThemeMode toThemeMode() {
    return this == ThemeState.dark ? ThemeMode.dark : ThemeMode.light;
  }
}
