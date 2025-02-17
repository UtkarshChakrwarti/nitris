import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logging/logging.dart';
import 'package:nitris/core/constants/app_colors.dart';
import 'package:nitris/core/constants/app_constants.dart';
import 'package:nitris/core/services/remote/api_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';

class NotificationService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final Logger _logger = Logger('NotificationService');

  Future<void> initializeNotifications() async {
    // Android initialization settings.
    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS (Darwin) initialization settings.
    const DarwinInitializationSettings iOSInitializationSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      // These options help display notifications when the app is in the foreground.
      defaultPresentAlert: true,
      defaultPresentBadge: true,
      defaultPresentSound: true,
    );

    // Combine platform settings.
    const InitializationSettings initializationSettings = InitializationSettings(
      android: androidInitializationSettings,
      iOS: iOSInitializationSettings,
    );

    try {
      await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse:
            (NotificationResponse notificationResponse) async {
          final String? payload = notificationResponse.payload;
          if (payload != null && await canLaunchUrl(Uri.parse(payload))) {
            await launchUrl(Uri.parse(payload));
          } else {
            _logger.warning('Invalid notification payload: $payload');
          }
        },
      );

      // Request notification permissions.
      await requestNotificationPermissions();
    } catch (e) {
      _logger.severe('Error initializing notifications: $e');
    }
  }

  Future<void> requestNotificationPermissions() async {
    try {
      // Request notification permissions using permission_handler.
      PermissionStatus status = await Permission.notification.request();
      if (status != PermissionStatus.granted) {
        _logger.warning('Notification permissions not granted');
      }
    } catch (e) {
      _logger.severe('Error requesting notification permissions: $e');
    }
  }

  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
    String channelId = 'default_channel_id',
    String channelName = 'default_channel_name',
    String channelDescription = 'Default Channel',
  }) async {
    // Android-specific notification details.
    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      icon: '@mipmap/ic_launcher',
      color: AppColors.primaryColor,
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
      ),
      enableVibration: true,
      playSound: true,
      actions: [
        const AndroidNotificationAction(
          'update_action',
          'Update Now',
          showsUserInterface: true,
          cancelNotification: true,
        ),
      ],
    );

    // iOS-specific (Darwin) notification details.
    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails();

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    try {
      await flutterLocalNotificationsPlugin.show(
        0,
        title,
        body,
        platformChannelSpecifics,
        payload: payload,
      );
    } catch (e) {
      _logger.severe('Error showing notification: $e');
    }
  }

  Future<void> scheduleUpdateNotification() async {
    try {
      // Check for an available app update.
      bool isUpdateAvailable = await ApiService().checkUpdate();

      _logger.info('Update available: $isUpdateAvailable');

      if (isUpdateAvailable) {
        await showNotification(
          title: 'Update Available',
          body:
              'A new version of NITRis is available. Update now to get the latest features and improvements.',
          payload: AppConstants.playStoreUrl, // Replace with your app's URL.
          channelId: 'update_channel_id',
          channelName: 'Update Notifications',
          channelDescription: 'Notifications for app updates',
        );
      }
    } catch (e) {
      _logger.severe('Error scheduling update notification: $e');
    }
  }
}
