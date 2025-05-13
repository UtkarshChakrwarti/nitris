import 'package:intl/intl.dart';

/// Attempts to parse a date string using multiple formats
/// and returns the month abbreviation.
/// If parsing fails, returns 'Invalid Date'.
String getMonthAbbreviation(String dateStr) {
  DateTime? parsedDate;
  try {
    // First, try the built-in ISO 8601 parser.
    parsedDate = DateTime.parse(dateStr);
  } catch (e) {
    // If ISO parsing fails, try the expected format with dots.
    try {
      final DateFormat inputFormat = DateFormat('yyyy.MM.dd');
      parsedDate = inputFormat.parseStrict(dateStr);
    } catch (e2) {
      print('Error parsing date: $e2');
      return 'Invalid Date';
    }
  }

  // Once parsed, format to get the month abbreviation.
  final DateFormat outputFormat = DateFormat('MMM');
  return outputFormat.format(parsedDate);
}
