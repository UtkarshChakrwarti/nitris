// App related constants
class AppConstants {
  
  // Security key for encryption and OTP generation
  static const String securityKey ="opSlTMEmocl0W9hbRv9n"; // Key for encryption

  //Current App version
  static const String currentAppVersion = '2.0.3';

  // Play Store URL
  static const String appStoreUrl = 'https://apps.apple.com/us/app/nitris/id6739775147';

  // API URLs and other constants
  static const String baseUrl =
      'https://api.nitrkl.ac.in/HelloNITR';

  static const String baseUrlPresentsir =
      'https://api.nitrkl.ac.in/Presentsir';

  static const String catUrl =
      'https://www.nitrkl.ac.in/CAT/';

  static const String biometric = 
      "https://api.nitrkl.ac.in/Biometric";

  // Database constants
  static const String dbName = 'app.db';
  static const String userTable = 'users';

  // Session keys
  static const String pinKey = 'pin_key'; // Key for user PIN encryption
  static const String currentLoggedInUserKey =
      'current_user_key'; // Key for encryption

  // OTP timeout in seconds
  static const int otpTimeOutSeconds = 60;

  static const int pageSize = 30;
}
