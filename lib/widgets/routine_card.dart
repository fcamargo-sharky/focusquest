import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focusquest/core/constants/app_colors.dart';
import 'package:focusquest/models/routine.dart';
import 'package:focusquest/providers/routines_provider.dart';
import 'package:focusquest/providers/subjects_provider.dart';
import 'package:focusquest/widgets/subject_chip.dart';

class RoutineCard extends ConsumerWidget {
  final Routine routine;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool isCompletedToday;
  final VoidCallback? onToggleComplete;

  const RoutineCard({
    super.key,
    required this.routine,
    this.onEdit,
    this.onDelete,
    this.isCompletedToday = false,
    this.onToggleComplete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subject = routine.subjectId != null
        ? ref.watch(selectedSubjectProvider(routine.subjectId))
        : null;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: routine.isActive
              ? AppColors.primary.withOpacity(0.3)
              : AppColors.textMuted.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Time column
            Container(
              width: 52,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              decoration: BoxDecoration(
                color: routine.isActive
                    ? AppColors.primary.withOpacity(0.15)
                    : AppColors.darkBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    routine.timeString,
                    style: TextStyle(
                      color: routine.isActive
                          ? AppColors.primary
                          : AppColors.textMuted,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    routine.title,
                    style: TextStyle(
                      color: routine.isActive
                          ? AppColors.textPrimary
                          : AppColors.textMuted,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.timer_outlined,
                              size: 12, color: AppColors.textMuted),
                          const SizedBox(width: 3),
                          Text(
                            routine.durationString,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.calendar_today_outlined,
                              size: 12, color: AppColors.textMuted),
                          const SizedBox(width: 3),
                          Text(
                            routine.daysString,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      if (subject != null)
                        SubjectChip(subject: subject, size: SubjectChipSize.small),
                    ],
                  ),
                ],
              ),
            ),
            // Actions
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onToggleComplete != null)
                  GestureDetector(
                    onTap: onToggleComplete,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompletedToday
                            ? AppColors.success
                            : Colors.transparent,
                        border: Border.all(
                          color: isCompletedToday
                              ? AppColors.success
                              : AppColors.textMuted,
                          width: 2,
                        ),
                      ),
                      child: isCompletedToday
                          ? const Icon(Icons.check,
                              size: 16, color: Colors.white)
                          : null,
                    ),
                  ),
                const SizedBox(height: 4),
                Switch(
                  value: routine.isActive,
                  onChanged: (_) =>
                      ref.read(routinesProvider.notifier).toggleRoutine(routine.id),
                  activeColor: AppColors.primary,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (onEdit != null)
                      GestureDetector(
                        onTap: onEdit,
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(Icons.edit_outlined,
                              size: 18, color: AppColors.textMuted),
                        ),
                      ),
                    if (onDelete != null)
                      GestureDetector(
                        onTap: onDelete,
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(Icons.delete_outline,
                              size: 18, color: AppColors.error),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
