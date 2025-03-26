import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:nitris/core/constants/app_colors.dart';
import 'package:nitris/core/models/subject.dart';
import 'package:nitris/core/services/remote/api_service.dart';
import 'package:nitris/core/utils/date_utils.dart';
import 'package:nitris/screens/apps/students_live_attendance_inapp/widgets/student_subject_qr_screen.dart';

class StudentSubjectsCardWidget extends StatefulWidget {
  final Subject subject;
  final String attendanceDate;
  final int index;

  const StudentSubjectsCardWidget({
    required this.subject,
    required this.attendanceDate,
    required this.index,
    Key? key,
  }) : super(key: key);

  @override
  _StudentSubjectsCardWidgetState createState() =>
      _StudentSubjectsCardWidgetState();
}

class _StudentSubjectsCardWidgetState extends State<StudentSubjectsCardWidget> {
  bool _isPressed = false;
  late int classNumber;

  @override
  void initState() {
    super.initState();
    classNumber = widget.subject.totalClass;
  }

  Future<void> _handleTap(BuildContext context) async {
    // Create an instance of ApiService
    final apiService = ApiService();
    final sectionId = widget.subject.sectionId;

    try {
      bool isActive = await apiService.checkSessionStatus(sectionId);
      if (isActive) {
        _showSubjectQrScreen(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              "Attendance session is not active yet. Please wait for it to start.",
            ),
            backgroundColor: AppColors.primaryColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error checking session status: $e"),
          backgroundColor: AppColors.darkRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _showSubjectQrScreen(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (BuildContext context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height,
          child: StudentSubjectQrScreen(
            subject: widget.subject,
            attendanceDate: widget.attendanceDate,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    String formattedMonth = getMonthAbbreviation(widget.attendanceDate);

    return AnimationConfiguration.staggeredList(
      position: widget.index,
      duration: const Duration(milliseconds: 375),
      child: SlideAnimation(
        verticalOffset: 50.0,
        child: FadeInAnimation(
          child: GestureDetector(
            onTap: () => _handleTap(context),
            onTapDown: (_) => setState(() => _isPressed = true),
            onTapCancel: () => setState(() => _isPressed = false),
            onTapUp: (_) => setState(() => _isPressed = false),
            child: AnimatedScale(
              scale: _isPressed ? 0.95 : 1.0,
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeOut,
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.white, Color(0xFFF9F9F9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryColor.withOpacity(0.15),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.menu_book_rounded,
                          color: AppColors.primaryColor,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.subject.subjectName,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${widget.subject.subjectCode} | '
                              '${widget.subject.subjectNature} | '
                              '${widget.subject.credit} Credits | '
                              '${widget.subject.timeSlot} | '
                              '#$classNumber classes taken in $formattedMonth',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: AppColors.secondaryColor,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
