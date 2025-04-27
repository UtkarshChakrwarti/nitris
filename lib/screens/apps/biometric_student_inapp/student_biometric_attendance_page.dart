import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:nitris/core/constants/app_colors.dart';
import 'package:nitris/core/models/attendance_record.dart';
import 'package:nitris/core/models/student_attendance_summary.dart';
import 'package:nitris/core/services/local/local_storage_service.dart';
import 'package:nitris/screens/apps/biometric_student_inapp/widgets/attendance_app_bar.dart';
import 'package:nitris/screens/apps/biometric_student_inapp/widgets/attendance_info_dialog.dart';
import 'package:nitris/screens/apps/biometric_student_inapp/widgets/formatter.dart';
import 'package:nitris/screens/apps/biometric_student_inapp/widgets/legend_item.dart';
import 'package:nitris/screens/apps/biometric_student_inapp/widgets/stat_card.dart';

class StudentAttendancePageBiometric extends StatefulWidget {
  const StudentAttendancePageBiometric({super.key});

  @override
  State<StudentAttendancePageBiometric> createState() => _StudentAttendancePageBiometricState();
}

class _StudentAttendancePageBiometricState extends State<StudentAttendancePageBiometric> {
  // Student information
  String _studentName = "Student";
  String _rollNumber = "";

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
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  late final List<int> years;

  // Loading and error states
  bool _isInitialLoading = false;
  bool _isCalendarLoading = false;
  bool _hasNetworkError = false;
  // ignore: unused_field
  String _errorMessage = '';
  
  // Data store
  List<AttendanceRecord> _attendanceRecords = [];
  
  // HTTP client for better connection management
  late http.Client _httpClient;
  
  // Debouncer for network requests
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    
    // Initialize HTTP client
    _httpClient = http.Client();
    
    // Set current month
    _selectedMonth = months[DateTime.now().month - 1];
    
    // Generate years for dropdown (current year and 4 previous years)
    years = List.generate(5, (i) => DateTime.now().year - i);
    
