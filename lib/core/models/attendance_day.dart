
import 'package:nitris/core/enums/attendance_status.dart';

class AttendanceDay {
  final int day;
  final AttendanceStatus status;
  final String statusCode;

  AttendanceDay({
    required this.day,
    required this.status,
    required this.statusCode,
  });
}
