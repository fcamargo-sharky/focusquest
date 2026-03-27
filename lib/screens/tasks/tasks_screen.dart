import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:focusquest/core/constants/app_colors.dart';
import 'package:focusquest/models/task.dart';
import 'package:focusquest/providers/subjects_provider.dart';
import 'package:focusquest/providers/tasks_provider.dart';
import 'package:focusquest/widgets/task_card.dart';
import 'package:focusquest/widgets/subject_chip.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedSubjectId;
  bool _showCompleted = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Task> _filterTasks(List<Task> tasks) {
    var filtered = tasks;
    if (_selectedSubjectId != null) {
      filtered = filtered.where((t) => t.subjectId == _selectedSubjectId).toList();
    }
    if (!_showCompleted) {
      filtered = filtered.where((t) => !t.isCompleted).toList();
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final tasksState = ref.watch(tasksProvider);
    final subjects = ref.watch(subjectsProvider);

    final todayTasks = _filterTasks(tasksState.todayTasks);
    final upcomingTasks = _filterTasks(tasksState.upcomingTasks);
    final allTasks = _filterTasks(tasksState.allTasks);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        actions: [
          IconButton(
            icon: Icon(
              _showCompleted ? Icons.visibility : Icons.visibility_off_outlined,
              color: AppColors.textMuted,
            ),
            onPressed: () => setState(() => _showCompleted = !_showCompleted),
            tooltip: _showCompleted ? 'Hide completed' : 'Show completed',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.primary,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: [
            Tab(
              text: 'Today (${tasksState.todayTasks.where((t) => !t.isCompleted).length})',
            ),
            Tab(
              text: 'Upcoming (${tasksState.upcomingTasks.length})',
            ),
            Tab(
              text: 'All (${tasksState.allTasks.where((t) => !t.isCompleted).length})',
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Subject filter
          if (subjects.isNotEmpty)
            SizedBox(
              height: 50,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _selectedSubjectId = null),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: _selectedSubjectId == null
                            ? AppColors.primary.withOpacity(0.3)
                            : AppColors.darkCard,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _selectedSubjectId == null
                              ? AppColors.primary
                              : AppColors.textMuted.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        'All',
                        style: TextStyle(
                          color: _selectedSubjectId == null
                              ? AppColors.primary
                              : AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  ...subjects.map((s) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: SubjectChip(
                          subject: s,
                          isSelected: _selectedSubjectId == s.id,
                          onTap: () => setState(() {
                            _selectedSubjectId =
                                _selectedSubjectId == s.id ? null : s.id;
                          }),
                        ),
                      )),
                ],
              ),
            ),

          // Task lists
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _TaskList(tasks: todayTasks, isLoading: tasksState.isLoading),
                _TaskList(tasks: upcomingTasks, isLoading: tasksState.isLoading),
                _TaskList(tasks: allTasks, isLoading: tasksState.isLoading),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/tasks/add'),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _TaskList extends StatelessWidget {
  final List<Task> tasks;
  final bool isLoading;

  const _TaskList({required this.tasks, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.task_alt,
              size: 64,
              color: AppColors.textMuted.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'No tasks here!',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add a task to get started',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ],
        ),
      );
    }

    // Group overdue tasks at top
    final overdue = tasks.where((t) => t.isOverdue).toList();
    final normal = tasks.where((t) => !t.isOverdue).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (overdue.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              'Overdue',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          ...overdue.map((t) => TaskCard(task: t)),
          const Divider(color: AppColors.error, height: 24),
        ],
        ...normal.map((t) => TaskCard(task: t)),
        const SizedBox(height: 80),
      ],
    );
  }
}
