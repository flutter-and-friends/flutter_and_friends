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

The Q&A tab lets attendees ask the panel questions and upvote each other's questions. Questions and votes are shared between all attendees, so they live in Firestore in the same Firebase project as the [website](https://github.com/flutter-and-friends/flutter_friends_web) (`flutter-and-friends-ad8fe`). The app signs every device in with anonymous Firebase Auth, and the security rules in [`firestore.rules`](firestore.rules) tie each question and vote to that identity.

## Pub quiz

The Pub Quiz entry under More lets a table play the live quiz that an organizer runs from the website's `/admin/quiz` page. Each phone creates one team (keyed by the same anonymous identity as the Q&A), answers the open question once, and follows the reveal and the scoreboard as the website's server moves the quiz forward. The server publishes questions, closes them, scores the answers (two points for a correct answer, one more for the three fastest correct teams) and writes the standings; the rules in [`firestore.rules`](firestore.rules) make sure a phone can only ever create its own team and one immutable, server-timestamped answer per open question, and never sees the correct answer before it is revealed.

### Local development

Debug builds talk to the local Firebase emulators by default, so no project access is needed. The emulators need a JDK; on a machine with Android Studio, point `JAVA_HOME` at its bundled one:

```sh
export JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
npx firebase-tools emulators:start --only auth,firestore
flutter run
```

On an Android emulator the app reaches the emulators through `10.0.2.2` automatically. Pass `--dart-define=USE_FIREBASE_EMULATORS=false` to debug against the real project instead. Uninstall the app when switching between the emulators and the real project: the anonymous user and Firestore's offline cache persist per install, and a user issued by the Auth emulator is rejected by production.

### Firebase project

[`lib/firebase_options.dart`](lib/firebase_options.dart) and the platform config files were generated with [FlutterFire](https://firebase.google.com/docs/flutter/setup); re-run `flutterfire configure --project=flutter-and-friends-ad8fe` to add a platform or refresh them. The security rules are deployed with:

```sh
npx firebase-tools deploy --only firestore
```

The Anonymous sign-in provider must be enabled under Authentication in the Firebase console for the Q&A and the pub quiz to work.

## Releasing

Releases are versioned with [melos](https://melos.invertase.dev) from the conventional commit history, so PR titles must follow the [conventional commits](https://www.conventionalcommits.org) format (enforced by the `PR title is conventional` workflow). `feat` bumps the minor version, `fix`, `perf`, `refactor` and `revert` bump the patch version, and the build number is incremented on every release.

1. Run the [Prepare release](https://github.com/flutter-and-friends/flutter_and_friends/actions/workflows/release-prepare.yaml) workflow. It bumps the version in `pubspec.yaml`, updates `CHANGELOG.md`, and opens a `chore(release)` PR.
2. Review and merge the PR. The `Tag release` workflow tags the merge commit as `flutter_and_friends-v<version>` and starts the `release` workflow on that tag, which builds and uploads the Android and iOS releases through Shorebird.

The `release` workflow can also be started by hand from the Actions tab (pick the release tag under "Use workflow from") to retry a failed build.
