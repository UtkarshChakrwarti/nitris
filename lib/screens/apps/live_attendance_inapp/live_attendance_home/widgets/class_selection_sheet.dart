import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Added for date formatting
import 'package:nitris/core/constants/app_colors.dart';
import 'package:nitris/core/models/subject.dart';
import 'package:nitris/screens/apps/live_attendance_inapp/attendance/attendance_screen.dart';

class ClassSelectionSheet extends StatelessWidget {
  final Subject subject;
  final String attendanceDate;

  const ClassSelectionSheet({
    required this.subject,
    required this.attendanceDate,
    Key? key,
  }) : super(key: key);

  /// Formats the date string from 'yyyy.MM.dd' to 'dd-MMM-yyyy'.
  String _formatDate(String dateStr) {
    try {
      final parts = dateStr.split('.');
      if (parts.length != 3) return dateStr;

      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final day = int.parse(parts[2]);

      final date = DateTime(year, month, day);
      return DateFormat('dd-MMM-yyyy').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    // Use the actual class number from the subject
    final classNumber = subject.totalClass + 1;
    final isButtonActive = classNumber >= 1 && classNumber <= 20;

    // Parse the attendance date once
    DateTime? parsedDate;
    try {
      final parts = attendanceDate.split('.');
      if (parts.length == 3) {
        parsedDate = DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
      }
    } catch (_) {
      parsedDate = null;
    }

    final displayDate = parsedDate != null
        ? DateFormat('dd-MMM-yyyy').format(parsedDate)
        : attendanceDate;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            // Title and Subject Code
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  Text(
                    subject.subjectName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryColor,
                      fontFamily: 'Roboto',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subject.subjectCode,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                      fontFamily: 'Roboto',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Date Display
            Text(
                displayDate,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.primaryColor,
                fontFamily: 'Roboto',
              ),
            ),
            const SizedBox(height: 12),
            // Class number display
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryColor.withOpacity(0.1),
                    AppColors.primaryColor.withOpacity(0.02),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.secondaryColor.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  'Class # $classNumber',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryColor,
                    fontFamily: 'Roboto',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            // Action button
            Padding(
              padding: EdgeInsets.only(bottom: bottomPadding + 16),
              child: ElevatedButton(
                onPressed: isButtonActive
                    ? () {
                        // Navigate to AttendancePage
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AttendancePage(
                              subject: subject,
                              classNumber: classNumber,
                              semester: subject.session,
                              academicYear: subject.academicYear,
                              sectionId: subject.sectionId,
                              date: parsedDate?.day ?? 0,
                              month: parsedDate?.month ?? 0,
                            ),
                          ),
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: AppColors.primaryColor,
                  disabledForegroundColor:
                      Colors.grey[300]?.withOpacity(0.38),
                  disabledBackgroundColor:
                      Colors.grey[300]?.withOpacity(0.12),
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 5,
                ),
                child: const Text(
                  'Take Attendance',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Roboto',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
