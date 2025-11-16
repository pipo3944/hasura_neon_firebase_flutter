import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../providers/auth_provider.dart';

/// Home screen (shown after successful login)
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final authService = ref.read(authServiceProvider);
              await authService.signOut();
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : _HomeContent(user: user),
    );
  }
}

class _HomeContent extends StatelessWidget {
  final User user;

  const _HomeContent({required this.user});

  @override
  Widget build(BuildContext context) {
    return Query(
      options: QueryOptions(
        document: gql(r'''
          query GetUser($id: uuid!) {
            users_by_pk(id: $id) {
              id
              email
              name
              role
              tenant_id
              organization {
                id
                name
                slug
                code
              }
            }
          }
        '''),
        variables: {'id': user.uid},
      ),
      builder: (result, {fetchMore, refetch}) {
        if (result.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (result.hasException) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${result.exception}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => refetch?.call(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final userData = result.data?['users_by_pk'];
        if (userData == null) {
          return const Center(child: Text('User not found'));
        }

        final organization = userData['organization'];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            child: Text(
                              userData['name']?[0]?.toUpperCase() ?? 'U',
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Welcome, ${userData['name'] ?? 'User'}!',
                                  style: Theme.of(context).textTheme.headlineSmall,
                                ),
                                Text(
                                  userData['email'] ?? '',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // User info section
              const Text(
                'User Information',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _InfoRow(
                        label: 'User ID',
                        value: userData['id'] ?? '',
                      ),
                      const Divider(),
                      _InfoRow(
                        label: 'Role',
                        value: userData['role'] ?? 'user',
                        valueColor: _getRoleColor(userData['role']),
                      ),
                      const Divider(),
                      _InfoRow(
                        label: 'Firebase Auth',
                        value: user.uid,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Organization info section
              if (organization != null) ...[
                const Text(
                  'Organization',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _InfoRow(
                          label: 'Name',
                          value: organization['name'] ?? '',
                        ),
                        const Divider(),
                        _InfoRow(
                          label: 'Code',
                          value: organization['code'] ?? '',
                        ),
                        const Divider(),
                        _InfoRow(
                          label: 'Slug',
                          value: organization['slug'] ?? '',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),

              // JWT Token info
              const Text(
                'Authentication',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'JWT Token Status',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      FutureBuilder<IdTokenResult?>(
                        future: user.getIdTokenResult(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const CircularProgressIndicator();
                          }
                          if (snapshot.hasError) {
                            return Text('Error: ${snapshot.error}');
                          }
                          final tokenResult = snapshot.data;
                          if (tokenResult == null) {
                            return const Text('No token');
                          }

                          final claims = tokenResult.claims ?? {};
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Role: ${claims['role'] ?? 'N/A'}'),
                              Text('Tenant ID: ${claims['tenant_id'] ?? 'N/A'}'),
                              Text('Issued: ${tokenResult.issuedAtTime}'),
                              Text('Expires: ${tokenResult.expirationTime}'),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getRoleColor(String? role) {
    switch (role) {
      case 'admin':
        return Colors.red;
      case 'tenant_admin':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontWeight: valueColor != null ? FontWeight.bold : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
