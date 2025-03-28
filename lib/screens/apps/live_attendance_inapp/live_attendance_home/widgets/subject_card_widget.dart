import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:nitris/core/constants/app_colors.dart';
import 'package:nitris/core/models/subject.dart';
import 'package:nitris/core/utils/date_utils.dart';
import 'package:nitris/screens/apps/live_attendance_inapp/live_attendance_home/widgets/class_selection_sheet.dart';


class SubjectCardWidget extends StatefulWidget {
  final Subject subject;
  final String attendanceDate;
  final int index;

  const SubjectCardWidget({
    required this.subject,
    required this.attendanceDate,
    required this.index,
    super.key,
  });

  @override
  State<SubjectCardWidget> createState() => _SubjectCardWidgetState();
}

class _SubjectCardWidgetState extends State<SubjectCardWidget> {
  bool _isPressed = false;

  // Assuming classNumber comes from the subject
  late int classNumber;

  @override
  void initState() {
    super.initState();
    classNumber = widget.subject.totalClass;
  }

  void _handleTap(BuildContext context) {
    _showClassSelectionSheet(context);
  }

  void _showClassSelectionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return ClassSelectionSheet(
            subject: widget.subject, attendanceDate: widget.attendanceDate);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Use the utility function to get the month abbreviation
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
                margin:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
