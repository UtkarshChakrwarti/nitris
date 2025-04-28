import 'package:intl/intl.dart';

/// Utility class for formatting operations
class Formatters {
  /// Converts 24-hr time to 12-hr format with AM/PM
  static String formatTime(int hour24, int minute) {
    final suffix = (hour24 >= 12) ? "PM" : "AM";
    int hour = (hour24 > 12) ? hour24 - 12 : hour24;
    if (hour == 0) hour = 12;
    
    final minStr = minute.toString().padLeft(2, '0');
    final hourStr = hour.toString().padLeft(2, '0');
    
    return "$hourStr:$minStr $suffix";
  }
  
  /// Formats a DateTime to display either "Today" or "DayOfWeek, DD/MM/YYYY"
  static String formatDateForDisplay(DateTime date) {
    final now = DateTime.now();
    final isToday = (date.year == now.year && 
                     date.month == now.month && 
                     date.day == now.day);
                     
    if (isToday) {
      return "Today";
    } else {
      final dayName = DateFormat('EEEE').format(date);
      final dayNum = date.day.toString().padLeft(2, '0');
      final monthNum = date.month.toString().padLeft(2, '0');
      final yearNum = date.year.toString();
      
      return "$dayName, $dayNum/$monthNum/$yearNum";
    }
  }
  
  /// Formats day number and month in short form (e.g., "31 MAR")
  static String formatDayAndMonth(int day, int month) {
    final monthNames = [
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'
    ];
    
    return "$day ${monthNames[month - 1]}";
  }
}