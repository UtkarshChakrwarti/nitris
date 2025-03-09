import 'package:flutter/material.dart';
import 'package:nitris/core/provider/login_provider.dart';
import 'package:nitris/core/utils/dialogs_and_prompts.dart';
import 'package:nitris/controllers/pin_creation_controller.dart';
import 'package:nitris/core/constants/app_colors.dart';
import 'package:nitris/screens/launch_screen/dashboard.dart';

import 'package:nitris/screens/pin/create/widgets/pin_input_field.dart';

class PinCreationScreen extends StatefulWidget {
  const PinCreationScreen({super.key});

  @override
  _PinCreationScreenState createState() => _PinCreationScreenState();
}

class _PinCreationScreenState extends State<PinCreationScreen> {
  final PinCreationController _pinCreationController = PinCreationController();
  final LoginProvider _loginProvider = LoginProvider();
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();
  final FocusNode _pinFocusNode = FocusNode();
  final FocusNode _confirmPinFocusNode = FocusNode();
  bool _pinVisible = false;
  bool _confirmPinVisible = false;
  bool _pinsMatch = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_pinFocusNode);
    });

    // Add listeners to update state when PIN fields change
    _pinController.addListener(_onPinChanged);
    _confirmPinController.addListener(_onConfirmPinChanged);
  }

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    _pinFocusNode.dispose();
    _confirmPinFocusNode.dispose();
    super.dispose();
  }

  bool get isButtonEnabled {
    return _pinController.text.length == 4 &&
        _confirmPinController.text.length == 4 &&
        _pinsMatch;
  }

  Future<bool> _onWillPop() async {
    final shouldExit =
        await DialogsAndPrompts.showExitConfirmationDialog(context);
    if (shouldExit != null && shouldExit) {
      await _logoutAndNavigateToLogin();
    }
    return false;
  }

  void _onSubmit() {
    if (isButtonEnabled) {
      try {
        _pinCreationController.savePin(_pinController.text).then((_) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const DashboardPage()),
            (Route<dynamic> route) => false, // Removes all previous routes
          );
        });
      } catch (e) {
        DialogsAndPrompts.showErrorDialog('Failed to save PIN.', context);
      }
    } else {
      // This else block can be optional since the button is disabled when conditions aren't met
      DialogsAndPrompts.showErrorDialog(
          'Please enter a valid 4-digit PIN in both fields and ensure they match.', context);
    }
  }

  Future<void> _logoutAndNavigateToLogin() async {
    try {
      await _loginProvider.logout(context);
    } catch (e) {
      DialogsAndPrompts.showErrorDialog('Failed to logout.', context);
    }
  }

  void _togglePinVisibility() {
    setState(() {
      _pinVisible = !_pinVisible;
    });
  }

  void _toggleConfirmPinVisibility() {
    setState(() {
      _confirmPinVisible = !_confirmPinVisible;
    });
  }

  void _onPinChanged() {
    setState(() {
      _pinsMatch = _pinController.text.isNotEmpty &&
          _confirmPinController.text.isNotEmpty &&
          _pinController.text == _confirmPinController.text;
    });
  }

  void _onConfirmPinChanged() {
    setState(() {
      _pinsMatch = _pinController.text.isNotEmpty &&
          _confirmPinController.text.isNotEmpty &&
          _pinController.text == _confirmPinController.text;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final topPadding = MediaQuery.of(context).padding.top;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          child: Padding(
            padding:
                EdgeInsets.only(top: topPadding + 25, left: 20, right: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Text(
                    'Create Your\nNITRis PIN',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'To set up your PIN create a 4 digit code then confirm it below',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 50),
                PinInputField(
                  label: 'ENTER YOUR PIN',
                  controller: _pinController,
                  focusNode: _pinFocusNode,
                  pinVisible: _pinVisible,
                  toggleVisibility: _togglePinVisibility,
                  onChanged: (value) {}, // Handled by listener
                ),
                const SizedBox(height: 20),
                PinInputField(
                  label: 'CONFIRM YOUR PIN',
                  controller: _confirmPinController,
                  focusNode: _confirmPinFocusNode,
                  pinVisible: _confirmPinVisible,
                  toggleVisibility: _toggleConfirmPinVisibility,
                  onChanged: (value) {}, // Handled by listener
                ),
                if (_pinsMatch)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                        Icon(Icons.check_circle,
                          color: Color.fromARGB(255, 32, 111, 38)),
                        SizedBox(width: 8),
                        Flexible(
                          child: Text(
                          'Your PINs match successfully!',
                          style: TextStyle(
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                          softWrap: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 30),
                SizedBox(
                  width: 170,
                  height: 60,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isButtonEnabled
                          ? AppColors.primaryColor
                          : AppColors.primaryColor.withOpacity(0.5), // Dimmed color when disabled
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 18),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                      elevation: isButtonEnabled ? 5 : 0, // Remove elevation when disabled
                      shadowColor:
                          isButtonEnabled ? Colors.black54 : Colors.transparent,
                    ),
                    onPressed: isButtonEnabled ? _onSubmit : null, // Disable button if conditions aren't met
                    child: const Text(
                      'CONTINUE',
                      style: TextStyle(fontSize: 13, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
