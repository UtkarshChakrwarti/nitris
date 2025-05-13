import 'subject.dart';

class SubjectResponse {
  final List<Subject> subjects;
  final String status;
  final int totalSubjects;
  final String attendancedate;

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
    
    // Sort subjects so that 'Theory' comes before 'Practical'
    subjectsList.sort((a, b) {
      if (a.subjectNature == 'Theory' && b.subjectNature != 'Theory') {
        return -1;
      } else if (a.subjectNature != 'Theory' && b.subjectNature == 'Theory') {
        return 1;
      }
      return 0;
    });

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
