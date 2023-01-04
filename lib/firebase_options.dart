// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDtL8RIt6V77H3WZxhNNrz8l0mCx36lJTY',
    appId: '1:939168091449:web:fe391ce8545ba4f1922ce8',
    messagingSenderId: '939168091449',
    projectId: 'sentinela-68110',
    authDomain: 'sentinela-68110.firebaseapp.com',
    storageBucket: 'sentinela-68110.appspot.com',
    measurementId: 'G-3S4JK2HSSJ',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD2MbTddJIk_rWTMFJ14PNLbo2LT7p2Qeo',
    appId: '1:939168091449:android:dac4d3d1325b3478922ce8',
    messagingSenderId: '939168091449',
    projectId: 'sentinela-68110',
    storageBucket: 'sentinela-68110.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyB11SkbqTqjjIo2lrh1GPXxilGdmI0yfrc',
    appId: '1:939168091449:ios:41789318d4193cf0922ce8',
    messagingSenderId: '939168091449',
    projectId: 'sentinela-68110',
    storageBucket: 'sentinela-68110.appspot.com',
    iosClientId: '939168091449-u11o27rrfm8cm5kjbkasof2pk4dsijou.apps.googleusercontent.com',
    iosBundleId: 'com.example.sentinela',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyB11SkbqTqjjIo2lrh1GPXxilGdmI0yfrc',
    appId: '1:939168091449:ios:41789318d4193cf0922ce8',
    messagingSenderId: '939168091449',
    projectId: 'sentinela-68110',
    storageBucket: 'sentinela-68110.appspot.com',
    iosClientId: '939168091449-u11o27rrfm8cm5kjbkasof2pk4dsijou.apps.googleusercontent.com',
    iosBundleId: 'com.example.sentinela',
  );
}
