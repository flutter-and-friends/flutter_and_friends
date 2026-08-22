// Placeholder Firebase configuration. Replace it by running
//
//   flutterfire configure --project=flutter-and-friends-ad8fe
//
// which overwrites this file with the real options for the conference's
// Firebase project (the same project the website deploys to). Until then
// only debug builds, which talk to the local Firebase emulators, can use the
// Firebase-backed features; see `isQaConfigured` in `config.dart`.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static bool get isSupportedPlatform {
    if (kIsWeb) return true;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android ||
      TargetPlatform.iOS ||
      TargetPlatform.macOS => true,
      TargetPlatform.windows ||
      TargetPlatform.linux ||
      TargetPlatform.fuchsia => false,
    };
  }

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  /// Project ids starting with `demo-` are what the Firebase emulator
  /// suite accepts without any real project behind them.
  static const placeholderProjectId = 'demo-flutter-and-friends';

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'placeholder',
    appId: '1:0:web:placeholder',
    messagingSenderId: '0',
    projectId: placeholderProjectId,
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'placeholder',
    appId: '1:0:android:placeholder',
    messagingSenderId: '0',
    projectId: placeholderProjectId,
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'placeholder',
    appId: '1:0:ios:placeholder',
    messagingSenderId: '0',
    projectId: placeholderProjectId,
    iosBundleId: 'com.felangel.flutterAndFriends',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'placeholder',
    appId: '1:0:ios:placeholder',
    messagingSenderId: '0',
    projectId: placeholderProjectId,
    iosBundleId: 'com.felangel.flutterAndFriends',
  );
}
