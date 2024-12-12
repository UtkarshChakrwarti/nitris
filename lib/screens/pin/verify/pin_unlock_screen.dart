import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nitris/controllers/pin_unlock_screen_controller.dart';
import 'package:nitris/controllers/user_profile_controller.dart';
import 'package:nitris/core/models/user.dart';
import 'package:nitris/core/services/local/local_storage_service.dart';

import 'package:nitris/core/utils/dialogs_and_prompts.dart';
import 'package:nitris/screens/launch_screen/dashboard.dart';

import 'package:nitris/screens/pin/verify/widgets/dialogs.dart';
import 'package:nitris/screens/pin/verify/widgets/exit_confirmation_dialog.dart';

import 'package:nitris/screens/pin/verify/widgets/keypad.dart';
import 'package:nitris/screens/pin/verify/widgets/pin_display.dart';

class PinUnlockScreen extends StatefulWidget {
  const PinUnlockScreen({super.key});

  @override
  _PinUnlockScreenState createState() => _PinUnlockScreenState();
}

class _PinUnlockScreenState extends State<PinUnlockScreen> {
  final PinUnlockScreenController _pinUnlockScreenController =
      PinUnlockScreenController();
  late final UserProfileController _userProfileController;
  String _pin = "";
  User? _loggedInUser; // Make the user nullable

  @override
  void initState() {
    super.initState();
    _lockOrientationToPortrait();
    _userProfileController = UserProfileController();
    _loadLoggedInUserDetails();
    _checkBiometrics();
  }

  @override
  void dispose() {
    _resetOrientation();
    super.dispose();
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

  void _lockOrientationToPortrait() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  void _resetOrientation() {
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
  }

  Future<void> _checkBiometrics() async {
    try {
      final canCheckBiometrics =
          await _pinUnlockScreenController.canCheckBiometrics();
      if (canCheckBiometrics) {
        _authenticateWithBiometrics();
      }
    } catch (e) {
      showErrorDialog(context, 'Failed to check biometric support.');
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    try {
      final authenticated =
          await _pinUnlockScreenController.authenticateWithBiometrics();

      if (authenticated) {
        _navigateToHome();
      } else {
        // Fallback to PIN unlock
      }
    } catch (e) {
      showErrorDialog(context, 'Biometric authentication failed.');
    }
  }

  void _onKeyPressed(String value) {
    setState(() {
      if (_pin.length < 4) {
        _pin += value;
      }
      if (_pin.length == 4) {
        _validatePin();
      }
    });
  }

  void _onDeletePressed() {
    setState(() {
      if (_pin.isNotEmpty) {
        _pin = _pin.substring(0, _pin.length - 1);
      }
    });
  }

  void _validatePin() async {
    try {
      final isValid = await _pinUnlockScreenController.validatePin(_pin);
      if (isValid) {
        _navigateToHome();
      } else {
        showErrorDialog(context, 'Invalid PIN. Please try again.');
        setState(() {
          _pin = "";
        });
      }
    } catch (e) {
      showErrorDialog(context, 'PIN validation failed.');
      setState(() {
        _pin = "";
      });
    }
  }

  void _navigateToHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const DashboardPage()),
      (Route<dynamic> route) => false, // Removes all previous routes
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;

    return WillPopScope(
      onWillPop: () async {
        return await showExitConfirmationDialog(context) ?? false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: screenHeight * 0.02),
                  Text(
                    'Welcome, ${_loggedInUser?.firstName ?? 'User'}',
                    style: TextStyle(
                      fontSize: 20, // Smaller font size
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'Enter Your NITRis PIN',
                    style: TextStyle(
                      fontSize: 18, // Smaller font size
                      color: theme.primaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: screenHeight * 0.05),
                  PinDisplay(pin: _pin),
                  SizedBox(height: screenHeight * 0.05),
                  Keypad(
                    onKeyPressed: _onKeyPressed,
                    onDeletePressed: _onDeletePressed,
                    onFingerprintPressed: _authenticateWithBiometrics,
                  ),
                  OutlinedButton.icon(
                    onPressed: () =>
                        DialogsAndPrompts.showLogoutConfirmationDialog(
                                context, _loggedInUser?.firstName ?? 'User')
                            .then((shouldExit) async {
                      if (shouldExit != null && shouldExit) {
                        await _userProfileController.logout(context);
                      }
                    }),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12.0, vertical: 7.0),
                      backgroundColor: Colors.transparent,
                      side: BorderSide(color: theme.primaryColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18.0),
                      ),
                    ),
                    icon:
                        Icon(Icons.logout, color: theme.primaryColor, size: 12),
                    label: Text(
                      'Logout',
                      style: TextStyle(color: theme.primaryColor, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
