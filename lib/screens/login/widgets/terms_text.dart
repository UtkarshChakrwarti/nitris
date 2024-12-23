import 'package:flutter/material.dart';
import 'package:nitris/core/constants/app_colors.dart';
import 'package:nitris/screens/privacy_policy/privacy_policy_screen.dart';

class TermsText extends StatelessWidget {
  const TermsText({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text("By signing in, you agree to our ",
            style: TextStyle(
                fontSize: 14, color: Colors.black, fontFamily: 'Roboto'),
            textAlign: TextAlign.center),
        GestureDetector(
          onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen())),
          child: const Text("Privacy Policy",
              style: TextStyle(
                  color: AppColors.primaryColor,
                  fontSize: 14,
                  decoration: TextDecoration.underline)),
        ),
      ],
    );
  }
}
