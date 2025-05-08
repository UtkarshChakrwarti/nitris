class Student {
  final String rollNumber;
  final String name;
  final List<String> originalAttendance;
  List<String> attendance;

  Student({
    required this.rollNumber,
    required this.name,
    required List<String> initialStates,
  })  : originalAttendance = List.from(initialStates),
        attendance = List.from(initialStates);

  factory Student.fromCombined(String combined, List<String> states) {
    final parts = combined.split(' ');
    final roll = parts.first;
    final nm = parts.sublist(1).join(' ').trim();
    return Student(rollNumber: roll, name: nm, initialStates: states);
  }
}