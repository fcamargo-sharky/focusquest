import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focusquest/core/database/database_helper.dart';
import 'package:focusquest/core/services/notification_service.dart';
import 'package:focusquest/models/study_session.dart';
import 'package:focusquest/providers/user_provider.dart';
import 'package:focusquest/providers/stats_provider.dart';
import 'package:focusquest/core/services/sound_service.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class TimerState {
  final int workMinutes;
  final int breakMinutes;
  final int secondsRemaining;
  final bool isRunning;
  final bool isBreak;
  final int completedPomodoros;
  final String? selectedSubjectId;
  final String? selectedTaskId;
  final DateTime? sessionStartTime;
  final List<StudySession> todaySessions;

  const TimerState({
    this.workMinutes = 25,
    this.breakMinutes = 5,
    this.secondsRemaining = 25 * 60,
    this.isRunning = false,
    this.isBreak = false,
    this.completedPomodoros = 0,
    this.selectedSubjectId,
    this.selectedTaskId,
    this.sessionStartTime,
    this.todaySessions = const [],
  });

  int get totalSeconds => isBreak ? breakMinutes * 60 : workMinutes * 60;
  double get progress => 1.0 - (secondsRemaining / totalSeconds);
  String get timeString {
    final m = (secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final s = (secondsRemaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  TimerState copyWith({
    int? workMinutes,
    int? breakMinutes,
    int? secondsRemaining,
    bool? isRunning,
    bool? isBreak,
    int? completedPomodoros,
    String? selectedSubjectId,
    String? selectedTaskId,
    DateTime? sessionStartTime,
    List<StudySession>? todaySessions,
    bool clearSelectedSubjectId = false,
    bool clearSelectedTaskId = false,
    bool clearSessionStartTime = false,
  }) {
    return TimerState(
      workMinutes: workMinutes ?? this.workMinutes,
      breakMinutes: breakMinutes ?? this.breakMinutes,
      secondsRemaining: secondsRemaining ?? this.secondsRemaining,
      isRunning: isRunning ?? this.isRunning,
      isBreak: isBreak ?? this.isBreak,
      completedPomodoros: completedPomodoros ?? this.completedPomodoros,
      selectedSubjectId: clearSelectedSubjectId
          ? null
          : (selectedSubjectId ?? this.selectedSubjectId),
      selectedTaskId:
          clearSelectedTaskId ? null : (selectedTaskId ?? this.selectedTaskId),
      sessionStartTime: clearSessionStartTime
          ? null
          : (sessionStartTime ?? this.sessionStartTime),
      todaySessions: todaySessions ?? this.todaySessions,
    );
  }
}

class TimerNotifier extends StateNotifier<TimerState> {
  final Ref _ref;
  final _db = DatabaseHelper();
  final _notifications = NotificationService();
  final _uuid = const Uuid();
  Timer? _timer;

  TimerNotifier(this._ref) : super(const TimerState()) {
    _loadTodaySessions();
  }

  Future<void> _loadTodaySessions() async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final sessions = await _db.getStudySessionsForDate(today);
    state = state.copyWith(todaySessions: sessions);
  }

  void start() {
    if (state.isRunning) return;

    final startTime = state.sessionStartTime ?? DateTime.now();
    state = state.copyWith(
      isRunning: true,
      sessionStartTime: startTime,
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void pause() {
    _timer?.cancel();
    _timer = null;
    state = state.copyWith(isRunning: false);
  }

  void reset() {
    _timer?.cancel();
    _timer = null;
    state = state.copyWith(
      secondsRemaining: state.workMinutes * 60,
      isRunning: false,
      isBreak: false,
      clearSessionStartTime: true,
    );
  }

  void skip() {
    _timer?.cancel();
    _timer = null;
    _onPeriodComplete();
  }

  void setWorkMinutes(int minutes) {
    _timer?.cancel();
    _timer = null;
    state = state.copyWith(
      workMinutes: minutes,
      secondsRemaining: state.isBreak ? state.secondsRemaining : minutes * 60,
      isRunning: false,
    );
  }

  void setBreakMinutes(int minutes) {
    _timer?.cancel();
    _timer = null;
    state = state.copyWith(
      breakMinutes: minutes,
      secondsRemaining: state.isBreak ? minutes * 60 : state.secondsRemaining,
      isRunning: false,
    );
  }

  void selectSubject(String? subjectId) {
    if (subjectId == null) {
      state = state.copyWith(clearSelectedSubjectId: true, clearSelectedTaskId: true);
    } else {
      state = state.copyWith(selectedSubjectId: subjectId, clearSelectedTaskId: true);
    }
  }

  void selectTask(String? taskId) {
    if (taskId == null) {
      state = state.copyWith(clearSelectedTaskId: true);
    } else {
      state = state.copyWith(selectedTaskId: taskId);
    }
  }

  void _tick() {
    if (state.secondsRemaining <= 1) {
      _onPeriodComplete();
    } else {
      state = state.copyWith(secondsRemaining: state.secondsRemaining - 1);
    }
  }

  Future<void> _onPeriodComplete() async {
    _timer?.cancel();
    _timer = null;

    if (!state.isBreak) {
      // Work period completed - save session
      await _saveStudySession();
      final newPomodoros = state.completedPomodoros + 1;

      SoundService.playPomodoroComplete();

      // Award XP
      await _ref.read(userProvider.notifier).addXP(15);
      await _ref.read(userProvider.notifier).updateStreak();
      await _ref.read(userProvider.notifier).checkAndUnlockAchievements();

      // Show notification
      await _notifications.showPomodoroCompleteNotification(isBreak: true);

      state = state.copyWith(
        isBreak: true,
        isRunning: false,
        secondsRemaining: state.breakMinutes * 60,
        completedPomodoros: newPomodoros,
        clearSessionStartTime: true,
      );
    } else {
      // Break period completed
      SoundService.playBreakComplete();
      await _notifications.showPomodoroCompleteNotification(isBreak: false);

      state = state.copyWith(
        isBreak: false,
        isRunning: false,
        secondsRemaining: state.workMinutes * 60,
        clearSessionStartTime: true,
      );
    }

    await _loadTodaySessions();
  }

  Future<void> _saveStudySession() async {
    final now = DateTime.now();
    final startTime = state.sessionStartTime ?? now;
    final durationSeconds = state.workMinutes * 60;

    final session = StudySession(
      id: _uuid.v4(),
      taskId: state.selectedTaskId,
      subjectId: state.selectedSubjectId,
      startTime: startTime,
      endTime: now,
      durationSeconds: durationSeconds,
      pomodoroCount: 1,
      createdAt: now,
    );

    await _db.insertStudySession(session);

    // Update daily stats
    final today = DateFormat('yyyy-MM-dd').format(now);
    await _db.updateDailyStats(today, 0, durationSeconds);

    // Refresh stats
    await _ref.read(statsProvider.notifier).refresh();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final timerProvider = StateNotifierProvider<TimerNotifier, TimerState>((ref) {
  return TimerNotifier(ref);
});
