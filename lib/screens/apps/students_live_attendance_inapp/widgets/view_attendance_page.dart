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
  final Color _primaryColor = const Color(0xFFC75E33); // Orange (App bar & buttons)
  final Color _backgroundColor = Colors.white; // White page background
  final Color _cardColor = Colors.white; // White cards
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
    _years = [now.year - 1, now.year]; // Only current and last year

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

      // 3) Load attendance using the current options.
      await _fetchAttendanceData();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load initial data: $e';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchAttendanceData() async {
    if (_rollNo == null || _selectedSubject == null) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _attendanceData = null; // Clear previous data
    });
    try {
      final url =
          "https://api.nitrkl.ac.in/PresentSir/GetStudentAttendance?sectionId=${_selectedSubject!.sectionId}&rollno=$_rollNo&month=$_selectedMonth&year=$_selectedYear";

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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Returns color for each attendance status.
  Color _getAttendanceColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return const Color.fromARGB(255, 0, 162, 0); // Green
      case AttendanceStatus.absent:
        return const Color.fromARGB(255, 234, 30, 27); // Red
      case AttendanceStatus.leave:
        return const Color.fromARGB(255, 62, 52, 196); // Blue-ish
      case AttendanceStatus.presentLate:
        return const Color.fromARGB(255, 212, 170, 3); // Yellow-ish
      case AttendanceStatus.absentLate:
        return const Color.fromARGB(255, 197, 99, 174); // Purple
      case AttendanceStatus.notMarked:
        return Colors.grey;
    }
  }

  int _monthNumber(String month) => _months.indexOf(month) + 1;

  /// Top App Bar.
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

  /// Filters card with reduced spacing.
  Widget _buildFilters() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Subject',
              style: TextStyle(color: Colors.black54, fontSize: 13)),
          const SizedBox(height: 4),
          _buildSubjectDropdown(),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Month',
                        style: TextStyle(color: Colors.black54, fontSize: 13)),
                    const SizedBox(height: 4),
                    _buildMonthDropdown(),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Year',
                        style: TextStyle(color: Colors.black54, fontSize: 13)),
                    const SizedBox(height: 4),
                    _buildYearDropdown(),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Compact Subject dropdown.
  Widget _buildSubjectDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Subject>(
          isDense: true,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: _primaryColor),
          style: TextStyle(color: _primaryColor, fontSize: 13),
          value: _selectedSubject,
          items: _subjects.map((subj) {
            return DropdownMenuItem<Subject>(
              value: subj,
              child: Text('${subj.subjectName} (${subj.subjectCode})'),
            );
          }).toList(),
          onChanged: (val) {
            setState(() {
              _selectedSubject = val;
              _attendanceData = null;
            });
            _fetchAttendanceData();
          },
        ),
      ),
    );
  }

  /// Compact Month dropdown.
  Widget _buildMonthDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isDense: true,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: _primaryColor),
          style: TextStyle(color: _primaryColor, fontSize: 13),
          value: _selectedMonth,
          items: _months.map((month) {
            return DropdownMenuItem<String>(
              value: month,
              child: Text(month),
            );
          }).toList(),
          onChanged: (val) {
            setState(() {
              _selectedMonth = val!;
              _attendanceData = null;
            });
            _fetchAttendanceData();
          },
        ),
      ),
    );
  }

  /// Compact Year dropdown.
  Widget _buildYearDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          isDense: true,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: _primaryColor),
          style: TextStyle(color: _primaryColor, fontSize: 13),
          value: _selectedYear,
          items: _years.map((year) {
            return DropdownMenuItem<int>(
              value: year,
              child: Text(year.toString()),
            );
          }).toList(),
          onChanged: (val) {
            setState(() {
              _selectedYear = val!;
              _attendanceData = null;
            });
            _fetchAttendanceData();
          },
        ),
      ),
    );
  }

  /// Statistics card with a 2×2 grid and a bottom row containing:
  /// - A pill-shaped percentage,
  /// - A progress bar in between, and
  /// - Fraction text on the right.
  Widget _buildStatisticsCard(AttendanceData data) {
    final double percentage =
        data.totalClass > 0 ? (data.totalPresent / data.totalClass) * 100 : 0;
    final Color percentColor = percentage >= 90
        ? const Color(0xFF4CAF50)
        : percentage >= 75
            ? const Color(0xFF8BC34A)
            : percentage >= 65
                ? const Color(0xFFFFC107)
                : const Color(0xFFEF5350);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subject row (icon + subject name/code)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: _primaryColor.withOpacity(0.2)),
                ),
                child: Icon(Icons.menu_book_rounded,
                    color: _primaryColor, size: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${_selectedSubject?.subjectName} (${_selectedSubject?.subjectCode ?? ''})',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // 2×2 grid for stats
          Row(
            children: [
              Expanded(
                child: _buildStatBox(
                  icon: Icons.calendar_today_rounded,
                  label: 'Total Classes',
                  value: '${data.totalClass}',
                  iconColor: Colors.grey.shade600,
                  bgColor: Colors.grey.shade200,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatBox(
                  icon: Icons.check_circle_rounded,
                  label: 'Present',
                  value: '${data.totalPresent}',
                  iconColor: Colors.white,
                  bgColor: const Color(0xFF4CAF50),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildStatBox(
                  icon: Icons.cancel_rounded,
                  label: 'Absent',
                  value: '${data.totalAbsent}',
                  iconColor: Colors.white,
                  bgColor: const Color(0xFFEF5350),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatBox(
                  icon: Icons.pending_rounded,
                  label: 'Leave',
                  value: '${data.totalLeave}',
                  iconColor: Colors.white,
                  bgColor: const Color.fromARGB(255, 7, 65, 255),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Bottom row with pill, progress bar, and fraction text
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Percentage pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: percentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: percentColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Progress bar in between
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: data.totalClass == 0
                        ? 0
                        : data.totalPresent / data.totalClass,
                    minHeight: 6,
                    color: percentColor,
                    backgroundColor: Colors.grey.shade300,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Fraction text on the right
              Text(
                '${data.totalPresent}/${data.totalClass}',
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Helper for a single stat box (icon + label + value)
  Widget _buildStatBox({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// TableCalendar widget with corrected day painting.
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
        // Month-Year heading in a pill shape.
        Container(
          margin: const EdgeInsets.only(top: 8, bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: _primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _primaryColor.withOpacity(0.2)),
          ),
          child: Text(
            '$_selectedMonth $_selectedYear',
            style: TextStyle(
              color: _primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        // Calendar card.
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 3),
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
            enabledDayPredicate: (day) =>
                day.year == _selectedYear && day.month == monthNum,
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
                      fontSize: 11,
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
                    padding: const EdgeInsets.all(4),
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
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 12,
                      ),
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

  /// Legend – using the original legend names.
  Widget _buildLegend() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: _cardColor,
        // borderRadius: BorderRadius.circular(10),
        // border: Border.all(color: Colors.grey.shade200),
       
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // First row with three items
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(
                  'Present', _getAttendanceColor(AttendanceStatus.present)),
              _buildLegendItem(
                  'Absent', _getAttendanceColor(AttendanceStatus.absent)),
              _buildLegendItem('Leave Sanctioned',
                  _getAttendanceColor(AttendanceStatus.leave)),
            ],
          ),
          const SizedBox(height: 6),
          // Second row with one item
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(
                  'Absent  (Late Registration)',
                  _getAttendanceColor(AttendanceStatus.absentLate)),
            ],
          ),
          const SizedBox(height: 6),
          // Third row with one item
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(
                  'Present  (Late Registration)',
                  _getAttendanceColor(AttendanceStatus.presentLate)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
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
                        _buildStatisticsCard(_attendanceData!),
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
