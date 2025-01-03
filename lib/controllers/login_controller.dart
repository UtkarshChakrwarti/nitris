import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:nitris/core/models/login.dart';
import 'package:nitris/core/provider/login_provider.dart';
import 'package:nitris/core/services/local/local_storage_service.dart';
import 'package:nitris/core/services/remote/api_service.dart';
import 'package:nitris/core/utils/device_id.dart';
import 'package:nitris/core/utils/encryption_functions.dart';
import 'package:nitris/screens/sim/sim_selection_screen.dart';
import 'package:provider/provider.dart';

class LoginController {
  final ApiService _apiService = ApiService();
  final Logger _logger = Logger('LoginController');

  Future<bool> login(
    String userId,
    String password,
    BuildContext context,
  ) async {
    try {
      // Get the LoginProvider instance
      final loginProvider = Provider.of<LoginProvider>(context, listen: false);

      // Check if the user is a mock user
      if (userId == "1000000") {
        loginProvider.setMockUser(true);
        _logger.info('Mock user detected: isMockUser set to true');
      } else {
        loginProvider.setMockUser(false);
        _logger.info('Regular user detected: isMockUser set to false');
      }

      String encryptedPassword = EncryptionFunction().encryptPassword(password);
      LoginResponse response =
          await _apiService.login(userId, encryptedPassword);

      if (response.loginSuccess) {
        await LocalStorageService.saveLoginResponse(response);

        // Fetch the user details from the saved session
        LoginResponse? currentUser =
            await LocalStorageService.getLoginResponse();
        _logger.info(
          '''User logged in (Fetched From saved logged In info from secured storage):
             ${currentUser!.firstName} ${currentUser.lastName}''',
        );

        if (response.loggedIn == true) {
          // User Already Logged In somewhere else so check if this is the same device or not

          final String udid = await DeviceUtil().getDeviceID();
          if (udid != response.deviceIMEI) {
            // Different device
            loginProvider.setAllowedToLogin(false);
            loginProvider.setInvalidUserNameOrPassword(false);
            _logger.warning(
              'User logged in from a different device thus not allowed to login from this device.',
            );
            _logger.warning(
              'Device IMEI: $udid, Device IMEI from API: ${response.deviceIMEI}',
            );
            _logger.info(
                'Is Allowed to login : ${loginProvider.isAllowedToLogin}');
            return false;
          }

          // Same device
          loginProvider.setAllowedToLogin(true);
          loginProvider.setInvalidUserNameOrPassword(false);
          loginProvider.setFreshLoginAttempt(false);
          _logger.info(
            'User logged in from the same device thus allowed to login from this device.',
          );
          _logger
              .info('Is Allowed to login : ${loginProvider.isAllowedToLogin}');
          return true;
        }

        loginProvider.setFreshLoginAttempt(true);
        loginProvider.setAllowedToLogin(true);
        loginProvider.setInvalidUserNameOrPassword(false);
        _logger.info(
            'Is Fresh Login Attempt : ${loginProvider.isFreshLoginAttempt}');
        _logger.info('Is Allowed to login : ${loginProvider.isAllowedToLogin}');
        _logger.info('User logged in');

        return true;
      } else {
        loginProvider.setInvalidUserNameOrPassword(true);
        _logger.warning('Login failed: ${response.message}');
        return false;
      }
    } catch (e, stacktrace) {
      _logger.severe("Login failed", e, stacktrace);
      return false;
    }
  }

  Future<void> logout(BuildContext context) async {
    try {
      await LocalStorageService.logout();
      _logger.info('User logged out');
      Navigator.of(context).maybePop();
      Navigator.pushNamedAndRemoveUntil(context, "/login", (route) => false);
    } catch (e, stacktrace) {
      _logger.severe("Logout failed", e, stacktrace);
    }
  }

  void showSimSelectionModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return const SimSelectionScreen();
      },
    );
  }
}
