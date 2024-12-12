import 'package:flutter/material.dart';
import 'package:nitris/app_routes.dart';
import 'package:nitris/core/constants/app_theme.dart';
import 'package:nitris/core/exception/custom_error.dart';
import 'package:nitris/core/notification/notifications_service.dart';
import 'package:nitris/core/provider/login_provider.dart';
import 'package:nitris/screens/apps/live_attendance_inapp/live_attendance_controller/home_controller.dart';
import 'package:provider/provider.dart';

class MyApp extends StatelessWidget {
  final NotificationService notificationService;

  const MyApp({super.key, required this.notificationService});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LoginProvider()),
        // In Apps Providers
        ChangeNotifierProvider(create: (_) => AttendanceHomeController()),
      ],
      child: MaterialApp(
        builder: (BuildContext context, Widget? widget) {
          ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
            return CustomError(errorDetails: errorDetails);
          };
          return widget ?? Container(); // Ensure widget is not null
        },
        debugShowCheckedModeBanner: false,
        title: 'NITRis',
        theme: AppTheme.buildAppTheme(),
        initialRoute: '/',
        routes: appRoutes,
      ),
    );
  }
}
