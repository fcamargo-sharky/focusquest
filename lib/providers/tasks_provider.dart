import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focusquest/core/database/database_helper.dart';
import 'package:focusquest/models/task.dart';
import 'package:focusquest/providers/user_provider.dart';
import 'package:focusquest/providers/stats_provider.dart';
import 'package:focusquest/core/services/sound_service.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

class TasksState {
  final List<Task> allTasks;
  final List<Task> todayTasks;
  final List<Task> upcomingTasks;
  final bool isLoading;

  const TasksState({
    this.allTasks = const [],
    this.todayTasks = const [],
    this.upcomingTasks = const [],
    this.isLoading = false,
  });

  TasksState copyWith({
    List<Task>? allTasks,
    List<Task>? todayTasks,
    List<Task>? upcomingTasks,
    bool? isLoading,
  }) {
    return TasksState(
      allTasks: allTasks ?? this.allTasks,
      todayTasks: todayTasks ?? this.todayTasks,
      upcomingTasks: upcomingTasks ?? this.upcomingTasks,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class TasksNotifier extends StateNotifier<TasksState> {
  final Ref _ref;
  final _db = DatabaseHelper();
  final _uuid = const Uuid();

  TasksNotifier(this._ref) : super(const TasksState(isLoading: true)) {
    loadTasks();
  }

  Future<void> loadTasks() async {
    state = state.copyWith(isLoading: true);
    try {
      final all = await _db.getTasks();
      final today = await _db.getTasksForToday(includeCompleted: true);
      final upcoming = await _db.getUpcomingTasks();
      state = TasksState(
        allTasks: all,
        todayTasks: today,
        upcomingTasks: upcoming,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> addTask(Task task) async {
    final newTask = Task(
      id: task.id.isEmpty ? _uuid.v4() : task.id,
      title: task.title,
      description: task.description,
      dueDate: task.dueDate,
      priority: task.priority,
      subjectId: task.subjectId,
      isCompleted: false,
      tags: task.tags,
      xpAwarded: 0,
      createdAt: task.createdAt,
    );
    await _db.insertTask(newTask);
    await loadTasks();
  }

  Future<void> completeTask(String id) async {
    final task = state.allTasks.firstWhere(
      (t) => t.id == id,
      orElse: () => throw Exception('Task not found'),
    );

    if (task.isCompleted) return;

    final xp = task.xpValue;
    await _db.completeTask(id, xp);
    SoundService.playTaskComplete();

    // Update daily stats
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    await _db.updateDailyStats(today, 1, 0);

    // Award XP to user
    await _ref.read(userProvider.notifier).addXP(xp);

    // Check achievements
    await _ref.read(userProvider.notifier).checkAndUnlockAchievements();

    // Refresh stats
    await _ref.read(statsProvider.notifier).refresh();

    await loadTasks();
  }

  Future<void> deleteTask(String id) async {
    await _db.deleteTask(id);
    state = state.copyWith(
      allTasks: state.allTasks.where((t) => t.id != id).toList(),
      todayTasks: state.todayTasks.where((t) => t.id != id).toList(),
      upcomingTasks: state.upcomingTasks.where((t) => t.id != id).toList(),
    );
  }

  Future<void> updateTask(Task task) async {
    await _db.updateTask(task);
    await loadTasks();
  }

  List<Task> getTasksBySubject(String? subjectId) {
    if (subjectId == null) return state.allTasks;
    return state.allTasks.where((t) => t.subjectId == subjectId).toList();
  }

  List<Task> getTasksByTag(String tag) {
    return state.allTasks.where((t) => t.tags.contains(tag)).toList();
  }
}

final tasksProvider = StateNotifierProvider<TasksNotifier, TasksState>((ref) {
  return TasksNotifier(ref);
});

final filteredTasksProvider = Provider.family<List<Task>, Map<String, String?>>((ref, filters) {
  final tasks = ref.watch(tasksProvider).allTasks;
  final subjectId = filters['subjectId'];
  final tag = filters['tag'];

  return tasks.where((task) {
    if (subjectId != null && task.subjectId != subjectId) return false;
    if (tag != null && !task.tags.contains(tag)) return false;
    return true;
  }).toList();
});
