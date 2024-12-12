import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:nitris/controllers/user_profile_controller.dart';
import 'package:nitris/core/models/user.dart';
import 'package:nitris/core/services/local/local_storage_service.dart';
import 'package:nitris/core/utils/dialogs_and_prompts.dart';
import 'package:nitris/core/utils/image_validator.dart';
import 'package:nitris/screens/launch_screen/theme/launch_app_theme.dart';
import 'package:nitris/screens/launch_screen/widgets/settings_popup.dart';
import 'package:nitris/screens/launch_screen/widgets/user_profile_popup.dart';

class UserProfileButton extends StatefulWidget {
  const UserProfileButton({super.key});

  @override
  _UserProfileButtonState createState() => _UserProfileButtonState();
}

class _UserProfileButtonState extends State<UserProfileButton> {
  User? _loggedInUser; // Make the user nullable

  @override
  void initState() {
    super.initState();
    _loadLoggedInUserDetails();
  }

  // Load user details including first name and avatar
  Future<void> _loadLoggedInUserDetails() async {
    try {
      final user = await LocalStorageService.getCurrentUser();
      if (user != null) {
        setState(() {
          _loggedInUser = user;
        });
      }
    } catch (e) {
      debugPrint('Error loading user information: $e');
    }
  }

  // Dummy function for button press
  void _onButtonClick(String value) {
    if (value == "My Profile") {
      _showUserProfilePopup();
    } else if (value == "Settings") {
      _showSettingsPopup();
    } else if (value == "Log Out") {
      DialogsAndPrompts.showLogoutConfirmationDialog(context, _loggedInUser!.empCode!)
          .then((shouldExit) async {
        if (shouldExit != null && shouldExit) {
          final userController = UserProfileController();
          await userController.logout(context);
        }
      });
    }
    else if (value == "Privacy Policy") {
      Navigator.pushNamed(context, '/privacyPolicy');
    }
  }

  void _showUserProfilePopup() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => UserProfilePopup(
        userName: [
          _loggedInUser?.firstName,
          _loggedInUser?.middleName,
          _loggedInUser?.lastName,
        ].where((name) => name != null && name.isNotEmpty).join(' '),
        avatarBase64: _loggedInUser?.photo ?? '',
        designation: _loggedInUser?.designation ?? '',
        department: _loggedInUser?.departmentName ?? '',
        mobile: _loggedInUser?.mobile ?? '',
        workNumber: _loggedInUser?.workPhone ?? '',
        residence: _loggedInUser?.residencePhone ?? '',
        email: _loggedInUser?.email ?? '',
        cabinNumber: _loggedInUser?.roomNo ?? '',
        quarterNumber: _loggedInUser?.quarterNo ?? '',
      ),
    );
  }

  void _showSettingsPopup() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const SettingsPopup(),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Check if the user is loaded before proceeding
    if (_loggedInUser == null) {
      return CircularProgressIndicator(); // Or any loading widget
    }

    bool isImageValid = _loggedInUser!.photo!.isNotEmpty &&
        ImageValidator().isValidBase64Image(_loggedInUser!.photo!);

    return PopupMenuButton(
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) => _onButtonClick(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: LaunchAppTheme.backgroundColor,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: LaunchAppTheme.accentColor,
              backgroundImage: isImageValid
                  ? MemoryImage(base64Decode(_loggedInUser!.photo!))
                  : null,
              child: !isImageValid
                  ? Text(
                      _loggedInUser!.firstName![0].toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 6),
            Text(
              _loggedInUser!.firstName ?? 'User',
              style: LaunchAppTheme.subheadingStyle.copyWith(
                color: LaunchAppTheme.textPrimaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: LaunchAppTheme.textSecondaryColor,
              size: 18,
            ),
          ],
        ),
      ),
      itemBuilder: (context) => [
        _buildMenuItem(Icons.person_outline_rounded, 'My Profile'),
        _buildMenuItem(Icons.settings_outlined, 'Settings'),
        _buildMenuItem(Icons.privacy_tip, 'Privacy Policy'),
        const PopupMenuDivider(),
        _buildMenuItem(Icons.logout_rounded, 'Log Out', isDestructive: true),
      ],
    );
  }

  PopupMenuEntry<dynamic> _buildMenuItem(IconData icon, String label,
      {bool isDestructive = false}) {
    return PopupMenuItem<dynamic>(
      value: label,
      child: Row(
        children: [
          Icon(
            icon,
            color:
                isDestructive ? Colors.red : LaunchAppTheme.textSecondaryColor,
            size: 18,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color:
                  isDestructive ? Colors.red : LaunchAppTheme.textPrimaryColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
