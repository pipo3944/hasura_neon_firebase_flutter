import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

/// Cloud Functions service for calling server-side functions
class CloudFunctionsService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Refresh current user's custom claims
  ///
  /// Call this after the user's role or tenant has been changed
  /// to update their JWT token with the latest claims
  Future<Map<String, dynamic>> refreshCustomClaims() async {
    try {
      if (kDebugMode) {
        print('Calling refreshCustomClaims function...');
      }

      final callable = _functions.httpsCallable('refreshCustomClaims');
      final result = await callable.call();

      if (kDebugMode) {
        print('Claims refreshed: ${result.data}');
      }

      return result.data as Map<String, dynamic>;
    } catch (e) {
      if (kDebugMode) {
        print('Error refreshing custom claims: $e');
      }
      rethrow;
    }
  }
}
