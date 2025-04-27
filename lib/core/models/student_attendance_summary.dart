

import 'package:nitris/core/models/attendance_record.dart';

class StudentAttendanceSummary {
  final int leaveAvailed, leaveRemaining;
  final String leaveMonth;
  final List<AttendanceRecord> records;
  
  StudentAttendanceSummary({
    required this.leaveAvailed,
    required this.leaveRemaining,
    required this.leaveMonth,
    required this.records,
  });
  
  factory StudentAttendanceSummary.fromJson(Map<String, dynamic> json) =>
      StudentAttendanceSummary(
        leaveAvailed: json['leaveAvailed'] ?? 0,
        leaveRemaining: json['leaveRemaining'] ?? 0,
        leaveMonth: json['leaveMonth'] ?? '',
        records: (json['attendance'] as List)
            .map((e) => AttendanceRecord.fromJson(e))
            .toList(),
      );
}