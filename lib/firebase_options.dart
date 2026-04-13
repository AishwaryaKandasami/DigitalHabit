import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
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

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyC5Q0gKbe1utp43qRcTpkwikh5NiZBOIJ4',
    appId: '1:485095313131:web:94bce993389bbb0a8938ae',
    messagingSenderId: '485095313131',
    projectId: 'habitquest-2b29f',
    storageBucket: 'habitquest-2b29f.firebasestorage.app',
    authDomain: 'habitquest-2b29f.firebaseapp.com',
    measurementId: 'G-7S0WZNNKFD',
  );

  // Android and iOS use the same project — add platform-specific apps
  // in Firebase Console if you want to build native mobile later.
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC5Q0gKbe1utp43qRcTpkwikh5NiZBOIJ4',
    appId: '1:485095313131:web:94bce993389bbb0a8938ae',
    messagingSenderId: '485095313131',
    projectId: 'habitquest-2b29f',
    storageBucket: 'habitquest-2b29f.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyC5Q0gKbe1utp43qRcTpkwikh5NiZBOIJ4',
    appId: '1:485095313131:web:94bce993389bbb0a8938ae',
    messagingSenderId: '485095313131',
    projectId: 'habitquest-2b29f',
    storageBucket: 'habitquest-2b29f.firebasestorage.app',
    iosBundleId: 'com.habitquest.habitQuest',
  );
}
