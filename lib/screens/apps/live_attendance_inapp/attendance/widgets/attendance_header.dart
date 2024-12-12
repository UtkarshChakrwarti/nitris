import 'package:flutter/material.dart';
import 'package:nitris/core/constants/app_colors.dart';
import 'package:nitris/screens/apps/live_attendance_inapp/attendance/widgets/attendance_card.dart';

class AttendanceHeader extends StatelessWidget {
  final int presentCount;
  final int absentCount;
  final int unmarkedCount;
  final int totalStudents;
  final bool isSelectAll;
  final ValueChanged<bool> onSelectAllChanged;
  final VoidCallback onClear;

  const AttendanceHeader({
    super.key,
    required this.presentCount,
    required this.absentCount,
    required this.unmarkedCount,
    required this.totalStudents,
    required this.isSelectAll,
    required this.onSelectAllChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 4,
      ),
      color: AppColors.primaryColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AttendanceCard(
                title: 'Present',
                count: presentCount,
                total: totalStudents,
                color: AppColors.darkGreen,
                icon: Icons.check_circle_outline,
              ),
              const SizedBox(width: 4),
              AttendanceCard(
                title: 'Absent',
                count: absentCount,
                total: totalStudents,
                color: AppColors.darkRed,
                icon: Icons.remove_circle_outline,
              ),
              const SizedBox(width: 4),
              AttendanceCard(
                title: 'Unmarked',
                count: unmarkedCount,
                total: totalStudents,
                color: Colors.grey,
                icon: Icons.help_outline,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Present All Toggle
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.15),
                      width: 1,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'All Present',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Transform.scale(
                        scale: 0.7,
                        child: Switch(
                          value: isSelectAll,
                          onChanged: onSelectAllChanged,
                          activeColor: AppColors.secondaryColor,
                          activeTrackColor: Colors.white.withOpacity(0.3),
                          inactiveThumbColor: Colors.white,
                          inactiveTrackColor: Colors.black12,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                ),

                // Clear Button
                TextButton.icon(
                  onPressed: onClear,
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  icon: const Icon(
                    Icons.refresh_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'Reset',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
