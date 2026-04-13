// TODO: Replace this file by running `flutterfire configure` after creating
// your Firebase project at https://console.firebase.google.com
//
// This placeholder allows the app to compile. You MUST replace it with real
// Firebase config before running on a device.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // Placeholder values - replace with real config from flutterfire configure
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'YOUR-API-KEY',
    appId: '1:000000000000:android:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'habit-quest-app',
    storageBucket: 'habit-quest-app.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR-API-KEY',
    appId: '1:000000000000:ios:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'habit-quest-app',
    storageBucket: 'habit-quest-app.appspot.com',
    iosBundleId: 'com.habitquest.habitQuest',
  );
}
