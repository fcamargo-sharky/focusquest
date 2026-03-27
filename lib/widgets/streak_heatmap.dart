import 'package:flutter/material.dart';
import 'package:focusquest/core/constants/app_colors.dart';

class StreakHeatmap extends StatelessWidget {
  final Map<String, bool> dateActivityMap;

  const StreakHeatmap({
    super.key,
    required this.dateActivityMap,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // Build 12 weeks of data ending on today
    final weeks = <List<DateTime?>>[];

    // Find the start of the current week (Monday)
    int daysFromMonday = now.weekday - 1; // 0=Mon
    final thisWeekMonday = now.subtract(Duration(days: daysFromMonday));

    // Build 12 weeks starting from 11 weeks before
    final startMonday = thisWeekMonday.subtract(const Duration(days: 7 * 11));

    for (int w = 0; w < 12; w++) {
      final weekStart = startMonday.add(Duration(days: w * 7));
      final week = <DateTime?>[];
      for (int d = 0; d < 7; d++) {
        final day = weekStart.add(Duration(days: d));
        if (day.isAfter(now)) {
          week.add(null);
        } else {
          week.add(day);
        }
      }
      weeks.add(week);
    }

    const dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    const cellSize = 12.0;
    const cellGap = 3.0;

    // Build month labels
    final monthLabels = <int, String>{};
    for (int w = 0; w < weeks.length; w++) {
      DateTime? firstDay;
      for (final d in weeks[w]) {
        if (d != null) { firstDay = d; break; }
      }
      if (firstDay != null) {
        final month = firstDay.month;
        // Show month label if it's the first week with this month
        bool isFirst = true;
        for (int pw = 0; pw < w; pw++) {
          DateTime? pd;
          for (final d in weeks[pw]) {
            if (d != null) { pd = d; break; }
          }
          if (pd != null && pd.month == month) {
            isFirst = false;
            break;
          }
        }
        if (isFirst) {
          monthLabels[w] = _monthAbbrev(month);
        }
      }
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month labels row
          Row(
            children: [
              const SizedBox(width: 20), // offset for day labels
              ...List.generate(weeks.length, (w) {
                return SizedBox(
                  width: cellSize + cellGap,
                  child: monthLabels.containsKey(w)
                      ? Text(
                          monthLabels[w]!,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 9,
                          ),
                        )
                      : const SizedBox(),
                );
              }),
            ],
          ),
          const SizedBox(height: 4),
          // Grid
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Day labels
              Column(
                children: List.generate(7, (d) {
                  return SizedBox(
                    height: cellSize + cellGap,
                    width: 16,
                    child: (d % 2 == 0)
                        ? Text(
                            dayLabels[d],
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 9,
                            ),
                          )
                        : const SizedBox(),
                  );
                }),
              ),
              const SizedBox(width: 4),
              // Weeks
              ...weeks.map((week) {
                return Padding(
                  padding: const EdgeInsets.only(right: cellGap),
                  child: Column(
                    children: List.generate(7, (d) {
                      final day = week[d];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: cellGap),
                        child: _HeatmapCell(
                          day: day,
                          hasActivity: day != null
                              ? (dateActivityMap[_dateKey(day)] ?? false)
                              : false,
                          isToday: day != null && _isToday(day),
                          size: cellSize,
                        ),
                      );
                    }),
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 8),
          // Legend
          Row(
            children: [
              const SizedBox(width: 20),
              const Text(
                'Less',
                style: TextStyle(color: AppColors.textMuted, fontSize: 10),
              ),
              const SizedBox(width: 6),
              ...List.generate(4, (i) {
                return Padding(
                  padding: const EdgeInsets.only(right: 3),
                  child: Container(
                    width: cellSize,
                    height: cellSize,
                    decoration: BoxDecoration(
                      color: _activityColor(i / 3),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                );
              }),
              const SizedBox(width: 6),
              const Text(
                'More',
                style: TextStyle(color: AppColors.textMuted, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  String _monthAbbrev(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  static Color _activityColor(double intensity) {
    if (intensity <= 0) return const Color(0xFF1A1A2E);
    return Color.lerp(
      AppColors.primary.withOpacity(0.3),
      AppColors.primary,
      intensity,
    )!;
  }
}

class _HeatmapCell extends StatelessWidget {
  final DateTime? day;
  final bool hasActivity;
  final bool isToday;
  final double size;

  const _HeatmapCell({
    required this.day,
    required this.hasActivity,
    required this.isToday,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    Color cellColor;
    if (day == null) {
      cellColor = Colors.transparent;
    } else if (hasActivity) {
      cellColor = AppColors.primary;
    } else {
      cellColor = const Color(0xFF1E1E3A);
    }

    return Tooltip(
      message: day != null
          ? '${day!.year}-${day!.month.toString().padLeft(2, '0')}-${day!.day.toString().padLeft(2, '0')}'
          : '',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: cellColor,
          borderRadius: BorderRadius.circular(3),
          border: isToday
              ? Border.all(color: AppColors.secondary, width: 1.5)
              : null,
        ),
      ),
    );
  }
}
