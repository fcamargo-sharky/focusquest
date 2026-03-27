import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focusquest/app.dart';
import 'package:focusquest/core/database/database_helper.dart';
import 'package:focusquest/core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize storage (SharedPreferences-based, works on all platforms)
  try {
    final db = DatabaseHelper();
    await db.database;
  } catch (e) {
    debugPrint('DB init error: $e');
  }

  // Initialize notifications (not supported on web)
  if (!kIsWeb) {
    try {
      final notificationService = NotificationService();
      await notificationService.initialize();
      await notificationService.requestPermissions();
    } catch (e) {
      debugPrint('Notification init error: $e');
    }
  }

  runApp(
    const ProviderScope(
      child: FocusQuestApp(),
    ),
  );
}
