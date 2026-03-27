import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focusquest/core/database/database_helper.dart';
import 'package:focusquest/models/daily_stat.dart';

class StatsState {
  final List<int> weeklyStudySeconds; // 7 days, index 0 = today-6, index 6 = today
  final int totalTasksCompleted;
  final int totalStudySeconds;
  final double taskCompletionRate;
  final Map<String, int> subjectBreakdown; // subjectId -> seconds
  final Map<String, bool> streakCalendarData; // date -> hasActivity
  final List<DailyStat> weeklyStats;
  final bool isLoading;

  const StatsState({
    this.weeklyStudySeconds = const [0, 0, 0, 0, 0, 0, 0],
    this.totalTasksCompleted = 0,
    this.totalStudySeconds = 0,
    this.taskCompletionRate = 0,
    this.subjectBreakdown = const {},
    this.streakCalendarData = const {},
    this.weeklyStats = const [],
    this.isLoading = true,
  });

  StatsState copyWith({
    List<int>? weeklyStudySeconds,
    int? totalTasksCompleted,
    int? totalStudySeconds,
    double? taskCompletionRate,
    Map<String, int>? subjectBreakdown,
    Map<String, bool>? streakCalendarData,
    List<DailyStat>? weeklyStats,
    bool? isLoading,
  }) {
    return StatsState(
      weeklyStudySeconds: weeklyStudySeconds ?? this.weeklyStudySeconds,
      totalTasksCompleted: totalTasksCompleted ?? this.totalTasksCompleted,
      totalStudySeconds: totalStudySeconds ?? this.totalStudySeconds,
      taskCompletionRate: taskCompletionRate ?? this.taskCompletionRate,
      subjectBreakdown: subjectBreakdown ?? this.subjectBreakdown,
      streakCalendarData: streakCalendarData ?? this.streakCalendarData,
      weeklyStats: weeklyStats ?? this.weeklyStats,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class StatsNotifier extends StateNotifier<StatsState> {
  final _db = DatabaseHelper();

  StatsNotifier() : super(const StatsState()) {
    refresh();
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    try {
      // Weekly stats
      final weeklyRaw = await _db.getWeeklyStats();
      final weeklyStats = weeklyRaw.map((m) => DailyStat.fromMap(m)).toList();
      final weeklyStudySeconds = weeklyStats.map((s) => s.studySeconds).toList();

      // Total tasks completed
      final totalTasks = await _db.getTotalCompletedTasks();

      // Total study seconds
      final allDailyStats = await _db.getAllDailyStats();
      int totalStudy = 0;
      for (final s in allDailyStats) {
        totalStudy += (s['studySeconds'] as int? ?? 0);
      }

      // Task completion rate
      final allTasks = await _db.getTasks();
      final completedCount = allTasks.where((t) => t.isCompleted).length;
      final totalCount = allTasks.length;
      final completionRate = totalCount > 0 ? completedCount / totalCount : 0.0;

      // Subject breakdown
      final subjectBreakdown = await _db.getSubjectStudyBreakdown();

      // Streak calendar data (last 84 days = 12 weeks)
      final streakCalendar = <String, bool>{};
      final now = DateTime.now();
      for (int i = 83; i >= 0; i--) {
        final day = now.subtract(Duration(days: i));
        final dateStr =
            '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
        final stats = await _db.getDailyStats(dateStr);
        final hasActivity = stats != null &&
            ((stats['studySeconds'] as int? ?? 0) > 0 ||
                (stats['tasksCompleted'] as int? ?? 0) > 0);
        streakCalendar[dateStr] = hasActivity;
      }

      state = StatsState(
        weeklyStudySeconds: weeklyStudySeconds,
        totalTasksCompleted: totalTasks,
        totalStudySeconds: totalStudy,
        taskCompletionRate: completionRate,
        subjectBreakdown: subjectBreakdown,
        streakCalendarData: streakCalendar,
        weeklyStats: weeklyStats,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }
}

final statsProvider = StateNotifierProvider<StatsNotifier, StatsState>((ref) {
  return StatsNotifier();
});
