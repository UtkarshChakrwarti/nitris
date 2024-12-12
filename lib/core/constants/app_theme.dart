import 'package:flutter/material.dart';
import 'package:nitris/core/constants/app_colors.dart';

class AppTheme {
  static ThemeData buildAppTheme() {
    const primaryColor = Color(0xFFC35839);
    return ThemeData(
      fontFamily: 'Roboto',
      primaryColor: primaryColor,
      highlightColor: primaryColor,
      splashColor: primaryColor,
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: primaryColor,
        selectionColor: primaryColor.withOpacity(0.4),
        selectionHandleColor: primaryColor,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(
          color: AppColors.primaryColor,
        ),
        titleTextStyle: TextStyle(
          color: AppColors.primaryColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: 'Roboto',
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: primaryColor,
          borderRadius: BorderRadius.circular(4),
        ),
        textStyle: const TextStyle(
          color: Colors.white,
          fontFamily: 'Roboto',
        ),
      ),
      scaffoldBackgroundColor: Colors.white,
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primaryColor,
      ),
    );
  }
}