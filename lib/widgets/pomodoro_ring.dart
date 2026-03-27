import 'dart:math';
import 'package:flutter/material.dart';
import 'package:focusquest/core/constants/app_colors.dart';

class PomodoroRing extends StatefulWidget {
  final double progress; // 0.0 to 1.0
  final String timeText;
  final bool isBreak;
  final double size;

  const PomodoroRing({
    super.key,
    required this.progress,
    required this.timeText,
    required this.isBreak,
    this.size = 260,
  });

  @override
  State<PomodoroRing> createState() => _PomodoroRingState();
}

class _PomodoroRingState extends State<PomodoroRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  Color get _ringColor => widget.isBreak ? AppColors.success : AppColors.primary;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: _PomodoroRingPainter(
              progress: widget.progress,
              ringColor: _ringColor,
              glowIntensity: _glowAnimation.value,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.timeText,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: widget.size * 0.18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  Text(
                    widget.isBreak ? 'Break' : 'Focus',
                    style: TextStyle(
                      color: _ringColor,
                      fontSize: widget.size * 0.07,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PomodoroRingPainter extends CustomPainter {
  final double progress;
  final Color ringColor;
  final double glowIntensity;

  _PomodoroRingPainter({
    required this.progress,
    required this.ringColor,
    required this.glowIntensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 16;
    const strokeWidth = 12.0;

    // Background ring
    final bgPaint = Paint()
      ..color = const Color(0xFF1E1E26)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    if (progress > 0) {
      // Glow effect
      final glowPaint = Paint()
        ..color = ringColor.withOpacity(0.3 * glowIntensity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 8
        ..strokeCap = StrokeCap.round
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8 * glowIntensity);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        2 * pi * progress,
        false,
        glowPaint,
      );

      // Progress arc
      final progressPaint = Paint()
        ..shader = SweepGradient(
          colors: [
            ringColor.withOpacity(0.7),
            ringColor,
          ],
          startAngle: -pi / 2,
          endAngle: -pi / 2 + 2 * pi * progress,
          tileMode: TileMode.clamp,
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        2 * pi * progress,
        false,
        progressPaint,
      );

      // Dot at the end of the arc
      if (progress < 1.0) {
        final angle = -pi / 2 + 2 * pi * progress;
        final dotX = center.dx + radius * cos(angle);
        final dotY = center.dy + radius * sin(angle);

        final dotPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;

        canvas.drawCircle(Offset(dotX, dotY), strokeWidth / 2 + 1, dotPaint);
      }
    }

    // Tick marks
    final tickPaint = Paint()
      ..color = const Color(0xFF24242E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int i = 0; i < 60; i++) {
      final angle = -pi / 2 + (i / 60) * 2 * pi;
      final isMajor = i % 5 == 0;
      final innerRadius = radius - (isMajor ? 8 : 5);
      final outerRadius = radius;

      canvas.drawLine(
        Offset(
          center.dx + innerRadius * cos(angle),
          center.dy + innerRadius * sin(angle),
        ),
        Offset(
          center.dx + outerRadius * cos(angle),
          center.dy + outerRadius * sin(angle),
        ),
        tickPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_PomodoroRingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.ringColor != ringColor ||
      oldDelegate.glowIntensity != glowIntensity;
}
