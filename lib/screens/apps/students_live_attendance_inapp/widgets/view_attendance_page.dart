import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:nitris/core/constants/app_colors.dart';
import 'package:flutter/services.dart';

class MyAttendancePage extends StatefulWidget {
  const MyAttendancePage({Key? key}) : super(key: key);

  @override
  _MyAttendancePageState createState() => _MyAttendancePageState();
}

class _MyAttendancePageState extends State<MyAttendancePage> {
  // Filter options
  final List<String> subjects = [
    "Information Theory and Coding (CS6303)",
    "Machine Learning (CS6304)",
    "Distributed Systems (CS6305)",
    "Computer Graphics (CS6306)"
  ];
  final List<String> months = [
    "January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December"
  ];
  final List<int> years = [2024, 2025];

  // Selected values
  String? selectedSubject;
  String? selectedMonth;
  int? selectedYear;

  // Attendance records (mock data)
  final Map<String, AttendanceData> attendanceRecords = {};

  // TableCalendar settings
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    selectedSubject = subjects.first;
    selectedMonth = months[DateTime.now().month - 1];
    selectedYear = DateTime.now().year;
    // Correct order: year, month, day.
    _focusedDay = DateTime(selectedYear!, _getMonthIndex(selectedMonth!), 1);
    _selectedDay = DateTime.now();
    _generateMockData();
  }

  int _getMonthIndex(String month) {
    return months.indexOf(month) + 1;
  }

  void _generateMockData() {
    // Generate attendance records for each subject/month/year combination
    for (String subject in subjects) {
      for (String month in months) {
        for (int year in years) {
          String key = "$subject-$month-$year";
          int totalClasses = 0;
          List<AttendanceDay> days = [];
          
          // Specific data for Information Theory in February 2025
          if (month == "February" && year == 2025 && subject == subjects[0]) {
            totalClasses = 6;
            days = [
              AttendanceDay(day: 5, status: AttendanceStatus.present),
              AttendanceDay(day: 7, status: AttendanceStatus.present),
              AttendanceDay(day: 12, status: AttendanceStatus.present),
              AttendanceDay(day: 14, status: AttendanceStatus.present),
              AttendanceDay(day: 19, status: AttendanceStatus.present),
              AttendanceDay(day: 26, status: AttendanceStatus.present),
            ];
          } 
          // Specific data for Information Theory in March 2025
          else if (month == "March" && year == 2025 && subject == subjects[0]) {
            totalClasses = 8;
            days = [
              AttendanceDay(day: 2, status: AttendanceStatus.present),
              AttendanceDay(day: 5, status: AttendanceStatus.present),
              AttendanceDay(day: 9, status: AttendanceStatus.absent),
              AttendanceDay(day: 12, status: AttendanceStatus.present),
              AttendanceDay(day: 16, status: AttendanceStatus.present),
              AttendanceDay(day: 19, status: AttendanceStatus.present),
              AttendanceDay(day: 23, status: AttendanceStatus.present),
              AttendanceDay(day: 30, status: AttendanceStatus.absent),
            ];
          } 
          // Specific data for Machine Learning in February 2025
          else if (month == "February" && year == 2025 && subject == subjects[1]) {
            totalClasses = 8;
            days = [
              AttendanceDay(day: 4, status: AttendanceStatus.present),
              AttendanceDay(day: 6, status: AttendanceStatus.present),
              AttendanceDay(day: 11, status: AttendanceStatus.absent),
              AttendanceDay(day: 13, status: AttendanceStatus.present),
              AttendanceDay(day: 18, status: AttendanceStatus.present),
              AttendanceDay(day: 20, status: AttendanceStatus.present),
              AttendanceDay(day: 25, status: AttendanceStatus.present),
              AttendanceDay(day: 27, status: AttendanceStatus.present),
            ];
          } 
          // Random data for other combinations
          else {
            final random = DateTime.now().millisecondsSinceEpoch % 100;
            totalClasses = 4 + (random % 5);
            int daysInMonth = _getDaysInMonth(month, year);
            List<int> classDays = [];
            
            for (int i = 1; i <= daysInMonth; i++) {
              if (i % 5 == 0 || i % 7 == 0) {
                if (classDays.length < totalClasses) {
                  classDays.add(i);
                }
              }
            }
            
            int absences = random % 3;
            for (int i = 0; i < totalClasses; i++) {
              AttendanceStatus status = AttendanceStatus.present;
              if (absences > 0 && i % 4 == 0) {
                status = AttendanceStatus.absent;
                absences--;
              }
              days.add(AttendanceDay(day: classDays[i], status: status));
            }
          }
          
          attendanceRecords[key] = AttendanceData(
            studentRollNo: "224CS2026",
            studentName: "RAUSHAN RAJ",
            subjectCode: _getSubjectCode(subject),
            subjectName: subject.split(" (")[0],
            month: month,
            year: year,
            attendanceDays: days,
          );
        }
      }
    }
  }

  // Extracts the subject code from the subject string
  String _getSubjectCode(String subject) {
    final regex = RegExp(r'\((.*?)\)');
    final match = regex.firstMatch(subject);
    return match != null ? match.group(1)! : subject;
  }

  int _getDaysInMonth(String month, int year) {
    int monthIndex = months.indexOf(month) + 1;
    DateTime firstDayNextMonth = monthIndex == 12
        ? DateTime(year + 1, 1, 1)
        : DateTime(year, monthIndex + 1, 1);
    DateTime lastDayCurrentMonth = firstDayNextMonth.subtract(const Duration(days: 1));
    return lastDayCurrentMonth.day;
  }

  AttendanceData? getCurrentAttendanceData() {
    if (selectedSubject == null || selectedMonth == null || selectedYear == null) {
      return null;
    }
    String key = "$selectedSubject-$selectedMonth-$selectedYear";
    return attendanceRecords[key];
  }

  double getAttendancePercentage(AttendanceData data) {
    int totalClasses = data.attendanceDays.length;
    int presentCount = data.attendanceDays.where((d) => d.status == AttendanceStatus.present).length;
    if (totalClasses == 0) return 0;
    return (presentCount / totalClasses) * 100;
  }

  Color getAttendanceStatusColor(double percentage) {
    if (percentage >= 90) return Colors.green;
    if (percentage >= 75) return const Color(0xFFFF9800); // Proper orange
    return Colors.red;
  }

  // Returns events for a given day (both present and absent records)
  List<AttendanceDay> _getEventsForDay(DateTime day, AttendanceData data) {
    return data.attendanceDays.where((ad) => ad.day == day.day).toList();
  }

  // Updates filters to reflect today's date
  void _setToday() {
    final now = DateTime.now();
    setState(() {
      selectedMonth = months[now.month - 1];
      selectedYear = now.year;
      _focusedDay = now;
      _selectedDay = now;
      HapticFeedback.lightImpact();
    });
  }

  // Builds attendance summary cards
  Widget _buildAttendanceSummary(AttendanceData data) {
    double percentage = getAttendancePercentage(data);
    int totalClasses = data.attendanceDays.length;
    int presentClasses = data.attendanceDays.where((d) => d.status == AttendanceStatus.present).length;
    int absentClasses = totalClasses - presentClasses;
    
    Color statusColor = getAttendanceStatusColor(percentage);
    String statusText = percentage >= 75 ? "Good Standing" : "Attendance Low";
    
    return Column(
      children: [
        // Student Info Card
        Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primaryColor.withOpacity(0.2),
                  radius: 40,
                  child: Text(
                    data.studentName.substring(0, 1),
                    style: TextStyle(
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.studentName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Roll No: ${data.studentRollNo}",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Attendance Stats Card
        Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      "Attendance Summary",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildAttendanceStatItem(
                      "Total Classes",
                      totalClasses.toString(),
                      Icons.calendar_month,
                      AppColors.primaryColor,
                    ),
                    _buildAttendanceStatItem(
                      "Present",
                      presentClasses.toString(),
                      Icons.check_circle,
                      Colors.green,
                    ),
                    _buildAttendanceStatItem(
                      "Absent",
                      absentClasses.toString(),
                      Icons.cancel,
                      Colors.red,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Percentage indicator
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Attendance Rate",
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        Text(
                          "${percentage.toStringAsFixed(1)}%",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: percentage / 100,
                        backgroundColor: Colors.grey.shade200,
                        color: statusColor,
                        minHeight: 10,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Minimum required: 75%",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    AttendanceData? currentData = getCurrentAttendanceData();
    if (currentData == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.primaryColor,
          title: const Text(
            "Attendance Dashboard",
            style: TextStyle(color: Colors.white),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(child: Text("No attendance data available")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        title: const Text(
          "Attendance Dashboard",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Today button in the app bar for better visibility
          IconButton(
            icon: const Icon(Icons.today, color: Colors.white),
            onPressed: _setToday,
            tooltip: "Today",
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Subject and month selectors with improved appearance
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Select Filters",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Subject dropdown with icon
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: "Subject",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.book),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        isExpanded: true,
                        value: selectedSubject,
                        items: subjects
                            .map((subject) => DropdownMenuItem<String>(
                                  value: subject,
                                  child: Tooltip(
                                    message: subject,
                                    child: Text(
                                      subject,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedSubject = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      // Date selector row
                      Row(
                        children: [
                          // Month dropdown
                          Expanded(
                            flex: 3,
                            child: DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: "Month",
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.date_range),
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                              value: selectedMonth,
                              isExpanded: true,
                              items: months
                                  .map((month) => DropdownMenuItem<String>(
                                        value: month,
                                        child: Text(
                                          month,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedMonth = value;
                                  if (selectedMonth != null && selectedYear != null) {
                                    _focusedDay = DateTime(selectedYear!, _getMonthIndex(selectedMonth!), 1);
                                  }
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Year dropdown
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<int>(
                              decoration: const InputDecoration(
                                labelText: "Year",
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.calendar_today),
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                              value: selectedYear,
                              items: years
                                  .map((year) => DropdownMenuItem<int>(
                                        value: year,
                                        child: Text(
                                          year.toString(),
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedYear = value;
                                  if (selectedMonth != null && selectedYear != null) {
                                    _focusedDay = DateTime(selectedYear!, _getMonthIndex(selectedMonth!), 1);
                                  }
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Calendar with attendance markers wrapped in a SizedBox
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_month, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            "Attendance Calendar",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppColors.primaryColor,
                            ),
                          ),
                          const Spacer(),
                          // Legend for calendar
                          Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const SizedBox(width: 8),
                              Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Wrap TableCalendar in a SizedBox with a fixed height.
                      SizedBox(
                        height: 400,
                        child: TableCalendar(
                          firstDay: DateTime.utc(2020, 1, 1),
                          lastDay: DateTime.utc(2030, 12, 31),
                          focusedDay: _focusedDay,
                          calendarFormat: _calendarFormat,
                          selectedDayPredicate: (day) {
                            return isSameDay(_selectedDay, day);
                          },
                          onDaySelected: (selectedDay, focusedDay) {
                            if (!isSameDay(_selectedDay, selectedDay)) {
                              setState(() {
                                _selectedDay = selectedDay;
                                _focusedDay = focusedDay;
                              });
                            }
                          },
                          availableCalendarFormats: const {CalendarFormat.month: 'Month'},
                          onFormatChanged: (format) {
                            setState(() {
                              _calendarFormat = format;
                            });
                          },
                          onPageChanged: (focusedDay) {
                            setState(() {
                              _focusedDay = focusedDay;
                              selectedMonth = months[focusedDay.month - 1];
                              selectedYear = focusedDay.year;
                            });
                          },
                          headerStyle: HeaderStyle(
                            formatButtonVisible: false,
                            titleCentered: true,
                            titleTextStyle: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryColor,
                            ),
                            leftChevronIcon: Icon(
                              Icons.chevron_left,
                              color: AppColors.primaryColor,
                            ),
                            rightChevronIcon: Icon(
                              Icons.chevron_right,
                              color: AppColors.primaryColor,
                            ),
                          ),
                          daysOfWeekStyle: DaysOfWeekStyle(
                            weekdayStyle: TextStyle(
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            weekendStyle: TextStyle(
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          calendarStyle: CalendarStyle(
                            defaultTextStyle: const TextStyle(fontSize: 14),
                            weekendTextStyle: const TextStyle(fontSize: 14),
                            outsideTextStyle: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade400,
                            ),
                            todayDecoration: BoxDecoration(
                              color: AppColors.primaryColor.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            todayTextStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                            selectedDecoration: BoxDecoration(
                              color: AppColors.primaryColor,
                              shape: BoxShape.circle,
                            ),
                            markersMaxCount: 1,
                            markerMargin: const EdgeInsets.only(top: 6),
                          ),
                          // Custom marker for attendance status
                          calendarBuilders: CalendarBuilders(
                            markerBuilder: (context, date, events) {
                              if (events.isNotEmpty) {
                                bool hasAbsent = false;
                                for (var event in events) {
                                  if (event!.status == AttendanceStatus.absent) {
                                    hasAbsent = true;
                                    break;
                                  }
                                }
                                Color markerColor = hasAbsent ? Colors.red : Colors.green;
                                return Positioned(
                                  bottom: 1,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    margin: const EdgeInsets.all(1),
                                    decoration: BoxDecoration(
                                      color: markerColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                );
                              }
                              return null;
                            },
                          ),
                          eventLoader: (day) {
                            return _getEventsForDay(day, currentData);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Attendance summary
              _buildAttendanceSummary(currentData),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _setToday,
        backgroundColor: AppColors.primaryColor,
        child: const Icon(Icons.today, color: Colors.white),
        tooltip: "Go to Today",
      ),
    );
  }
}

extension on Object {
  get status => null;
}

// Models

enum AttendanceStatus { present, absent }

class AttendanceDay {
  final int day;
  final AttendanceStatus status;
  AttendanceDay({required this.day, required this.status});
}

class AttendanceData {
  final String studentRollNo;
  final String studentName;
  final String subjectCode;
  final String subjectName;
  final String month;
  final int year;
  final List<AttendanceDay> attendanceDays;
  
  AttendanceData({
    required this.studentRollNo,
    required this.studentName,
    required this.subjectCode,
    required this.subjectName,
    required this.month,
    required this.year,
    required this.attendanceDays,
  });
}
