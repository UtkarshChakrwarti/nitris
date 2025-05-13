import 'package:flutter/material.dart';
import 'package:nitris/core/constants/app_colors.dart';
import 'package:nitris/core/constants/app_constants.dart';
import 'package:nitris/core/utils/link_launcher.dart';

class Footer extends StatelessWidget {
  const Footer({super.key});

  @override
  Widget build(BuildContext context) {
     final int currentYear = DateTime.now().year;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text("\u{00A9} NIT Rourkela $currentYear \nDesigned and Developed by ",
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 14, color: Colors.black, fontFamily: 'Roboto')),
        GestureDetector(
          onTap: () => LinkLauncher.launchURL(AppConstants.catUrl),
          child: const Text("Centre for Automation Technology",
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppColors.primaryColor,
                  fontSize: 14,
                  fontFamily: 'Roboto',
                  decoration: TextDecoration.none)),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
