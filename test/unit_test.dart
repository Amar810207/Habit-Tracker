import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:habit_tracker/models/habit.dart';
import 'package:habit_tracker/services/storage_service.dart';
import 'package:habit_tracker/services/notification_service.dart';
import 'package:habit_tracker/providers/habit_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Date Validation & Editing Unit Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('First launch date is set and normalized', () async {
      final storage = StorageService();
      final firstLaunch = await storage.loadFirstLaunchDate();
      final now = DateTime.now();
      
      expect(firstLaunch.year, equals(now.year));
      expect(firstLaunch.month, equals(now.month));
      expect(firstLaunch.day, equals(now.day));
    });

    test('HabitProvider initializes firstLaunchDate and clamps selectedDate', () async {
      final provider = HabitProvider();
      // Wait for provider initialization
      await Future.delayed(const Duration(milliseconds: 100));

      final today = provider.today;      
      expect(provider.selectedDate, equals(today));

      // Attempt to select a future date
      final futureDate = today.add(const Duration(days: 5));
      provider.setSelectedDate(futureDate);
      expect(provider.selectedDate, equals(today)); // Clamped to today

      // Attempt to select a date before first launch
      final pastDate = provider.firstLaunchDate.subtract(const Duration(days: 5));
      provider.setSelectedDate(pastDate);
      expect(provider.selectedDate, equals(provider.firstLaunchDate)); // Clamped to first launch
    });

    test('cycleHabitStatus only mutates status for TODAY', () async {
      final provider = HabitProvider();
      await Future.delayed(const Duration(milliseconds: 100));

      if (provider.habits.isNotEmpty) {
        final habitId = provider.habits.first.id;
        final initialStatus = provider.habits.first.getStatusForDate(provider.today);

        // Cycle status on today -> should succeed
        await provider.cycleHabitStatus(habitId, provider.today);
        final newStatus = provider.habits.first.getStatusForDate(provider.today);
        expect(newStatus, isNot(equals(initialStatus)));

        // Attempt to cycle status on past date -> should be rejected
        final pastDate = provider.today.subtract(const Duration(days: 1));
        final pastInitialStatus = provider.habits.first.getStatusForDate(pastDate);
        await provider.cycleHabitStatus(habitId, pastDate);
        final pastStatusAfter = provider.habits.first.getStatusForDate(pastDate);
        expect(pastStatusAfter, equals(pastInitialStatus));
      }
    });

    test('Streak calculation counts contiguous completed days', () {
      final now = DateTime.now();
      final today = Habit.formatDate(now);
      final yesterday = Habit.formatDate(now.subtract(const Duration(days: 1)));
      final dayBefore = Habit.formatDate(now.subtract(const Duration(days: 2)));

      final habit = Habit(
        id: 'test_1',
        name: 'Test Streak',
        iconCodePoint: 0xe6d4,
        createdAt: now.subtract(const Duration(days: 10)),
        history: {
          today: HabitStatus.completed,
          yesterday: HabitStatus.completed,
          dayBefore: HabitStatus.completed,
        },
      );

      expect(habit.getStreak(now), equals(3));
    });

    test('Notification slot threshold logic', () {
      // Slot 10 AM: 0% completion threshold (0.01)
      final slot10 = NotificationService.scheduledSlots[0];
      expect(slot10.hour, equals(10));
      expect(slot10.completionThreshold, equals(0.01));
      expect(0.0 < slot10.completionThreshold, isTrue); // 0% triggers
      expect(0.2 < slot10.completionThreshold, isFalse); // 20% does not trigger

      // Slot 3 PM: 50% completion threshold (0.50)
      final slot15 = NotificationService.scheduledSlots[1];
      expect(slot15.hour, equals(15));
      expect(slot15.completionThreshold, equals(0.50));
      expect(0.4 < slot15.completionThreshold, isTrue); // < 50% triggers
      expect(0.6 < slot15.completionThreshold, isFalse); // >= 50% does not trigger

      // Slot 8 PM: 75% completion threshold (0.75)
      final slot20 = NotificationService.scheduledSlots[2];
      expect(slot20.hour, equals(20));
      expect(slot20.completionThreshold, equals(0.75));
      expect(0.6 < slot20.completionThreshold, isTrue); // < 75% triggers
      expect(0.8 < slot20.completionThreshold, isFalse); // >= 75% does not trigger
    });

    test('Habit reflection saving and JSON serialization', () async {
      final now = DateTime.now();
      final todayStr = Habit.formatDate(now);

      final habit = Habit(
        id: 'refl_1',
        name: 'Reflection Test',
        iconCodePoint: 0xe6d4,
        createdAt: now,
        history: {todayStr: HabitStatus.partial},
        reflections: {todayStr: 'Felt tired after work'},
      );

      expect(habit.getReflectionForDate(now), equals('Felt tired after work'));

      final json = habit.toJson();
      final recreated = Habit.fromJson(json);
      expect(recreated.getReflectionForDate(now), equals('Felt tired after work'));
    });
  });
}
