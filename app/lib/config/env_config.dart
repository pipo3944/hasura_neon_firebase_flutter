import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Environment configuration manager
///
/// Loads environment variables from .env.dev or .env.prod based on build flavor
class EnvConfig {
  /// Hasura GraphQL endpoint
  static String get hasuraEndpoint => dotenv.env['HASURA_ENDPOINT'] ?? '';

  /// Firebase Project ID
  static String get firebaseProjectId =>
      dotenv.env['FIREBASE_PROJECT_ID'] ?? '';

  /// Current environment (dev/prod)
  static String get environment => dotenv.env['ENV'] ?? 'dev';

  /// Check if current environment is dev
  static bool get isDev => environment == 'dev';

  /// Check if current environment is prod
  static bool get isProd => environment == 'prod';

  /// Load environment variables from .env file
  ///
  /// [flavor] should be 'dev' or 'prod'
  static Future<void> load({required String flavor}) async {
    final fileName = '.env.$flavor';
    await dotenv.load(fileName: fileName);
  }
}
