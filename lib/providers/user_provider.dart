import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focusquest/core/database/database_helper.dart';
import 'package:focusquest/core/services/notification_service.dart';
import 'package:focusquest/models/achievement.dart';
import 'package:focusquest/models/user_profile.dart';
import 'package:intl/intl.dart';

class UserNotifier extends StateNotifier<UserProfile> {
  final _db = DatabaseHelper();
  final _notifications = NotificationService();

  UserNotifier()
      : super(const UserProfile(
          id: 1,
          name: 'Student',
          xp: 0,
          level: 1,
          currentStreak: 0,
          longestStreak: 0,
          streakShields: 1,
        )) {
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await _db.getUserProfile();
    if (profile != null) {
      state = profile;
    }
  }

  Future<void> addXP(int amount) async {
    final newXp = state.xp + amount;
    final newLevel = UserProfile.calculateLevel(newXp);
    final didLevelUp = newLevel > state.level;

    final updated = state.copyWith(xp: newXp, level: newLevel);
    state = updated;
    await _db.updateUserProfile(updated);

    if (didLevelUp) {
      await _checkLevelAchievements(newLevel);
    }
  }

  Future<void> updateStreak() async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final yesterday = DateFormat('yyyy-MM-dd')
        .format(DateTime.now().subtract(const Duration(days: 1)));

    if (state.lastActiveDate == today) return; // Already updated today

    int newStreak = state.currentStreak;
    int shields = state.streakShields;

    if (state.lastActiveDate == yesterday) {
      // Consecutive day
      newStreak++;
    } else if (state.lastActiveDate != null && state.lastActiveDate != today) {
      // Missed a day
      final lastDate = DateTime.parse(state.lastActiveDate!);
      final diff = DateTime.now().difference(lastDate).inDays;

      if (diff == 2 && shields > 0) {
        // Use shield
        shields--;
        newStreak++;
      } else {
        newStreak = 1;
      }
    } else {
      newStreak = 1;
    }

    final newLongest = newStreak > state.longestStreak ? newStreak : state.longestStreak;

    final updated = state.copyWith(
      currentStreak: newStreak,
      longestStreak: newLongest,
      lastActiveDate: today,
      streakShields: shields,
    );
    state = updated;
    await _db.updateUserProfile(updated);

    // Check streak achievements
    await _checkStreakAchievements(newStreak);
  }

  Future<void> checkAndUnlockAchievements() async {
    final unlockedIds = await _db.getUnlockedAchievements();

    // Check task-based achievements
    final totalTasks = await _db.getTotalCompletedTasks();
    if (totalTasks >= 1 && !unlockedIds.contains('first_task')) {
      await unlockAchievement(Achievement.findById('first_task')!);
    }
    if (totalTasks >= 10 && !unlockedIds.contains('tasks_10')) {
      await unlockAchievement(Achievement.findById('tasks_10')!);
    }
    if (totalTasks >= 50 && !unlockedIds.contains('tasks_50')) {
      await unlockAchievement(Achievement.findById('tasks_50')!);
    }

    // Check pomodoro achievements
    final totalPomodoros = await _db.getTotalPomodoroCount();
    if (totalPomodoros >= 1 && !unlockedIds.contains('first_pomodoro')) {
      await unlockAchievement(Achievement.findById('first_pomodoro')!);
    }
    if (totalPomodoros >= 10 && !unlockedIds.contains('pomodoro_10')) {
      await unlockAchievement(Achievement.findById('pomodoro_10')!);
    }

    // Check study time achievements
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final todayStudySeconds = await _db.getTotalStudySecondsForDate(today);
    if (todayStudySeconds >= 7200 && !unlockedIds.contains('study_2h')) {
      await unlockAchievement(Achievement.findById('study_2h')!);
    }
    if (todayStudySeconds >= 18000 && !unlockedIds.contains('study_5h')) {
      await unlockAchievement(Achievement.findById('study_5h')!);
    }

    final weekStudySeconds = await _db.getTotalStudySecondsForWeek();
    if (weekStudySeconds >= 36000 && !unlockedIds.contains('study_10h_week')) {
      await unlockAchievement(Achievement.findById('study_10h_week')!);
    }
  }

  Future<void> _checkStreakAchievements(int streak) async {
    final unlockedIds = await _db.getUnlockedAchievements();

    if (streak >= 3 && !unlockedIds.contains('streak_3')) {
      await unlockAchievement(Achievement.findById('streak_3')!);
    }
    if (streak >= 7 && !unlockedIds.contains('streak_7')) {
      await unlockAchievement(Achievement.findById('streak_7')!);
    }
    if (streak >= 30 && !unlockedIds.contains('streak_30')) {
      await unlockAchievement(Achievement.findById('streak_30')!);
    }
  }

  Future<void> _checkLevelAchievements(int level) async {
    final unlockedIds = await _db.getUnlockedAchievements();

    if (level >= 5 && !unlockedIds.contains('level_5')) {
      await unlockAchievement(Achievement.findById('level_5')!);
    }
    if (level >= 10 && !unlockedIds.contains('level_10')) {
      await unlockAchievement(Achievement.findById('level_10')!);
    }
  }

  Future<void> unlockAchievement(Achievement achievement) async {
    await _db.unlockAchievement(achievement.id);
    await addXP(achievement.xpReward);
    await _notifications.showAchievementNotification(
      achievement.title,
      achievement.description,
    );
  }

  Future<void> updateName(String name) async {
    final updated = state.copyWith(name: name);
    state = updated;
    await _db.updateUserProfile(updated);
  }

  Future<void> addStreakShield() async {
    final updated = state.copyWith(streakShields: state.streakShields + 1);
    state = updated;
    await _db.updateUserProfile(updated);
  }
}

final userProvider = StateNotifierProvider<UserNotifier, UserProfile>((ref) {
  return UserNotifier();
});

final unlockedAchievementsProvider = FutureProvider<List<String>>((ref) async {
  ref.watch(userProvider); // Rebuild when user changes
  return DatabaseHelper().getUnlockedAchievements();
});
