// Firebase Options - Flavor-aware configuration
// This file supports dev/prod environments
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Flavor-aware [FirebaseOptions] for use with your Firebase apps.
///
/// Usage:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform(flavor: 'dev'),
/// );
/// ```
class DefaultFirebaseOptions {
  /// Get Firebase options for the current platform and flavor
  ///
  /// [flavor] should be 'dev' or 'prod'
  static FirebaseOptions currentPlatform({required String flavor}) {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web',
      );
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _getAndroidOptions(flavor);
      case TargetPlatform.iOS:
        return _getIosOptions(flavor);
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for $defaultTargetPlatform',
        );
    }
  }

  // Dev environment - Android
  static const FirebaseOptions _androidDev = FirebaseOptions(
    apiKey: 'AIzaSyB_G_RZpikkPJvrMuVD_UtEN_VvMJa4KKo',
    appId: '1:708502679003:android:f535e6567934be8bde4bfe',
    messagingSenderId: '708502679003',
    projectId: 'hasura-flutter-dev',
    storageBucket: 'hasura-flutter-dev.firebasestorage.app',
  );

  // Prod environment - Android
  static const FirebaseOptions _androidProd = FirebaseOptions(
    apiKey: 'AIzaSyDOuVBQ0aW3Km-O5h4qDu9BnIJAx3DJDGo',
    appId: '1:1054398154478:android:e04f6e84dcbae5a7e52ad9',
    messagingSenderId: '1054398154478',
    projectId: 'hasura-flutter-prod',
    storageBucket: 'hasura-flutter-prod.firebasestorage.app',
  );

  // Dev environment - iOS
  static const FirebaseOptions _iosDev = FirebaseOptions(
    apiKey: 'AIzaSyCNp1GdhjEFi0sYhsumv0sKd1YKfCeMOL0',
    appId: '1:708502679003:ios:377364b010db6f44de4bfe',
    messagingSenderId: '708502679003',
    projectId: 'hasura-flutter-dev',
    storageBucket: 'hasura-flutter-dev.firebasestorage.app',
    iosBundleId: 'com.mizunoyusei.hasuraFlutter.dev',
  );

  // Prod environment - iOS
  static const FirebaseOptions _iosProd = FirebaseOptions(
    apiKey: 'AIzaSyDCLj_p3VMY5qvdTwYBOpIwbGm0aDsRQog',
    appId: '1:1054398154478:ios:fd56e9eda1a61dbee52ad9',
    messagingSenderId: '1054398154478',
    projectId: 'hasura-flutter-prod',
    storageBucket: 'hasura-flutter-prod.firebasestorage.app',
    iosBundleId: 'com.mizunoyusei.hasuraFlutter',
  );

  static FirebaseOptions _getAndroidOptions(String flavor) {
    switch (flavor) {
      case 'dev':
        return _androidDev;
      case 'prod':
        return _androidProd;
      default:
        throw ArgumentError('Unknown flavor: $flavor');
    }
  }

  static FirebaseOptions _getIosOptions(String flavor) {
    switch (flavor) {
      case 'dev':
        return _iosDev;
      case 'prod':
        return _iosProd;
      default:
        throw ArgumentError('Unknown flavor: $flavor');
    }
  }
}
