import 'package:rootbound/models/habit.dart';
import 'package:rootbound/supabase/supabase_config.dart';
import 'package:uuid/uuid.dart';

class HabitService {
  static const String _table = 'habits';
  static const _uuid = Uuid();

  /// Get all habits for a user
  static Future<List<Habit>> getHabits(String userId) async {
    try {
      final data = await SupabaseService.select(
        _table,
        filters: {'user_id': userId},
        orderBy: 'created_at',
        ascending: false,
      );
      return data.map((json) => Habit.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load habits: $e');
    }
  }

  /// Get a single habit by ID
  static Future<Habit?> getHabit(String id, String userId) async {
    try {
      final data = await SupabaseService.selectSingle(
        _table,
        filters: {'id': id, 'user_id': userId},
      );
      return data != null ? Habit.fromJson(data) : null;
    } catch (e) {
      throw Exception('Failed to load habit: $e');
    }
  }

  /// Create a new habit
  static Future<Habit> createHabit({
    required String userId,
    required String name,
    required String icon,
    required String color,
  }) async {
    try {
      final now = DateTime.now();
      final habit = Habit(
        id: _uuid.v4(),
        userId: userId,
        name: name,
        icon: icon,
        color: color,
        isCompleted: false,
        streak: 0,
        createdAt: now,
        updatedAt: now,
      );
      
      final data = await SupabaseService.insert(_table, habit.toJson());
      return Habit.fromJson(data.first);
    } catch (e) {
      throw Exception('Failed to create habit: $e');
    }
  }

  /// Update an existing habit
  static Future<Habit> updateHabit(Habit habit) async {
    try {
      final updatedHabit = habit.copyWith(updatedAt: DateTime.now());
      final data = await SupabaseService.update(
        _table,
        updatedHabit.toJson(),
        filters: {'id': habit.id, 'user_id': habit.userId},
      );
      return Habit.fromJson(data.first);
    } catch (e) {
      throw Exception('Failed to update habit: $e');
    }
  }

  /// Toggle habit completion status
  static Future<Habit> toggleCompletion(Habit habit) async {
    try {
      final updatedHabit = habit.copyWith(
        isCompleted: !habit.isCompleted,
        streak: !habit.isCompleted ? habit.streak + 1 : habit.streak,
        updatedAt: DateTime.now(),
      );
      return await updateHabit(updatedHabit);
    } catch (e) {
      throw Exception('Failed to toggle habit completion: $e');
    }
  }

  /// Delete a habit
  static Future<void> deleteHabit(String id, String userId) async {
    try {
      await SupabaseService.delete(
        _table,
        filters: {'id': id, 'user_id': userId},
      );
    } catch (e) {
      throw Exception('Failed to delete habit: $e');
    }
  }

  /// Get today's habits for a user
  static Future<List<Habit>> getTodayHabits(String userId) async {
    try {
      return await getHabits(userId);
    } catch (e) {
      throw Exception('Failed to load today\'s habits: $e');
    }
  }

  /// Reset all habits completion status (for new day)
  static Future<void> resetDailyCompletions(String userId) async {
    try {
      final habits = await getHabits(userId);
      for (final habit in habits) {
        if (habit.isCompleted) {
          await updateHabit(habit.copyWith(isCompleted: false));
        }
      }
    } catch (e) {
      throw Exception('Failed to reset daily completions: $e');
    }
  }
}
