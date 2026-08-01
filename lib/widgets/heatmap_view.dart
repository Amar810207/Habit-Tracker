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
                final isBeforeFirstLaunch = date.isBefore(provider.firstLaunchDate);
                final isFuture = date.isAfter(today);
                final isCurrentDay = date.year == today.year &&
                    date.month == today.month &&
                    date.day == today.day;

                Color cellColor;
                BoxBorder? cellBorder;
                String tooltipText;
                VoidCallback? handleTap;

                if (isBeforeFirstLaunch) {
                  cellColor = isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : Colors.black.withValues(alpha: 0.04);
                  cellBorder = Border.all(
                    color: isDark ? Colors.white10 : Colors.black12,
                    width: 1,
                  );
                  tooltipText = '${DateFormat('MMM d, yyyy').format(date)}: Not tracked (Before first launch)';
                  handleTap = null;
                } else if (isFuture) {
                  cellColor = isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : Colors.black.withValues(alpha: 0.04);
                  cellBorder = null;
                  tooltipText = '${DateFormat('MMM d, yyyy').format(date)}: Future date';
                  handleTap = null;
                } else if (isCurrentDay) {
                  cellColor = status.color;
                  cellBorder = Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  );
                  tooltipText = '${DateFormat('MMM d, yyyy').format(date)}: ${_statusLabel(status)} (Tap to edit)';
                  handleTap = () {
                    provider.cycleHabitStatus(habit.id, date);
                  };
                } else {
                  // Past day after first launch date (Read-only)
                  cellColor = status.color;
                  cellBorder = null;
                  tooltipText = '${DateFormat('MMM d, yyyy').format(date)}: ${_statusLabel(status)} (Read-only)';
                  handleTap = null;
                }

                return GestureDetector(
                  onTap: handleTap,
                  child: Tooltip(
                    message: tooltipText,
                    child: Container(
                      decoration: BoxDecoration(
                        color: cellColor,
                        borderRadius: BorderRadius.circular(6),
                        border: cellBorder,
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
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 6,
            children: [
              _buildLegendItem('Not Tracked', isDark ? Colors.white12 : Colors.grey.shade300),
              _buildLegendItem('Not Done', const Color(0xFFEF4444)),
              _buildLegendItem('Partial', const Color(0xFFF59E0B)),
              _buildLegendItem('Completed', const Color(0xFF10B981)),
            ],
          ),
        ],
      ),
    );
  }

  String _statusLabel(HabitStatus status) {
    switch (status) {
      case HabitStatus.completed:
        return 'Completed';
      case HabitStatus.partial:
        return 'Partial';
      case HabitStatus.notDone:
        return 'Not Done';
    }
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
