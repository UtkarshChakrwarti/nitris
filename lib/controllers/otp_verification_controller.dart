import 'dart:async';
import 'package:flutter/material.dart';
import 'package:nitris/core/constants/app_constants.dart';
import 'package:nitris/core/models/login.dart';
import 'package:nitris/core/provider/login_provider.dart';

import 'package:nitris/core/services/local/local_storage_service.dart';
import 'package:nitris/core/services/remote/api_service.dart';
import 'package:nitris/core/utils/device_id.dart';

import 'package:logging/logging.dart';
import 'package:otp/otp.dart';
import 'package:provider/provider.dart';

class OtpVerificationController {
  final Logger _logger = Logger('OtpVerificationController');
  final ApiService _apiService = ApiService();
  String generatedOtp = '';
  DateTime otpGenerationTime = DateTime.now();

  /// Generates a time-based OTP TOTP valid for 10 minutes after generation.
  String _generateOtp() {
    final otp = OTP.generateTOTPCodeString(
      AppConstants.securityKey,
      DateTime.now().millisecondsSinceEpoch,
      interval: 60, // time interval in seconds for OTP generation
      length: 6,
      algorithm: Algorithm.SHA256,
    );
    otpGenerationTime = DateTime.now();
    _logger.info('Generated OTP: $otp');
    return otp;
  }

  // Sends the generated OTP to the specified mobile number.
  Future<void> sendOtp(String mobileNumber, BuildContext context) async {
    // Retrieve the LoginProvider from the context
    final loginProvider = Provider.of<LoginProvider>(context, listen: false);

    // Check if the user is a mock user and if the value of isMockUser then do not send the OTP
    if (loginProvider.isMockUser) {
      _logger.info('Use OTP 000000 for mock user');
      return;
    }
    try {
      generatedOtp = _generateOtp();
      await _apiService.sendOtp(mobileNumber, generatedOtp);
      _logger.info("OTP sent to $mobileNumber");
    } catch (e) {
      _logger.severe("Failed to send OTP: $e");
    }
  }

  // OTP verification with expiration check.
  Future<bool> verifyOtp(String enteredOtp, BuildContext context) async {
    // Retrieve the LoginProvider from the context
    final loginProvider = Provider.of<LoginProvider>(context, listen: false);

    // Check if the user is a mock user and if the value of isMockUser is true then return true
    if (loginProvider.isMockUser && enteredOtp == '000000') {
      _logger.info('Mock user verified successfully');
      return true;
    }

    final currentTime = DateTime.now();
    const otpValidityDuration =
        Duration(seconds: 600); // OTP valid for 10 minutes (600 seconds)
    if (currentTime.isBefore(otpGenerationTime.add(otpValidityDuration))) {
      if (enteredOtp == generatedOtp) {
        _logger.info('OTP verified successfully');
        return true;
      } else {
        _logger.warning('Invalid OTP entered');
        return false;
      }
    } else {
      _logger.warning('OTP expired');
      return false;
    }
  }

  // Logs out the user and navigates to the login screen.
  Future<void> logout(BuildContext context) async {
    final loginProvider = Provider.of<LoginProvider>(context, listen: false);

    try {
      await loginProvider.logout(context);
      _logger.info('User logged out successfully');
    } catch (e) {
      _logger.severe("Logout failed: $e");
    }
  }

  Future<void> updateDeviceId(BuildContext context) async {
    try {
      final String udid = await DeviceUtil().getDeviceID();
      LoginResponse? currentUser = await LocalStorageService.getLoginResponse();
      await _apiService.updateDeviceId(currentUser!.empCode, udid);
      _logger.info('Device ID updated successfully');
    } catch (e) {
      _logger.severe("Device ID update failed: $e");
    }
  }
}
