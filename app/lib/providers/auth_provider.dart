import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../config/graphql_config.dart';
import '../services/auth_service.dart';

/// Auth service provider
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Current user stream provider
final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

/// GraphQL client provider (automatically updates with auth state)
final graphqlClientProvider = Provider<ValueNotifier<GraphQLClient>>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.value;

  return GraphQLConfig.initializeClient(user: user);
});
