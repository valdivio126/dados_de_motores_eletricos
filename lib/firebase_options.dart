import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAK97vQHA0L0HPcswVHPjZqbitIoOScupA',
    appId: '1:628130412825:web:4d8fd03ac4b9421dda6d88',
    messagingSenderId: '628130412825',
    projectId: 'dados-motores-eletricos',
    authDomain: 'dados-motores-eletricos.firebaseapp.com',
    storageBucket: 'dados-motores-eletricos.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAK97vQHA0L0HPcswVHPjZqbitIoOScupA',
    appId: '1:628130412825:web:4d8fd03ac4b9421dda6d88',
    messagingSenderId: '628130412825',
    projectId: 'dados-motores-eletricos',
    storageBucket: 'dados-motores-eletricos.firebasestorage.app',
  );
  
  static const FirebaseOptions ios = web;
  static const FirebaseOptions macos = web;
  static const FirebaseOptions windows = web;
}