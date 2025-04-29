import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:just_the_tooltip/just_the_tooltip.dart';
import 'package:nitris/core/constants/app_colors.dart';
import 'package:nitris/core/models/attendance_record.dart';
import 'package:nitris/core/services/local/local_storage_service.dart';
import 'package:nitris/core/services/remote/api_service.dart';
import 'package:nitris/screens/apps/biometric_student_inapp/widgets/attendance_app_bar.dart';
import 'package:nitris/screens/apps/biometric_student_inapp/widgets/attendance_info_dialog.dart';
import 'package:nitris/screens/apps/biometric_student_inapp/widgets/date_formatter.dart';
import 'package:nitris/screens/apps/biometric_student_inapp/widgets/legend_item.dart';
import 'package:nitris/screens/apps/biometric_student_inapp/widgets/stat_card.dart';

class StudentAttendancePageBiometric extends StatefulWidget {
  const StudentAttendancePageBiometric({super.key});

  @override
  State<StudentAttendancePageBiometric> createState() =>
      _StudentAttendancePageBiometricState();
}

class _StudentAttendancePageBiometricState
    extends State<StudentAttendancePageBiometric> {
  ApiService apiService = ApiService();

  // Student information
  String _studentName = 'Student';
  String _rollNumber = '';

  // Date and time state
  DateTime _selectedDate = DateTime.now();
  String _timeIn = '--:--';
  String _timeOut = '--:--';

  // Attendance stats
  int presentCount = 0;
  int absentCount = 0;
  int leaveAvailed = 0;
  int leaveRemaining = 0;

  // Calendar filters
  String _selectedMonth = '';
  int _selectedYear = DateTime.now().year;
  final List<String> months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  late final List<int> years;

  // Loading and error states
  bool _isInitialLoading = false;
  bool _isCalendarLoading = false;
  bool _hasNetworkError = false;
  // ignore: unused_field, prefer_final_fields
  String _errorMessage = '';

  // Data store
  List<AttendanceRecord> _attendanceRecords = [];

  Timer? _debounceTimer;

  // Avatar cache
  Uint8List? _cachedAvatarImage;
  bool _avatarLoadAttempted = false;

  @override
  void initState() {
    super.initState();
    _selectedMonth = months[DateTime.now().month - 1];
    years = List.generate(5, (i) => DateTime.now().year - i);
    _loadStudentData();
    _loadAvatarImage();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadAvatarImage() async {
    if (_avatarLoadAttempted) return;
    _avatarLoadAttempted = true;
    try {
      final avatarBase64 = await LocalStorageService.getCurrentUserAvatar();
      if (avatarBase64 != null && avatarBase64.isNotEmpty) {
        if (mounted) {
          setState(() {
            _cachedAvatarImage = base64Decode(avatarBase64);
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _loadStudentData() async {
    try {
      final empcode = await LocalStorageService.getCurrentUserEmpCode();
      final fullName = await LocalStorageService.getCurrentUserFullName();
      if (!mounted) return;
      setState(() {
        _rollNumber = empcode ?? '';
        _studentName = fullName != null
            ? fullName.replaceAll(RegExp(r'\s+'), ' ').trim()
            : 'Student';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _rollNumber = '';
        _studentName = 'Student';
      });
    } finally {
      _fetchInitialData();
    }
  }

  Future<void> _fetchInitialData() async {
    if (_isInitialLoading) return;
    setState(() {
      _isInitialLoading = true;
      _hasNetworkError = false;
    });

    final monthIdx = months.indexOf(_selectedMonth) + 1;

    try {
      final summary = await ApiService().getStudentAttendance(
          rollNo: _rollNumber, month: monthIdx, year: _selectedYear);

      final stats = _calculateStats(summary.records);
      final todayRec = _getTodayRecord(summary.records);

      if (!mounted) return;
      setState(() {
        _attendanceRecords = summary.records;
        presentCount = stats['present']!;
        absentCount = stats['absent']!;
        leaveAvailed = summary.leaveAvailed;
        leaveRemaining = summary.leaveRemaining;

        if (DateTime.now().month == monthIdx &&
            DateTime.now().year == _selectedYear) {
          _selectedDate = DateTime.now();
        } else {
          final firstDay =
              summary.records.isNotEmpty ? summary.records.first.day : 1;
          _selectedDate = DateTime(_selectedYear, monthIdx, firstDay);
        }

        _timeIn = todayRec.inTime.isNotEmpty ? todayRec.inTime : '--:--';
        _timeOut = todayRec.outTime.isNotEmpty ? todayRec.outTime : '--:--';
      });
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().contains('SocketException')
          ? 'No internet connection. Please check your network and try again.'
          : 'Failed to load attendance data: ${e.toString()}';
      setState(() => _hasNetworkError = true);
      _showErrorSnackBar(msg, _fetchInitialData);
    } finally {
      if (mounted) setState(() => _isInitialLoading = false);
    }
  }

  Future<void> _fetchCalendarData() async {
    if (_isCalendarLoading) return;
    setState(() => _isCalendarLoading = true);

    final monthIdx = months.indexOf(_selectedMonth) + 1;
    try {
      final summary = await ApiService().getStudentAttendance(
          rollNo: _rollNumber, month: monthIdx, year: _selectedYear);

      final stats = _calculateStats(summary.records);

      if (!mounted) return;
      setState(() {
        _attendanceRecords = summary.records;
        presentCount = stats['present']!;
        absentCount = stats['absent']!;
        leaveAvailed = summary.leaveAvailed;
        leaveRemaining = summary.leaveRemaining;

        if (summary.records.isNotEmpty) {
          final firstDay = summary.records.first.day;
          _selectedDate = DateTime(_selectedYear, monthIdx, firstDay);
          final rec = _getRecordForDay(firstDay);
          _timeIn = (rec?.inTime.isNotEmpty ?? false) ? rec!.inTime : '--:--';
          _timeOut =
              (rec?.outTime.isNotEmpty ?? false) ? rec!.outTime : '--:--';
        }

        _hasNetworkError = false;
      });
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().contains('SocketException')
          ? 'Network error. Calendar data could not be loaded.'
          : 'Failed to update calendar data: ${e.toString()}';
      setState(() => _hasNetworkError = true);
      _showErrorSnackBar(msg, _fetchCalendarData,
          duration: const Duration(seconds: 3));
    } finally {
      if (mounted) setState(() => _isCalendarLoading = false);
    }
  }

  void _showErrorSnackBar(String message, VoidCallback onRetry,
      {Duration? duration}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: duration ?? const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: onRetry,
        ),
      ),
    );
  }

  void _refreshData() {
    _debounceTimer?.cancel();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Refreshing attendance data...',
          style: TextStyle(fontSize: 14),
        ),
        backgroundColor: AppColors.primaryColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
      ),
    );

    setState(() {
      _selectedDate = DateTime.now();
      _selectedMonth = months[DateTime.now().month - 1];
      _selectedYear = DateTime.now().year;
    });

    _debounceTimer =
        Timer(const Duration(milliseconds: 300), _fetchInitialData);
  }

  void _onMonthYearChanged() {
    _debounceTimer?.cancel();
    _debounceTimer =
        Timer(const Duration(milliseconds: 300), _fetchCalendarData);
  }

  AttendanceRecord _getTodayRecord(List<AttendanceRecord> records) {
    try {
      return records.firstWhere(
        (r) => r.day == DateTime.now().day,
        orElse: () => AttendanceRecord.empty(),
      );
    } catch (_) {
      return AttendanceRecord.empty();
    }
  }

  Map<String, int> _calculateStats(List<AttendanceRecord> recs) {
    var pres = 0, abs = 0;
    for (var r in recs) {
      if (r.isPresent) pres++;
      if (r.isAbsent) abs++;
    }
    return {'present': pres, 'absent': abs};
  }

  AttendanceRecord? _getRecordForDay(int day) {
    try {
      return _attendanceRecords.firstWhere((r) => r.day == day);
    } catch (_) {
      return null;
    }
  }

  IconData _getStatusIcon(int day) {
    final record = _getRecordForDay(day);
    if (record == null) return Icons.help_outline;
    if (record.isHoliday || record.isWeekend) return Icons.beach_access;
    if (record.isPresent) return Icons.check_circle;
    if (record.isAbsent) return Icons.clear;
    if (record.isFutureDate) return Icons.schedule;
    return Icons.help_outline;
  }

  Color _getStatusColor(int day) {
    final record = _getRecordForDay(day);
    if (record == null) return Colors.grey;

    // 1. Holiday / Weekend
    if (record.isHoliday || record.isWeekend) {
      return AppColors.blueStatus;
    }

    // 2. if one signature
    if (record.message == 'One Signature') {
      return AppColors.cyanStatus;
    }

    // 2. Approval Pending
    if (record.message == 'Approval Pending') {
      final hasIn = record.inTime.isNotEmpty;
      final hasOut = record.outTime.isNotEmpty;
      // both in+out → fully approved (purple)
      if (hasIn && hasOut) {
        return AppColors.purpleStatus;
      }
      // only one of the two → one signature (cyan)
      return AppColors.cyanStatus;
    }

    // 3. Normal Present / Absent
    if (record.isPresent) return AppColors.greenStatus;
    if (record.isAbsent) return AppColors.yellowStatus;

    // fallback
    return Colors.grey;
  }

  void _onDayTapped(int day) {
    final monthIndex = months.indexOf(_selectedMonth) + 1;
    final record = _getRecordForDay(day);
    setState(() {
      _selectedDate = DateTime(_selectedYear, monthIndex, day);
      _timeIn = (record?.inTime.isNotEmpty ?? false) ? record!.inTime : '--:--';
      _timeOut =
          (record?.outTime.isNotEmpty ?? false) ? record!.outTime : '--:--';
    });
  }

  @override
  Widget build(BuildContext context) {
    // loading or error screens...
    if (_isInitialLoading && _attendanceRecords.isEmpty) {
      return Scaffold(
        appBar: AttendanceAppBar(
          title: 'Biometric Attendance',
          onBackPressed: () => Navigator.pop(context),
          onRefreshPressed: _refreshData,
          onInfoPressed: () => showDialog(
            context: context,
            builder: (_) => AttendanceInfoDialog(),
          ),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading attendance data...'),
            ],
          ),
        ),
      );
    }
    if (_hasNetworkError && _attendanceRecords.isEmpty) {
      return Scaffold(
        appBar: AttendanceAppBar(
          title: 'Biometric Attendance',
          onBackPressed: () => Navigator.pop(context),
          onRefreshPressed: _refreshData,
          onInfoPressed: () => showDialog(
            context: context,
            builder: (_) => AttendanceInfoDialog(),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.signal_wifi_off, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'No internet connection',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please check your network settings and try again',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _fetchInitialData,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // main content
    return Scaffold(
      appBar: AttendanceAppBar(
        title: 'Biometric Attendance',
        onBackPressed: () => Navigator.pop(context),
        onRefreshPressed: _refreshData,
        onInfoPressed: () => showDialog(
          context: context,
          builder: (_) => AttendanceInfoDialog(),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: _buildProfileBlock(),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await _fetchInitialData();
              },
              color: AppColors.primaryColor,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: [
                    _buildDailyStatusBlock(),
                    _buildMonthlyStatusBlock(),
                    _buildCalendarBlock(),
                    _buildLegendBlock(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Helper for each leave tile
  Widget _buildLeaveTile(String label, String value, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w400, color: color)),
          Text(value,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryColor)),
        ],
      ),
    );
  }

  /// Elegant profile block with 3‐line name and deeper shadow/gradient
  Widget _buildProfileBlock() {
    // converting in uppercase all letters
    _studentName = _studentName.toUpperCase();

    final parts = _studentName.split(' ');
    final lines = <String>[];
    if (parts.isNotEmpty) lines.add(parts[0]);
    if (parts.length > 1) lines.add(parts[1]);
    if (parts.length > 2) {
      var third = parts[2];
      if (parts.length > 3) third = third + '…';
      lines.add(third);
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 242, 234, 234),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondaryColor.withOpacity(.08),
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: AppColors.primaryColor.withOpacity(.05),
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── AVATAR + ROLL ──
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primaryColor, width: 1.5),
                ),
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primaryColor.withOpacity(.1),
                  backgroundImage: _cachedAvatarImage != null
                      ? MemoryImage(_cachedAvatarImage!)
                      : null,
                  child: _cachedAvatarImage == null
                      ? const Icon(Icons.person,
                          size: 28, color: AppColors.primaryColor)
                      : null,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _rollNumber,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryColor,
                ),
              ),
            ],
          ),

          const SizedBox(width: 18),

          // ── NAME (3 rows) ──
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: List.generate(lines.length, (i) {
                return Text(
                  lines[i],
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                );
              }),
            ),
          ),

          const SizedBox(width: 18),

          // ── LEAVE TILES (vertical) ──
          Expanded(
            flex: 3,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildLeaveTile(
                  'Leave Availed',
                  leaveAvailed.toString(),
                  AppColors.darkGreen,
                ),
                const SizedBox(height: 10),
                _buildLeaveTile(
                  'Remaining Leaves',
                  leaveRemaining.toString(),
                  AppColors.darkRed,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Daily status block
  Widget _buildDailyStatusBlock() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 3)
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Daily Status',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textColor,
                ),
              ),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: AppColors.primaryColor,
                  ),
                  const SizedBox(width: 4),
                  FormattedDateLabel(date: _selectedDate),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildTimeCard('Time In', _timeIn, AppColors.darkGreen),
              const SizedBox(width: 8),
              _buildTimeCard('Time Out', _timeOut, AppColors.darkRed),
            ],
          ),
        ],
      ),
    );
  }

  /// Monthly status block (filters + Present/Absent)
  Widget _buildMonthlyStatusBlock() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 3)
        ],
      ),
      child: Column(
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Monthly Status',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textColor)),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildMonthDropdown(),
              const SizedBox(width: 8),
              _buildYearDropdown(),
            ],
          ),
          const SizedBox(height: 12),
          _isCalendarLoading
              ? Opacity(
                  opacity: 0.6,
                  child: Row(
                    children: [
                      StatCard(
                        title: 'Present',
                        value: '...',
                        color: AppColors.greenStatus.withOpacity(.5),
                        icon: Icons.check_circle_outline,
                      ),
                      const SizedBox(width: 6),
                      StatCard(
                        title: 'Absent',
                        value: '...',
                        color: AppColors.yellowStatus.withOpacity(.5),
                        icon: Icons.cancel_outlined,
                      ),
                    ],
                  ),
                )
              : Row(
                  children: [
                    StatCard(
                      title: 'Present',
                      value: '$presentCount',
                      color: AppColors.greenStatus,
                      icon: Icons.check_circle_outline,
                    ),
                    const SizedBox(width: 6),
                    StatCard(
                      title: 'Absent',
                      value: '$absentCount',
                      color: AppColors.yellowStatus,
                      icon: Icons.cancel_outlined,
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  /// Calendar block
  Widget _buildCalendarBlock() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 6)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$_selectedMonth $_selectedYear',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.textColor)),
              Row(
                children: [
                  const Icon(Icons.calendar_today,
                      size: 14, color: AppColors.primaryColor),
                  const SizedBox(width: 4),
                  const Text('Attendance Calendar',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          _isCalendarLoading
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Column(
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text('Loading calendar data...',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 12)),
                      ],
                    ),
                  ),
                )
              : _buildCompactCalendar(),
        ],
      ),
    );
  }

  /// Legend block
  Widget _buildLegendBlock() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 10,
        runSpacing: 6,
        alignment: WrapAlignment.center,
        children: const [
          LegendItem(color: AppColors.greenStatus, label: 'Present'),
          LegendItem(color: AppColors.yellowStatus, label: 'Absent'),
          LegendItem(color: AppColors.redStatus, label: 'Absent (supervisor)'),
          LegendItem(color: AppColors.purpleStatus, label: 'Approval Pending'),
          LegendItem(color: AppColors.cyanStatus, label: 'One Signature'),
          LegendItem(color: AppColors.blueStatus, label: 'Holiday / Leave'),
        ],
      ),
    );
  }

  /// Compact calendar view
  Widget _buildCompactCalendar() {
    final monthIndex = months.indexOf(_selectedMonth) + 1;
    final daysInMonth = DateTime(_selectedYear, monthIndex + 1, 0).day;
    final firstWeekday = DateTime(_selectedYear, monthIndex, 1).weekday;
    final total = daysInMonth + firstWeekday - 1;
    final rows = (total / 7).ceil();
    final itemCount = rows * 7;

    if (_hasNetworkError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Icon(Icons.wifi_off_rounded, size: 32, color: Colors.grey),
              const SizedBox(height: 8),
              Text('Calendar data unavailable',
                  style: TextStyle(
                      color: Colors.grey[700], fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _fetchCalendarData,
                icon: const Icon(Icons.refresh, size: 14),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
              .map((d) => SizedBox(
                  width: 25,
                  child: Text(d,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey))))
              .toList(),
        ),
        const SizedBox(height: 4),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            crossAxisSpacing: 3,
            mainAxisSpacing: 3,
          ),
          itemCount: itemCount,
          itemBuilder: (_, i) {
            final offset = firstWeekday - 1;
            final day = i - offset + 1;
            if (day < 1 || day > daysInMonth) return const SizedBox();
            return _buildCalendarDay(day, monthIndex);
          },
        ),
      ],
    );
  }

  /// Single day cell with long-press tooltip
  Widget _buildCalendarDay(int day, int monthIndex) {
    final record = _getRecordForDay(day);
    final isFuture = record?.isFutureDate ?? false;
    final now = DateTime.now();
    final isToday =
        day == now.day && monthIndex == now.month && _selectedYear == now.year;
    final isSelected = !isFuture &&
        day == _selectedDate.day &&
        monthIndex == _selectedDate.month &&
        _selectedYear == now.year;

    final baseColor = _getStatusColor(day);
    final backgroundColor = isFuture
        ? Colors.grey.withOpacity(.15)
        : isSelected
            ? AppColors.primaryColor.withOpacity(.2)
            : baseColor.withOpacity(.15);
    final border = isSelected
        ? Border.all(color: AppColors.primaryColor, width: 2)
        : isToday
            ? Border.all(color: AppColors.primaryColor.withOpacity(.5))
            : null;

    // prepare tooltip data
    final inTime =
        (record?.inTime.isNotEmpty ?? false) ? record!.inTime : '--:--';
    final outTime =
        (record?.outTime.isNotEmpty ?? false) ? record!.outTime : '--:--';
    final statusLabel = record?.message ?? '';
    final holidayName = record?.holidayName ?? '';

    return JustTheTooltip(
      triggerMode: TooltipTriggerMode.longPress,
      tailLength: 10,
      tailBaseWidth: 16,
      backgroundColor: AppColors.primaryColor,
      borderRadius: BorderRadius.circular(8),

      // Constrain the entire tooltip content
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 200),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (record?.isHoliday ?? false) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.beach_access,
                        size: 16, color: Colors.white.withOpacity(0.9)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Holiday: $holidayName',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ] else if (record?.isWeekend ?? false) ...[
                Row(
                  children: [
                    Icon(Icons.weekend,
                        size: 16, color: Colors.white.withOpacity(0.9)),
                    const SizedBox(width: 6),
                    const Expanded(
                      child: Text('Weekend',
                          style: TextStyle(color: Colors.white, fontSize: 14)),
                    ),
                  ],
                ),
              ] else ...[
                Row(
                  children: [
                    Icon(Icons.login,
                        size: 16, color: Colors.white.withOpacity(0.9)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text('In: $inTime',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 14)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.logout,
                        size: 16, color: Colors.white.withOpacity(0.9)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text('Out: $outTime',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 14)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.info,
                        size: 16, color: Colors.white.withOpacity(0.9)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text('Status: $statusLabel',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 14)),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),

      child: GestureDetector(
        onTap: isFuture ? null : () => _onDayTapped(day),
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(6),
            border: border,
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$day',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isFuture
                      ? Colors.grey
                      : isSelected
                          ? AppColors.primaryColor
                          : AppColors.textColor,
                ),
              ),
              Icon(
                _getStatusIcon(day),
                size: 10,
                color: isFuture ? Colors.grey : baseColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Time card for in/out
  Widget _buildTimeCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.access_time, size: 14, color: color),
            const SizedBox(width: 6),
            Text('$label ',
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
            Text(value,
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  /// Month dropdown
  Widget _buildMonthDropdown() {
    return Expanded(
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _selectedMonth,
            isExpanded: true,
            icon: const Icon(Icons.keyboard_arrow_down, size: 16),
            items: months
                .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                .toList(),
            onChanged: (v) {
              if (v != null && v != _selectedMonth) {
                setState(() => _selectedMonth = v);
                _onMonthYearChanged();
              }
            },
          ),
        ),
      ),
    );
  }

  /// Year dropdown
  Widget _buildYearDropdown() {
    return Expanded(
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            value: _selectedYear,
            isExpanded: true,
            icon: const Icon(Icons.keyboard_arrow_down, size: 16),
            items: years
                .map((y) => DropdownMenuItem(value: y, child: Text('$y')))
                .toList(),
            onChanged: (v) {
              if (v != null && v != _selectedYear) {
                setState(() => _selectedYear = v);
                _onMonthYearChanged();
              }
            },
          ),
        ),
      ),
    );
  }
}
