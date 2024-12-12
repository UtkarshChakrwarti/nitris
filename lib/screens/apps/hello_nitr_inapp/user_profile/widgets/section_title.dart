import 'package:flutter/material.dart';
import 'package:nitris/core/constants/app_colors.dart';

class SectionTitle extends StatelessWidget {
  final String title;
  final double fontSize;

  const SectionTitle(
    this.title,
    this.fontSize, {
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          // Left Divider
          Expanded(
            child: Divider(
              color: AppColors.primaryColor.withOpacity(0.3),
              thickness: 1.5,
            ),
          ),
          const SizedBox(width: 12.0),
          // Title Text
          Text(
            title,
            style: TextStyle(
              color: AppColors.primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: fontSize,
              fontFamily: 'Roboto',
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 12.0),
          // Right Divider
          Expanded(
            child: Divider(
              color: AppColors.primaryColor.withOpacity(0.3),
              thickness: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
