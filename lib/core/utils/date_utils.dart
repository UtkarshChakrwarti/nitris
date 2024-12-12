import 'package:intl/intl.dart';

/// Parses a date string in the format 'yyyy.MM.dd' and returns the month abbreviation.
///
/// If parsing fails, returns 'Invalid Date'.
String getMonthAbbreviation(String dateStr) {
  try {
    // Define the expected input format
    final DateFormat inputFormat = DateFormat('yyyy.MM.dd');
    
    // Parse the input date string to a DateTime object
    DateTime parsedDate = inputFormat.parseStrict(dateStr);
    
    // Define the desired output format (e.g., 'Dec' for December)
    final DateFormat outputFormat = DateFormat('MMM');
    
    // Format the DateTime object to get the month abbreviation
    return outputFormat.format(parsedDate);
  } catch (e) {
    // Handle parsing errors
    print('Error parsing date: $e');
    return 'Invalid Date';
  }
}
