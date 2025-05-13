import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:nitris/controllers/user_profile_controller.dart';
import 'package:nitris/core/models/user.dart';
import 'package:nitris/core/services/local/local_storage_service.dart';
import 'package:nitris/core/utils/dialogs_and_prompts.dart';
import 'package:nitris/screens/launch_screen/theme/launch_app_theme.dart';
import 'package:nitris/screens/launch_screen/widgets/user_profile_popup.dart';

class UserProfileButton extends StatefulWidget {
  const UserProfileButton({Key? key}) : super(key: key);

  @override
  State<UserProfileButton> createState() => _UserProfileButtonState();
}

class _UserProfileButtonState extends State<UserProfileButton> {
  User? _user;
  Uint8List? _avatarBytes;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initUser();
  }

  Future<void> _initUser() async {
    try {
      final user = await LocalStorageService.getCurrentUser();
      if (user != null) {
        // decode Base-64 string (strip data URI prefix if present)
        final raw = user.photo ?? '';
        final base64Str = raw.contains(',') ? raw.split(',').last : raw;
        Uint8List? bytes;
        try {
          final decoded = base64Decode(base64Str);
          if (decoded.isNotEmpty) bytes = decoded;
        } catch (_) {
          bytes = null;
        }

        setState(() {
          _user = user;
          _avatarBytes = bytes;
        });
      }
    } catch (e) {
      debugPrint('Failed to load user: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _onMenuSelected(String choice) {
    switch (choice) {
      case 'My Profile':
        _showProfilePopup();
        break;
      case 'Privacy Policy':
        Navigator.pushNamed(context, '/privacyPolicy');
        break;
      case 'Log Out':
        _confirmLogout();
        break;
      case 'Deregister and Log Out':
        _deregister();
        break;
    }
  }

  void _showProfilePopup() {
    if (_user == null) return;
    final fullName = [
      _user!.firstName,
      _user!.middleName,
      _user!.lastName,
    ].where((s) => s != null && s.isNotEmpty).join(' ');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => UserProfilePopup(
        userName: fullName,
        avatarBase64: _user!.photo ?? '',
        designation: _user!.designation ?? '',
        department: _user!.departmentName ?? '',
        mobile: _user!.mobile ?? '',
        workNumber: _user!.workPhone ?? '',
        residence: _user!.residencePhone ?? '',
        email: _user!.email ?? '',
        cabinNumber: _user!.roomNo ?? '',
        quarterNumber: _user!.quarterNo ?? '',
        empType: _user!.employeeType ?? '',
        empCode: _user!.empCode ?? '',
      ),
    );
  }

  Future<void> _confirmLogout() async {
    if (_user?.empCode == null) return;
    final shouldLogout = await DialogsAndPrompts.showLogoutConfirmationDialog(
      context,
      _user!.empCode!,
    );
    if (shouldLogout == true) {
      await UserProfileController().logout(context);
    }
  }

  void _deregister() {
    LocalStorageService.getCurrentUser().then((u) {
      if (u?.empCode != null) {
        DialogsAndPrompts.showDeRegisterDeviceDialog(context, u!.empCode!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        width: 32,
        height: 32,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    final hasImage = _avatarBytes != null;
    final firstName = _user?.firstName ?? '';

    return PopupMenuButton<String>(
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: _onMenuSelected,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: LaunchAppTheme.backgroundColor,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // -------- avatar with thin border --------
            Container(
              width: 32,
              height: 32,
              padding: const EdgeInsets.all(1.2), // border thickness
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: LaunchAppTheme.accentColor,
                  width: 1.2,
                ),
              ),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: LaunchAppTheme.accentColor,
                backgroundImage: hasImage ? MemoryImage(_avatarBytes!) : null,
                child: !hasImage && firstName.isNotEmpty
                    ? Text(
                        firstName[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      )
                    : null,
              ),
            ),
            // -----------------------------------------
            const SizedBox(width: 6),
            Text(
              firstName.isNotEmpty ? firstName : 'User',
              style: LaunchAppTheme.subheadingStyle.copyWith(
                color: LaunchAppTheme.textPrimaryColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: LaunchAppTheme.textSecondaryColor,
            ),
          ],
        ),
      ),
      itemBuilder: (_) => [
        _menuItem(Icons.person_outline, 'My Profile'),
        _menuItem(Icons.privacy_tip, 'Privacy Policy'),
        const PopupMenuDivider(),
        _menuItem(Icons.logout, 'Log Out', isDestructive: true),
        _menuItem(Icons.delete_forever, 'Deregister and Log Out',
            isDestructive: true),
      ],
    );
  }

  PopupMenuEntry<String> _menuItem(IconData icon, String label,
      {bool isDestructive = false}) {
    final color =
        isDestructive ? Colors.red : LaunchAppTheme.textSecondaryColor;
    return PopupMenuItem<String>(
      value: label,
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDestructive ? Colors.red : LaunchAppTheme.textPrimaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