    // Only load student data once, then fetch attendance data
    _loadStudentData();
  }

  @override
  void dispose() {
    // Clean up resources
    _httpClient.close();
    _debounceTimer?.cancel();
    super.dispose();
  }

  /// Load student data from local storage
  Future<void> _loadStudentData() async {
    try {
      final empcode = await LocalStorageService.getCurrentUserEmpCode();
      final fullName = await LocalStorageService.getCurrentUserFullName();
      
      if (!mounted) return;
      
      setState(() {
        _rollNumber = empcode ?? "";
        _studentName = fullName != null 
            ? fullName.replaceAll(RegExp(r'\s+'), ' ').trim()
            : "Student";
      });
      
      // Fetch attendance data after student data is loaded
      _fetchInitialData();
    } catch (e) {
      debugPrint('Error loading student data: $e');
      
      if (!mounted) return;
      
      setState(() {
        _rollNumber = "";
        _studentName = "Student";
      });
      
      // Still try to fetch attendance data even if student data fails
      _fetchInitialData();
    }
  }

  /// Fetch initial attendance data
  Future<void> _fetchInitialData() async {
    // Prevent multiple concurrent requests
    if (_isInitialLoading) return;
    
    setState(() {
      _isInitialLoading = true;
      _errorMessage = '';
      _hasNetworkError = false;
    });

    final monthIdx = months.indexOf(_selectedMonth) + 1;
    final url = 'https://api.nitrkl.ac.in/Biometric/GetStudentAttendance?rollno=$_rollNumber&month=$monthIdx&year=$_selectedYear';

    try {
      // Use dedicated HTTP client with proper timeout
      final res = await _httpClient.get(Uri.parse(url)).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Connection timed out. Please check your internet connection and try again.');
        },
      );
      
      // Handle HTTP status codes
      if (res.statusCode != 200) {
        if (res.statusCode >= 500) {
          throw Exception('Server error. Please try again later.');
        } else if (res.statusCode == 404) {
          throw Exception('Data not found for the selected month and year.');
        } else {
          throw Exception('HTTP Error ${res.statusCode}. Please try again.');
        }
      }

      // Parse response data
      final summary = StudentAttendanceSummary.fromJson(
        json.decode(res.body) as Map<String, dynamic>,
      );
      
      final stats = _calculateStats(summary.records);
      final todayRec = _getTodayRecord(summary.records);

      if (!mounted) return;
      
      setState(() {
        _attendanceRecords = summary.records;
        presentCount = stats['present']!;
        absentCount = stats['absent']!;
        leaveAvailed = summary.leaveAvailed;
        leaveRemaining = summary.leaveRemaining;
        
        // Update selected date based on current month/year
        if (DateTime.now().month == monthIdx && DateTime.now().year == _selectedYear) {
          _selectedDate = DateTime.now();
        } else {
          // Or select the first day with attendance data
          final firstValidDay = summary.records.isNotEmpty ? 
            summary.records.first.day : 1;
          _selectedDate = DateTime(_selectedYear, monthIdx, firstValidDay);
        }
        
        // Update time display
        _timeIn = todayRec.inTime.isNotEmpty ? todayRec.inTime : '--:--';
        _timeOut = todayRec.outTime.isNotEmpty ? todayRec.outTime : '--:--';
        _hasNetworkError = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      // Create a user-friendly error message
      String errorMsg;
      if (e.toString().contains('SocketException') || 
          e.toString().contains('Connection refused') ||
          e.toString().contains('timed out') ||
          e.toString().contains('Failed host lookup') ||
          e.toString().contains('Network is unreachable')) {
        errorMsg = 'No internet connection. Please check your network and try again.';
      } else {
        errorMsg = 'Failed to load attendance data: ${e.toString()}';
      }
      
      setState(() {
        _errorMessage = errorMsg;
        _hasNetworkError = true;
      });
      
      // Show error message
      _showErrorSnackBar(errorMsg, _fetchInitialData);
    } finally {
      // Always clear loading state when done
      if (mounted) {
        setState(() => _isInitialLoading = false);
      }
    }
  }

  /// Fetch calendar data when month/year changes
  Future<void> _fetchCalendarData() async {
    if (_isCalendarLoading) return;
    
    setState(() {
      _isCalendarLoading = true;
    });

    final monthIdx = months.indexOf(_selectedMonth) + 1;
    final url = 'https://api.nitrkl.ac.in/Biometric/GetStudentAttendance?rollno=$_rollNumber&month=$monthIdx&year=$_selectedYear';

    try {
      // Use dedicated HTTP client
      final res = await _httpClient.get(Uri.parse(url)).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Connection timed out. Please check your internet connection and try again.');
        },
      );
      
      // Handle HTTP status codes
      if (res.statusCode != 200) {
        if (res.statusCode >= 500) {
          throw Exception('Server error. Please try again later.');
        } else if (res.statusCode == 404) {
          throw Exception('Data not found for the selected month and year.');
        } else {
          throw Exception('HTTP Error ${res.statusCode}. Please try again.');
        }
      }

      // Parse response data
      final summary = StudentAttendanceSummary.fromJson(
        json.decode(res.body) as Map<String, dynamic>,
      );
      
      final stats = _calculateStats(summary.records);

      if (!mounted) return;
      
      setState(() {
        _attendanceRecords = summary.records;
        presentCount = stats['present']!;
        absentCount = stats['absent']!;
        leaveAvailed = summary.leaveAvailed;
        leaveRemaining = summary.leaveRemaining;
        
        // Update selected date if we have data
        if (summary.records.isNotEmpty) {
          final firstValidDay = summary.records.first.day;
          _selectedDate = DateTime(_selectedYear, monthIdx, firstValidDay);
          
          // Update time display for selected date
          final record = _getRecordForDay(firstValidDay);
          _timeIn = record?.inTime.isNotEmpty ?? false ? record!.inTime : '--:--';
          _timeOut = record?.outTime.isNotEmpty ?? false ? record!.outTime : '--:--';
        }
        
        _hasNetworkError = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      // Create a user-friendly error message
      String errorMsg;
      if (e.toString().contains('SocketException') || 
          e.toString().contains('Connection refused') ||
          e.toString().contains('timed out') ||
          e.toString().contains('Failed host lookup') ||
          e.toString().contains('Network is unreachable')) {
        errorMsg = 'Network error. Calendar data could not be loaded.';
      } else {
        errorMsg = 'Failed to update calendar data: ${e.toString()}';
      }
      
      setState(() {
        _hasNetworkError = true;
        _errorMessage = errorMsg;
      });
      
      // Show a toast notification for calendar errors
      _showErrorSnackBar(errorMsg, _fetchCalendarData, duration: const Duration(seconds: 3));
    } finally {
      if (mounted) {
        setState(() => _isCalendarLoading = false);
      }
    }
  }

  /// Show error snackbar with retry option
  void _showErrorSnackBar(String message, VoidCallback onRetry, {Duration? duration}) {
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

  /// Full page refresh using the refresh button
  void _refreshData() {
    // Cancel any pending timer
    _debounceTimer?.cancel();
    
    // Show a loading indicator
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

    // Reset to current month/year
    setState(() {
      _selectedDate = DateTime.now();
      _selectedMonth = months[DateTime.now().month - 1];
      _selectedYear = DateTime.now().year;
    });
    
    // Add a small delay to ensure UI updates first
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _fetchInitialData();
    });
  }

  /// Called when month or year changes in dropdowns
  void _onMonthYearChanged() {
    // Cancel any pending timer
    _debounceTimer?.cancel();
    
    // Add a small delay to prevent multiple rapid requests
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _fetchCalendarData();
    });
  }

  /// Get record for today
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

  /// Calculate present/absent stats
  Map<String, int> _calculateStats(List<AttendanceRecord> recs) {
    int present = 0, absent = 0;
    for (var record in recs) {
      if (record.isPresent) present++;
      if (record.isAbsent) absent++;
    }
    return {'present': present, 'absent': absent};
  }

  /// Get record for specific day
  AttendanceRecord? _getRecordForDay(int day) {
    try {
      return _attendanceRecords.firstWhere((r) => r.day == day);
    } catch (_) {
      return null;
    }
  }

  /// Get status icon for calendar
  IconData _getStatusIcon(int day) {
    final record = _getRecordForDay(day);
    if (record == null) return Icons.help_outline;
    if (record.isHoliday || record.isWeekend) return Icons.beach_access;
    if (record.isPresent) return Icons.check_circle;
    if (record.isAbsent) return Icons.clear;
    if (record.isFutureDate) return Icons.schedule;
    return Icons.help_outline;
  }

  /// Get status color for calendar
  Color _getStatusColor(int day) {
    final record = _getRecordForDay(day);
    if (record == null) return Colors.grey;
    if (record.isHoliday || record.isWeekend) return AppColors.blueStatus;
    if (record.isPresent) return AppColors.greenStatus;
    if (record.isAbsent) return AppColors.yellowStatus;
    return Colors.grey;
  }

  /// Handle day tapped in calendar
  void _onDayTapped(int day) {
    final monthIndex = months.indexOf(_selectedMonth) + 1;
    final record = _getRecordForDay(day);
    setState(() {
      _selectedDate = DateTime(_selectedYear, monthIndex, day);
      _timeIn = record?.inTime.isNotEmpty ?? false ? record!.inTime : '--:--';
      _timeOut = record?.outTime.isNotEmpty ?? false ? record!.outTime : '--:--';
    });
  }

  @override
  Widget build(BuildContext context) {
    // Initial loading state with no prior data
    if (_isInitialLoading && _attendanceRecords.isEmpty) {
      return Scaffold(
        appBar: AttendanceAppBar(
          title: 'Biometric Attendance',
          onBackPressed: () => Navigator.pop(context),
          onRefreshPressed: _refreshData,
          onInfoPressed: () => showDialog(
            context: context,
            builder: (context) => AttendanceInfoDialog(),
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

    // Network error with no prior data
    if (_hasNetworkError && _attendanceRecords.isEmpty) {
      return Scaffold(
        appBar: AttendanceAppBar(
          title: 'Biometric Attendance',
          onBackPressed: () => Navigator.pop(context),
          onRefreshPressed: _refreshData,
          onInfoPressed: () => showDialog(
            context: context,
            builder: (context) => AttendanceInfoDialog(),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.signal_wifi_off,
                size: 64,
                color: Colors.grey,
              ),
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
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Main content view
    return Scaffold(
      appBar: AttendanceAppBar(
        title: 'Biometric Attendance',
        onBackPressed: () => Navigator.pop(context),
        onRefreshPressed: _refreshData,
        onInfoPressed: () => showDialog(
          context: context,
          builder: (context) => AttendanceInfoDialog(),
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
              return;
              },
              color: AppColors.primaryColor, // Set spinner color to primary
              child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(), // Enable pull-to-refresh
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

  /// Build user profile with name and roll number
  Widget _buildProfileBlock() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 3),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primaryColor,
            child: const Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _studentName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textColor,
                  ),
                ),
                Text(
                  _rollNumber,
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build daily status block with time in/out
  Widget _buildDailyStatusBlock() {
    final dateLabel = Formatters.formatDateForDisplay(_selectedDate);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 3),
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
                  Text(
                    dateLabel,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
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

  /// Build monthly status block with stats and filters
  Widget _buildMonthlyStatusBlock() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 3),
        ],
      ),
      child: Column(
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Monthly Status',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textColor,
              ),
            ),
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
          // Keep stats visible during loading, but show shimmer/skeleton effect
          _isCalendarLoading ? 
          Opacity(
            opacity: 0.6,
            child: Column(
              children: [
                Row(
                  children: [
                    StatCard(
                      title: 'Present',
                      value: '...',
                      color: AppColors.greenStatus.withOpacity(0.5),
                      icon: Icons.check_circle_outline,
                    ),
                    const SizedBox(width: 6),
                    StatCard(
                      title: 'Absent',
                      value: '...',
                      color: AppColors.yellowStatus.withOpacity(0.5),
                      icon: Icons.cancel_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    StatCard(
                      title: 'Leave Availed',
                      value: '...',
                      color: AppColors.darkGreen.withOpacity(0.5),
                      icon: Icons.event_busy,
                    ),
                    const SizedBox(width: 6),
                    StatCard(
                      title: 'Leave Remaining',
                      value: '...',
                      color: AppColors.darkRed.withOpacity(0.5),
                      icon: Icons.event_available,
                    ),
                  ],
                ),
              ],
            ),
          ) :
          Column(
            children: [
              Row(
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
              const SizedBox(height: 12),
              Row(
                children: [
                  StatCard(
                    title: 'Leave Availed',
                    value: '$leaveAvailed',
                    color: AppColors.darkGreen,
                    icon: Icons.event_busy,
                  ),
                  const SizedBox(width: 6),
                  StatCard(
                    title: 'Leave Remaining',
                    value: '$leaveRemaining',
                    color: AppColors.darkRed,
                    icon: Icons.event_available,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build calendar block
  Widget _buildCalendarBlock() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 6),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$_selectedMonth $_selectedYear',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.textColor,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: AppColors.primaryColor,
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Attendance Calendar',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 12),
                  // Calendar-specific refresh button
                  _isCalendarLoading ? 
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                    ),
                  ) :
                  GestureDetector(
                    onTap: _fetchCalendarData,
                    child: const Icon(
                      Icons.refresh,
                      size: 18,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          _isCalendarLoading ? 
          Center(
            child: Padding(
              padding: const EdgeInsets.all(40.0),
              child: Column(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Loading calendar data...',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ) : 
          _buildCompactCalendar(),
        ],
      ),
    );
  }

  /// Build legend block
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

  /// Build calendar view
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
              const Icon(
                Icons.wifi_off_rounded,
                size: 32,
                color: Colors.grey,
              ),
              const SizedBox(height: 8),
              Text(
                'Calendar data unavailable',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
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
          children:
              ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                  .map(
                    (day) => SizedBox(
                      width: 25,
                      child: Text(
                        day,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  )
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
          itemBuilder: (_, index) {
            final offset = firstWeekday - 1;
            final day = index - offset + 1;
            if (day < 1 || day > daysInMonth) return const SizedBox();

            return _buildCalendarDay(day, monthIndex);
          },
        ),
      ],
    );
  }

  /// Build calendar day cell
  Widget _buildCalendarDay(int day, int monthIndex) {
    final record = _getRecordForDay(day);
    final isFuture = record?.isFutureDate ?? false;
    final now = DateTime.now();
    final isToday =
        day == now.day && monthIndex == now.month && _selectedYear == now.year;
    final isSelected =
        !isFuture &&
        day == _selectedDate.day &&
        monthIndex == _selectedDate.month &&
        _selectedYear == _selectedDate.year;

    final baseColor = _getStatusColor(day);
    final backgroundColor =
        isFuture
            ? Colors.grey.withOpacity(.15)
            : isSelected
            ? AppColors.primaryColor.withOpacity(.2)
            : baseColor.withOpacity(.15);
    final border =
        isSelected
            ? Border.all(color: AppColors.primaryColor, width: 2)
            : isToday
            ? Border.all(color: AppColors.primaryColor.withOpacity(.5))
            : null;

    return GestureDetector(
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
                color:
                    isFuture
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
    );
  }

  /// Build time card for time in/out
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
            Text(
              '$label ',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  /// Build month dropdown selector
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
                .map((month) => DropdownMenuItem(value: month, child: Text(month)))
                .toList(),
            onChanged: (value) {
              if (value != null && value != _selectedMonth) {
                setState(() => _selectedMonth = value);
                _onMonthYearChanged();
              }
            },
          ),
        ),
      ),
    );
  }

  /// Build year dropdown selector
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
                .map((year) => DropdownMenuItem(value: year, child: Text('$year')))
                .toList(),
            onChanged: (value) {
              if (value != null && value != _selectedYear) {
                setState(() => _selectedYear = value);
                _onMonthYearChanged();
              }
            },
          ),
        ),
      ),
    );
  }
}