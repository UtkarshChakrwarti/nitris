import 'package:nitris/screens/apps/biometric_inapp/biometric_models/attendance_models.dart';

/// Helper to pick status code from a day + working‐dates
class AttendanceUtils {
  static String statusFor(AttendanceDay day, List<DateTime> workingDates) {
    final d = day.date;
    final isWorking = workingDates.any(
      (w) => w.year == d.year && w.month == d.month && w.day == d.day,
    );

    // not clickable
    // Holiday/Leave
    if (!isWorking) return 'Bl';
    //Late Registration
    if (day.isLateRegistration) return 'Br';

    // Case 1: Check for pending attendance status when both inTime and outTime are present
    if (day.inTime != null && day.outTime != null) {
      // Parse inTime and outTime
      final inTimeParts = day.inTime!.split(':');
      final outTimeParts = day.outTime!.split(':');

      if (inTimeParts.length >= 2 && outTimeParts.length >= 2) {
        final inTimeHour = int.tryParse(inTimeParts[0]) ?? 0;
        final inTimeMinute = int.tryParse(inTimeParts[1]) ?? 0;

        final outTimeHour = int.tryParse(outTimeParts[0]) ?? 0;

        // Check if inTime is between 7:30 AM and 9:30 AM
        final isInTimeValid =
            (inTimeHour == 7 && inTimeMinute >= 30) ||
            (inTimeHour == 8) ||
            (inTimeHour == 9 && inTimeMinute <= 30);

        // Check if outTime is between 5:00 PM and 10:00 PM
        final isOutTimeValid = (outTimeHour >= 17 && outTimeHour <= 22);

        // Check if duration is greater than 9 hours
        final durationHours = int.tryParse(day.duration ?? '0') ?? 0;
        final isDurationValid = durationHours >= 9;

        // Special case: If message is "A" (marked absent by supervisor) but duration is valid
        if (day.message == "A" && isDurationValid) {
          return 'R';
        }

        // Regular case: If conditions are met and message is empty
        final isMessageEmpty = (day.message == null || day.message!.isEmpty);
        if (isInTimeValid &&
            isOutTimeValid &&
            isDurationValid &&
            isMessageEmpty) {
          return 'P';
        }
      }
    }

    // NEW CASE: Only one of inTime or outTime is present and is within valid range
    if ((day.inTime != null && day.outTime == null) ||
        (day.inTime == null && day.outTime != null)) {
      // Check if the single time entry is valid
      if (day.inTime != null) {
        final inTimeParts = day.inTime!.split(':');
        if (inTimeParts.length >= 2) {
          final inTimeHour = int.tryParse(inTimeParts[0]) ?? 0;
          final inTimeMinute = int.tryParse(inTimeParts[1]) ?? 0;

          // Check if inTime is between 7:30 AM and 9:30 AM
          final isInTimeValid =
              (inTimeHour == 7 && inTimeMinute >= 30) ||
              (inTimeHour == 8) ||
              (inTimeHour == 9 && inTimeMinute <= 30);

          if (isInTimeValid) {
            // If the message is "A", return 'R' (similar to case 2)
            if (day.message == "A") return 'R';
            // Otherwise mark as partial attendance
            return 'C';
          }
        }
      }

      if (day.outTime != null) {
        final outTimeParts = day.outTime!.split(':');
        if (outTimeParts.length >= 2) {
          final outTimeHour = int.tryParse(outTimeParts[0]) ?? 0;

          // Check if outTime is between 5:00 PM and 10:00 PM
          final isOutTimeValid = (outTimeHour >= 17 && outTimeHour <= 22);

          if (isOutTimeValid) {
            // If the message is "A", return 'R' (similar to case 2)
            if (day.message == "A") return 'R';
            // Otherwise mark as partial attendance
            return 'C';
          }
        }
      }
    }

    // Case 2: Only one of inTime or outTime is present and message is "A"
    if ((day.inTime != null || day.outTime != null) && day.message == "A") {
      return 'R';
    }

    // Case 3: Partial attendance with message "A"
    if (day.isPartialAttendance && day.message == "A") {
      return 'R';
    }

    // Other standard cases
    if (day.message == "A") return 'Y';
    if (day.message == "P") return 'G';
    if (day.isPartialAttendance) {
      if (day.message == "P") {
        return 'G';
      } else {
        return 'C';
      }
    }

    // Default absent
    if (day.inTime == null && day.outTime == null) return 'Y';

    // When both inTime and outTime are present but don't meet other criteria
    // This ensures yellow cells with both time entries are clickable and can be
    // changed by the teacher
    if (day.inTime != null || day.outTime != null) return 'Y';

    return 'Y';
  }
}
