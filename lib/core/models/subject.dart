// lib/models/subject.dart
class Subject {
  final int totalClass;
  final String subjectCode;
  final String subjectName;
  final String ltp;
  final int credit;
  final String subjectNature;
  final String timeSlot;
  final String academicYear;
  final String session;
  final String section;
  final int sectionId;
  final String roomNo; // Added roomNo field, nullable

  Subject({
    required this.totalClass,
    required this.subjectCode,
    required this.subjectName,
    required this.ltp,
    required this.credit,
    required this.subjectNature,
    required this.timeSlot,
    required this.academicYear,
    required this.session,
    required this.section,
    required this.sectionId,
    required this.roomNo, // Initialize roomNo
  });

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      totalClass: json['totalClass'] ?? 0,
      subjectCode: json['subjectcode'] ?? '',
      subjectName: json['subjectname'] ?? '',
      ltp: json['ltp'] ?? '',
      credit: json['credit'] ?? 0,
      subjectNature: json['subjectnature'] ?? '',
      timeSlot: json['timeslot'] ?? '',
      academicYear: json['academicyear'] ?? '',
      session: json['session'] ?? '',
      section: json['section'] ?? '',
      sectionId: json['sectionId'] ?? 0,
      roomNo: json['roomno'] ?? '', // Initialize roomNo from JSON
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalClass': totalClass,
      'subjectcode': subjectCode,
      'subjectname': subjectName,
      'ltp': ltp,
      'credit': credit,
      'subjectnature': subjectNature,
      'timeslot': timeSlot,
      'academicyear': academicYear,
      'session': session,
      'section': section,
      'sectionId': sectionId,
      'roomno': roomNo, // Include roomNo in JSON
    };
  }
}
