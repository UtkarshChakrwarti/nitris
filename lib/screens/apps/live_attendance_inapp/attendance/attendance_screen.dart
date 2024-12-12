import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:nitris/core/constants/app_colors.dart';
import 'package:nitris/core/models/student.dart';
import 'package:nitris/core/models/subject.dart';
import 'package:nitris/core/services/remote/api_service.dart';
import 'package:nitris/core/utils/dialogs_and_prompts.dart';
import 'package:nitris/screens/apps/live_attendance_inapp/attendance/widgets/attendance_header.dart';
import 'package:nitris/screens/apps/live_attendance_inapp/attendance/widgets/floating_submit_button.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:nitris/screens/apps/live_attendance_inapp/attendance/widgets/student_tile.dart';

class AttendancePage extends StatefulWidget {
  final int date;
  final int month;
  final Subject subject;
  final String semester;
  final String academicYear;
  final int classNumber;
  final int sectionId;

  const AttendancePage({
    Key? key,
    required this.date,
    required this.month,
    required this.subject,
    required this.semester,
    required this.academicYear,
    required this.classNumber,
    required this.sectionId,
  }) : super(key: key);

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  // Services and Logging
  final ApiService _apiService = ApiService();
  final Logger _logger = Logger('AttendancePage');

  // State Variables
  List<Student> students = [];
  bool _isSelectAll = false;
  bool _isAttendanceSaved = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  /// Helper method to convert month number to three-letter abbreviation
  String _getMonthAbbreviation(int month) {
    const List<String> monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];

