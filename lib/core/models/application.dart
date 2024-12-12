import 'package:flutter/material.dart';
import 'package:nitris/core/constants/app_colors.dart';

class Application {
  final String icon; // This must always be a String representing a path
  final String label; // Main label or title for the application
  final String subtitle; // Subtitle for the application (optional)
  final Color color;

  const Application({
    required this.icon,
    required this.label,
    this.subtitle = "", // Subtitle is optional, default to empty
    required this.color,
  });
}

final List<Application> applications = [
  const Application(
    icon: 'assets/images/mark-nitr.png',
    label: 'Live Class',
    subtitle: ' Attendance',
    color: AppColors.primaryColor,
  ),
  const Application(
    icon: 'assets/images/hello-nitr.png', // use a valid image path
    label: 'Hello',
    subtitle: 'NITR',
    color: AppColors.primaryColor,
  ),
];
