import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:nitris/core/constants/app_colors.dart';
import 'package:nitris/core/models/user.dart';
import 'package:nitris/core/utils/link_launcher.dart';
import 'package:nitris/screens/apps/hello_nitr_inapp/contacts/profile/contact_profile_screen.dart';

class ExpandedMenu extends StatelessWidget {
  final User contact;

  const ExpandedMenu({super.key, required this.contact});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: const Color(0xFFFDEEE8),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        children: [
          Divider(thickness: 1, color: AppColors.primaryColor.withOpacity(0.5)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildIconButton(CupertinoIcons.phone_solid, () {
                LinkLauncher.makeCall(context, contact.mobile ?? '');
              }),
              _buildIconButton(FontAwesomeIcons.whatsapp, () {
                LinkLauncher.sendWpMsg(contact.mobile ?? '');
              }),
              _buildIconButton(CupertinoIcons.chat_bubble_text_fill, () {
                LinkLauncher.sendMsg(contact.mobile ?? '');
              }),
              _buildIconButton(CupertinoIcons.mail_solid, () {
                LinkLauncher.sendEmail(contact.email ?? '');
              }),
              _buildIconButton(CupertinoIcons.person_crop_circle_fill, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ContactProfileScreen(contact),
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onPressed) {
    return IconButton(
      icon: Icon(icon, color: AppColors.primaryColor, size: 30.0),
      onPressed: onPressed,
    );
  }
}