    if (month < 1 || month > 12) {
      return 'Invalid';
    }
    return monthNames[month - 1];
  }

  /// Fetch students from the API
  Future<void> _fetchStudents() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final fetchedStudents = await _apiService.getStudents(widget.sectionId);
      setState(() {
        students = fetchedStudents;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      _logger.severe('Error fetching students: $e', e, stackTrace);
      setState(() {
        _isLoading = false;
      });
      DialogsAndPrompts.showFailureDialog(
        context,
        'Failed to load students: $e',
      );
    }
  }

  /// Check if all students have been marked (present or absent)
  bool get _isAllMarked =>
      students.isNotEmpty &&
      students.every((student) => student.status != AttendanceStatus.notMarked);

  /// Handle back navigation with unsaved attendance check
  Future<bool> _handleBackNavigation() async {
    if (!_isAttendanceSaved && _isAnyAttendanceMarked()) {
      final shouldPop =
          await DialogsAndPrompts.showUnsavedAttendanceDialog(context) ?? false;
      return shouldPop;
    }
    return true;
  }

  /// Check if any student's attendance has been marked
  bool _isAnyAttendanceMarked() {
    return students
        .any((student) => student.status != AttendanceStatus.notMarked);
  }

  /// Clear all attendance selections after user confirmation
  Future<void> _clearAllSelections() async {
    final confirm =
        await DialogsAndPrompts.showConfirmClearAllDialog(context) ?? false;
    if (confirm) {
      setState(() {
        for (var student in students) {
          student.status = AttendanceStatus.notMarked;
        }
        _isSelectAll = false;
        _isAttendanceSaved = false;
      });
    }
  }

  /// Submit attendance to the API
  Future<void> _handleSubmitAttendance() async {
    try {
      // Prepare attendance records in the exact format needed
      final attendanceRecords = students
          .map((student) => {
                'attendanceId': student.attendanceId,
                'id': student.id,
                'status':
                    student.status == AttendanceStatus.present ? 'G' : 'R',
              })
          .toList();

      // Create the payload matching the exact JSON structure
      final Map<String, dynamic> payload = {
        'classNumber': widget.classNumber,
        'date': widget.date,
        'year': widget.academicYear.split('-')[0],
        'month': _getMonthAbbreviation(widget.month), // Convert to month name
        'sectionId': widget.sectionId,
        'attendance': attendanceRecords,
      };

      // Log the payload for debugging
      _logger.info('Saving attendance payload: $payload');

      // Submit the attendance
      await _apiService.submitAttendance(payload);

      // Show success dialog
      final success = await DialogsAndPrompts.showSuccessDialog(
        context,
        'Attendance saved successfully. You can modify the attendance in NITRis web portal next month.',
      );

      if (success == true) {
        // go to the home screen via route and clear the stack
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/attendanceHome', (route) => false);
      }

      setState(() {
        _isAttendanceSaved = true;
      });
    } catch (e, stackTrace) {
      _logger.severe('Error submitting attendance: $e', e, stackTrace);
      DialogsAndPrompts.showFailureDialog(
        context,
        'Failed to save attendance: $e',
      );
    }
  }

  /// Handle submit button press with confirmation
  Future<void> _handleSubmitButtonPressed() async {
    final confirm =
        await DialogsAndPrompts.showConfirmSubmissionDialog(context) ?? false;
    if (confirm) {
      await _handleSubmitAttendance();
    }
  }

  /// Handle select all checkbox change with confirmation
  Future<void> _handleSelectAll(bool value) async {
    final confirm =
        await DialogsAndPrompts.showConfirmSelectAllDialog(context) ?? false;
    if (confirm) {
      setState(() {
        _isSelectAll = value;
        for (var student in students) {
          student.status =
              value ? AttendanceStatus.present : AttendanceStatus.notMarked;
        }
        _isAttendanceSaved = false;
      });
    }
  }

  /// Update individual student's attendance status
  void _updateStudentStatus(int index, AttendanceStatus status) {
    setState(() {
      students[index].status = status;
      _isAttendanceSaved = false;

      // Update _isSelectAll based on current attendance statuses
      _isSelectAll = students
          .every((student) => student.status == AttendanceStatus.present);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Count attendance statuses
    final presentCount = students
        .where((student) => student.status == AttendanceStatus.present)
        .length;
    final absentCount = students
        .where((student) => student.status == AttendanceStatus.absent)
        .length;
    final unmarkedCount = students
        .where((student) => student.status == AttendanceStatus.notMarked)
        .length;

    return WillPopScope(
      onWillPop: _handleBackNavigation,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.primaryColor,
          elevation: 0,
          centerTitle: true,
          title: Text(
            '${widget.subject.subjectCode} - ${widget.subject.subjectName}',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () async {
              final shouldPop = await _handleBackNavigation();
              if (shouldPop) {
                Navigator.of(context).pop();
              }
            },
          ),
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : Column(
                children: [
                  // Display semester, academic year, class number, and formatted date
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: AppColors.primaryColor,
                    child: Center(
                      child: Text(
                        '${widget.semester} ${widget.academicYear} | '
                        '${widget.date}-${_getMonthAbbreviation(widget.month)}-'
                        '${widget.academicYear.split('-').first} | '
                        'Class ${widget.classNumber}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  // Attendance Header with counts and select all option
                  AttendanceHeader(
                    presentCount: presentCount,
                    absentCount: absentCount,
                    unmarkedCount: unmarkedCount,
                    totalStudents: students.length,
                    isSelectAll: _isSelectAll,
                    onSelectAllChanged: _handleSelectAll,
                    onClear: _clearAllSelections,
                  ),
                  // List of students with animation
                  Expanded(
                    child: Stack(
                      children: [
                        Positioned.fill(
                          top: 0,
                          bottom: 80, // Space for the submit button
                          child: AnimationLimiter(
                            child: ListView.builder(
                              padding: const EdgeInsets.only(bottom: 80),
                              itemCount: students.length,
                              itemBuilder: (context, index) {
                                final student = students[index];
                                return AnimationConfiguration.staggeredList(
                                  position: index,
                                  duration: const Duration(milliseconds: 300),
                                  child: SlideAnimation(
                                    verticalOffset: 50.0,
                                    child: FadeInAnimation(
                                      child: StudentTile(
                                        index: index +
                                            1, // 1-based indexing for display
                                        student: student,
                                        isSmallDevice: true,
                                        onMarkPresent: () =>
                                            _updateStudentStatus(index,
                                                AttendanceStatus.present),
                                        onMarkAbsent: () =>
                                            _updateStudentStatus(
                                                index, AttendanceStatus.absent),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        // Floating submit button
                        Positioned(
                          bottom: 16,
                          left: 16,
                          right: 16,
                          child: FloatingSubmitButton(
                            isAllMarked: _isAllMarked,
                            isSmallDevice: true,
                            onPressed: _handleSubmitButtonPressed,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
