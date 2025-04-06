import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logging/logging.dart';
import 'package:nitris/core/constants/app_colors.dart';
import 'package:nitris/core/constants/app_constants.dart';
import 'package:nitris/core/services/remote/api_service.dart';
import 'package:url_launcher/url_launcher.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final Logger _logger = Logger('NotificationService');

  Future<void> initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    try {
      await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) async {
          final payload = response.payload;
          if (payload != null && await canLaunchUrl(Uri.parse(payload))) {
            await launchUrl(Uri.parse(payload), mode: LaunchMode.externalApplication);
          } else {
            _logger.warning('Invalid notification payload: $payload');
          }
        },
      );

      await requestNotificationPermissions();
    } catch (e) {
      _logger.severe('Error initializing notifications: $e');
    }
  }

  Future<void> requestNotificationPermissions() async {
    try {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    } catch (e) {
      _logger.severe('Error requesting iOS notification permissions: $e');
    }
  }

  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
    String channelId = 'default_channel_id',
    String channelName = 'default_channel_name',
    String channelDescription = 'Default channel for notifications',
  }) async {
    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: AppColors.primaryColor,
      styleInformation: BigTextStyleInformation(body),
    );

    const iOSDetails = DarwinNotificationDetails();

    final platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    try {
      await flutterLocalNotificationsPlugin.show(
        0,
        title,
        body,
        platformDetails,
        payload: payload,
      );
    } catch (e) {
      _logger.severe('Error showing notification: $e');
    }
  }

  Future<void> showUpdateNotificationIfAvailable() async {
    try {
      final isUpdateAvailable = await ApiService().checkUpdate();
      _logger.info('Update available: $isUpdateAvailable');

      if (isUpdateAvailable) {
        await showNotification(
          title: 'Update Available',
          body:
              'A new version of NITRis is available. Tap to update and enjoy the latest features.',
          payload: AppConstants.appStoreUrl,
          channelId: 'update_channel_id',
          channelName: 'Update Notifications',
          channelDescription: 'Notifications for app updates',
        );
      }
    } catch (e) {
      _logger.severe('Error checking update status: $e');
    }
  }
}
