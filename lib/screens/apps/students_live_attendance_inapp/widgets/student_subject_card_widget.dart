import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:nitris/core/constants/app_colors.dart';
import 'package:nitris/core/models/subject.dart';
import 'package:nitris/core/utils/date_utils.dart';

class StudentSubjectsCardWidget extends StatelessWidget {
  final Subject subject;
  final String attendanceDate;
  final int index;
  final bool isLoading; // Optional flag to show a loading indicator

  const StudentSubjectsCardWidget({
    required this.subject,
    required this.attendanceDate,
    required this.index,
    this.isLoading = false,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Optionally, call your helper to get a month abbreviation.
    getMonthAbbreviation(attendanceDate);
    
    return AnimationConfiguration.staggeredList(
      position: index,
      duration: const Duration(milliseconds: 375),
      child: SlideAnimation(
        verticalOffset: 50.0,
        child: FadeInAnimation(
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.white, Color(0xFFF9F9F9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryColor.withOpacity(0.12),
                  spreadRadius: 1,
                  blurRadius: 6,
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
                      color: AppColors.primaryColor.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: isLoading
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
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
                        Text(
                          subject.subjectName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.visible,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${subject.subjectCode} | ${subject.credit} Credits',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.visible,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${subject.subjectNature} | ${subject.timeSlot}${subject.roomNo.isNotEmpty ? ' | Room# ${subject.roomNo}' : ''}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: AppColors.secondaryColor,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
