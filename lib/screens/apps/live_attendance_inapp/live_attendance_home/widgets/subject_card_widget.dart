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
    String formattedMonth = getMonthAbbreviation(widget.attendanceDate);

    return AnimationConfiguration.staggeredList(
      position: widget.index,
      duration: const Duration(milliseconds: 375),
      child: SlideAnimation(
        verticalOffset: 30.0,
        child: FadeInAnimation(
          child: GestureDetector(
            onTap: () => _handleTap(context),
            onTapDown: (_) => setState(() => _isPressed = true),
            onTapCancel: () => setState(() => _isPressed = false),
            onTapUp: (_) => setState(() => _isPressed = false),
            child: AnimatedScale(
              scale: _isPressed ? 0.97 : 1.0,
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeOut,
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryColor.withOpacity(0.10),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.menu_book_rounded,
                      color: AppColors.primaryColor,
                      size: 26,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.subject.subjectName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${widget.subject.subjectCode} | '
                            '${widget.subject.subjectNature} | '
                            '${widget.subject.credit} Credits | '
                            '${widget.subject.timeSlot}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '#$classNumber classes in $formattedMonth'
                            '${widget.subject.roomNo.isNotEmpty ? ' | Room# ${widget.subject.roomNo}' : ''}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 20,
                      color: AppColors.secondaryColor,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
