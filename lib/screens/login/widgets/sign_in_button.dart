import 'package:flutter/material.dart';
import 'package:nitris/controllers/login_controller.dart';
import 'package:nitris/core/constants/app_colors.dart';
import 'package:nitris/core/utils/dialogs_and_prompts.dart';
import 'package:nitris/core/provider/login_provider.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart'; // Add this import

class SignInButton extends StatelessWidget {
  final AnimationController animationController;
  final Animation<double> buttonScaleAnimation;
  final bool allFieldsFilled;
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final FocusNode usernameFocusNode;
  final FocusNode passwordFocusNode;

  const SignInButton({
    super.key, 
    required this.animationController,
    required this.buttonScaleAnimation,
    required this.allFieldsFilled,
    required this.usernameController,
    required this.passwordController,
    required this.usernameFocusNode,
    required this.passwordFocusNode,
  });

  Future<bool> checkInternetConnection() async {
    final connectivityResult = await (Connectivity().checkConnectivity());
    return connectivityResult != ConnectivityResult.none;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => animationController.forward(),
      onTapUp: (_) => animationController.reverse(),
      child: AnimatedBuilder(
        animation: animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: buttonScaleAnimation.value,
            child: ElevatedButton(
              onPressed: allFieldsFilled
                  ? () async {
                      final loginProvider = context.read<LoginProvider>();
                      try {
                        // Check internet connection first
                        final hasInternet = await checkInternetConnection();
                        if (!hasInternet) {
                          DialogsAndPrompts.showErrorDialog(
                              'No internet connection. Please check your network and try again.',
                              context);
                          return;
                        }

                        animationController.forward();
                        final isSuccess = await loginProvider.login(
                            usernameController.text,
                            passwordController.text,
                            context);
                        if (!isSuccess) {
                          if (!loginProvider.isAllowedToLogin &&
                              !loginProvider.invalidUserNameOrPassword) {
                            // Only show login from different device dialog if we have internet
                            if (await checkInternetConnection()) {
                              DialogsAndPrompts
                                  .showLoginFromDifferentDeviceDialog(context);
                            } else {
                              DialogsAndPrompts.showErrorDialog(
                                  'No internet connection. Please check your network and try again.',
                                  context);
                            }
                          } else {
                            DialogsAndPrompts.showErrorDialog(
                                'Invalid username or password', context);
                          }
                        } else {
                          usernameFocusNode.unfocus();
                          passwordFocusNode.unfocus();
                          LoginController().showSimSelectionModal(context);
                        }
                      } catch (e, stacktrace) {
                        debugPrint('Login error: $e\n$stacktrace');
                        // Check if the error is due to network connectivity
                        final hasInternet = await checkInternetConnection();
                        if (!hasInternet) {
                          DialogsAndPrompts.showErrorDialog(
                              'No internet connection. Please check your network and try again.',
                              context);
                        } else {
                          DialogsAndPrompts.showErrorDialog(
                              'An error occurred. Please try again.', context);
                        }
                      } finally {
                        animationController.reverse();
                      }
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: allFieldsFilled
                    ? AppColors.primaryColor
                    : AppColors.lightSecondaryColor,
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
                elevation: 5,
                shadowColor: Colors.black54,
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 150),
                child: context.watch<LoginProvider>().isLoading
                    ? const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        key: ValueKey('loading'))
                    : const Text("SIGN IN",
                        style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontFamily: 'Roboto'),
                        key: ValueKey('text')),
              ),
            ),
          );
        },
      ),
    );
  }
}