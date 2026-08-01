import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/habit.dart';
import '../providers/habit_provider.dart';

class ReflectionSheet extends StatefulWidget {
  final Habit habit;
  final DateTime date;

  const ReflectionSheet({
    super.key,
    required this.habit,
    required this.date,
  });

  static const List<String> warmEncouragements = [
    "That's alright — small steps still count! Progress over perfection. 🌟",
    "Every bit counts! You're making progress one day at a time. 💪",
    "Reflecting is half the journey. Take it easy and try again tomorrow! ✨",
    "Progress isn't always linear. Be proud of the effort you put in today! 🌱",
    "Partial progress is still progress! Keep your momentum going tomorrow. 🚀",
  ];

  static void show(BuildContext context, Habit habit, DateTime date) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => ReflectionSheet(habit: habit, date: date),
    );
  }

  @override
  State<ReflectionSheet> createState() => _ReflectionSheetState();
}

class _ReflectionSheetState extends State<ReflectionSheet> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showEncouragementMessage(BuildContext context) {
    final random = Random();
    final message = ReflectionSheet.warmEncouragements[
        random.nextInt(ReflectionSheet.warmEncouragements.length)];

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.favorite_rounded, color: Colors.amber, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _handleSave(BuildContext context) {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      final provider = Provider.of<HabitProvider>(context, listen: false);
      provider.saveReflectionForDate(widget.habit.id, widget.date, text);
    }
    Navigator.of(context).pop();
    _showEncouragementMessage(context);
  }

  void _handleSkip(BuildContext context) {
    Navigator.of(context).pop();
    _showEncouragementMessage(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Icon & Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.habit.icon,
                  color: Colors.amber.shade800,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.habit.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Partially Completed Today',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.amber,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          const Text(
            'What got in the way today?',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Optional — record a short note for reflection or skip anytime.',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
          const SizedBox(height: 12),

          // Short 1-2 line input field
          TextField(
            controller: _controller,
            maxLines: 2,
            maxLength: 120,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: 'e.g. Busy morning, felt tired, ran out of time...',
              hintStyle: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
              filled: true,
              fillColor: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.04),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.amber, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Action Buttons: "Not now" (Skip) & "Save Note"
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => _handleSkip(context),
                child: const Text('Not now'),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber.shade800,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => _handleSave(context),
                icon: const Icon(Icons.check_rounded, size: 18),
                label: const Text('Save Note'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
