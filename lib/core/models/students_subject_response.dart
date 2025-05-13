import 'package:nitris/core/models/subject.dart';

class StudentSubjectResponse {
  final String status;
  final String message;
  final List<Subject> data;

  StudentSubjectResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory StudentSubjectResponse.fromJson(Map<String, dynamic> json) {
    var dataJson = json['data'] as List<dynamic>? ?? [];
    List<Subject> subjectsList =
        dataJson.map((subject) => Subject.fromJson(subject)).toList();

    // Sort the subjects so that 'Theory' comes before 'Practical'
    subjectsList.sort((a, b) {
      if (a.subjectNature == b.subjectNature) {
        return 0;
      }
      return a.subjectNature == "Theory" ? -1 : 1;
    });

    return StudentSubjectResponse(
      status: json['status'] ?? 'Unknown',
      message: json['message'] ?? '',
      data: subjectsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'data': data.map((subject) => subject.toJson()).toList(),
    };
  }
}
