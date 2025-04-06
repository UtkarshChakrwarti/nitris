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
import 'package:nitris/screens/apps/students_live_attendance_inapp/widgets/view_attendance_page.dart';

class StudentAttendanceHomeScreen extends StatefulWidget {
  const StudentAttendanceHomeScreen({Key? key}) : super(key: key);

  @override
  State<StudentAttendanceHomeScreen> createState() =>
      _StudentAttendanceHomeScreenState();
}

class _StudentAttendanceHomeScreenState
    extends State<StudentAttendanceHomeScreen> {
  LoginResponse? _loginResponse;
  List<Subject> _subjects = [];
  bool _isDataLoading = false;
  int? _loadingSubjectIndex;

  @override
  void initState() {
    super.initState();
    _loadData();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: AppColors.primaryColor,
      statusBarIconBrightness: Brightness.light,
    ));
  }

  Future<void> _loadData() async {
    setState(() => _isDataLoading = true);
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
      setState(() => _isDataLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: AppColors.primaryColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  Future<void> _handleSubjectTap(Subject subject, int index) async {
    setState(() => _loadingSubjectIndex = index);

    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        final requested = await Geolocator.requestPermission();
        if (requested == LocationPermission.denied || requested == LocationPermission.deniedForever) {
          _showErrorSnackBar("Location permission is required to mark attendance.");
          return;
        }
      }

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showErrorSnackBar("Please enable location services to mark attendance.");
        return;
      }

      final apiService = ApiService();
      final sessionResponse = await apiService.checkSessionStatus(subject.sectionId);

      if (sessionResponse["status"] != "ACTIVE" || sessionResponse["location"] == null) {
        _showErrorSnackBar(
            "Faculty has not started taking attendance yet. Please wait until faculty starts taking attendance.");
        return;
      }

      final currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final sessionLocation = sessionResponse["location"]!.split('|');
      if (sessionLocation.length < 2) {
        throw Exception("Invalid session location data.");
      }

      final sessionLat = double.parse(sessionLocation[0]);
      final sessionLng = double.parse(sessionLocation[1]);
      final distance = Geolocator.distanceBetween(
        currentPosition.latitude,
        currentPosition.longitude,
        sessionLat,
        sessionLng,
      );

      print("Distance from classroom: ${distance.toStringAsFixed(2)} meters");

      if (distance <= 100) {
        final attendanceDate = DateTime.now().toIso8601String();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StudentSubjectQrScreen(
              subject: subject,
              attendanceDate: attendanceDate,
              currentPosition: currentPosition,
            ),
          ),
        );
      } else {
        _showErrorSnackBar(
            "Attendance QR generation not allowed: Please ensure you are within the designated classroom location.");
      }
    } catch (error) {
      _showErrorSnackBar(error.toString());
    } finally {
      setState(() => _loadingSubjectIndex = null);
    }
  }

  PreferredSizeWidget _buildCustomAppBar() {
    // Get screen width to make responsive decisions
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360; // Threshold for small screens

    return AppBar(
      backgroundColor: AppColors.primaryColor,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        padding: EdgeInsets.zero,
        onPressed: () => Navigator.pop(context),
      ),
      titleSpacing: 0,
      title: Text(
        'My Attendance',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: isSmallScreen ? 18 : 20,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: _loadData,
          tooltip: 'Update',
        ),
        IconButton(
          icon: Image.asset(
                      'assets/images/cal.png',
                      width: 40,
                      height: 40,
                    ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AttendancePage()),
            );
          },
          tooltip: 'View Attendance',
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: _loginResponse != null
              ? StudentProfileWidget(student: _loginResponse!)
              : const SizedBox.shrink(),
        ),
      ),
    );
  }

  Widget _buildSubjectsList() {
    final subjectsWithLectures = _subjects;
    if (subjectsWithLectures.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning_rounded, size: 60, color: AppColors.lightRed),
            const SizedBox(height: 16),
            Text(
              'No subjects available',
              style: TextStyle(
                  color: AppColors.textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w500),
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
              onTap: () => _handleSubjectTap(subject, index),
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              overlayColor:
                  MaterialStateProperty.all(Colors.grey.withOpacity(0.1)),
              child: StudentSubjectsCardWidget(
                subject: subject,
                attendanceDate: attendanceDate,
                index: index,
                isLoading: _loadingSubjectIndex == index,
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
      body: _isDataLoading
          ? Center(
              child: CircularProgressIndicator(color: AppColors.primaryColor))
          : _buildSubjectsList(),
    );
  }
}
