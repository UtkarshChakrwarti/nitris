class AttendanceRecord {
  final String date;
  final String inTime;
  final String outTime;
  final String duration;
  final String reason;
  final String message;
  final bool isPartialAttendance;
  final bool isLateRegistration;
  
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
  
  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      date: json['date'] ?? '',
      inTime: json['inTime'] ?? '',
      outTime: json['outTime'] ?? '',
      duration: json['duration'] ?? '',
      reason: json['reason'] ?? '',
      isPartialAttendance: json['isPartialAttendance'] ?? false,
      isLateRegistration: json['isLateRegistration'] ?? false,
      message: json['message'] ?? '',
    );
  }
  
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
  
  /// Extract day number from the date string "YYYY.MM.DD"
  int get day => int.tryParse(date.split('.').last) ?? 0;
  
  bool get isWeekend => message == 'Weekend';
  
  /// Only true when message=="Holiday" *and* reason is non-empty
  bool get isHoliday => message == 'Holiday' && reason.isNotEmpty;
  
  /// Returns the holiday name (e.g. "Good Friday"), or null otherwise
  String? get holidayName => isHoliday ? reason : null;
  
  bool get isPresent => message.toLowerCase().contains('present');
  bool get isAbsent => message.toLowerCase().contains('absent');
  bool get isFutureDate => message == 'Date is more than current date';

  bool get isOneSignature => message =='One Signature';

    /// True if supervisor has approved this record (duration is set)
  bool get isApproved => duration.isNotEmpty;

  /// True if it’s an Absent entry that’s been approved by the supervisor
  bool get isSupervisorAbsent => isAbsent && isApproved;
  
}
