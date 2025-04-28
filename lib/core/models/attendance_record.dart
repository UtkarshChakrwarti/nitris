class AttendanceRecord {
  final String date, inTime, outTime, duration, reason, message;
  final bool isPartialAttendance, isLateRegistration;
  
  AttendanceRecord({
    required this.date,
    required this.inTime,
    required this.outTime,
    required this.duration,
    required this.reason,
    required this.isPartialAttendance,
    required this.isLateRegistration,
    required this.message,
  });
  
  factory AttendanceRecord.fromJson(Map<String, dynamic> json) => AttendanceRecord(
    date: json['date'] ?? '',
    inTime: json['inTime'] ?? '',
    outTime: json['outTime'] ?? '',
    duration: json['duration'] ?? '',
    reason: json['reason'] ?? '',
    isPartialAttendance: json['isPartialAttendance'] ?? false,
    isLateRegistration: json['isLateRegistration'] ?? false,
    message: json['message'] ?? '',
  );
  
  factory AttendanceRecord.empty() => AttendanceRecord(
    date: '',
    inTime: '',
    outTime: '',
    duration: '',
    reason: '',
    isPartialAttendance: false,
    isLateRegistration: false,
    message: '',
  );
  
  int get day => int.tryParse(date.split('.').last) ?? 0;
  bool get isWeekend => message == 'Weekend';
  bool get isHoliday => message == 'Holiday';
  bool get isPresent => message == 'Present';
  bool get isAbsent => message == 'Absent';
  bool get isFutureDate => message == 'Date is more than current date';
}