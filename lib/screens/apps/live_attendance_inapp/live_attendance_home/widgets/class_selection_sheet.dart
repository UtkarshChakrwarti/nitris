import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:nitris/core/constants/app_colors.dart';
import 'package:nitris/core/models/subject.dart';
import 'package:nitris/core/services/remote/api_service.dart';
import 'package:nitris/screens/apps/live_attendance_inapp/attendance/attendance_screen.dart';

class ClassSelectionSheet extends StatefulWidget {
  final Subject subject;
  final String attendanceDate;

  const ClassSelectionSheet({
    required this.subject,
    required this.attendanceDate,
    Key? key,
  }) : super(key: key);

  @override
  _ClassSelectionSheetState createState() => _ClassSelectionSheetState();
}

class _ClassSelectionSheetState extends State<ClassSelectionSheet> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    // Calculate class number and button availability.
    final classNumber = widget.subject.totalClass + 1;
    final isButtonActive = classNumber >= 1 && classNumber <= 20;

    // Process the attendanceDate (expected format "yyyy.MM.dd").
    String displayDate = widget.attendanceDate;
    String currentYear = "0000";
    int dayInt = 0;
    int monthInt = 0;
    final parts = widget.attendanceDate.split('.');
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
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar (aesthetic improvement)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 16),
              width: 50,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            // Title and Subject Code
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                children: [
                  Text(
                    widget.subject.subjectName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryColor,
                      fontFamily: 'Roboto',
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.subject.subjectCode,
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
            const SizedBox(height: 24),
            // Date Display
            Text(
              displayDate,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: AppColors.primaryColor,
                fontFamily: 'Roboto',
              ),
            ),
            const SizedBox(height: 16),
            // Class number display with refined padding and shadow.
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryColor.withOpacity(0.1),
                    AppColors.primaryColor.withOpacity(0.02),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.secondaryColor.withOpacity(0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  'Class # $classNumber',
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryColor,
                    fontFamily: 'Roboto',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 36),
            // Action button with enhanced loading indicator.
            Padding(
              padding: EdgeInsets.only(bottom: bottomPadding + 16),
              child: ElevatedButton(
              onPressed: isButtonActive && !_isLoading
                  ? () async {
                      setState(() {
                        _isLoading = true;
                      });
                      final apiService = ApiService();
                      try {
                        LocationPermission permission = await Geolocator.checkPermission();
                        if (permission == LocationPermission.denied ||
                            permission == LocationPermission.deniedForever) {
                          permission = await Geolocator.requestPermission();
                        }

                        if (permission == LocationPermission.denied ||
                            permission == LocationPermission.deniedForever) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Location permission is required to proceed.'),
                              backgroundColor: AppColors.primaryColor,
                            ),
                          );
                          setState(() {
                            _isLoading = false;
                          });
                          return;
                        }

                        final currentPosition = await Geolocator.getCurrentPosition(
                          desiredAccuracy: LocationAccuracy.high,
                        );

                        final latLongString =
                            '${currentPosition.latitude}|${currentPosition.longitude}';

                        final activeSession = await apiService.startLiveSession(
                          widget.subject.sectionId.toString(),
                          latLongString,
                        );
                        final sessionTime = activeSession['sessionTime'];

                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AttendancePage(
                              subject: widget.subject,
                              classNumber: classNumber,
                              semester: widget.subject.session,
                              currentYear: currentYear,
                              academicYear: widget.subject.academicYear,
                              sectionId: widget.subject.sectionId,
                              date: dayInt,
                              month: monthInt,
                              sessionTime: sessionTime,
                            ),
                          ),
                        );
                      } catch (error) {
                        print("Error starting active session: $error");
                        setState(() {
                          _isLoading = false;
                        });
                      }
                    }
                  : null,

                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: AppColors.primaryColor,
                  disabledForegroundColor: AppColors.primaryColor.withOpacity(0.38),
                  disabledBackgroundColor: AppColors.primaryColor.withOpacity(0.12),
                  minimumSize: const Size(double.infinity, 64),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 6,
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  child: _isLoading
                      ? Row(
                          key: const ValueKey('loading'),
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 3.0,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Text(
                              'Fetching Location...',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Roboto',
                              ),
                            ),
                          ],
                        )
                      : const Text(
                          'Take Attendance',
                          key: ValueKey('text'),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Roboto',
                          ),
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
