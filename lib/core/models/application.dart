import 'package:flutter/material.dart';
import 'package:nitris/core/constants/app_colors.dart';
import 'package:nitris/core/services/local/local_storage_service.dart';
import 'package:logging/logging.dart';

final logger = Logger('Application');

class Application {
  final String icon;     // Image asset path
  final String label;    // Main label for the application
  final String subtitle; // Subtitle for the application (optional)
  final Color color;

  const Application({
    required this.icon,
    required this.label,
    this.subtitle = "",
    required this.color,
  });
}

/// Returns a list of applications based on the logged-in user's employee type.
/// If the employee type is 'student', only the "Live Class" module is returned;
/// otherwise, both modules are returned.
Future<List<Application>> getApplications() async {
  final loginResponse = await LocalStorageService.getLoginResponse();
  final employeeType = loginResponse?.employeeType?.toLowerCase() ?? 'employee';

  if (employeeType == 'student') {
    // log add
    logger.info('Student logged in');
    return [
      const Application(
        icon: 'assets/images/mark-nitr.png',
        label: 'Live Class',
        subtitle: ' Attendance',
        color: AppColors.primaryColor,
      ),
    ];
  } else {
    // log add
    logger.info('others logged in', employeeType);
    return [
      const Application(
        icon: 'assets/images/mark-nitr.png',
        label: 'Live Class',
        subtitle: ' Attendance',
        color: AppColors.primaryColor,
      ),
      const Application(
        icon: 'assets/images/hello-nitr.png', // Ensure this asset path is valid.
        label: 'Hello',
        subtitle: 'NITR',
        color: AppColors.primaryColor,
      ),
    ];
  }
}
