import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nitris/core/constants/app_colors.dart';
import 'package:nitris/core/models/login.dart';
import 'package:nitris/core/models/subject.dart';
import 'package:nitris/core/services/local/local_storage_service.dart';
import 'package:nitris/core/services/remote/api_service.dart';
import 'package:nitris/screens/apps/students_live_attendance_inapp/widgets/student_profile_widget.dart';
import 'package:nitris/screens/apps/students_live_attendance_inapp/widgets/student_subject_card_widget.dart';

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

    // Set status bar color to match AppBar
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

  PreferredSizeWidget _buildCustomAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(180), // Adjust height as needed
      child: Container(
        color: AppColors.primaryColor,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button and title row
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
                            color: Colors.white
                          ),
                        ),
                      ),
                    ),
                    // Add extra space for symmetry if needed
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              // Header content
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
                          icon: Icon(Icons.refresh, size: 16, color: AppColors.primaryColor),
                          label: Text(
                            'Refresh',
                            style: TextStyle(
                              color: AppColors.primaryColor,
                              fontSize: 13,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
    if (_subjects.isEmpty) {
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
        itemCount: _subjects.length,
        itemBuilder: (context, index) {
          final subject = _subjects[index];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: StudentSubjectsCardWidget(
              subject: subject,
              attendanceDate: attendanceDate,
              index: index,
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