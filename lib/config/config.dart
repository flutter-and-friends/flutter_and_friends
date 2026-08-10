import 'package:flutter/foundation.dart';

export 'version.dart';

/// Public schedule feed published by the conference website alongside the
/// site itself. Served with permissive CORS and a short cache lifetime so a
/// mid-conference change reaches the app quickly.
const scheduleFeedUrl = 'https://flutterfriends.dev/schedule.json';

/// Debug-only default for the local feed host override (see
/// `SettingsCubit.debugUseLocalFeed`). On an Android emulator `localhost`
/// resolves to the emulator itself, not the host machine serving the feed -
/// `10.0.2.2` is the documented alias back to the host loopback interface.
/// Every other target (web, iOS simulator, desktop) reaches the host
/// directly via `localhost`.
String get defaultDebugFeedHost {
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:4500';
  }
  return 'http://localhost:4500';
}
