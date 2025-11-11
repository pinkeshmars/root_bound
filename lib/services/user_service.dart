import 'package:rootbound/models/user.dart';
import 'package:rootbound/supabase/supabase_config.dart';

class UserService {
  static const String _table = 'users';

  /// Get user by ID
  static Future<User?> getUser(String userId) async {
    try {
      final data = await SupabaseService.selectSingle(
        _table,
        filters: {'id': userId},
      );
      return data != null ? User.fromJson(data) : null;
    } catch (e) {
      throw Exception('Failed to load user: $e');
    }
  }

  /// Create or update user profile
  static Future<User> upsertUser({
    required String id,
    required String email,
    String? displayName,
  }) async {
    try {
      final now = DateTime.now();
      final existingUser = await getUser(id);
      
      if (existingUser != null) {
        // Update existing user
        final updatedUser = existingUser.copyWith(
          email: email,
          displayName: displayName,
          updatedAt: now,
        );
        final data = await SupabaseService.update(
          _table,
          updatedUser.toJson(),
          filters: {'id': id},
        );
        return User.fromJson(data.first);
      } else {
        // Create new user
        final newUser = User(
          id: id,
          email: email,
          displayName: displayName,
          createdAt: now,
          updatedAt: now,
        );
        final data = await SupabaseService.insert(_table, newUser.toJson());
        return User.fromJson(data.first);
      }
    } catch (e) {
      throw Exception('Failed to upsert user: $e');
    }
  }

  /// Update user profile
  static Future<User> updateUser(User user) async {
    try {
      final updatedUser = user.copyWith(updatedAt: DateTime.now());
      final data = await SupabaseService.update(
        _table,
        updatedUser.toJson(),
        filters: {'id': user.id},
      );
      return User.fromJson(data.first);
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  /// Delete user
  static Future<void> deleteUser(String userId) async {
    try {
      await SupabaseService.delete(
        _table,
        filters: {'id': userId},
      );
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    }
  }
}
