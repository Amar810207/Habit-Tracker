import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/habit.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';

class HabitProvider with ChangeNotifier {
  final StorageService _storageService = StorageService();
  final NotificationService _notificationService = NotificationService();

  List<Habit> _habits = [];
  DateTime _selectedDate = DateTime.now();
  late DateTime _firstLaunchDate;
  ThemeMode _themeMode = ThemeMode.system;
  bool _reminderEnabled = true;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 20, minute: 0); // 8:00 PM default
  bool _isLoading = true;

  List<Habit> get habits => List.unmodifiable(_habits);
  DateTime get selectedDate => _selectedDate;
  DateTime get firstLaunchDate => _firstLaunchDate;
  DateTime get today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }
  ThemeMode get themeMode => _themeMode;
  bool get reminderEnabled => _reminderEnabled;
  TimeOfDay get reminderTime => _reminderTime;
  bool get isLoading => _isLoading;

  bool get isToday =>
      _selectedDate.year == DateTime.now().year &&
      _selectedDate.month == DateTime.now().month &&
      _selectedDate.day == DateTime.now().day;

  HabitProvider() {
    _init();
  }

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();

    _habits = await _storageService.loadHabits();
    _firstLaunchDate = await _storageService.loadFirstLaunchDate(existingHabits: _habits);
    _selectedDate = today;
    
    final themeStr = await _storageService.loadThemeMode();
    _themeMode = _parseThemeMode(themeStr);

    final reminderMap = await _storageService.loadReminderSettings();
    _reminderEnabled = reminderMap['enabled'] as bool;
    _reminderTime = TimeOfDay(
      hour: reminderMap['hour'] as int,
      minute: reminderMap['minute'] as int,
    );

    _isLoading = false;
    notifyListeners();

    _updateReminderNotification();
  }

  ThemeMode _parseThemeMode(String modeStr) {
    switch (modeStr) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  void setSelectedDate(DateTime date) {
    final target = DateTime(date.year, date.month, date.day);
    if (target.isBefore(_firstLaunchDate)) {
      _selectedDate = _firstLaunchDate;
    } else if (target.isAfter(today)) {
      _selectedDate = today;
    } else {
      _selectedDate = target;
    }
    notifyListeners();
  }

  void goToToday() {
    _selectedDate = today;
    notifyListeners();
  }

  Future<void> cycleHabitStatus(String habitId, [DateTime? targetDate]) async {
    final date = targetDate ?? _selectedDate;
    final normDate = DateTime(date.year, date.month, date.day);

    // Only today is editable
    if (normDate != today) return;

    final index = _habits.indexWhere((h) => h.id == habitId);
    if (index == -1) return;

    // Haptic feedback requirement
    await HapticFeedback.lightImpact();

    final habit = _habits[index];
    final currentStatus = habit.getStatusForDate(date);
    final nextStatus = currentStatus.next();

    final updatedHistory = Map<String, HabitStatus>.from(habit.history);
    updatedHistory[Habit.formatDate(date)] = nextStatus;

    _habits[index] = habit.copyWith(history: updatedHistory);
    notifyListeners();

    await _storageService.saveHabits(_habits);
    _updateReminderNotification();
  }

  Future<void> setHabitStatusForDate(String habitId, DateTime date, HabitStatus status) async {
    final normDate = DateTime(date.year, date.month, date.day);

    // Only today is editable
    if (normDate != today) return;

    final index = _habits.indexWhere((h) => h.id == habitId);
    if (index == -1) return;

    await HapticFeedback.lightImpact();

    final habit = _habits[index];
    final updatedHistory = Map<String, HabitStatus>.from(habit.history);
    updatedHistory[Habit.formatDate(date)] = status;

    _habits[index] = habit.copyWith(history: updatedHistory);
    notifyListeners();

    await _storageService.saveHabits(_habits);
    _updateReminderNotification();
  }

  Future<void> addHabit(String name, int iconCodePoint) async {
    final newHabit = Habit(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name.trim(),
      iconCodePoint: iconCodePoint,
      createdAt: DateTime.now(),
    );

    _habits.add(newHabit);
    notifyListeners();

    await _storageService.saveHabits(_habits);
    _updateReminderNotification();
  }

  Future<void> editHabit(String habitId, String name, int iconCodePoint) async {
    final index = _habits.indexWhere((h) => h.id == habitId);
    if (index == -1) return;

    _habits[index] = _habits[index].copyWith(
      name: name.trim(),
      iconCodePoint: iconCodePoint,
    );
    notifyListeners();

    await _storageService.saveHabits(_habits);
  }

  Future<void> deleteHabit(String habitId) async {
    _habits.removeWhere((h) => h.id == habitId);
    notifyListeners();

    await _storageService.saveHabits(_habits);
    _updateReminderNotification();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();

    String modeStr = 'system';
    if (mode == ThemeMode.light) modeStr = 'light';
    if (mode == ThemeMode.dark) modeStr = 'dark';

    await _storageService.saveThemeMode(modeStr);
  }

  Future<void> setReminderSettings(bool enabled, TimeOfDay time) async {
    _reminderEnabled = enabled;
    _reminderTime = time;
    notifyListeners();

    await _storageService.saveReminderSettings(
      enabled: enabled,
      hour: time.hour,
      minute: time.minute,
    );

    _updateReminderNotification();
  }

  int get completedTodayCount {
    return _habits.where((h) => h.getStatusForDate(_selectedDate) == HabitStatus.completed).length;
  }

  int get partialTodayCount {
    return _habits.where((h) => h.getStatusForDate(_selectedDate) == HabitStatus.partial).length;
  }

  double get completionPercentage {
    if (_habits.isEmpty) return 0.0;
    double score = 0.0;
    for (final habit in _habits) {
      score += habit.getStatusForDate(_selectedDate).progressPercentage;
    }
    return score / _habits.length;
  }

  double get todayCompletionRatio {
    if (_habits.isEmpty) return 1.0;
    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);
    final completedCount = _habits.where((h) => h.getStatusForDate(todayDate) == HabitStatus.completed).length;
    return completedCount / _habits.length;
  }

  void _updateReminderNotification() {
    _notificationService.syncScheduledNotifications(
      enabled: _reminderEnabled,
      todayCompletionRatio: todayCompletionRatio,
      hasHabits: _habits.isNotEmpty,
    );
  }
}
