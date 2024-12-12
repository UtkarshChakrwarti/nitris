import 'subject.dart';

class SubjectResponse {
  final List<Subject> subjects;
  final String status;
  final int totalSubjects;
  final String attendancedate;
  // final String totalClass

  SubjectResponse({
    required this.subjects,
    required this.status,
    required this.totalSubjects,
    required this.attendancedate,
  });
  factory SubjectResponse.fromJson(Map<String, dynamic> json) {
    var subjectsJson = json['subjects'] as List<dynamic>? ?? [];
    List<Subject> subjectsList =
        subjectsJson.map((subject) => Subject.fromJson(subject)).toList();

    return SubjectResponse(
      subjects: subjectsList,
      status: json['status'] ?? 'Unknown',
      totalSubjects: json['totalSubjects'] ?? subjectsList.length,
      attendancedate: json['attendancedate'] ?? 'N/A',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subjects': subjects.map((subject) => subject.toJson()).toList(),
      'status': status,
      'totalSubjects': totalSubjects,
      'attendancedate': attendancedate,
    };
  }
}
