// lib/widgets/student_tile.dart

import 'package:flutter/material.dart';
import 'package:nitris/core/constants/app_colors.dart';
import 'package:nitris/core/models/student.dart';

class StudentTile extends StatelessWidget {
  final int index; // Index parameter for enumeration
  final Student student;
  final bool isSmallDevice;
  final VoidCallback onMarkPresent;
  final VoidCallback onMarkAbsent;

  const StudentTile({
    super.key,
    required this.index,
    required this.student,
    required this.isSmallDevice,
    required this.onMarkPresent,
    required this.onMarkAbsent,
  });

  // Determine the background color based on attendance status
  Color _getTileColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return Colors.lightGreen[50]!;
      case AttendanceStatus.absent:
        return Colors.red[50]!;
      default:
        return Colors.white;
    }
  }

  // Determine the text color for the student's name
  Color _getNameColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return AppColors.darkGreen;
      case AttendanceStatus.absent:
        return AppColors.darkRed;
      default:
        return Colors.black87;
    }
  }

  // Determine the color for status indicators
  Color _getStatusColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return AppColors.darkGreen;
      case AttendanceStatus.absent:
        return AppColors.darkRed;
      default:
        return Colors.grey.shade400;
    }
  }

  // Build the roll number tag
  Widget _buildRollNumberTag() {
    final bgColor = _getStatusColor(student.status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: bgColor.withOpacity(0.5)),
      ),
      child: Text(
        student.rollNo,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  // Build the status buttons (Present/Absent)
  Widget _buildStatusButtons() {
    return Row(
      children: [
        // Present Button or Icon
        student.status == AttendanceStatus.present
            ? Container(
                width: 90, // Fixed width to avoid layout shift
                alignment: Alignment.center,
                child: const Icon(
                  Icons.check_circle,
                  color: AppColors.darkGreen,
                  size: 20,
                ),
              )
            : SizedBox(
                width: 90, // Fixed width to maintain position
                child: ElevatedButton(
                  onPressed: onMarkPresent,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.darkGreen,
                    side: const BorderSide(color: AppColors.darkGreen, width: 1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  ),
                  child: const Text(
                    'Present',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ),
        const SizedBox(width: 8),
        // Absent Button or Icon
        student.status == AttendanceStatus.absent
            ? Container(
                width: 90, // Fixed width to avoid layout shift
                alignment: Alignment.center,
                child: const Icon(
                  Icons.remove_circle_outline,
                  color: AppColors.darkRed,
                  size: 20,
                ),
              )
            : SizedBox(
                width: 90, // Fixed width to maintain position
                child: ElevatedButton(
                  onPressed: onMarkAbsent,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.darkRed,
                    side: const BorderSide(color: AppColors.darkRed, width: 1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  ),
                  child: const Text(
                    'Absent',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ),
      ],
    );
  }

  // Build the index tag with up to 3 digits
  Widget _buildIndexTag() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.lightSecondaryColor, // Color for the index tag
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        index.toString(), // Formats index as 3 digits
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tileColor = _getTileColor(student.status);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tileColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row containing the index tag and student name
          Row(
            children: [
              _buildIndexTag(), // Display the index tag
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  student.name.replaceAll(RegExp(r'\s+'), ' ').toUpperCase(),
                  style: TextStyle(
                    fontSize: isSmallDevice ? 14 : 16,
                    fontWeight: FontWeight.bold,
                    color: _getNameColor(student.status),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Row containing the roll number and status buttons
          Row(
            children: [
              _buildRollNumberTag(),
              const Spacer(),
              _buildStatusButtons(),
            ],
          ),
        ],
      ),
    );
  }
}
