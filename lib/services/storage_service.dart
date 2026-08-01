import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/habit.dart';

class StorageService {
  static const String _habitsKey = 'habit_tracker_habits';
  static const String _themeKey = 'habit_tracker_theme';
  static const String _reminderEnabledKey = 'habit_tracker_reminder_enabled';
  static const String _reminderHourKey = 'habit_tracker_reminder_hour';
  static const String _reminderMinuteKey = 'habit_tracker_reminder_minute';
  static const String _firstLaunchDateKey = 'habit_tracker_first_launch_date';

  Future<void> saveHabits(List<Habit> habits) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = habits.map((h) => h.toJson()).toList();
    await prefs.setString(_habitsKey, jsonEncode(jsonList));
  }

  Future<List<Habit>> loadHabits() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_habitsKey);
    if (jsonString == null || jsonString.isEmpty) {
      return _getDefaultHabits();
    }
    try {
      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded.map((item) => Habit.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      return _getDefaultHabits();
    }
  }

  List<Habit> _getDefaultHabits() {
    final now = DateTime.now();
    final today = Habit.formatDate(now);
    
    return [
      Habit(
        id: '1',
        name: 'Drink Water (2L)',
        iconCodePoint: 0xe6d4, // water_drop
        createdAt: now,
        history: {today: HabitStatus.completed},
      ),
      Habit(
        id: '2',
        name: 'Daily Exercise / Workout',
        iconCodePoint: 0xe28d, // fitness_center
        createdAt: now,
        history: {today: HabitStatus.partial},
      ),
      Habit(
        id: '3',
        name: 'Read 20 Pages',
        iconCodePoint: 0xe3e9, // menu_book
        createdAt: now,
        history: {today: HabitStatus.notDone},
      ),
      Habit(
        id: '4',
        name: '8 Hours Sleep',
        iconCodePoint: 0xe0e7, // bedtime
        createdAt: now,
        history: {today: HabitStatus.completed},
      ),
      Habit(
        id: '5',
        name: 'Meditation & Mindfulness',
        iconCodePoint: 0xf3bd, // self_improvement
        createdAt: now,
        history: {today: HabitStatus.notDone},
      ),
    ];
  }

  Future<void> saveThemeMode(String themeMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, themeMode);
  }

  Future<String> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_themeKey) ?? 'system';
  }

  Future<void> saveReminderSettings({required bool enabled, required int hour, required int minute}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_reminderEnabledKey, enabled);
    await prefs.setInt(_reminderHourKey, hour);
    await prefs.setInt(_reminderMinuteKey, minute);
  }

  Future<Map<String, dynamic>> loadReminderSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'enabled': prefs.getBool(_reminderEnabledKey) ?? true,
      'hour': prefs.getInt(_reminderHourKey) ?? 20, // 8 PM default
      'minute': prefs.getInt(_reminderMinuteKey) ?? 0,
    };
  }

  Future<DateTime> loadFirstLaunchDate({List<Habit>? existingHabits}) async {
    final prefs = await SharedPreferences.getInstance();
    final storedStr = prefs.getString(_firstLaunchDateKey);
    if (storedStr != null && storedStr.isNotEmpty) {
      try {
        final parsed = DateTime.parse(storedStr);
        return DateTime(parsed.year, parsed.month, parsed.day);
      } catch (_) {}
    }

    // Determine initial first launch date
    DateTime firstDate = DateTime.now();
    if (existingHabits != null && existingHabits.isNotEmpty) {
      for (final habit in existingHabits) {
        final created = DateTime(habit.createdAt.year, habit.createdAt.month, habit.createdAt.day);
        if (created.isBefore(firstDate)) {
          firstDate = created;
        }
        for (final dateStr in habit.history.keys) {
          try {
            final parts = dateStr.split('-');
            if (parts.length == 3) {
              final hDate = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
              if (hDate.isBefore(firstDate)) {
                firstDate = hDate;
              }
            }
          } catch (_) {}
        }
      }
    }

    final normalized = DateTime(firstDate.year, firstDate.month, firstDate.day);
    await prefs.setString(_firstLaunchDateKey, normalized.toIso8601String());
    return normalized;
  }
}
