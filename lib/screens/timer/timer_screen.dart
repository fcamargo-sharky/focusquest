import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focusquest/core/constants/app_colors.dart';
import 'package:focusquest/providers/subjects_provider.dart';
import 'package:focusquest/providers/tasks_provider.dart';
import 'package:focusquest/providers/timer_provider.dart';
import 'package:focusquest/widgets/pomodoro_ring.dart';

class TimerScreen extends ConsumerWidget {
  const TimerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(timerProvider);
    final timerNotifier = ref.read(timerProvider.notifier);
    final subjects = ref.watch(subjectsProvider);
    final tasksState = ref.watch(tasksProvider);

    final availableTasks = timerState.selectedSubjectId != null
        ? tasksState.allTasks
            .where((t) =>
                !t.isCompleted && t.subjectId == timerState.selectedSubjectId)
            .toList()
        : tasksState.allTasks.where((t) => !t.isCompleted).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Focus Timer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppColors.textMuted),
            onPressed: () => _showSettingsSheet(context, ref),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            const SizedBox(height: 16),

            // Pomodoro counter
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.darkCard,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🍅', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Text(
                    'Pomodoro #${timerState.completedPomodoros + 1}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Circular timer
            PomodoroRing(
              progress: timerState.progress,
              timeText: timerState.timeString,
              isBreak: timerState.isBreak,
              size: 260,
            ),
            const SizedBox(height: 32),

            // Status label
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: timerState.isBreak
                    ? AppColors.success.withOpacity(0.15)
                    : AppColors.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                timerState.isBreak
                    ? '☕ Break Time – Relax!'
                    : '🎯 Focus Mode – Stay on track!',
                style: TextStyle(
                  color: timerState.isBreak ? AppColors.success : AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Control buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Reset
                _ControlButton(
                  icon: Icons.replay,
                  size: 44,
                  onTap: timerNotifier.reset,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 20),

                // Play/Pause (main)
                GestureDetector(
                  onTap: timerState.isRunning
                      ? timerNotifier.pause
                      : timerNotifier.start,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: timerState.isBreak
                          ? AppColors.success
                          : AppColors.primary,
                      boxShadow: [
                        BoxShadow(
                          color: (timerState.isBreak
                                  ? AppColors.success
                                  : AppColors.primary)
                              .withOpacity(0.3),
                          blurRadius: 16,
                          spreadRadius: 0,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      timerState.isRunning ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                ),
                const SizedBox(width: 20),

                // Skip
                _ControlButton(
                  icon: Icons.skip_next,
                  size: 44,
                  onTap: timerNotifier.skip,
                  color: AppColors.textMuted,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Subject selector
            _SelectorCard(
              label: 'Subject',
              hint: 'Select a subject (optional)',
              icon: Icons.book_outlined,
              child: DropdownButton<String>(
                value: timerState.selectedSubjectId,
                isExpanded: true,
                underline: const SizedBox(),
                dropdownColor: AppColors.darkCard,
                hint: const Text('None', style: TextStyle(color: AppColors.textMuted)),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('None', style: TextStyle(color: AppColors.textMuted)),
                  ),
                  ...subjects.map((s) => DropdownMenuItem<String>(
                        value: s.id,
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: s.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(s.name,
                                style:
                                    const TextStyle(color: AppColors.textPrimary)),
                          ],
                        ),
                      )),
                ],
                onChanged: timerNotifier.selectSubject,
              ),
            ),
            const SizedBox(height: 8),

            // Task selector
            _SelectorCard(
              label: 'Task',
              hint: 'Select a task (optional)',
              icon: Icons.task_alt,
              child: DropdownButton<String>(
                value: timerState.selectedTaskId,
                isExpanded: true,
                underline: const SizedBox(),
                dropdownColor: AppColors.darkCard,
                hint: const Text('None', style: TextStyle(color: AppColors.textMuted)),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('None', style: TextStyle(color: AppColors.textMuted)),
                  ),
                  ...availableTasks.map((t) => DropdownMenuItem<String>(
                        value: t.id,
                        child: Text(
                          t.title,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.textPrimary),
                        ),
                      )),
                ],
                onChanged: timerNotifier.selectTask,
              ),
            ),
            const SizedBox(height: 20),

            // Today's sessions
            if (timerState.todaySessions.isNotEmpty) ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Today's Sessions",
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ...timerState.todaySessions.map((session) {
                final subject = session.subjectId != null
                    ? ref.read(selectedSubjectProvider(session.subjectId))
                    : null;
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.darkCard,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Text(
                        '🍅 × ${session.pomodoroCount}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              subject?.name ?? 'General Study',
                              style: TextStyle(
                                color: subject?.color ?? AppColors.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              session.durationFormatted,
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '+${session.pomodoroCount * 15} XP',
                        style: const TextStyle(
                          color: AppColors.xpColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  void _showSettingsSheet(BuildContext context, WidgetRef ref) {
    final timerNotifier = ref.read(timerProvider.notifier);
    final timerState = ref.read(timerProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          int workMin = timerState.workMinutes;
          int breakMin = timerState.breakMinutes;

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Timer Settings',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),

                const Text('Work Duration',
                    style: TextStyle(color: AppColors.textMuted)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [15, 20, 25, 30, 45, 60].map((m) {
                    return ChoiceChip(
                      label: Text('$m min'),
                      selected: workMin == m,
                      selectedColor: AppColors.primary.withOpacity(0.3),
                      onSelected: (_) {
                        setModalState(() => workMin = m);
                        timerNotifier.setWorkMinutes(m);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                const Text('Break Duration',
                    style: TextStyle(color: AppColors.textMuted)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [5, 10, 15].map((m) {
                    return ChoiceChip(
                      label: Text('$m min'),
                      selected: breakMin == m,
                      selectedColor: AppColors.success.withOpacity(0.3),
                      onSelected: (_) {
                        setModalState(() => breakMin = m);
                        timerNotifier.setBreakMinutes(m);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Done'),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final VoidCallback onTap;
  final Color color;

  const _ControlButton({
    required this.icon,
    required this.size,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.darkCard,
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Icon(icon, color: color, size: size * 0.5),
      ),
    );
  }
}

class _SelectorCard extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final Widget child;

  const _SelectorCard({
    required this.label,
    required this.hint,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF374151)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textMuted),
          const SizedBox(width: 8),
          Expanded(child: child),
        ],
      ),
    );
  }
}
