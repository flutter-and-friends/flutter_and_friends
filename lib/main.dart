import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_and_friends/favorites/favorites.dart';
import 'package:flutter_and_friends/launchpad/launchpad.dart';
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
  final storageDirectory = kIsWeb
      ? HydratedStorageDirectory.web
      : HydratedStorageDirectory((await getTemporaryDirectory()).path);
  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: storageDirectory,
  );
  if (kDebugMode) await HydratedBloc.storage.clear();
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
      create: (_) => ShorebirdUpdater(),
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => ThemeCubit()),
          BlocProvider(create: (_) => FavoritesCubit()),
          BlocProvider(
            create: (context) => UpdaterCubit(
              updater: context.read<ShorebirdUpdater>(),
            )..init(),
          ),
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
    return MaterialApp(
      // Also becomes the browser tab title on web; Flutter overwrites the
      // <title> from index.html with this at runtime.
      title: 'Flutter & Friends',
      debugShowCheckedModeBanner: false,
      home: const UpdateListener(child: LaunchpadPage()),
      themeMode: themeMode,
      theme: lightTheme,
      darkTheme: darkTheme,
    );
  }
}

extension on ThemeState {
  ThemeMode toThemeMode() {
    return this == ThemeState.dark ? ThemeMode.dark : ThemeMode.light;
  }
}
