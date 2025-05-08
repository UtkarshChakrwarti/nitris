import 'dart:convert';
import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:nitris/screens/apps/biometric_inapp/biometric_models/attendance_models.dart';
import 'package:nitris/screens/apps/biometric_inapp/biometric_models/student.dart';
import 'package:nitris/screens/apps/biometric_inapp/service/bio_remote_service.dart';
import 'package:nitris/screens/apps/biometric_inapp/widgets/app_colors.dart';

class AttendanceSubmitDialog extends StatefulWidget {
  final String teacherId;
  final DateTime startDate;
  final DateTime endDate;
  final List<Student> students;
  final List<StudentData> studentData;
  final Function onSubmitSuccess;
  final Function onCancel;

  const AttendanceSubmitDialog({
    Key? key,
    required this.teacherId,
    required this.startDate,
    required this.endDate,
    required this.students,
    required this.studentData,
    required this.onSubmitSuccess,
    required this.onCancel,
  }) : super(key: key);

  @override
  _AttendanceSubmitDialogState createState() => _AttendanceSubmitDialogState();
}

class _AttendanceSubmitDialogState extends State<AttendanceSubmitDialog> {
  final _service = AttendanceService();
  bool _submitting = false;
  String? _errorMessage;
  late Map<String, dynamic> _payload;

  @override
  void initState() {
    super.initState();
    _preparePayload();
  }

  // Format date for API
  String _formatApiDate(DateTime date) {
    return "${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}";
  }

  // Prepare the payload for submission
  void _preparePayload() {
    _payload = {
      "teacherId": widget.teacherId,
      "startDate": _formatApiDate(widget.startDate),
      "endDate": _formatApiDate(widget.endDate),
      "students": <Map<String, dynamic>>[],
    };

    // Build attendance data for each student
    for (var i = 0; i < widget.students.length; i++) {
      final student = {
        "rollNo": widget.students[i].rollNumber,
        "attendance": <Map<String, dynamic>>[]
      };

      // Add attendance for each day
      for (var d = 0; d < widget.students[i].attendance.length; d++) {
        final currentCode = widget.students[i].attendance[d];
        final day = widget.studentData[i].days[d];
        final dayDate = widget.startDate.add(Duration(days: d));
        
        // Map color codes to message values according to requirements
        String message;
        switch (currentCode) {
          case 'G': // Green - Present
            message = "P";
            break;
          case 'C': // Cyan - One Sign
            message = "W";
            break;
          case 'R': // Red - Absent (supervisor)
            message = "A";
            break;
          case 'Y': // Yellow - Absent
            // If inTime and outTime are present, mark as late
            if (day.inTime != null && day.outTime != null) {
              message = "F"; // Late
            } else {
              message = ""; // No time data
            }
            break;
          case 'Bl': // Blue - Holiday/Leave
            message = "";
            break;
          case 'Br': // Brown - Late Registration
            message = "F";
            break;
          case 'P': // Purple - Should be handled earlier
            message = "P"; // Default to present for API
            break;
          default:
            message = "";
        }

         // Add attendance record for this day
        (student["attendance"] as List).add({
          "date": _formatApiDate(dayDate),
          "reason": day.reason ?? "",
          "message": message
        });
      }

      // Add student to the payload
      (_payload["students"] as List).add(student);
    }
  }

  // Helper function to split large strings into chunks for logging
  List<String> _chunkString(String str, int chunkSize) {
    List<String> chunks = [];
    for (var i = 0; i < str.length; i += chunkSize) {
      chunks.add(
        str.substring(i, i + chunkSize < str.length ? i + chunkSize : str.length)
      );
    }
    return chunks;
  }

  // Submit the payload
  Future<void> _submitAttendance() async {
    if (_submitting) return;

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      // Log complete request body with markers to make it easy to find in logs
      final jsonString = const JsonEncoder.withIndent('  ').convert(_payload);
      
      // Print to console with clear start/end markers to find in logs
      dev.log('======== ATTENDANCE API REQUEST START ========');
      dev.log(jsonString);
      dev.log('======== ATTENDANCE API REQUEST END ========');
      
      // For even more visibility, also split large JSON into smaller chunks
      // This ensures nothing is truncated in the logs
      final chunks = _chunkString(jsonString, 1000); // Break into 1000-char chunks
      for (var i = 0; i < chunks.length; i++) {
        dev.log('PAYLOAD CHUNK ${i+1}/${chunks.length}: ${chunks[i]}');
      }
      
      // Make the actual API call with the prepared payload
      await _service.submitAttendance(
        widget.teacherId,
        "${_formatApiDate(widget.startDate)} - ${_formatApiDate(widget.endDate)}",
        _payload,
      );
      
      if (mounted) {
        Navigator.of(context).pop();
        widget.onSubmitSuccess();
      }
    } catch (e) {
      if (mounted) {
        dev.log('ATTENDANCE API ERROR: ${e.toString()}');
        setState(() {
          _errorMessage = 'Submission failed: ${e.toString()}';
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Submit Attendance',
        style: TextStyle(color: AppColors.primaryColor),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Are you sure you want to submit the attendance data?',
            style: TextStyle(fontSize: 16),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                "Some error occurred, please try again.",
                style: TextStyle(color: Colors.red.shade900),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () {
            Navigator.of(context).pop();
            widget.onCancel();
          },
          child: const Text('CANCEL',
          style: TextStyle(color: AppColors.primaryColor))),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: _submitting ? null : _submitAttendance,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryColor,
          ),
          child: _submitting 
              ? const SizedBox(
                  width: 20, 
                  height: 20, 
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  'SUBMIT',
                  style: TextStyle(color: Colors.white),
                ),
        ),
      ],
    );
  }
}

// Class to check for pending approvals
class AttendanceApprovalHelper {
  // Check if any student has pending approval (purple status)
  static bool hasPendingApprovals(List<Student> students) {
    return students.any((student) => student.attendance.contains('P'));
  }
  
  // Show pending approval warning dialog
  static void showPendingApprovalWarning(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          'Attendance Review Required',
          style: TextStyle(color: AppColors.primaryColor),
        ),
        content: const Text(
          'Some students have pending attendance approval. Please review and address all pending attendance statuses before proceeding with submission.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: TextStyle(color: AppColors.primaryColor),
            ),
          ),
        ],
      ),
    );
  }
}