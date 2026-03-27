import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:focusquest/core/constants/app_colors.dart';
import 'package:focusquest/providers/tasks_provider.dart';
import 'package:focusquest/providers/routines_provider.dart';
import 'package:focusquest/providers/user_provider.dart';
import 'package:focusquest/models/routine.dart';
import 'package:focusquest/widgets/task_card.dart';
import 'package:focusquest/widgets/routine_card.dart';
import 'package:focusquest/widgets/xp_progress_bar.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final tasksState = ref.watch(tasksProvider);
    final todayRoutines = ref.watch(todayRoutinesProvider);
    final completedRoutineIds = ref.watch(routineCompletionsProvider);
    final todayTasks = tasksState.todayTasks.where((t) => !t.isCompleted).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Text(
              '🎯 ',
              style: TextStyle(fontSize: 22),
            ),
            Text(
              'FocusQuest',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        actions: [
          GestureDetector(
            onTap: () => context.go('/profile'),
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)],
                ),
              ),
              child: Center(
                child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : 'S',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(tasksProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting section
              Text(
                '${_greeting()}, ${user.name}.',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.3,
                ),
              ),
              Text(
                DateFormat('EEEE, MMMM d, y').format(DateTime.now()),
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 20),

              // XP Progress Bar
              XpProgressBar(
                level: user.level,
                xpInLevel: user.xpInCurrentLevel,
                xpNeededForLevel: user.xpNeededForNextLevel,
              ),
              const SizedBox(height: 12),

              // Streak Card
              _StreakCard(
                streak: user.currentStreak,
                shields: user.streakShields,
              ),
              const SizedBox(height: 20),

              // Today's Schedule
              _SectionHeader(
                title: "Today's Schedule",
                actionLabel: 'All Routines',
                onAction: () => context.push('/routines'),
              ),
              const SizedBox(height: 10),
              if (todayRoutines.isEmpty)
                _EmptyState(
                  icon: Icons.event_note_outlined,
                  message: 'No routines scheduled for today',
                  subMessage: 'Add routines to build healthy habits',
                  actionLabel: 'Add Routine',
                  onAction: () => context.push('/routines/add'),
                )
              else
                ...todayRoutines.take(3).map(
                      (routine) => RoutineCard(
                        routine: routine,
                        isCompletedToday:
                            completedRoutineIds.contains(routine.id),
                        onToggleComplete: () => ref
                            .read(routineCompletionsProvider.notifier)
                            .toggle(routine.id),
                        onEdit: () =>
                            context.push('/routines/edit', extra: routine),
                        onDelete: null,
                      ),
                    ),
              if (todayRoutines.length > 3)
                TextButton(
                  onPressed: () => context.push('/routines'),
                  child: Text(
                    '+${todayRoutines.length - 3} more routines',
                    style: const TextStyle(color: AppColors.primary),
                  ),
                ),
              const SizedBox(height: 20),

              // Today's Tasks
              _SectionHeader(
                title: "Today's Tasks",
                actionLabel: 'All Tasks',
                onAction: () => context.go('/tasks'),
              ),
              const SizedBox(height: 10),
              if (tasksState.isLoading)
                const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
              else if (todayTasks.isEmpty)
                _EmptyState(
                  icon: Icons.task_alt,
                  message: 'No tasks due today',
                  subMessage: 'Add a task to stay on track',
                  actionLabel: 'Add Task',
                  onAction: () => context.push('/tasks/add'),
                )
              else
                ...todayTasks.map(
                  (task) => TaskCard(task: task),
                ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/tasks/add'),
        icon: const Icon(Icons.add),
        label: const Text('Add Task'),
        backgroundColor: AppColors.primary,
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  final int streak;
  final int shields;

  const _StreakCard({required this.streak, required this.shields});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.streakColor.withOpacity(0.2),
            AppColors.secondary.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.streakColor.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Text('🔥', style: TextStyle(fontSize: 36)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '$streak',
                      style: const TextStyle(
                        color: AppColors.streakColor,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'day streak',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const Text(
                  '一日一歩 — one day, one step.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12, letterSpacing: 0.3),
                ),
              ],
            ),
          ),
          // Streak Shields
          Column(
            children: [
              const Text('🛡️', style: TextStyle(fontSize: 20)),
              Text(
                '$shields',
                style: const TextStyle(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'shields',
                style: TextStyle(color: AppColors.textMuted, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
          ),
        ),
        TextButton(
          onPressed: onAction,
          child: Text(
            actionLabel,
            style: const TextStyle(color: AppColors.primary, fontSize: 13),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String subMessage;
  final String actionLabel;
  final VoidCallback onAction;

  const _EmptyState({
    required this.icon,
    required this.message,
    required this.subMessage,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            subMessage,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: onAction,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}
