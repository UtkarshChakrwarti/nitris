
import 'package:nitris/core/enums/attendance_status.dart';

class Student {
  final String id;
  final String name;
  final String rollNo;
  final String programme;
  final String deptCode;
  final String mobile;
  final String attendanceId;
  AttendanceStatus status;

  Student({
    required this.id,
    required this.name,
    required this.rollNo,
    required this.programme,
    required this.deptCode,
    required this.mobile,
    required this.attendanceId,
    this.status = AttendanceStatus.notMarked,
  });

// from json and tojson
  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'] ?? 'unknown',
      name: json['name'] ?? 'unknown',
      rollNo: json['rollNo'] ?? 'unknown',
      programme: json['programme'] ?? 'unknown',
      deptCode: json['deptCode'] ?? 'unknown',
      mobile: json['mobile'] ?? 'unknown',
      attendanceId: json['attendanceId'] ?? 'unknown',
      status: AttendanceStatus.notMarked,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'rollNo': rollNo,
      'programme': programme,
      'deptCode': deptCode,
      'mobile': mobile,
      'attendanceId': attendanceId,
      'status': status,
    };
  }
}
