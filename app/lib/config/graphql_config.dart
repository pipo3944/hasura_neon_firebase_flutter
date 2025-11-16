import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'env_config.dart';

/// GraphQL client configuration
class GraphQLConfig {
  /// Create GraphQL client with Firebase Auth token
  static GraphQLClient createClient({User? user}) {
    final httpLink = HttpLink(EnvConfig.hasuraEndpoint);

    final authLink = AuthLink(
      getToken: () async {
        if (user != null) {
          // Get Firebase ID Token
          final token = await user.getIdToken();
          return 'Bearer $token';
        }
        return null;
      },
    );

    final link = authLink.concat(httpLink);

    return GraphQLClient(
      cache: GraphQLCache(store: InMemoryStore()),
      link: link,
      defaultPolicies: DefaultPolicies(
        query: Policies(
          fetch: FetchPolicy.networkOnly,
        ),
        mutate: Policies(
          fetch: FetchPolicy.networkOnly,
        ),
      ),
    );
  }

  /// Initialize GraphQL client provider
  static ValueNotifier<GraphQLClient> initializeClient({User? user}) {
    return ValueNotifier<GraphQLClient>(
      createClient(user: user),
    );
  }

  /// Update GraphQL client when user authentication state changes
  static void updateClient(
    ValueNotifier<GraphQLClient> clientNotifier, {
    User? user,
  }) {
    if (kDebugMode) {
      print('Updating GraphQL client with user: ${user?.uid}');
    }
    clientNotifier.value = createClient(user: user);
  }
}
