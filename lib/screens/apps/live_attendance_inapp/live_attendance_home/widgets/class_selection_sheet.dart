import 'package:flutter/material.dart';
import 'package:nitris/core/constants/app_colors.dart';
import 'package:nitris/core/models/subject.dart';
import 'package:nitris/core/services/remote/api_service.dart';
import 'package:nitris/screens/apps/live_attendance_inapp/attendance/attendance_screen.dart';

class ClassSelectionSheet extends StatelessWidget {
  final Subject subject;
  final String attendanceDate;

  const ClassSelectionSheet({
    required this.subject,
    required this.attendanceDate,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    // Calculate class number and check button availability.
    final classNumber = subject.totalClass + 1;
    final isButtonActive = classNumber >= 1 && classNumber <= 20;

    // Process the attendanceDate (expected format "yyyy.MM.dd").
    String displayDate = attendanceDate;
    String currentYear = "0000";
    int dayInt = 0;
    int monthInt = 0;
    final parts = attendanceDate.split('.');
    if (parts.length == 3) {
      final year = parts[0];
      final month = parts[1];
      final day = parts[2];
      final monthMap = {
        '01': 'Jan',
        '02': 'Feb',
        '03': 'Mar',
        '04': 'Apr',
        '05': 'May',
        '06': 'Jun',
        '07': 'Jul',
        '08': 'Aug',
        '09': 'Sep',
        '10': 'Oct',
        '11': 'Nov',
        '12': 'Dec',
      };
      displayDate = '$day-${monthMap[month] ?? month}-$year';
      currentYear = year;
      dayInt = int.tryParse(day) ?? 0;
      monthInt = int.tryParse(month) ?? 0;
    }

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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
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
                    ? () async {
                        // Create an instance of ApiService.
                        final apiService = ApiService();
                        try {
                          // Trigger the active session API call.
                          final activeSession = await apiService.startLiveSession(
                            subject.sectionId.toString(),
                          );
                          print("Active session started: $activeSession");
                          // Extract sessionTime from the response.
                          final sessionTime = activeSession['sessionTime'];
                          
                          // Navigate to AttendancePage with sessionTime passed.
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AttendancePage(
                                subject: subject,
                                classNumber: classNumber,
                                semester: subject.session,
                                currentYear: currentYear,
                                sectionId: subject.sectionId,
                                date: dayInt,
                                month: monthInt,
                                sessionTime: sessionTime,
                              ),
                            ),
                          );
                        } catch (error) {
                          print("Error starting active session: $error");
                          // Optionally, display an error message to the user.
                          return;
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: AppColors.primaryColor,
                  disabledForegroundColor: Colors.grey[300]?.withOpacity(0.38),
                  disabledBackgroundColor: Colors.grey[300]?.withOpacity(0.12),
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
