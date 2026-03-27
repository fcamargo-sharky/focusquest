import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focusquest/core/database/database_helper.dart';
import 'package:focusquest/core/services/notification_service.dart';
import 'package:focusquest/core/services/sound_service.dart';
import 'package:focusquest/models/routine.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class RoutinesNotifier extends StateNotifier<List<Routine>> {
  RoutinesNotifier() : super([]) {
    _loadRoutines();
  }

  final _db = DatabaseHelper();
  final _notifications = NotificationService();
  final _uuid = const Uuid();

  Future<void> _loadRoutines() async {
    final routines = await _db.getRoutines();
    state = routines;
  }

  Future<void> addRoutine(Routine routine) async {
    final newRoutine = Routine(
      id: routine.id.isEmpty ? _uuid.v4() : routine.id,
      title: routine.title,
      description: routine.description,
      startHour: routine.startHour,
      startMinute: routine.startMinute,
      durationMinutes: routine.durationMinutes,
      days: routine.days,
      subjectId: routine.subjectId,
      isActive: routine.isActive,
      createdAt: routine.createdAt,
    );
    await _db.insertRoutine(newRoutine);
    if (newRoutine.isActive) {
      await _notifications.scheduleRoutineNotification(newRoutine);
    }
    state = [...state, newRoutine];
  }

  Future<void> updateRoutine(Routine routine) async {
    await _db.updateRoutine(routine);
    await _notifications.cancelRoutineNotifications(routine.id);
    if (routine.isActive) {
      await _notifications.scheduleRoutineNotification(routine);
    }
    state = state.map((r) => r.id == routine.id ? routine : r).toList();
  }

  Future<void> deleteRoutine(String id) async {
    await _db.deleteRoutine(id);
    await _notifications.cancelRoutineNotifications(id);
    state = state.where((r) => r.id != id).toList();
  }

  Future<void> toggleRoutine(String id) async {
    final routine = state.firstWhere((r) => r.id == id);
    final updated = routine.copyWith(isActive: !routine.isActive);
    await updateRoutine(updated);
  }
}

class RoutineCompletionsNotifier extends StateNotifier<Set<String>> {
  RoutineCompletionsNotifier() : super({}) {
    _load();
  }

  final _db = DatabaseHelper();

  String get _today => DateFormat('yyyy-MM-dd').format(DateTime.now());

  Future<void> _load() async {
    final ids = await _db.getCompletedRoutineIdsForDate(_today);
    state = ids;
  }

  Future<void> toggle(String routineId) async {
    final nowCompleted = await _db.toggleRoutineCompletion(routineId, _today);
    if (nowCompleted) {
      SoundService.playRoutineComplete();
      state = {...state, routineId};
    } else {
      state = state.where((id) => id != routineId).toSet();
    }
  }

  bool isCompleted(String routineId) => state.contains(routineId);
}

final routinesProvider = StateNotifierProvider<RoutinesNotifier, List<Routine>>((ref) {
  return RoutinesNotifier();
});

final routineCompletionsProvider =
    StateNotifierProvider<RoutineCompletionsNotifier, Set<String>>((ref) {
  return RoutineCompletionsNotifier();
});

final todayRoutinesProvider = Provider<List<Routine>>((ref) {
  final routines = ref.watch(routinesProvider);
  return routines.where((r) => r.isToday && r.isActive).toList()
    ..sort((a, b) {
      final aTime = a.startHour * 60 + a.startMinute;
      final bTime = b.startHour * 60 + b.startMinute;
      return aTime.compareTo(bTime);
    });
});
