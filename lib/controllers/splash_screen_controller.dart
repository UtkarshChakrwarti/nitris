import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:nitris/core/models/login.dart';
import 'package:nitris/core/services/local/local_storage_service.dart';
import 'package:nitris/core/services/remote/api_service.dart';

class SplashScreenController {
  final Logger _logger = Logger('SplashScreen');

  Future<String?> checkLoginStatus(BuildContext context) async {

    try {
      bool isLoggedIn = await LocalStorageService.checkIfUserIsLoggedIn();
      String? storedPin = await LocalStorageService.getPin();

      _logger.info('Login status: $isLoggedIn');
      _logger.info('Stored PIN: $storedPin');

      LoginResponse? loginResponse = await LocalStorageService.getLoginResponse();
      _logger.info('User Name: ${loginResponse?.firstName}');

      if (isLoggedIn) {
        try {
          bool isValid = await ApiService().validateUser(loginResponse?.empCode);
          _logger.info('User is valid: $isValid');
          if (!isValid) {
            await LocalStorageService.logout();
            _logger.info('User logged out because the user is not valid anymore.');
            return '/login';
          }
        } catch (e) {
          _logger.severe('Unable to check User Status : Connectivity issues');
        }
        if (storedPin != null) {
          _logger.info('User is still valid, Redirecting to PIN unlock screen.');
          return '/pinUnlock';
        } else {
          await LocalStorageService.logout();
          _logger.info('User is still valid or currently app offline but User\'s Pin is not set, Redirecting to login screen.');
          return '/login';
        }
      } else {
        _logger.info('User is not logged in. Redirecting to login screen.');
        return '/login';
      }
    } on PlatformException catch (e) {
      _logger.severe('PlatformException occurred: $e');
      return null;
    } catch (e) {
      _logger.severe('An error occurred: $e');
      return null;
    }
  }
}