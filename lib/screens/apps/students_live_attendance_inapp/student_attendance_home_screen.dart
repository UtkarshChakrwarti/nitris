import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:nitris/core/constants/app_colors.dart';
import 'package:nitris/core/models/login.dart';
import 'package:nitris/core/models/subject.dart';
import 'package:nitris/core/services/local/local_storage_service.dart';
import 'package:nitris/core/services/remote/api_service.dart';
import 'package:nitris/screens/apps/students_live_attendance_inapp/widgets/student_profile_widget.dart';
import 'package:nitris/screens/apps/students_live_attendance_inapp/widgets/student_subject_card_widget.dart';
import 'package:nitris/screens/apps/students_live_attendance_inapp/widgets/student_subject_qr_screen.dart';


class StudentAttendanceHomeScreen extends StatefulWidget {
  const StudentAttendanceHomeScreen({Key? key}) : super(key: key);

  @override
  _StudentAttendanceHomeScreenState createState() =>
      _StudentAttendanceHomeScreenState();
}

class _StudentAttendanceHomeScreenState
    extends State<StudentAttendanceHomeScreen> {
  LoginResponse? _loginResponse;
  List<Subject> _subjects = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();

    // Set status bar color to match AppBar.
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: AppColors.primaryColor,
        statusBarIconBrightness: Brightness.light,
      ),
    );
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final loginResponse = await LocalStorageService.getLoginResponse();
      if (loginResponse == null || loginResponse.empCode == null) {
        throw Exception("Login details not found. Please log in again.");
      }
      final apiService = ApiService();
      final subjectResponse =
          await apiService.getStudentSubjects(loginResponse.empCode!);
      setState(() {
        _loginResponse = loginResponse;
        _subjects = subjectResponse.data;
      });
    } catch (e) {
      _showErrorSnackBar(e.toString());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.darkRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Future<void> _handleSubjectTap(Subject subject) async {
    setState(() {
      _isLoading = true;
    });
    try {
      final apiService = ApiService();
      // Call the API service method that returns status and location.
      final sessionResponse =
          await apiService.checkSessionStatus(subject.sectionId);
      if (sessionResponse["status"] != "ACTIVE") {
        _showErrorSnackBar(
            "Session hasn't started yet. Please wait until the class is active.");
      } else {
        // Get the student's current location.
        final currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        // "location" is provided as a pipe-separated string (e.g., "12.9593588|77.7085815").
        final sessionLocation = sessionResponse["location"];
        final latLng = sessionLocation.split('|');
        if (latLng.length < 2) {
          throw Exception("Invalid session location data.");
        }
        final double sessionLat = double.parse(latLng[0]);
        final double sessionLng = double.parse(latLng[1]);
        // Calculate the distance in meters between the student's current location and the session location.
        final distance = Geolocator.distanceBetween(
          currentPosition.latitude,
          currentPosition.longitude,
          sessionLat,
          sessionLng,
        );
        if (distance <= 100) {
          // Student is within range; navigate to QR generation page.
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StudentSubjectQrScreen(
                subject: subject,
                sessionResponse: sessionResponse,
              ),
            ),
          );
        } else {
          _showErrorSnackBar(
              "Session is active, but you must be within 100 meters of the classroom to generate your QR code. Please move closer and try again.");
        }
      }
    } catch (error) {
      _showErrorSnackBar(error.toString());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  PreferredSizeWidget _buildCustomAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(180), // Adjust height as needed.
      child: Container(
        color: AppColors.primaryColor,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button and title row.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Center(
                        child: Text(
                          'Student Attendance',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              // Header content.
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_loginResponse != null)
                      StudentProfileWidget(student: _loginResponse!),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Class Overview',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _loadData,
                          icon: Icon(Icons.update,
                              size: 16, color: AppColors.primaryColor),
                          label: Text(
                            'Update',
                            style: TextStyle(
                              color: AppColors.primaryColor,
                              fontSize: 13,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubjectsList() {
    // Filter subjects that have a non-zero lecture component in the LTP value.
    final subjectsWithLectures = _subjects.where((subject) {
      if (subject.ltp.isEmpty) return false;
      final parts = subject.ltp.split('-');
      if (parts.isEmpty) return false;
      final lectureCount = int.tryParse(parts[0]) ?? 0;
      return lectureCount != 0;
    }).toList();

    if (subjectsWithLectures.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.warning_rounded,
              size: 60,
              color: AppColors.lightRed,
            ),
            const SizedBox(height: 16),
            Text(
              'No subjects available',
              style: TextStyle(
                color: AppColors.textColor,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    final String attendanceDate = DateTime.now().toIso8601String();

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: subjectsWithLectures.length,
        itemBuilder: (context, index) {
          final subject = subjectsWithLectures[index];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: InkWell(
              onTap: () => _handleSubjectTap(subject),
              child: StudentSubjectsCardWidget(
                subject: subject,
                attendanceDate: attendanceDate,
                index: index,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildCustomAppBar(),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryColor,
              ),
            )
          : _buildSubjectsList(),
    );
  }
}
