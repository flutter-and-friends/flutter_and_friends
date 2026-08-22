<h1 align="center">Flutter & Friends</h1>
<p align="center">
  <a href="https://bloclibrary.dev"><img src="https://tinyurl.com/bloc-library?style=for-the-badge&color=black&labelColor=black" alt="Bloc Library"></a>
  <a href="https://shorebird.dev">    
    <img alt="Powered by Shorebird" src="https://img.shields.io/endpoint?url=https://tinyurl.com/shorebirddev&style=for-the-badge">
  </a>
  <a href="https://pub.dev/packages/very_good_analysis">
    <img alt="style: very good analysis" src="https://img.shields.io/badge/style-very_good_analysis-B22C89.svg?style=for-the-badge">
  </a>  
  <a href="https://opensource.org/licenses/MIT">    
    <img alt="MIT License" src="https://img.shields.io/badge/License-MIT-blue.svg?style=for-the-badge">
  </a>
</p>

![hero](./art/hero.png)

<p align="center">The official <a href="https://www.flutterfriends.dev/">Flutter & Friends</a> conference app.</p>

<p align="center">
  <a href="https://play.google.com/store/apps/details?id=com.felangel.flutter_and_friends"><img alt="Get it on Google Play" src="art/google_play_badge.png" height="80px"/></a>
  <a href="https://apps.apple.com/us/app/flutter-friends/id6462616068"><img alt="Get it on AppStore" src="art/appstore_badge.png" height="80px"/></a>
</p>

## Audience Q&A

The Q&A tab lets attendees ask the panel questions and upvote each other's questions. Questions and votes are shared between all attendees, so they live in Firestore in the same Firebase project as the [website](https://github.com/flutter-and-friends/flutter_friends_web). The app signs every device in with anonymous Firebase Auth, and the security rules in [`firebase/firestore.rules`](firebase/firestore.rules) tie each question and vote to that identity.

### Local development

Debug builds talk to the local Firebase emulators by default, so no project access is needed:

```sh
npx firebase-tools emulators:start --project demo-flutter-and-friends --config firebase/firebase.json
flutter run
```

On an Android emulator the app reaches the emulators through `10.0.2.2` automatically. Pass `--dart-define=USE_FIREBASE_EMULATORS=false` to debug against the real project instead.

### Connecting the real project

[`lib/firebase_options.dart`](lib/firebase_options.dart) is a placeholder until the app is registered in the Firebase project. Generate the real one with [FlutterFire](https://firebase.google.com/docs/flutter/setup):

```sh
dart pub global activate flutterfire_cli
flutterfire configure --project=flutter-and-friends-ad8fe
```

Then enable the Anonymous sign-in provider under Authentication in the Firebase console and deploy the security rules:

```sh
npx firebase-tools deploy --only firestore --config firebase/firebase.json
```

Release builds without the real options show the Q&A tab as unavailable instead of failing.
