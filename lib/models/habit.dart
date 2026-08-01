import 'package:flutter/material.dart';

enum HabitStatus {
  notDone,   // Red (0)
  partial,   // Yellow (1)
  completed; // Green (2)

  int toInt() => index;

  static HabitStatus fromInt(int value) {
    switch (value) {
      case 1:
        return HabitStatus.partial;
      case 2:
        return HabitStatus.completed;
      case 0:
      default:
        return HabitStatus.notDone;
    }
  }

  HabitStatus next() {
    switch (this) {
      case HabitStatus.notDone:
        return HabitStatus.partial;
      case HabitStatus.partial:
        return HabitStatus.completed;
      case HabitStatus.completed:
        return HabitStatus.notDone;
    }
  }

  Color get color {
    switch (this) {
      case HabitStatus.notDone:
        return const Color(0xFFEF4444); // Red
      case HabitStatus.partial:
        return const Color(0xFFF59E0B); // Amber / Yellow
      case HabitStatus.completed:
        return const Color(0xFF10B981); // Emerald Green
    }
  }

  double get progressPercentage {
    switch (this) {
      case HabitStatus.notDone:
        return 0.0;
      case HabitStatus.partial:
        return 0.5;
      case HabitStatus.completed:
        return 1.0;
    }
  }
}

class Habit {
  final String id;
  final String name;
  final int iconCodePoint;
  final DateTime createdAt;
  final Map<String, HabitStatus> history; // Key format: YYYY-MM-DD
  final Map<String, String> reflections; // Key format: YYYY-MM-DD

  Habit({
    required this.id,
    required this.name,
    required this.iconCodePoint,
    required this.createdAt,
    Map<String, HabitStatus>? history,
    Map<String, String>? reflections,
  })  : history = history ?? {},
        reflections = reflections ?? {};

  static String formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  HabitStatus getStatusForDate(DateTime date) {
    final key = formatDate(date);
    return history[key] ?? HabitStatus.notDone;
  }

  String? getReflectionForDate(DateTime date) {
    final key = formatDate(date);
    return reflections[key];
  }

  Habit copyWith({
    String? id,
    String? name,
    int? iconCodePoint,
    DateTime? createdAt,
    Map<String, HabitStatus>? history,
    Map<String, String>? reflections,
  }) {
    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      createdAt: createdAt ?? this.createdAt,
      history: history ?? Map.from(this.history),
      reflections: reflections ?? Map.from(this.reflections),
    );
  }

  /// Calculates the current consecutive days marked completed ending today or yesterday.
  int getStreak([DateTime? relativeTo]) {
    final refDate = relativeTo ?? DateTime.now();
    int streak = 0;
    
    // Check starting from reference date backwards
    DateTime curr = DateTime(refDate.year, refDate.month, refDate.day);
    
    // If current day is not completed, check if yesterday was completed to keep streak active until today is over
    final todayStatus = getStatusForDate(curr);
    if (todayStatus != HabitStatus.completed) {
      curr = curr.subtract(const Duration(days: 1));
      if (getStatusForDate(curr) != HabitStatus.completed) {
        return 0;
      }
    }

    while (true) {
      final status = getStatusForDate(curr);
      if (status == HabitStatus.completed) {
        streak++;
        curr = curr.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }

  // ignore: non_const_argument_for_const_parameter
  IconData get icon => IconData(iconCodePoint, fontFamily: 'MaterialIcons');

  Map<String, dynamic> toJson() {
    final historyMap = <String, int>{};
    history.forEach((key, status) {
      historyMap[key] = status.toInt();
    });

    return {
      'id': id,
      'name': name,
      'iconCodePoint': iconCodePoint,
      'createdAt': createdAt.toIso8601String(),
      'history': historyMap,
      'reflections': reflections,
    };
  }

  factory Habit.fromJson(Map<String, dynamic> json) {
    final historyJson = json['history'] as Map<String, dynamic>? ?? {};
    final history = <String, HabitStatus>{};
    historyJson.forEach((key, value) {
      history[key] = HabitStatus.fromInt(value as int);
    });

    final reflectionsJson = json['reflections'] as Map<String, dynamic>? ?? {};
    final reflections = <String, String>{};
    reflectionsJson.forEach((key, value) {
      reflections[key] = value.toString();
    });

    return Habit(
      id: json['id'] as String,
      name: json['name'] as String,
      iconCodePoint: json['iconCodePoint'] as int? ?? Icons.star.codePoint,
      createdAt: DateTime.parse(json['createdAt'] as String),
      history: history,
      reflections: reflections,
    );
  }
}
