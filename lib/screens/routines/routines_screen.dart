import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:focusquest/core/constants/app_colors.dart';
import 'package:focusquest/models/routine.dart';
import 'package:focusquest/providers/routines_provider.dart';
import 'package:focusquest/widgets/routine_card.dart';

class RoutinesScreen extends ConsumerWidget {
  const RoutinesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routines = ref.watch(routinesProvider);
    final todayRoutines = ref.watch(todayRoutinesProvider);
    final allOtherRoutines = routines.where((r) => !r.isToday).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Routines'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
        ),
      ),
      body: routines.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.repeat, size: 64, color: AppColors.textMuted),
                  const SizedBox(height: 16),
                  const Text(
                    'No Routines Yet',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Build healthy habits with daily routines',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => context.push('/routines/add'),
                    icon: const Icon(Icons.add),
                    label: const Text('Create Routine'),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (todayRoutines.isNotEmpty) ...[
                  _SectionHeader(
                    title: "Today's Routines",
                    count: todayRoutines.length,
                  ),
                  const SizedBox(height: 8),
                  ...todayRoutines.map((r) => _RoutineCardWithActions(routine: r)),
                  const SizedBox(height: 20),
                ],
                if (allOtherRoutines.isNotEmpty) ...[
                  _SectionHeader(
                    title: 'All Routines',
                    count: routines.length,
                  ),
                  const SizedBox(height: 8),
                  ...routines.map((r) => _RoutineCardWithActions(routine: r)),
                ] else if (routines.isNotEmpty) ...[
                  _SectionHeader(
                    title: 'All Routines',
                    count: routines.length,
                  ),
                  const SizedBox(height: 8),
                  ...routines.map((r) => _RoutineCardWithActions(routine: r)),
                ],
                const SizedBox(height: 80),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/routines/add'),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _RoutineCardWithActions extends ConsumerWidget {
  final Routine routine;

  const _RoutineCardWithActions({required this.routine});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final completedIds = ref.watch(routineCompletionsProvider);
    final isCompleted = completedIds.contains(routine.id);
    final isToday = routine.isToday && routine.isActive;

    return RoutineCard(
      routine: routine,
      isCompletedToday: isCompleted,
      onToggleComplete: isToday
          ? () => ref.read(routineCompletionsProvider.notifier).toggle(routine.id)
          : null,
      onEdit: () => context.push('/routines/edit', extra: routine),
      onDelete: () => _confirmDelete(context, ref),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkCard,
        title: const Text('Delete Routine'),
        content: Text('Delete "${routine.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(routinesProvider.notifier).deleteRoutine(routine.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;

  const _SectionHeader({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
