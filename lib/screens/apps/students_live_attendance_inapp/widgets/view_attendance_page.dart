import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:nitris/core/enums/attendance_status.dart';
import 'package:nitris/core/services/local/local_storage_service.dart';
import 'package:table_calendar/table_calendar.dart';

// Adjust these imports to match your actual structure
import 'package:nitris/core/models/Attendance_data.dart';
import 'package:nitris/core/models/subject.dart';
import 'package:nitris/core/services/remote/api_service.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage>
    with SingleTickerProviderStateMixin {
  AttendanceData? _attendanceData;
  bool _isLoading = false;
  String _errorMessage = '';

  late AnimationController _controller;
  late String _selectedMonth;
  late int _selectedYear;
  List<Subject> _subjects = [];
  Subject? _selectedSubject;
  String? _rollNo;

  final List<String> _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];
  late final List<int> _years;

  // COLORS:
  final Color _primaryColor =
      const Color(0xFFC75E33); // Orange (App bar & buttons)
  final Color _backgroundColor = Colors.white; // White page background
  final Color _cardColor = Colors.white; // White cards
  final Color _lightText = Colors.black54;
  final Color _errorColor = const Color(0xFFB3261E);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    final now = DateTime.now();
    _selectedMonth = _months[now.month - 1];
    _selectedYear = now.year;
    _years = List.generate(21, (i) => now.year - 10 + i);

    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      // 1) Retrieve roll number
      final rollNo = await LocalStorageService.getCurrentUserEmpCode();
      if (rollNo == null) {
        setState(() {
          _errorMessage = 'Roll number not found. Please log in again.';
        });
        return;
      }

      // 2) Fetch subject list
      final subjectResponse = await ApiService().getStudentSubjects(rollNo);

      setState(() {
        _rollNo = rollNo;
        _subjects = subjectResponse.data;
        if (_subjects.isNotEmpty) {
          _selectedSubject = _subjects[0];
        }
      });

      // 3) Load attendance
      await _fetchAttendanceData();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load initial data: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _fetchAttendanceData() async {
    if (_rollNo == null || _selectedSubject == null) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final url = "https://api.nitrkl.ac.in/PresentSir/GetStudentAttendance?"
          "sectionId=${_selectedSubject!.sectionId}"
          "&rollno=$_rollNo"
          "&month=$_selectedMonth"
          "&year=$_selectedYear";

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        _attendanceData = AttendanceData.fromJson(decoded);
        _controller.forward(from: 0.0);
      } else {
        _errorMessage = "Error: ${response.statusCode}";
      }
    } catch (e) {
      _errorMessage = 'Failed to load attendance data: $e';
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Returns color for each attendance status
  Color _getAttendanceColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return const Color.fromARGB(255, 0, 162, 0); // Green
      case AttendanceStatus.leave:
        return const Color.fromARGB(255, 62, 52, 196); // Blue-ish
      case AttendanceStatus.absent:
        return const Color.fromARGB(255, 234, 30, 27); // Red
      case AttendanceStatus.presentLate:
        return const Color.fromARGB(255, 212, 170, 3); // Yellow-ish
      case AttendanceStatus.absentLate:
        return const Color(0xFF9575CD); // Purple
      case AttendanceStatus.notMarked:
        return Colors.grey;
    }
  }

  int _monthNumber(String month) => _months.indexOf(month) + 1;

  /// Build the top app bar: back arrow + title + two action buttons (share & refresh)
  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: _primaryColor,
      elevation: 2,
      title: const Text(
        'View Attendance',
        style: TextStyle(
            fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          onPressed: _fetchAttendanceData,
          tooltip: 'Refresh Data',
        ),
      ],
    );
  }

  /// Build the "Search Filters" card with improved styling
  Widget _buildFilters() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _primaryColor.withOpacity(0.2)),
                ),
                child:
                    Icon(Icons.search_rounded, color: _primaryColor, size: 22),
              ),
              const SizedBox(width: 14),
              Text(
                'Search',
                style: TextStyle(
                  color: _primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Subject dropdown
          const Text('Subject', style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 6),
          _buildSubjectDropdown(),
          const SizedBox(height: 18),

          // Month & Year row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Month',
                        style: TextStyle(color: Colors.black54)),
                    const SizedBox(height: 6),
                    _buildMonthDropdown(),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Year', style: TextStyle(color: Colors.black54)),
                    const SizedBox(height: 6),
                    _buildYearDropdown(),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),

          // Apply Filters button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _fetchAttendanceData,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 3,
              ),
              child: const Text(
                'Apply Filters',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Subject>(
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: _primaryColor),
          style: TextStyle(color: _primaryColor, fontSize: 15),
          value: _selectedSubject,
          items: _subjects.map((subj) {
            return DropdownMenuItem<Subject>(
              value: subj,
              child: Text('${subj.subjectName} (${subj.subjectCode})'),
            );
          }).toList(),
          onChanged: (val) => setState(() => _selectedSubject = val),
        ),
      ),
    );
  }

  Widget _buildMonthDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: _primaryColor),
          style: TextStyle(color: _primaryColor, fontSize: 15),
          value: _selectedMonth,
          items: _months.map((month) {
            return DropdownMenuItem<String>(
              value: month,
              child: Text(month),
            );
          }).toList(),
          onChanged: (val) => setState(() => _selectedMonth = val!),
        ),
      ),
    );
  }

  Widget _buildYearDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: _primaryColor),
          style: TextStyle(color: _primaryColor, fontSize: 15),
          value: _selectedYear,
          items: _years.map((year) {
            return DropdownMenuItem<int>(
              value: year,
              child: Text(year.toString()),
            );
          }).toList(),
          onChanged: (val) => setState(() => _selectedYear = val!),
        ),
      ),
    );
  }

  /// Displays total classes, present/absent with circles, plus attendance %
  Widget _buildStatistics(AttendanceData data) {
    final double percentage =
        data.totalClass > 0 ? (data.totalPresent / data.totalClass) * 100 : 0;

    // Determine the percentage color
    final Color percentColor = percentage >= 90
        ? const Color(0xFF4CAF50)
        : percentage >= 75
            ? const Color(0xFF8BC34A)
            : percentage >= 65
                ? const Color(0xFFFFC107)
                : const Color(0xFFEF5350);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subject name row
          Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: _primaryColor.withOpacity(0.2)),
                ),
                child: Icon(Icons.menu_book_rounded,
                    color: _primaryColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  '${data.subjectName} (${_selectedSubject?.subjectCode ?? ''})',
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Statistics row: total classes, present, absent
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.library_books_rounded, size: 26),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${data.totalClass}\nClasses',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
              Column(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: const BoxDecoration(
                      color: Color(0xFF4CAF50),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_circle_rounded,
                        color: Colors.white, size: 26),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${data.totalPresent}\nPresent',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
              Column(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF5350),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.cancel_rounded,
                        color: Colors.white, size: 26),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${data.totalAbsent}\nAbsent',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Attendance percentage display
          Text(
            'Attendance Percentage',
            style: TextStyle(
              color: _lightText,
              fontWeight: FontWeight.w500,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: percentColor,
                ),
              ),
              Text(
                '${data.totalPresent}/${data.totalClass}',
                style: const TextStyle(fontSize: 16, color: Colors.black54),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Animated progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: data.totalClass == 0
                  ? 0
                  : data.totalPresent / data.totalClass,
              minHeight: 8,
              color: percentColor,
              backgroundColor: Colors.grey.shade300,
            ),
          ),
        ],
      ),
    );
  }

  /// A non-swipeable TableCalendar with color-coded attendance and refined day styling
  Widget _buildTableCalendar() {
    if (_attendanceData == null) return const SizedBox();

    final Map<DateTime, AttendanceStatus> attendanceMap = {};
    final int monthNum = _monthNumber(_selectedMonth);
    for (final dayData in _attendanceData!.attendanceDays) {
      final date = DateTime(_selectedYear, monthNum, dayData.day);
      attendanceMap[date] = dayData.status;
    }
    final focusedDay = DateTime(_selectedYear, monthNum, 1);

    AttendanceStatus? _getStatusForDay(DateTime day) {
      for (final entry in attendanceMap.entries) {
        if (isSameDay(entry.key, day)) return entry.value;
      }
      return null;
    }

    return Column(
      children: [
        // Heading with Month and Year in a pill-shaped background
        Container(
          margin: const EdgeInsets.only(bottom: 12, top: 10),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: _primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: _primaryColor.withOpacity(0.2)),
          ),
          child: Text(
            '$_selectedMonth $_selectedYear',
            style: TextStyle(
              color: _primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 17,
            ),
          ),
        ),
        // Calendar card with a modern, responsive look
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              )
            ],
          ),
          child: TableCalendar(
            firstDay: DateTime(_selectedYear - 10, 1, 1),
            lastDay: DateTime(_selectedYear + 10, 12, 31),
            focusedDay: focusedDay,
            calendarFormat: CalendarFormat.month,
            availableCalendarFormats: const {CalendarFormat.month: 'Month'},
            availableGestures: AvailableGestures.none,
            startingDayOfWeek: StartingDayOfWeek.monday,
            headerVisible: false,
            daysOfWeekVisible: true,
            enabledDayPredicate: (day) {
              return day.year == _selectedYear && day.month == monthNum;
            },
            calendarStyle: const CalendarStyle(
              isTodayHighlighted: false,
              outsideDaysVisible: false,
            ),
            calendarBuilders: CalendarBuilders(
              dowBuilder: (context, day) {
                final text = DateFormat.E().format(day);
                return Center(
                  child: Text(
                    text,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                );
              },
              defaultBuilder: (context, day, focusedDay) {
                final status = _getStatusForDay(day);
                if (status != null) {
                  final color = _getAttendanceColor(status);
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.all(2),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${day.day}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                } else {
                  return Center(
                    child: Text(
                      '${day.day}',
                      style:
                          const TextStyle(color: Colors.black87, fontSize: 12),
                    ),
                  );
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  /// Displays a simple legend for attendance statuses
  Widget _buildLegend() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 12,
        children: [
          _buildLegendItem(
              'Present', _getAttendanceColor(AttendanceStatus.present)),
          _buildLegendItem(
              'Absent', _getAttendanceColor(AttendanceStatus.absent)),
          _buildLegendItem(
              'Leave', _getAttendanceColor(AttendanceStatus.leave)),
          _buildLegendItem('Late Present',
              _getAttendanceColor(AttendanceStatus.presentLate)),
          _buildLegendItem(
              'Late Absent', _getAttendanceColor(AttendanceStatus.absentLate)),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Text(
                    _errorMessage,
                    style: TextStyle(color: _errorColor),
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildFilters(),
                      if (_attendanceData != null) ...[
                        _buildStatistics(_attendanceData!),
                        const SizedBox(height: 10),
                        _buildTableCalendar(),
                        _buildLegend(),
                      ],
                    ],
                  ),
                ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
