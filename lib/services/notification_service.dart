import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationSlot {
  final int id;
  final int hour;
  final int minute;
  final String title;
  final String body;
  final double completionThreshold; // Notification triggers if completionRatio < threshold

  const NotificationSlot({
    required this.id,
    required this.hour,
    required this.minute,
    required this.title,
    required this.body,
    required this.completionThreshold,
  });
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const List<NotificationSlot> scheduledSlots = [
    NotificationSlot(
      id: 10,
      hour: 10,
      minute: 0,
      title: 'Morning Habit Check-in ☀️',
      body: "You haven't checked in on any habits yet today",
      completionThreshold: 0.01, // Triggers if 0% completed (strictly < 0.01)
    ),
    NotificationSlot(
      id: 15,
      hour: 15,
      minute: 0,
      title: 'Afternoon Habit Check-in 🌤️',
      body: "You're less than halfway through your habits today",
      completionThreshold: 0.50, // Triggers if < 50% completed
    ),
    NotificationSlot(
      id: 20,
      hour: 20,
      minute: 0,
      title: 'Evening Habit Check-in 🌙',
      body: "You're close, but haven't hit 75% completion yet",
      completionThreshold: 0.75, // Triggers if < 75% completed
    ),
  ];

  Future<void> init() async {
    if (_initialized) return;

    try {
      tz.initializeTimeZones();
      final String timeZoneName = DateTime.now().timeZoneName;
      try {
        tz.setLocalLocation(tz.getLocation(timeZoneName));
      } catch (_) {}
    } catch (e) {
      debugPrint('Timezone initialization warning: $e');
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    try {
      await _notificationsPlugin.initialize(initSettings);
      _initialized = true;

      // Request notification permissions for Android 13+
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        await androidImplementation.requestNotificationsPermission();
      }
    } catch (e) {
      debugPrint('Notification init exception: $e');
    }
  }

  Future<void> cancelNotification(int id) async {
    if (!_initialized) await init();
    try {
      await _notificationsPlugin.cancel(id);
    } catch (e) {
      debugPrint('Error cancelling notification $id: $e');
    }
  }

  /// Syncs 3 fixed daily notification slots (10:00 AM, 3:00 PM, 8:00 PM) based on today's habit completion ratio.
  Future<void> syncScheduledNotifications({
    required bool enabled,
    required double todayCompletionRatio,
    required bool hasHabits,
  }) async {
    if (!_initialized) await init();

    if (!enabled || !hasHabits) {
      await cancelAll();
      return;
    }

    final now = DateTime.now();

    for (final slot in scheduledSlots) {
      final shouldTrigger = todayCompletionRatio < slot.completionThreshold;

      if (!shouldTrigger) {
        // Cancel notification for this slot if completion percentage meets/exceeds threshold
        await cancelNotification(slot.id);
        continue;
      }

      final tz.TZDateTime scheduledDate = _nextInstanceOfTime(slot.hour, slot.minute, now);

      const androidDetails = AndroidNotificationDetails(
        'habit_tracker_scheduled_reminders',
        'Habit Scheduled Reminders',
        channelDescription: 'Fixed daily check-in reminders for incomplete habits',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(),
      );

      try {
        await _notificationsPlugin.zonedSchedule(
          slot.id,
          slot.title,
          slot.body,
          scheduledDate,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      } catch (e) {
        try {
          await _notificationsPlugin.zonedSchedule(
            slot.id,
            slot.title,
            slot.body,
            scheduledDate,
            notificationDetails,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            matchDateTimeComponents: DateTimeComponents.time,
          );
        } catch (e2) {
          debugPrint('Error scheduling notification slot ${slot.id}: $e2');
        }
      }
    }
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute, DateTime now) {
    final tz.TZDateTime tzNow = tz.TZDateTime.from(now, tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, tzNow.year, tzNow.month, tzNow.day, hour, minute);

    if (scheduledDate.isBefore(tzNow)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  Future<void> cancelAll() async {
    if (!_initialized) await init();
    try {
      await _notificationsPlugin.cancelAll();
    } catch (e) {
      debugPrint('Error cancelling notifications: $e');
    }
  }
}
