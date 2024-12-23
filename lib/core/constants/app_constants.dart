// App related constants
class AppConstants {
  
  // Security key for encryption and OTP generation
  static const String securityKey ="opSlTMEmocl0W9hbRv9n"; // Key for encryption

  //Current App version
  static const String currentAppVersion = '1.0.0';

  // Play Store URL
  static const String playStoreUrl = '';

  // API URLs and other constants
  static const String baseUrl =
      'https://arogyakavach.nitrkl.ac.in/WebApi/HelloNITR';

  static const String baseUrlPresentsir =
      'https://arogyakavach.nitrkl.ac.in/WebAPI/Presentsir';

  static const String catUrl =
      'https://www.nitrkl.ac.in/CAT/';

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
