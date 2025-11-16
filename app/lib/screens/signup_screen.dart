import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../providers/auth_provider.dart';

/// Signup screen with optional organization code
class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _orgCodeController = TextEditingController();
  bool _isLoading = false;
  bool _showOrgCodeField = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _orgCodeController.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider);

      // 1. Create Firebase user
      final user = await authService.signUpWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        displayName: _nameController.text.trim(),
      );

      // 2. Get organization ID (validate code or use default)
      final graphqlClient = ref.read(graphqlClientProvider).value;
      String? tenantId;

      if (_showOrgCodeField && _orgCodeController.text.isNotEmpty) {
        // Validate organization code
        tenantId = await _validateOrgCode(
          graphqlClient,
          _orgCodeController.text.trim(),
        );
      } else {
        // Use default organization
        tenantId = await _getDefaultOrgId(graphqlClient);
      }

      if (tenantId == null) {
        throw Exception('Failed to get organization');
      }

      // 3. Sync user to Hasura database
      await _syncUserToHasura(
        graphqlClient,
        userId: user.uid,
        email: user.email!,
        name: _nameController.text.trim(),
        tenantId: tenantId,
      );

      // Navigation is handled by SplashScreen via authStateProvider
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = _getFirebaseErrorMessage(e.code);
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<String?> _validateOrgCode(GraphQLClient client, String code) async {
    const query = r'''
      query ValidateOrgCode($code: String!) {
        organizations(where: { code: { _eq: $code }, deleted_at: { _is_null: true } }) {
          id
        }
      }
    ''';

    final result = await client.query(
      QueryOptions(
        document: gql(query),
        variables: {'code': code},
      ),
    );

    if (result.hasException) {
      throw Exception('Organization validation failed: ${result.exception}');
    }

    final orgs = result.data?['organizations'] as List?;
    if (orgs == null || orgs.isEmpty) {
      throw Exception('Invalid organization code');
    }

    return orgs.first['id'] as String;
  }

  Future<String?> _getDefaultOrgId(GraphQLClient client) async {
    const query = r'''
      query GetDefaultOrg {
        organizations(where: { deleted_at: { _is_null: true } }, limit: 1, order_by: { created_at: asc }) {
          id
        }
      }
    ''';

    final result = await client.query(
      QueryOptions(
        document: gql(query),
      ),
    );

    if (result.hasException) {
      throw Exception('Failed to get default organization: ${result.exception}');
    }

    final orgs = result.data?['organizations'] as List?;
    if (orgs == null || orgs.isEmpty) {
      throw Exception('No organizations available');
    }

    return orgs.first['id'] as String;
  }

  Future<void> _syncUserToHasura(
    GraphQLClient client, {
    required String userId,
    required String email,
    required String name,
    required String tenantId,
  }) async {
    const mutation = r'''
      mutation UpsertUser($id: uuid!, $email: String!, $name: String, $tenantId: uuid!) {
        insert_users_one(
          object: {
            id: $id
            email: $email
            name: $name
            tenant_id: $tenantId
          }
          on_conflict: {
            constraint: users_pkey
            update_columns: [email, name, updated_at]
          }
        ) {
          id
        }
      }
    ''';

    final result = await client.mutate(
      MutationOptions(
        document: gql(mutation),
        variables: {
          'id': userId,
          'email': email,
          'name': name,
          'tenantId': tenantId,
        },
      ),
    );

    if (result.hasException) {
      throw Exception('User sync failed: ${result.exception}');
    }
  }

  String _getFirebaseErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'This email is already registered';
      case 'invalid-email':
        return 'Invalid email address';
      case 'weak-password':
        return 'Password is too weak';
      default:
        return 'Signup failed: $code';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Up'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo or title
                  const Icon(
                    Icons.person_add,
                    size: 80,
                    color: Colors.deepPurple,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Create Account',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Name field
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Email field
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Confirm password field
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Confirm Password',
                      prefixIcon: Icon(Icons.lock_outline),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Organization code toggle
                  SwitchListTile(
                    title: const Text('I have an organization code'),
                    value: _showOrgCodeField,
                    onChanged: (value) {
                      setState(() {
                        _showOrgCodeField = value;
                      });
                    },
                  ),

                  // Organization code field (conditional)
                  if (_showOrgCodeField) ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _orgCodeController,
                      decoration: const InputDecoration(
                        labelText: 'Organization Code',
                        prefixIcon: Icon(Icons.business),
                        border: OutlineInputBorder(),
                        hintText: 'e.g., ACME2024',
                      ),
                      validator: (value) {
                        if (_showOrgCodeField && (value == null || value.isEmpty)) {
                          return 'Please enter organization code';
                        }
                        return null;
                      },
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Error message
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  if (_errorMessage != null) const SizedBox(height: 16),

                  // Signup button
                  FilledButton(
                    onPressed: _isLoading ? null : _signup,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Sign Up'),
                  ),
                  const SizedBox(height: 16),

                  // Login link
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Already have an account? Login'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
