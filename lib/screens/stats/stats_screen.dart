import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:focusquest/core/constants/app_colors.dart';
import 'package:focusquest/models/subject.dart';
import 'package:focusquest/providers/stats_provider.dart';
import 'package:focusquest/providers/subjects_provider.dart';
import 'package:focusquest/providers/user_provider.dart';
import 'package:focusquest/widgets/streak_heatmap.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(statsProvider);
    final user = ref.watch(userProvider);
    final subjects = ref.watch(subjectsProvider);

    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));

    if (stats.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final totalWeekStudyHours = stats.weeklyStudySeconds.fold<int>(0, (a, b) => a + b) / 3600;
    final weeklyCompletedTasks = stats.weeklyStats
        .fold<int>(0, (a, s) => a + s.tasksCompleted);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textMuted),
            onPressed: () => ref.read(statsProvider.notifier).refresh(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(statsProvider.notifier).refresh(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // This week header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'This Week',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${DateFormat('MMM d').format(weekStart)} – ${DateFormat('MMM d').format(weekEnd)}',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Weekly bar chart
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.darkCard,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Study Hours',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 160,
                      child: _WeeklyBarChart(
                        studySeconds: stats.weeklyStudySeconds,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Stats cards
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.access_time,
                      value: '${totalWeekStudyHours.toStringAsFixed(1)}h',
                      label: 'Study Time',
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.task_alt,
                      value: '$weeklyCompletedTasks',
                      label: 'Tasks Done',
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.local_fire_department,
                      value: '${user.currentStreak}',
                      label: 'Day Streak',
                      color: AppColors.streakColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Subject Breakdown
              if (stats.subjectBreakdown.isNotEmpty) ...[
                const Text(
                  'Subject Breakdown',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.darkCard,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 140,
                        height: 140,
                        child: _SubjectPieChart(
                          breakdown: stats.subjectBreakdown,
                          subjects: subjects,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: stats.subjectBreakdown.entries.map((e) {
                            try {
                              final subject = subjects.firstWhere((s) => s.id == e.key);
                              final hours = e.value / 3600;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: subject.color,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        subject.name,
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      '${hours.toStringAsFixed(1)}h',
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            } catch (_) {
                              return const SizedBox();
                            }
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Streak Calendar
              const Text(
                'Activity Calendar',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.darkCard,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: StreakHeatmap(
                  dateActivityMap: stats.streakCalendarData,
                ),
              ),
              const SizedBox(height: 20),

              // All Time Stats
              const Text(
                'All Time',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.8,
                children: [
                  _AllTimeCard(
                    label: 'Total Tasks',
                    value: '${stats.totalTasksCompleted}',
                    icon: '✅',
                  ),
                  _AllTimeCard(
                    label: 'Study Hours',
                    value: (stats.totalStudySeconds / 3600).toStringAsFixed(0),
                    icon: '📚',
                  ),
                  _AllTimeCard(
                    label: 'Best Streak',
                    value: '${user.longestStreak} days',
                    icon: '🔥',
                  ),
                  _AllTimeCard(
                    label: 'Level',
                    value: '${user.level}',
                    icon: '⭐',
                  ),
                ],
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeeklyBarChart extends StatelessWidget {
  final List<int> studySeconds;

  const _WeeklyBarChart({required this.studySeconds});

  @override
  Widget build(BuildContext context) {
    final dayLabels = List.generate(7, (i) {
      final day = DateTime.now().subtract(Duration(days: 6 - i));
      return ['M', 'T', 'W', 'T', 'F', 'S', 'S'][day.weekday - 1];
    });
    final maxHours =
        studySeconds.map((s) => s / 3600).reduce((a, b) => a > b ? a : b);
    final chartMax = maxHours < 1 ? 2.0 : (maxHours * 1.3).ceilToDouble();
    const todayIndex = 6;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: chartMax,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) => AppColors.darkSurface,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final hours = rod.toY;
              return BarTooltipItem(
                '${hours.toStringAsFixed(1)}h',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= dayLabels.length) {
                  return const SizedBox();
                }
                return Text(
                  dayLabels[idx],
                  style: TextStyle(
                    color: idx == todayIndex
                        ? AppColors.primary
                        : AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: idx == todayIndex
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: chartMax > 4 ? 2 : 1,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const SizedBox();
                return Text(
                  '${value.toInt()}h',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(
          show: true,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: AppColors.textMuted.withOpacity(0.1),
              strokeWidth: 1,
            );
          },
          drawVerticalLine: false,
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(7, (i) {
          final hours = studySeconds[i] / 3600;
          final isToday = i == todayIndex;
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: hours,
                color: isToday ? AppColors.primary : AppColors.primary.withOpacity(0.5),
                width: 18,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: chartMax,
                  color: AppColors.darkBg,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _SubjectPieChart extends StatelessWidget {
  final Map<String, int> breakdown;
  final List<Subject> subjects;

  const _SubjectPieChart({required this.breakdown, required this.subjects});

  @override
  Widget build(BuildContext context) {
    final total = breakdown.values.fold<int>(0, (a, b) => a + b);
    if (total == 0) return const SizedBox();

    final sections = breakdown.entries.map((e) {
      final color = _subjectColor(e.key);
      return PieChartSectionData(
        value: e.value.toDouble(),
        color: color,
        radius: 40,
        showTitle: false,
      );
    }).toList();

    return PieChart(
      PieChartData(
        sections: sections,
        centerSpaceRadius: 30,
        sectionsSpace: 2,
        startDegreeOffset: -90,
      ),
    );
  }

  Color _subjectColor(String subjectId) {
    try {
      final subject = subjects.firstWhere((s) => s.id == subjectId);
      return subject.color;
    } catch (_) {
      return AppColors.primary;
    }
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _AllTimeCard extends StatelessWidget {
  final String label;
  final String value;
  final String icon;

  const _AllTimeCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
