import 'subject.dart';

class Faculty {
  final String name;
  final String avatarUrl;
  final String semester;
  final String academicYear;
  final List<Subject> subjects;
  final int totalSubjects;

  Faculty({
    required this.name,
    required this.avatarUrl,
    required this.semester,
    required this.academicYear,
    required this.subjects,
    required this.totalSubjects,
  });

  factory Faculty.fromJson(Map<String, dynamic> json) {
    var subjectsJson = json['subjects'] as List<dynamic>? ?? [];
    List<Subject> subjectsList =
        subjectsJson.map((subject) => Subject.fromJson(subject)).toList();

    return Faculty(
      name: json['name'] ?? 'Unknown',
      avatarUrl: json['avatarUrl'] ?? '',
      semester: json['semester'] ?? 'N/A',
      academicYear: json['academicyear'] ?? 'N/A',
      subjects: subjectsList,
      totalSubjects: json['totalsubjects'] ?? subjectsList.length,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'avatarUrl': avatarUrl,
      'semester': semester,
      'academicyear': academicYear,
      'subjects': subjects.map((subject) => subject.toJson()).toList(),
      'totalsubjects': totalSubjects,
    };
  }

  static Faculty defaultUser() {
    return Faculty(
      name: 'Default User',
      avatarUrl: 'https://invalid-url.com/avatar.png', // Use a URL to test fallback
      semester: '1',
      academicYear: '2023-2024',
      subjects: [],
      totalSubjects: 0,
    );
  }
}
