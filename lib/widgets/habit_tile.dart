import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/habit.dart';
import '../providers/habit_provider.dart';
import 'animated_progress_ring.dart';
import 'heatmap_view.dart';
import 'add_edit_habit_dialog.dart';
import 'reflection_sheet.dart';

class HabitTile extends StatelessWidget {
  final Habit habit;

  const HabitTile({super.key, required this.habit});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<HabitProvider>(context);
    final status = habit.getStatusForDate(provider.selectedDate);
    final streak = habit.getStreak(provider.selectedDate);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            habit.icon,
            color: Theme.of(context).colorScheme.primary,
            size: 22,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                habit.name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  decoration: status == HabitStatus.completed ? TextDecoration.lineThrough : null,
                  color: status == HabitStatus.completed
                      ? (isDark ? Colors.white60 : Colors.black54)
                      : (isDark ? Colors.white : Colors.black87),
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Row(
            children: [
              // Streak Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: streak > 0 ? Colors.orange.withOpacity(0.15) : Colors.grey.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      streak > 0 ? '🔥 $streak day streak' : '🔥 0 days',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: streak > 0 ? Colors.orange.shade800 : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Status text indicator
              Text(
                status == HabitStatus.completed
                    ? 'Completed'
                    : status == HabitStatus.partial
                        ? 'Partial'
                        : 'Not done',
                style: TextStyle(
                  fontSize: 12,
                  color: status.color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated 3-State Circular Ring Progress Indicator
            Tooltip(
              message: provider.isToday ? 'Tap to change status' : 'Past dates are read-only',
              child: AnimatedProgressRing(
                status: status,
                onTap: provider.isToday
                    ? () async {
                        final newStatus = await provider.cycleHabitStatus(habit.id);
                        if (newStatus == HabitStatus.partial && context.mounted) {
                          ReflectionSheet.show(context, habit, provider.selectedDate);
                        }
                      }
                    : null,
              ),
            ),

            // More Options Popup Menu
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert_rounded,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              onSelected: (value) {
                if (value == 'heatmap') {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => HabitHeatmapSheet(habit: habit),
                  );
                } else if (value == 'edit') {
                  showDialog(
                    context: context,
                    builder: (_) => AddEditHabitDialog(habit: habit),
                  );
                } else if (value == 'delete') {
                  _confirmDelete(context, provider, habit);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'heatmap',
                  child: Row(
                    children: [
                      Icon(Icons.grid_on_rounded, size: 18),
                      SizedBox(width: 10),
                      Text('Calendar Heatmap'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_rounded, size: 18),
                      SizedBox(width: 10),
                      Text('Edit Habit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline_rounded, color: Colors.red, size: 18),
                      SizedBox(width: 10),
                      Text('Delete Habit', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, HabitProvider provider, Habit habit) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Habit'),
        content: Text('Are you sure you want to delete "${habit.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              provider.deleteHabit(habit.id);
              Navigator.of(ctx).pop();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
