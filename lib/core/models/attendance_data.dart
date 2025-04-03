import 'package:nitris/core/enums/attendance_status.dart';
import 'package:nitris/core/models/attendance_day.dart';

class AttendanceData {
  final String rollNo;
  final String name;
  final String month;
  final String subjectCode;
  final String subjectName;
  final int year;
  final int totalClass;
  final int totalPresent;
  final int totalAbsent;
  final List<AttendanceDay> attendanceDays;

  AttendanceData({
    required this.rollNo,
    required this.name,
    required this.month,
    required this.subjectCode,
    required this.subjectName,
    required this.year,
    required this.totalClass,
    required this.totalPresent,
    required this.totalAbsent,
    required this.attendanceDays,
  });

  factory AttendanceData.fromJson(Map<String, dynamic> json) {
    List<AttendanceDay> days = [];
    for (int i = 1; i <= 20; i++) {
      final dateKey = 'c${i}Date';
      final statusKey = 'c$i';
      if (json[dateKey] != null && json[dateKey].toString().isNotEmpty) {
        int dayNum = int.tryParse(json[dateKey].toString()) ?? 0;
        if (dayNum > 0) {
          String code = json[statusKey] ?? "";
          AttendanceStatus status;
          switch (code) {
            case "G":
              status = AttendanceStatus.present;
              break;
            case "Y":
              status = AttendanceStatus.presentLate;
              break;
            case "L":
              status = AttendanceStatus.leave;
              break;
            case "R":
              status = AttendanceStatus.absent;
              break;
            case "B":
              status = AttendanceStatus.absentLate;
              break;
            default:
              status = AttendanceStatus.absent;
              break;
          }
          days.add(AttendanceDay(day: dayNum, status: status, statusCode: code));
        }
      }
    }
    return AttendanceData(
      rollNo: json['rollNo'] ?? "",
      name: json['name'] ?? "",
      month: json['month'] ?? "",
      subjectCode: json['subjectCode'] ?? "",
      subjectName: json['subjectName'] ?? "",
      year: json['year'] is int ? json['year'] : int.tryParse(json['year'].toString()) ?? 0,
      totalClass: json['totalClass'] is int ? json['totalClass'] : int.tryParse(json['totalClass'].toString()) ?? 0,
      totalPresent: json['totalPresent'] is int ? json['totalPresent'] : int.tryParse(json['totalPresent'].toString()) ?? 0,
      totalAbsent: json['totalAbsent'] is int ? json['totalAbsent'] : int.tryParse(json['totalAbsent'].toString()) ?? 0,
      attendanceDays: days,
    );
  }
}
