import 'package:flutter/material.dart';
import 'package:rootbound/auth/auth_manager.dart';
import 'package:rootbound/models/user.dart';
import 'package:rootbound/supabase/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

class SupabaseAuthManager extends AuthManager with EmailSignInManager {
  static final SupabaseAuthManager _instance = SupabaseAuthManager._internal();
  factory SupabaseAuthManager() => _instance;
  SupabaseAuthManager._internal();

  sb.GoTrueClient get _auth => SupabaseConfig.auth;

  /// Get the current authenticated user
  User? get currentUser {
    final sbUser = _auth.currentUser;
    if (sbUser == null) return null;
    
    return User(
      id: sbUser.id,
      email: sbUser.email ?? '',
      displayName: sbUser.userMetadata?['display_name'] as String?,
      createdAt: DateTime.parse(sbUser.createdAt),
      updatedAt: DateTime.now(),
    );
  }

  /// Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.onAuthStateChange.map((data) {
    final sbUser = data.session?.user;
    if (sbUser == null) return null;
    
    return User(
      id: sbUser.id,
      email: sbUser.email ?? '',
      displayName: sbUser.userMetadata?['display_name'] as String?,
      createdAt: DateTime.parse(sbUser.createdAt),
      updatedAt: DateTime.now(),
    );
  });

  @override
  Future<User?> signInWithEmail(
    BuildContext context,
    String email,
    String password,
  ) async {
    try {
      final response = await _auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user == null) return null;
      
      final user = User(
        id: response.user!.id,
        email: response.user!.email ?? '',
        displayName: response.user!.userMetadata?['display_name'] as String?,
        createdAt: DateTime.parse(response.user!.createdAt),
        updatedAt: DateTime.now(),
      );

      // Ensure user exists in database
      await _ensureUserInDatabase(user);
      
      return user;
    } on sb.AuthException catch (e) {
      if (context.mounted) {
        _showError(context, e.message);
      }
      return null;
    } catch (e) {
      if (context.mounted) {
        _showError(context, 'Failed to sign in: $e');
      }
      return null;
    }
  }

  @override
  Future<User?> createAccountWithEmail(
    BuildContext context,
    String email,
    String password,
  ) async {
    try {
      final response = await _auth.signUp(
        email: email,
        password: password,
      );
      
      if (response.user == null) return null;
      
      final user = User(
        id: response.user!.id,
        email: response.user!.email ?? '',
        displayName: null,
        createdAt: DateTime.parse(response.user!.createdAt),
        updatedAt: DateTime.now(),
      );

      // Create user in database
      await _ensureUserInDatabase(user);
      
      return user;
    } on sb.AuthException catch (e) {
      if (context.mounted) {
        _showError(context, e.message);
      }
      return null;
    } catch (e) {
      if (context.mounted) {
        _showError(context, 'Failed to create account: $e');
      }
      return null;
    }
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }

  @override
  Future<void> deleteUser(BuildContext context) async {
    try {
      final userId = currentUser?.id;
      if (userId == null) return;
      
      // Delete user data
      await SupabaseConfig.client.from('habits').delete().eq('user_id', userId);
      await SupabaseConfig.client.from('users').delete().eq('id', userId);
      
      // Delete auth user (requires service_role key, might not work with anon key)
      // await _auth.admin.deleteUser(userId);
      
      await signOut();
    } catch (e) {
      if (context.mounted) {
        _showError(context, 'Failed to delete account: $e');
      }
    }
  }

  @override
  Future<void> updateEmail({
    required String email,
    required BuildContext context,
  }) async {
    try {
      await _auth.updateUser(sb.UserAttributes(email: email));
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email updated successfully')),
        );
      }
    } on sb.AuthException catch (e) {
      if (context.mounted) {
        _showError(context, e.message);
      }
    }
  }

  @override
  Future<void> resetPassword({
    required String email,
    required BuildContext context,
  }) async {
    try {
      await _auth.resetPasswordForEmail(email);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset email sent')),
        );
      }
    } on sb.AuthException catch (e) {
      if (context.mounted) {
        _showError(context, e.message);
      }
    }
  }

  /// Ensure user exists in database
  Future<void> _ensureUserInDatabase(User user) async {
    try {
      final existingUser = await SupabaseConfig.client
          .from('users')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (existingUser == null) {
        await SupabaseConfig.client.from('users').insert(user.toJson());
      }
    } catch (e) {
      debugPrint('Error ensuring user in database: $e');
    }
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
