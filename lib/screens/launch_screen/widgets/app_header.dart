import 'package:flutter/material.dart';
import 'package:nitris/screens/launch_screen/theme/launch_app_theme.dart';
import 'app_logo.dart';
import 'user_profile_button.dart';

class AppHeader extends StatelessWidget {
  const AppHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: LaunchAppTheme.cardDecoration.copyWith(
        borderRadius: BorderRadius.zero,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AppLogo(),
          UserProfileButton(),
        ],
      ),
    );
  }
}
