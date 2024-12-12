// lib/controllers/home_controller.dart
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:nitris/core/models/faculty.dart';
import 'package:nitris/core/models/subject_response.dart';
import 'package:nitris/core/provider/login_provider.dart';
import 'package:nitris/core/services/local/local_storage_service.dart';
import 'package:nitris/core/services/remote/api_service.dart';

class AttendanceHomeController extends ChangeNotifier {
  final Logger _logger = Logger();

  final LoginProvider _loginProvider = LoginProvider();
  Faculty? _user;
  bool _isLoading = false;
  String? _attendanceDate;
  String? _errorMessage;

  AttendanceHomeController() {
    _logger.i("HomeController initialized");
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    _logger.i("Initializing user data");

    try {
      // Fetch the current logged-in user's details from local storage
      final currentLoggedInUser = await LocalStorageService.getLoginResponse();

      if (currentLoggedInUser == null) {
        throw Exception("No user is currently logged in.");
      }

      _logger
          .i("Fetched current logged-in user: ${currentLoggedInUser.empCode}");

      // Fetch subjects for the user
      final apiService = ApiService();
      final SubjectResponse fetchedSubjectForUser =
          await apiService.getSubjectsResponse(currentLoggedInUser.empCode!);

      _logger.i("Fetched subjects: Status - ${fetchedSubjectForUser.status}");

      if (fetchedSubjectForUser.status.toLowerCase() != "success") {
        throw Exception(
            "Failed to fetch subjects: ${fetchedSubjectForUser.status}");
      }

      // set the attendance date in the controller
      _attendanceDate = fetchedSubjectForUser.attendancedate;

      // Parse subjects
      final subjects = fetchedSubjectForUser.subjects;

      if (subjects.isEmpty) {
        _logger.w("No subjects found for user: ${currentLoggedInUser.empCode}");
      }

      // Extract semester and academicYear from the first subject
      final firstSubject = subjects.isNotEmpty ? subjects.first : null;
      final semester =
          firstSubject?.session ?? "N/A"; // Default if not available
      final academicYear = firstSubject?.academicYear ?? "N/A";

      // Initialize User object
      _user = Faculty(
        name: [
          currentLoggedInUser.firstName,
          if (currentLoggedInUser.middleName != null &&
              currentLoggedInUser.middleName!.isNotEmpty)
            currentLoggedInUser.middleName!,
          currentLoggedInUser.lastName
        ].join(" "),
        avatarUrl: currentLoggedInUser.photo ?? '',
        semester: semester,
        academicYear: academicYear,
        subjects: subjects,
        totalSubjects: fetchedSubjectForUser.totalSubjects,
      );

      _logger.i("User data initialized successfully: ${_user!.name}");
    } catch (e, stackTrace) {
      _logger.e("Error initializing user data: $e",
          error: e, stackTrace: stackTrace);
      _errorMessage = e.toString();
      _user = null;
    } finally {
      _isLoading = false;
      notifyListeners();
      _logger.i("User data initialization completed");
    }
  }

  Faculty? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String? get attendanceDate => _attendanceDate;

  Future<void> refreshData() async {
    _logger.i("Refreshing user data");
    await _initializeUser();
  }

  void logout(BuildContext context) {
    try {
      _loginProvider.logout(context);
      _logger.i('User logged out successfully');
    } catch (e) {
      _logger.e("Logout failed: $e");
    }
  }
}
