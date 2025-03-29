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
  bool _isLoading = false;
  late int classNumber;

  @override
  void initState() {
    super.initState();
    classNumber = widget.subject.totalClass;
  }

  Future<void> _handleTap(BuildContext context) async {
    if (_isLoading) return; // Prevent multiple taps while loading
    
    setState(() {
      _isLoading = true;
    });
    
    // Create an instance of ApiService
    final apiService = ApiService();
    final sectionId = widget.subject.sectionId;

    try {
      bool isActive = await apiService.checkSessionStatus(sectionId);
      
      // Add a small delay if the API returns too quickly to show loading state
      await Future.delayed(const Duration(milliseconds: 300));
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      
      if (isActive) {
        _showSubjectQrScreen(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              "Attendance session is not active yet. Please wait for faculty to start taking attendance.",
            ),
            backgroundColor: AppColors.primaryColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error checking session status: $e"),
          backgroundColor: AppColors.darkRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  void _showSubjectQrScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StudentSubjectQrScreen(
          subject: widget.subject,
          attendanceDate: widget.attendanceDate,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    getMonthAbbreviation(widget.attendanceDate);

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
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _isLoading 
                      ? [const Color(0xFFF0F8FF), const Color(0xFFE6F2FF)]
                      : [Colors.white, const Color(0xFFF9F9F9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _isLoading
                          ? AppColors.primaryColor.withOpacity(0.2)
                          : AppColors.primaryColor.withOpacity(0.12),
                      spreadRadius: _isLoading ? 2 : 1,
                      blurRadius: _isLoading ? 8 : 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withOpacity(_isLoading ? 0.18 : 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: _isLoading
                            ? SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.primaryColor,
                                  ),
                                ),
                              )
                            : const Icon(
                                Icons.menu_book_rounded,
                                color: AppColors.primaryColor,
                                size: 24,
                              ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    widget.subject.subjectName,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.visible,
                                  ),
                                ),
                                if (_isLoading)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'Checking...',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.primaryColor,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            // First row of details
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    '${widget.subject.subjectCode} | ${widget.subject.credit} Credits',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[700],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.visible,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            // Second row of details
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    '${widget.subject.subjectNature} | ${widget.subject.timeSlot}${widget.subject.roomNo.isNotEmpty ? ' | Room# ${widget.subject.roomNo}' : ''}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[700],
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: _isLoading
                            ? Container(
                                key: const ValueKey('loading'),
                                width: 16,
                                height: 16,
                              )
                            : const Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: AppColors.secondaryColor,
                                size: 16,
                                key: ValueKey('arrow'),
                              ),
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