import 'package:flutter/material.dart';
import 'package:nitris/core/constants/app_colors.dart';

class WelcomeText extends StatelessWidget {
  const WelcomeText({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Column(
          children: [
            Text("Sign in to",
                style: TextStyle(
                    fontSize: 26,
                    color: AppColors.primaryColor,
                    fontFamily: 'Roboto')),
            Text("NITRis",
                style: TextStyle(
                    fontSize: 32,
                    color: AppColors.primaryColor,
                    fontFamily: 'Roboto')),
          ],
        ),
      ],
    );
  }
}
