import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/habit.dart';
import '../providers/habit_provider.dart';

class HabitHeatmapSheet extends StatelessWidget {
  final Habit habit;

  const HabitHeatmapSheet({super.key, required this.habit});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<HabitProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Generate dates for the last 60 days
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final List<DateTime> days = List.generate(60, (index) {
      return today.subtract(Duration(days: 59 - index));
    });

    final streak = habit.getStreak();

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Icon, Name, and Streak
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  habit.icon,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '🔥 $streak Day Streak',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Text(
            '60-Day Activity Heatmap',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),

          // Heatmap grid (10 columns x 6 rows)
          SizedBox(
            height: 220,
            child: GridView.builder(
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 10,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
              ),
              itemCount: days.length,
              itemBuilder: (context, index) {
                final date = days[index];
                final status = habit.getStatusForDate(date);
                final isCurrentDay = date.year == today.year &&
                    date.month == today.month &&
                    date.day == today.day;

                return GestureDetector(
                  onTap: () {
                    provider.cycleHabitStatus(habit.id, date);
                  },
                  child: Tooltip(
                    message: '${DateFormat('MMM d, yyyy').format(date)}: ${status.name}',
                    child: Container(
                      decoration: BoxDecoration(
                        color: status == HabitStatus.notDone && !habit.history.containsKey(Habit.formatDate(date))
                            ? (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06))
                            : status.color,
                        borderRadius: BorderRadius.circular(6),
                        border: isCurrentDay
                            ? Border.all(
                                color: Theme.of(context).colorScheme.primary,
                                width: 2,
                              )
                            : null,
                      ),
                      child: isCurrentDay
                          ? Center(
                              child: Container(
                                width: 4,
                                height: 4,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            )
                          : null,
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 12),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('Not Done', const Color(0xFFEF4444)),
              const SizedBox(width: 16),
              _buildLegendItem('Partial', const Color(0xFFF59E0B)),
              const SizedBox(width: 16),
              _buildLegendItem('Completed', const Color(0xFF10B981)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}
