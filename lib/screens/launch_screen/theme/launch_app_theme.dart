import 'package:flutter/material.dart';

class LaunchAppTheme {
  // Colors
  static const MaterialColor primarySwatch = MaterialColor(0xFFC35839, {
    50: Color(0xFFFFEDE8),
    100: Color(0xFFFFD2C5),
    200: Color(0xFFFFB4A0),
    300: Color(0xFFFF957A),
    400: Color(0xFFFF7D5D),
    500: Color(0xFFC35839),
    600: Color(0xFFB04F33),
    700: Color(0xFF9A442C),
    800: Color(0xFF843A25),
    900: Color(0xFF5F2919),
  });

  static const Color accentColor = Color(0xFFC35839);
  static const Color backgroundColor = Color(0xFFF5F5F7);
  static const Color cardColor = Colors.white;
  static const Color textPrimaryColor = Color(0xFF1A1A1A);
  static const Color textSecondaryColor = Color(0xFF757575);

  // Text Styles
  static const TextStyle headingStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: textPrimaryColor, 
    letterSpacing: 0.5,
  );

  static const TextStyle subheadingStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: textSecondaryColor,
  );

  static const TextStyle bodyTextStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textPrimaryColor,
  );

  static const TextStyle headlineStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: textPrimaryColor,
  );

  // Card decoration
  static BoxDecoration get cardDecoration => BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
      );
}
