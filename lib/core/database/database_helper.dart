import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:focusquest/models/subject.dart';
import 'package:focusquest/models/task.dart';
import 'package:focusquest/models/routine.dart';
import 'package:focusquest/models/study_session.dart';
import 'package:focusquest/models/user_profile.dart';

/// Storage backend using SharedPreferences + JSON.
/// Drop-in replacement for the SQLite-based DatabaseHelper.
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  // Keys
  static const _kSubjects = 'db_subjects';
  static const _kTasks = 'db_tasks';
  static const _kRoutines = 'db_routines';
  static const _kSessions = 'db_study_sessions';
  static const _kProfile = 'db_user_profile';
  static const _kAchievements = 'db_achievements';
  static const _kDailyStats = 'db_daily_stats';
  static const _kRoutineCompletions = 'db_routine_completions';

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _p async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // ── helpers ──────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> _getList(String key) async {
    final p = await _p;
    final raw = p.getString(key);
    if (raw == null || raw.isEmpty) return [];
    return List<Map<String, dynamic>>.from(jsonDecode(raw));
  }

  Future<void> _setList(String key, List<Map<String, dynamic>> list) async {
    final p = await _p;
    await p.setString(key, jsonEncode(list));
  }

  Future<Map<String, dynamic>?> _getMap(String key) async {
    final p = await _p;
    final raw = p.getString(key);
    if (raw == null || raw.isEmpty) return null;
    return Map<String, dynamic>.from(jsonDecode(raw));
  }

  Future<void> _setMap(String key, Map<String, dynamic> map) async {
    final p = await _p;
    await p.setString(key, jsonEncode(map));
  }

  // Fake database getter kept for compatibility (used in main.dart)
  Future<void> get database async {
    await _ensureProfile();
  }

  Future<void> _ensureProfile() async {
    final existing = await _getMap(_kProfile);
    if (existing == null) {
      await _setMap(_kProfile, {
        'id': 1,
        'name': 'Student',
        'xp': 0,
        'level': 1,
        'currentStreak': 0,
        'longestStreak': 0,
        'lastActiveDate': null,
        'streakShields': 1,
      });
    }
  }

  // ── SUBJECTS ─────────────────────────────────────────────────────────────

  Future<void> insertSubject(Subject subject) async {
    final list = await _getList(_kSubjects);
    list.add(subject.toMap());
    await _setList(_kSubjects, list);
  }

  Future<List<Subject>> getSubjects() async {
    final list = await _getList(_kSubjects);
    return list.map((m) => Subject.fromMap(m)).toList();
  }

  Future<void> updateSubject(Subject subject) async {
    final list = await _getList(_kSubjects);
    final idx = list.indexWhere((m) => m['id'] == subject.id);
    if (idx != -1) list[idx] = subject.toMap();
    await _setList(_kSubjects, list);
  }

  Future<void> deleteSubject(String id) async {
    final list = await _getList(_kSubjects);
    list.removeWhere((m) => m['id'] == id);
    await _setList(_kSubjects, list);
  }

  // ── TASKS ────────────────────────────────────────────────────────────────

  Future<void> insertTask(Task task) async {
    final list = await _getList(_kTasks);
    list.add(task.toMap());
    await _setList(_kTasks, list);
  }

  Future<List<Task>> getTasks() async {
    final list = await _getList(_kTasks);
    final tasks = list.map((m) => Task.fromMap(m)).toList();
    tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return tasks;
  }

  Future<List<Task>> getTasksForToday({bool includeCompleted = false}) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59).millisecondsSinceEpoch;
    final all = await _getList(_kTasks);
    return all
        .map((m) => Task.fromMap(m))
        .where((t) =>
            t.dueDate != null &&
            t.dueDate!.millisecondsSinceEpoch >= start &&
            t.dueDate!.millisecondsSinceEpoch <= end &&
            (includeCompleted || !t.isCompleted))
        .toList()
      ..sort((a, b) => b.priority.index.compareTo(a.priority.index));
  }

  Future<List<Task>> getUpcomingTasks() async {
    final now = DateTime.now();
    final endOfDay =
        DateTime(now.year, now.month, now.day, 23, 59, 59).millisecondsSinceEpoch;
    final all = await _getList(_kTasks);
    return all
        .map((m) => Task.fromMap(m))
        .where((t) =>
            t.dueDate != null &&
            t.dueDate!.millisecondsSinceEpoch > endOfDay &&
            !t.isCompleted)
        .toList()
      ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
  }

  Future<void> updateTask(Task task) async {
    final list = await _getList(_kTasks);
    final idx = list.indexWhere((m) => m['id'] == task.id);
    if (idx != -1) list[idx] = task.toMap();
    await _setList(_kTasks, list);
  }

  Future<void> deleteTask(String id) async {
    final list = await _getList(_kTasks);
    list.removeWhere((m) => m['id'] == id);
    await _setList(_kTasks, list);
  }

  Future<void> completeTask(String id, int xp) async {
    final list = await _getList(_kTasks);
    final idx = list.indexWhere((m) => m['id'] == id);
    if (idx != -1) {
      list[idx]['isCompleted'] = 1;
      list[idx]['completedAt'] = DateTime.now().millisecondsSinceEpoch;
      list[idx]['xpAwarded'] = xp;
    }
    await _setList(_kTasks, list);
  }

  Future<int> getTotalCompletedTasks() async {
    final list = await _getList(_kTasks);
    return list.where((m) => (m['isCompleted'] as int? ?? 0) == 1).length;
  }

  // ── ROUTINES ──────────────────────────────────────────────────────────────

  Future<void> insertRoutine(Routine routine) async {
    final list = await _getList(_kRoutines);
    list.add(routine.toMap());
    await _setList(_kRoutines, list);
  }

  Future<List<Routine>> getRoutines() async {
    final list = await _getList(_kRoutines);
    return list.map((m) => Routine.fromMap(m)).toList()
      ..sort((a, b) {
        final at = a.startHour * 60 + a.startMinute;
        final bt = b.startHour * 60 + b.startMinute;
        return at.compareTo(bt);
      });
  }

  Future<void> updateRoutine(Routine routine) async {
    final list = await _getList(_kRoutines);
    final idx = list.indexWhere((m) => m['id'] == routine.id);
    if (idx != -1) list[idx] = routine.toMap();
    await _setList(_kRoutines, list);
  }

  Future<void> deleteRoutine(String id) async {
    final list = await _getList(_kRoutines);
    list.removeWhere((m) => m['id'] == id);
    await _setList(_kRoutines, list);
  }

  // ── STUDY SESSIONS ────────────────────────────────────────────────────────

  Future<void> insertStudySession(StudySession session) async {
    final list = await _getList(_kSessions);
    list.add(session.toMap());
    await _setList(_kSessions, list);
  }

  Future<List<StudySession>> getStudySessionsForDate(String date) async {
    final dt = DateTime.parse(date);
    final start = DateTime(dt.year, dt.month, dt.day).millisecondsSinceEpoch;
    final end =
        DateTime(dt.year, dt.month, dt.day, 23, 59, 59).millisecondsSinceEpoch;
    final list = await _getList(_kSessions);
    return list
        .map((m) => StudySession.fromMap(m))
        .where((s) =>
            s.startTime.millisecondsSinceEpoch >= start &&
            s.startTime.millisecondsSinceEpoch <= end)
        .toList();
  }

  Future<List<StudySession>> getStudySessionsForWeek() async {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final start =
        DateTime(weekStart.year, weekStart.month, weekStart.day).millisecondsSinceEpoch;
    final list = await _getList(_kSessions);
    return list
        .map((m) => StudySession.fromMap(m))
        .where((s) => s.startTime.millisecondsSinceEpoch >= start)
        .toList();
  }

  Future<void> updateStudySession(StudySession session) async {
    final list = await _getList(_kSessions);
    final idx = list.indexWhere((m) => m['id'] == session.id);
    if (idx != -1) {
      list[idx] = session.toMap();
    } else {
      list.add(session.toMap());
    }
    await _setList(_kSessions, list);
  }

  Future<int> getTotalPomodoroCount() async {
    final list = await _getList(_kSessions);
    return list.fold<int>(
        0, (sum, m) => sum + (m['pomodoroCount'] as int? ?? 0));
  }

  // ── USER PROFILE ──────────────────────────────────────────────────────────

  Future<UserProfile?> getUserProfile() async {
    final map = await _getMap(_kProfile);
    if (map == null) return null;
    return UserProfile.fromMap(map);
  }

  Future<void> updateUserProfile(UserProfile profile) async {
    await _setMap(_kProfile, profile.toMap());
  }

  // ── ACHIEVEMENTS ──────────────────────────────────────────────────────────

  Future<List<String>> getUnlockedAchievements() async {
    final list = await _getList(_kAchievements);
    return list.map((m) => m['achievementId'] as String).toList();
  }

  Future<void> unlockAchievement(String achievementId) async {
    final list = await _getList(_kAchievements);
    if (list.any((m) => m['achievementId'] == achievementId)) return;
    list.add({
      'achievementId': achievementId,
      'unlockedAt': DateTime.now().millisecondsSinceEpoch,
    });
    await _setList(_kAchievements, list);
  }

  Future<bool> isAchievementUnlocked(String achievementId) async {
    final list = await _getList(_kAchievements);
    return list.any((m) => m['achievementId'] == achievementId);
  }

  // ── DAILY STATS ───────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> getDailyStats(String date) async {
    final p = await _p;
    final raw = p.getString('$_kDailyStats:$date');
    if (raw == null) return null;
    return Map<String, dynamic>.from(jsonDecode(raw));
  }

  Future<void> updateDailyStats(
      String date, int tasksCompleted, int studySeconds) async {
    final existing = await getDailyStats(date);
    final updated = {
      'date': date,
      'tasksCompleted':
          (existing?['tasksCompleted'] as int? ?? 0) + tasksCompleted,
      'studySeconds': (existing?['studySeconds'] as int? ?? 0) + studySeconds,
      'routinesCompleted': existing?['routinesCompleted'] as int? ?? 0,
    };
    final p = await _p;
    await p.setString('$_kDailyStats:$date', jsonEncode(updated));
  }

  Future<List<Map<String, dynamic>>> getWeeklyStats() async {
    final now = DateTime.now();
    final result = <Map<String, dynamic>>[];
    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final dateStr =
          '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      final stats = await getDailyStats(dateStr);
      result.add(stats ??
          {
            'date': dateStr,
            'tasksCompleted': 0,
            'studySeconds': 0,
            'routinesCompleted': 0,
          });
    }
    return result;
  }

  Future<List<Map<String, dynamic>>> getAllDailyStats() async {
    final p = await _p;
    final keys = p.getKeys().where((k) => k.startsWith('$_kDailyStats:'));
    final result = <Map<String, dynamic>>[];
    for (final k in keys) {
      final raw = p.getString(k);
      if (raw != null) result.add(Map<String, dynamic>.from(jsonDecode(raw)));
    }
    result.sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));
    return result;
  }

  Future<int> getTotalStudySecondsForDate(String date) async {
    final stats = await getDailyStats(date);
    return stats?['studySeconds'] as int? ?? 0;
  }

  Future<int> getTotalStudySecondsForWeek() async {
    final now = DateTime.now();
    int total = 0;
    for (int i = 0; i < 7; i++) {
      final day = now.subtract(Duration(days: i));
      final dateStr =
          '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      final stats = await getDailyStats(dateStr);
      total += stats?['studySeconds'] as int? ?? 0;
    }
    return total;
  }

  Future<Map<String, int>> getSubjectStudyBreakdown() async {
    final list = await _getList(_kSessions);
    final map = <String, int>{};
    for (final m in list) {
      final sid = m['subjectId'] as String?;
      if (sid != null) {
        map[sid] = (map[sid] ?? 0) + (m['durationSeconds'] as int? ?? 0);
      }
    }
    return map;
  }

  // ── ROUTINE COMPLETIONS ───────────────────────────────────────────────────

  Future<Set<String>> getCompletedRoutineIdsForDate(String date) async {
    final list = await _getList(_kRoutineCompletions);
    return list
        .where((m) => m['date'] == date)
        .map((m) => m['routineId'] as String)
        .toSet();
  }

  Future<bool> toggleRoutineCompletion(String routineId, String date) async {
    final list = await _getList(_kRoutineCompletions);
    final idx = list.indexWhere(
        (m) => m['routineId'] == routineId && m['date'] == date);
    if (idx == -1) {
      list.add({'routineId': routineId, 'date': date});
      await _setList(_kRoutineCompletions, list);
      return true;
    } else {
      list.removeAt(idx);
      await _setList(_kRoutineCompletions, list);
      return false;
    }
  }
}
