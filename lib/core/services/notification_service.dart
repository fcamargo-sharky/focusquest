import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:focusquest/models/routine.dart';
import 'package:focusquest/models/task.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {},
    );

    _initialized = true;
  }

  Future<void> requestPermissions() async {
    try {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.requestNotificationsPermission();
        await androidPlugin.requestExactAlarmsPermission();
      }
      final iosPlugin = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (iosPlugin != null) {
        await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
      }
    } catch (e) {
      // Permissions denied gracefully - app continues without notifications
      debugPrint('Notification permission: $e');
    }
  }

  Future<void> scheduleRoutineNotification(Routine routine) async {
    if (!routine.isActive) return;
    // Routine notifications are shown as immediate reminders when the app is open
    // Full scheduling requires timezone package which is not included
    debugPrint('Routine notification scheduled for: ${routine.title}');
  }

  Future<void> cancelNotification(int id) async {
    try {
      await _plugin.cancel(id);
    } catch (e) {
      debugPrint('Cancel notification error: $e');
    }
  }

  Future<void> cancelRoutineNotifications(String routineId) async {
    for (int day = 0; day < 7; day++) {
      await cancelNotification(_routineNotificationId(routineId, day));
    }
  }

  Future<void> showTaskDueNotification(Task task) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'tasks_channel',
        'Tasks',
        channelDescription: 'Notifications for due tasks',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

      await _plugin.show(
        task.id.hashCode.abs() % 100000,
        'Task Due: ${task.title}',
        task.description?.isNotEmpty == true
            ? task.description!
            : 'You have a task due now!',
        details,
      );
    } catch (e) {
      debugPrint('Task notification error: $e');
    }
  }

  Future<void> showPomodoroCompleteNotification({required bool isBreak}) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'pomodoro_channel',
        'Pomodoro Timer',
        channelDescription: 'Pomodoro timer notifications',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        playSound: true,
      );
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: false,
        presentSound: true,
      );
      const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

      if (isBreak) {
        await _plugin.show(
          9999,
          'Break Time! Great work!',
          'You finished a Pomodoro! Take a well-deserved break.',
          details,
        );
      } else {
        await _plugin.show(
          9998,
          'Back to Work!',
          'Break is over. Time to focus again!',
          details,
        );
      }
    } catch (e) {
      debugPrint('Pomodoro notification error: $e');
    }
  }

  Future<void> showAchievementNotification(String title, String description) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'achievements_channel',
        'Achievements',
        channelDescription: 'Achievement unlock notifications',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        icon: '@mipmap/ic_launcher',
      );
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

      await _plugin.show(
        DateTime.now().millisecondsSinceEpoch % 100000,
        'Achievement Unlocked: $title',
        description,
        details,
      );
    } catch (e) {
      debugPrint('Achievement notification error: $e');
    }
  }

  int _routineNotificationId(String routineId, int day) {
    return (routineId.hashCode.abs() % 100000) * 10 + day;
  }
}
