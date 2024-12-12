import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:nitris/core/provider/login_provider.dart';

class DashboardController {
  final LoginProvider _loginProvider = LoginProvider();
  final Logger _logger = Logger('DashboardController');
  
  void logout(BuildContext context) {
    try {
      _loginProvider.logout(context);
      _logger.info('User logged out successfully');
    } catch (e) {
      _logger.severe("Logout failed: $e");
    }
  }
}