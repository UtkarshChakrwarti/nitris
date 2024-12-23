import 'package:flutter/material.dart';
import 'package:nitris/controllers/login_controller.dart';

class LoginProvider with ChangeNotifier {
  final LoginController _loginController = LoginController();
  bool isLoading = false;
  bool isAuthenticated = false;
  bool isFreshLoginAttempt = false;
  bool isAllowedToLogin = false;
  bool invalidUserNameOrPassword = false;
  bool expiredSession = false;
  bool isMockUser = false;

  Future<bool> login(
      String userId, String password, BuildContext context) async {
    isLoading = true;
    notifyListeners();

    bool result = await _loginController.login(userId, password, context);

    isLoading = false;
    isAuthenticated = result;
    notifyListeners();

    return result;
  }

  Future<void> logout(BuildContext context) async {
    await _loginController.logout(context);
    isAuthenticated = false;
    notifyListeners();
  }

  // Method to set isFreshLoginAttempt
  void setFreshLoginAttempt(bool value) {
    isFreshLoginAttempt = value;
    notifyListeners();
  }

  // Method to set isAllowedToLogin
  void setAllowedToLogin(bool value) {
    isAllowedToLogin = value;
    notifyListeners();
  }

  // Method to set invalidUserNameOrPassword
  void setInvalidUserNameOrPassword(bool value) {
    invalidUserNameOrPassword = value;
    notifyListeners();
  }

  // Method to set expiredSession
  void setExpiredSession(bool value) {
    expiredSession = value;
    notifyListeners();
  }

  // Method to set isMockUser
  void setMockUser(bool value) {
    isMockUser = value;
    notifyListeners();
  }
}
