import 'package:flutter/material.dart';
import 'package:nitris/controllers/user_profile_controller.dart';
import 'package:nitris/screens/apps/hello_nitr_inapp/user_profile/widgets/icon_button.dart';

class UtilityButtons extends StatelessWidget {
  final UserProfileController controller;

  const UtilityButtons(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButtonWidget(
                icon: Icons.sync,
                label: "Sync",
                iconSize: 22.0,
                fontSize: 11.0,
                onTap: () {
                  Navigator.pushReplacementNamed(context, '/contactsUpdate');
                },
              ),
            ],
          ),
          const SizedBox(height: 8.0),
        ],
      ),
    );
  }
}
