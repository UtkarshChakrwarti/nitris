import 'package:flutter/material.dart';
import 'package:nitris/core/exception/custom_error.dart';
import 'package:nitris/screens/apps/biometric_student_inapp/student_biometric_attendance_page.dart';
import 'package:nitris/screens/apps/hello_nitr_inapp/contacts/update/contacts_update_screen.dart';
import 'package:nitris/screens/apps/hello_nitr_inapp/main_screen/home_screen.dart';
import 'package:nitris/screens/apps/live_attendance_inapp/live_attendance_home/attendance_home_screen.dart';
import 'package:nitris/screens/apps/placeholder_pages/biometric_placeholder.dart';
import 'package:nitris/screens/apps/placeholder_pages/file-tracking.dart';
import 'package:nitris/screens/apps/students_live_attendance_inapp/student_attendance_home_screen.dart';
import 'package:nitris/screens/launch_screen/dashboard.dart';
import 'package:nitris/screens/login/login_screen.dart';
import 'package:nitris/screens/otp/otp_verification_screen.dart';
import 'package:nitris/screens/pin/create/pin_creation_screen.dart';
import 'package:nitris/screens/pin/verify/pin_unlock_screen.dart';
import 'package:nitris/screens/privacy_policy/privacy_policy_screen.dart';
import 'package:nitris/screens/sim/sim_selection_screen.dart';
import 'package:nitris/screens/splash/splash_screen.dart';

final Map<String, WidgetBuilder> appRoutes = {
  // Splash Screen
  '/': (_) => const SplashScreen(),

  // Privacy Policy Screen
  '/privacyPolicy': (_) => const PrivacyPolicyScreen(),

  //Login Screen
  '/login': (context) => const LoginScreen(),

  //Sim Selection Screen
  '/simSelection': (context) => const SimSelectionScreen(),

  //OTP Verification Screen
  '/otp': (context) => const OtpVerificationScreen(mobileNumber: ''),

  //Pin Creation Screen
  '/pinCreation': (context) => const PinCreationScreen(),

  //Pin Unlock Screen
  '/pinUnlock': (context) => const PinUnlockScreen(),

  //Dashboard Screen
  '/home': (context) => const DashboardPage(),

  // Attendance Home Screen
  '/attendanceHome': (context) => const AttendanceHomeScreen(),

  // Contacts Update Screen
  '/contactsUpdate': (context) => const ContactsUpdateScreen(),

  // Hello NITR Home Screen
  '/helloNITRHome': (context) => const HelloNITRHomeScreen(),

  // students Attendance Screen
  '/studentAttendance': (context) => const StudentAttendanceHomeScreen(),

  // Biometric Attendance Screen Student
  '/biometricAttendanceStudent': (context) => const StudentAttendancePageBiometric(),

  //Biometric placeholder page
  '/biometricPlaceholder': (context) => const NoAccessBiometricAttendance(),

  //File tracking placeholder page
  '/fileTrackingPlaceholder': (context) => const FileTrackingInDevelopment(),


  //Custom error page
  '/error': (context) => CustomError(
        key: null,
        errorDetails: FlutterErrorDetails(
          exception: Exception('Dummy Exception'),
          stack: StackTrace.fromString('Dummy Stack Trace'),
        ),
      ),
};
