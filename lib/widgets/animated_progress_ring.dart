import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/habit.dart';

class AnimatedProgressRing extends StatefulWidget {
  final HabitStatus status;
  final VoidCallback onTap;
  final double size;

  const AnimatedProgressRing({
    super.key,
    required this.status,
    required this.onTap,
    this.size = 54.0,
  });

  @override
  State<AnimatedProgressRing> createState() => _AnimatedProgressRingState();
}

class _AnimatedProgressRingState extends State<AnimatedProgressRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _handleTap() {
    _scaleController.forward().then((_) {
      _scaleController.reverse();
    });
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = widget.status.color;
    final progress = widget.status.progressPercentage;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: (_) => _scaleController.forward(),
      onTapUp: (_) => _scaleController.reverse(),
      onTapCancel: () => _scaleController.reverse(),
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: SizedBox(
              width: widget.size,
              height: widget.size,
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: progress),
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOutCubic,
                builder: (context, fillValue, _) {
                  return TweenAnimationBuilder<Color?>(
                    tween: ColorTween(
                      begin: widget.status.color,
                      end: statusColor,
                    ),
                    duration: const Duration(milliseconds: 350),
                    builder: (context, currentColor, _) {
                      final activeColor = currentColor ?? statusColor;
                      
                      return CustomPaint(
                        painter: RingPainter(
                          progress: fillValue,
                          color: activeColor,
                          trackColor: isDark
                              ? Colors.white.withOpacity(0.12)
                              : Colors.black.withOpacity(0.08),
                          strokeWidth: 4.5,
                        ),
                        child: Center(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: widget.size * 0.65,
                            height: widget.size * 0.65,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: activeColor.withOpacity(0.15),
                            ),
                            child: Icon(
                              _getIconForStatus(widget.status),
                              size: widget.size * 0.4,
                              color: activeColor,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _getIconForStatus(HabitStatus status) {
    switch (status) {
      case HabitStatus.completed:
        return Icons.check_rounded;
      case HabitStatus.partial:
        return Icons.remove_rounded;
      case HabitStatus.notDone:
        return Icons.close_rounded;
    }
  }
}

class RingPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  RingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background track ring
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, trackPaint);

    // Active progress arc
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      const startAngle = -math.pi / 2;
      final sweepAngle = 2 * math.pi * progress;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant RingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
