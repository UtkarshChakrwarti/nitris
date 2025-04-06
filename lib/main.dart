import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:nitris/app.dart';
import 'package:nitris/core/constants/app_colors.dart';
import 'package:nitris/core/notification/notifications_service.dart';
import 'package:nitris/core/permission/permissions_util.dart';
import 'package:package_info_plus/package_info_plus.dart';

const String originalPackageName = "com.nitrkl.nitris"; // Adjust if needed

Future<bool> isClonedApp() async {
  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  return packageInfo.packageName != originalPackageName;
}

void main() async {
  _setupLogging();
  WidgetsFlutterBinding.ensureInitialized();

  // Clone app detection
  bool isCloned = await isClonedApp();
  if (isCloned) {
    if (kDebugMode) {
      print("Cloned app detected. Exiting...");
    }

    runApp(MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Builder(
        builder: (context) {
          Future.delayed(Duration.zero, () {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                title: const Text('Unauthorized App'),
                content: const Text(
                    'This appears to be an unofficial copy of the app. For security reasons, this app will now close.'),
                actions: [
                  ElevatedButton(
                    onPressed: () => exit(0),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        },
      ),
    ));
    return;
  }

  // Request OS-level permissions
  await requestPermissions();

  // Setup notifications
  final notificationService = NotificationService();
  await notificationService.initializeNotifications();
  await notificationService.showUpdateNotificationIfAvailable();

  runApp(MyApp(notificationService: notificationService));
}

void _setupLogging() {
  Logger.root.onRecord.listen((record) {
    if (kDebugMode) {
      print('${record.level.name}: ${record.time}: ${record.message}');
    }
  });
}
