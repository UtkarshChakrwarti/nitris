import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:nitris/app.dart';
import 'package:nitris/core/notification/notifications_service.dart';
import 'package:nitris/core/permission/permissions_util.dart';

void main() async {
  _setupLogging(); // Setup logging
  WidgetsFlutterBinding.ensureInitialized();

  // Lock the entire app in portrait mode.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Request necessary permissions
  await requestPermissions();

  // Initialize the NotificationService
  NotificationService notificationService = NotificationService();
  await notificationService.initializeNotifications();
  await notificationService.requestNotificationPermissions(); // Request notification permissions

  // Schedule the update notification
  notificationService.scheduleUpdateNotification();

  runApp(MyApp(notificationService: notificationService));
}

void _setupLogging() {
  // Setup logging for the app only in debug mode
  Logger.root.onRecord.listen((LogRecord rec) {
    if (kDebugMode) {
      print('${rec.level.name}: ${rec.time}: ${rec.message}');
    }
  });
}
