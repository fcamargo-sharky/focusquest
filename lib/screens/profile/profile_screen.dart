import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focusquest/core/constants/app_colors.dart';
import 'package:focusquest/models/achievement.dart';
import 'package:focusquest/providers/subjects_provider.dart';
import 'package:focusquest/providers/theme_provider.dart';
import 'package:focusquest/providers/user_provider.dart';
import 'package:focusquest/widgets/xp_progress_bar.dart';
import 'package:focusquest/widgets/subject_chip.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameController = TextEditingController();
  bool _isEditingName = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final subjects = ref.watch(subjectsProvider);
    final unlockedAsync = ref.watch(unlockedAchievementsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User avatar and name
            Center(
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.primary.withOpacity(0.6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : 'S',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_isEditingName)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 160,
                          child: TextField(
                            controller: _nameController,
                            autofocus: true,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.check, color: AppColors.success),
                          onPressed: () async {
                            final name = _nameController.text.trim();
                            if (name.isNotEmpty) {
                              await ref.read(userProvider.notifier).updateName(name);
                            }
                            setState(() => _isEditingName = false);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: AppColors.textMuted),
                          onPressed: () =>
                              setState(() => _isEditingName = false),
                        ),
                      ],
                    )
                  else
                    GestureDetector(
                      onTap: () {
                        _nameController.text = user.name;
                        setState(() => _isEditingName = true);
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            user.name,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.edit_outlined,
                              size: 16, color: AppColors.textMuted),
                        ],
                      ),
                    ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.primary.withOpacity(0.4)),
                    ),
                    child: Text(
                      'Level ${user.level} Scholar',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // XP progress
            XpProgressBar(
              level: user.level,
              xpInLevel: user.xpInCurrentLevel,
              xpNeededForLevel: user.xpNeededForNextLevel,
            ),
            const SizedBox(height: 16),

            // Stats overview
            Row(
              children: [
                Expanded(
                  child: _MiniStatCard(
                    icon: '🔥',
                    value: '${user.currentStreak}',
                    label: 'Streak',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MiniStatCard(
                    icon: '⭐',
                    value: '${user.xp}',
                    label: 'Total XP',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MiniStatCard(
                    icon: '🛡️',
                    value: '${user.streakShields}',
                    label: 'Shields',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Achievements
            _SectionHeader(title: 'Achievements'),
            const SizedBox(height: 12),
            unlockedAsync.when(
              data: (unlockedIds) => _AchievementsGrid(unlockedIds: unlockedIds),
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (_, __) => const Text('Failed to load achievements'),
            ),
            const SizedBox(height: 24),

            // Subjects
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const _SectionHeader(title: 'Subjects'),
                TextButton.icon(
                  onPressed: () => _showAddSubjectDialog(context),
                  icon: const Icon(Icons.add, size: 16, color: AppColors.primary),
                  label: const Text('Add',
                      style: TextStyle(color: AppColors.primary, fontSize: 13)),
                  style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (subjects.isEmpty)
              const Text(
                'No subjects yet. Add one to organize your tasks!',
                style: TextStyle(color: AppColors.textMuted),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: subjects.map((s) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SubjectChip(subject: s),
                      const SizedBox(width: 2),
                      GestureDetector(
                        onTap: () => _confirmDeleteSubject(context, s.id, s.name),
                        child: const Icon(Icons.close,
                            size: 14, color: AppColors.textMuted),
                      ),
                    ],
                  );
                }).toList(),
              ),
            const SizedBox(height: 24),

            // Appearance
            _SectionHeader(title: 'Appearance'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.darkCard,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Consumer(
                builder: (context, ref, _) {
                  final isDark = ref.watch(themeProvider) == ThemeMode.dark;
                  return SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Dark Mode',
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                    subtitle: Text(
                      isDark ? 'Currently dark' : 'Currently light',
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 12),
                    ),
                    secondary: Icon(
                      isDark ? Icons.dark_mode : Icons.light_mode,
                      color: AppColors.primary,
                    ),
                    value: isDark,
                    onChanged: (_) =>
                        ref.read(themeProvider.notifier).toggle(),
                    activeColor: AppColors.primary,
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // About
            _SectionHeader(title: 'About'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.darkCard,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'FocusQuest v1.0.0',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'A gamified productivity app for university students. Track tasks, build routines, and level up your academic life!',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  void _showAddSubjectDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    int selectedColor = AppColors.subjectColors[0].value;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.darkCard,
          title: const Text('New Subject'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  hintText: 'Subject name',
                  labelText: 'Name',
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              const Text('Color', style: TextStyle(color: AppColors.textMuted)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: AppColors.subjectColors.map((c) {
                  final isSelected = selectedColor == c.value;
                  return GestureDetector(
                    onTap: () =>
                        setDialogState(() => selectedColor = c.value),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: Colors.white, width: 2)
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isNotEmpty) {
                  await ref
                      .read(subjectsProvider.notifier)
                      .addSubject(nameCtrl.text.trim(), selectedColor);
                  if (ctx.mounted) Navigator.pop(ctx);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteSubject(BuildContext context, String id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkCard,
        title: const Text('Delete Subject'),
        content: Text('Delete "$name"? Tasks with this subject will not be deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(subjectsProvider.notifier).deleteSubject(id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _AchievementsGrid extends StatelessWidget {
  final List<String> unlockedIds;

  const _AchievementsGrid({required this.unlockedIds});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.85,
      ),
      itemCount: Achievement.all.length,
      itemBuilder: (context, i) {
        final achievement = Achievement.all[i];
        final isUnlocked = unlockedIds.contains(achievement.id);
        return _AchievementCard(
          achievement: achievement,
          isUnlocked: isUnlocked,
        );
      },
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final Achievement achievement;
  final bool isUnlocked;

  const _AchievementCard({required this.achievement, required this.isUnlocked});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.darkCard,
            title: Row(
              children: [
                Text(achievement.icon,
                    style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(achievement.title,
                      style: const TextStyle(color: AppColors.textPrimary)),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.description,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Reward: ',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                    Text(
                      '+${achievement.xpReward} XP',
                      style: const TextStyle(
                        color: AppColors.xpColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                if (isUnlocked)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle,
                            color: AppColors.success, size: 16),
                        SizedBox(width: 4),
                        Text('Unlocked!',
                            style: TextStyle(
                                color: AppColors.success, fontSize: 13)),
                      ],
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isUnlocked
              ? AppColors.primary.withOpacity(0.15)
              : AppColors.darkCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isUnlocked
                ? AppColors.primary.withOpacity(0.5)
                : AppColors.textMuted.withOpacity(0.1),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              achievement.icon,
              style: TextStyle(
                fontSize: 26,
                color: isUnlocked ? null : const Color(0xFF1E1E3A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              achievement.title,
              style: TextStyle(
                color: isUnlocked ? AppColors.textPrimary : AppColors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (isUnlocked) ...[
              const SizedBox(height: 2),
              Text(
                '+${achievement.xpReward} XP',
                style: const TextStyle(
                  color: AppColors.xpColor,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ] else
              const SizedBox(height: 4),
            if (!isUnlocked)
              const Icon(Icons.lock_outline,
                  size: 12, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  final String icon;
  final String value;
  final String label;

  const _MiniStatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
