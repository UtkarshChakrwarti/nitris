class AttendanceDay {
  final DateTime date;
  final String? inTime, outTime;
  final String? duration;
  final String? reason;
  final String? message;
  final String? approvedOn;
  final bool isPartialAttendance, isLateRegistration;

  AttendanceDay({
    required this.date,
    this.inTime,
    this.outTime,
    this.duration,
    this.reason,
    this.message,
    this.approvedOn,
    required this.isPartialAttendance,
    required this.isLateRegistration,
  });

  factory AttendanceDay.fromJson(Map<String, dynamic> j) {
    DateTime pd(String s) => DateTime.parse(s.replaceAll('.', '-'));
    return AttendanceDay(
      date: pd(j['date'] as String),
      inTime: j['inTime'] as String?,
      outTime: j['outTime'] as String?,
      duration: j['duration'] as String?,
      reason: j['reason'] as String?,
      message: j['message'] as String?,
      approvedOn: j.containsKey('approvedOn') ? j['approvedOn'] as String? : null,
      isPartialAttendance: j['isPartialAttendance'] as bool? ?? false,
      isLateRegistration: j['isLateRegistration'] as bool? ?? false,
    );
  }
}

/// Working‐days info from API
class WorkingDays {
  final List<DateTime> workingDates;
  WorkingDays({required this.workingDates});

  factory WorkingDays.fromJson(Map<String, dynamic> j) {
    DateTime pd(String s) => DateTime.parse(s.replaceAll('.', '-'));
    return WorkingDays(
      workingDates:
          (j['workingDates'] as List).map((s) => pd(s as String)).toList(),
    );
  }
}

/// One student’s week of data
class StudentData {
  final String rollNo;
  final String name;
  final List<AttendanceDay> days;

  StudentData({
    required this.rollNo,
    required this.name,
    required this.days,
  });

  factory StudentData.fromJson(Map<String, dynamic> j) {
    return StudentData(
      rollNo: j['rollNo'] as String,
      name: j['name'] as String,
      days: (j['attendance'] as List)
          .map((e) => AttendanceDay.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// The week payload
class TeacherWeekData {
  final DateTime startDate, endDate;
  final WorkingDays workingDays;
  final List<StudentData> students;

  TeacherWeekData({
    required this.startDate,
    required this.endDate,
    required this.workingDays,
    required this.students,
  });

  factory TeacherWeekData.fromJson(Map<String, dynamic> j) {
    DateTime pd(String s) => DateTime.parse(s.replaceAll('.', '-'));
    return TeacherWeekData(
      startDate: pd(j['startDate'] as String),
      endDate: pd(j['endDate'] as String),
      workingDays: WorkingDays.fromJson(j['workingDays'] as Map<String, dynamic>),
      students: (j['students'] as List)
          .map((e) => StudentData.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}