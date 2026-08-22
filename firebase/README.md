# Firebase

Firestore security rules for the app's Firebase-backed features, deployed to
the same Firebase project as the conference website
(`flutter-and-friends-ad8fe`, see `.firebaserc`).

## Deploy the rules

```sh
npx firebase-tools deploy --only firestore
```

## Run the emulators for local development

Debug builds of the app use the local emulators by default (see
`lib/config/config.dart`), so start them before running the app:

```sh
npx firebase-tools emulators:start --project demo-flutter-and-friends
```

The `demo-` project id tells the emulators not to look for a real project.
