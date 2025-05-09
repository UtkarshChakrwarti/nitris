import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:nitris/core/constants/app_constants.dart';
import 'package:nitris/core/services/local/local_storage_service.dart';
import 'package:nitris/screens/apps/biometric_inapp/biometric_models/attendance_models.dart';
import 'package:nitris/screens/apps/biometric_inapp/biometric_models/student.dart' show Student;

class AttendanceService {
  static const _base = AppConstants.biometric;
  
  // Helper method to get the correct teacherId
  String _getEffectiveTeacherId(String teacherId) {
    return teacherId == "1000000" ? "1151213" : teacherId;
  }

  /// Page‐load: fetches current week & students
  Future<TeacherWeekData> fetchInitialWeek(String teacherId) async {
    final effectiveTeacherId = _getEffectiveTeacherId(teacherId);
    
    final uri = Uri.parse('$_base/GetStudents?facultyid=$effectiveTeacherId');
    final res = await http.get(uri).timeout(const Duration(seconds: 30));
    if (res.statusCode != 200) {
      throw Exception('Failed to load initial week (${res.statusCode})');
    }
    return TeacherWeekData.fromJson(
      json.decode(res.body) as Map<String, dynamic>,
    );
  }

  /// Navigate: fetch any week by dates
  Future<TeacherWeekData> fetchWeek(
    String teacherId,
    DateTime start,
    DateTime end,
  ) async {
    final effectiveTeacherId = _getEffectiveTeacherId(teacherId);
    
    String fmt(DateTime d) =>
        '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';
    final uri = Uri.parse(
      '$_base/GetTeacherAttendance?facultyid=$effectiveTeacherId&startDate=${fmt(start)}&endDate=${fmt(end)}',
    );
    final res = await http.get(uri).timeout(const Duration(seconds: 30));
    if (res.statusCode != 200) {
      throw Exception('Failed to load week (${res.statusCode})');
    }
    return TeacherWeekData.fromJson(
      json.decode(res.body) as Map<String, dynamic>,
    );
  }

  /// Builds—but does NOT send—the payload for SubmitTeacherAttendance
  Map<String, dynamic> buildSubmitPayload(
    String teacherId,
    DateTime start,
    DateTime end,
    List<Student> uiStudents,
    List<AttendanceDay> daysForStudent, // parallel list per student
  ) {
    final effectiveTeacherId = _getEffectiveTeacherId(teacherId);
    
    String fmt(DateTime d) =>
        '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';
    return {
      'teacherId': effectiveTeacherId,
      'startDate': fmt(start),
      'endDate': fmt(end),
      'students': [
        for (int i = 0; i < uiStudents.length; i++)
          {
            'rollNo': uiStudents[i].rollNumber,
            'attendance': [
              for (int j = 0; j < uiStudents[i].attendance.length; j++)
                {
                  'date': fmt(
                    daysForStudent[i * uiStudents[i].attendance.length + j]
                        .date,
                  ),
                  'reason': '',
                  'message': uiStudents[i].attendance[j],
                },
            ],
          },
      ],
    };
  }

  /// Submit teacher attendance data
  Future<bool> submitAttendance(
    String teacherId,
    String weekLabel,
    Map<String, dynamic> payloadData,
  ) async {
    // For userId "1000000", return success without making API call
    final loginResponse = await LocalStorageService.getLoginResponse();
    if (loginResponse?.empCode == "1000000") {
      print("returning from dummy payload");
      return true;
    }
    
    final uri = Uri.parse('$_base/SubmitTeacherAttendance');
    try {
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: json.encode(payloadData),
          )
          .timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        // Check response body for success indicators if the API returns them
        return true;
      } else {
        throw Exception('API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to submit attendance: $e');
    }
  }
}