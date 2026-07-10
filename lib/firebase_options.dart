import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Firebase config for the shared Closero project, the same backend the
/// marketing site uses. Values mirror closero-site/assets/js/firebase-init.js
/// (checked-in copy: context/js/firebase-init.js) and are safe to commit.
///
/// v1 ships web only. iOS/Android options are added when those targets land
/// (via `flutterfire configure`, which will rewrite this file).
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    throw UnsupportedError(
      'DefaultFirebaseOptions has no options for this platform yet. '
      'v1 targets web; run flutterfire configure when adding iOS/Android.',
    );
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBQHV40AAxbYtFDdNJP_OtW9W1FFmQFDzA',
    appId: '1:751996788920:web:c476d09cde4304f6e5944d',
    messagingSenderId: '751996788920',
    projectId: 'closero',
    authDomain: 'closero.firebaseapp.com',
    storageBucket: 'closero.firebasestorage.app',
    measurementId: 'G-5JJEJ283H7',
  );
}
