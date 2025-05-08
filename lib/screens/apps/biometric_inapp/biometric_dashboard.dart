import 'dart:io';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:just_the_tooltip/just_the_tooltip.dart';
import 'package:intl/intl.dart';
import 'package:nitris/screens/apps/biometric_inapp/biometric_models/student.dart';
import 'package:nitris/screens/apps/biometric_inapp/biometric_models/attendance_models.dart';
import 'package:nitris/screens/apps/biometric_inapp/service/bio_remote_service.dart';
import 'package:nitris/screens/apps/biometric_inapp/widgets/app_colors.dart';
import 'package:nitris/screens/apps/biometric_inapp/widgets/attendance_submit_dialog.dart';
import 'package:nitris/screens/apps/biometric_inapp/widgets/attendance_utils.dart';

class BiometricTeacherAttendancePage extends StatefulWidget {
  final String teacherId;
  const BiometricTeacherAttendancePage({Key? key, required this.teacherId})
      : super(key: key);

  @override
  _BiometricTeacherAttendancePageState createState() =>
      _BiometricTeacherAttendancePageState();
}

class _BiometricTeacherAttendancePageState
    extends State<BiometricTeacherAttendancePage> {
  final _service = AttendanceService();
  bool _loading = true;
  String? _errorMessage;
  bool _mounted = true; // Track if widget is mounted

  late DateTime _initialStart, _initialEnd;
  late DateTime _currentStart, _currentEnd;
  TeacherWeekData? _weekData;
  List<Student> _uiStudents = [];

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  @override
  void dispose() {
    _mounted = false; // Mark as unmounted when being disposed
    super.dispose();
  }

  // Safe setState that checks if widget is still mounted
  void _safeSetState(VoidCallback fn) {
    if (_mounted && mounted) {
      setState(fn);
    }
  }

  Future<void> _loadInitial() async {
    _safeSetState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final data = await _service.fetchInitialWeek(widget.teacherId);
      if (!_mounted) return; // Check if still mounted after async operation

      // Adjust dates to ensure weeks start on Monday
      final daysSinceMonday = data.startDate.weekday - 1;

      // If not starting on Monday (0), adjust to the previous Monday
      DateTime adjustedStart = data.startDate;
      if (daysSinceMonday != 0) {
        adjustedStart = data.startDate.subtract(
          Duration(days: daysSinceMonday),
        );

        // We need to fetch the week again with adjusted dates
        if (!_mounted) return;
        final adjustedData = await _service.fetchWeek(
          widget.teacherId,
          adjustedStart,
          adjustedStart.add(const Duration(days: 6)),
        );
        if (!_mounted) return;

        _initialStart = adjustedData.startDate;
        _initialEnd = adjustedData.endDate;
        _currentStart = adjustedData.startDate;
        _currentEnd = adjustedData.endDate;
        _applyWeek(adjustedData);
      } else {
        // Already starts on Monday, use as is
        _initialStart = data.startDate;
        _initialEnd = data.endDate;
        _currentStart = data.startDate;
        _currentEnd = data.endDate;
        _applyWeek(data);
      }
    } on SocketException {
      if (!_mounted) return;
      _safeSetState(
        () => _errorMessage = 'Network error. Please check your connection.',
      );
    } catch (_) {
      if (!_mounted) return;
      _safeSetState(() => _errorMessage = 'Oops! Something went wrong.');
    } finally {
      if (_mounted) {
        _safeSetState(() => _loading = false);
      }
    }
  }

  Future<void> _loadWeek(DateTime s, DateTime e) async {
    if (_loading || !_mounted) return;

    _safeSetState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      // Adjust dates to ensure weeks start on Monday
      // Get days since Monday (0 for Monday, 1 for Tuesday, etc.)
      final daysSinceMonday = s.weekday - 1;

      // If not starting on Monday (0), adjust to previous Monday
      final adjustedStart = daysSinceMonday == 0
          ? s
          : s.subtract(Duration(days: daysSinceMonday));

      // End date is always 6 days after start (for a total of 7 days)
      final adjustedEnd = adjustedStart.add(const Duration(days: 6));

      final data = await _service.fetchWeek(
        widget.teacherId,
        adjustedStart,
        adjustedEnd,
      );
      if (!_mounted) return;

      _currentStart = data.startDate;
      _currentEnd = data.endDate;
      _applyWeek(data);
    } on SocketException {
      if (!_mounted) return;
      _safeSetState(
        () => _errorMessage = 'Network error. Please check your connection.',
      );
    } catch (_) {
      if (!_mounted) return;
      _safeSetState(() => _errorMessage = 'Oops! Something went wrong.');
    } finally {
      if (_mounted) {
        _safeSetState(() => _loading = false);
      }
    }
  }

  void _applyWeek(TeacherWeekData data) {
    if (!_mounted) return;

    _weekData = data;
    _uiStudents = data.students.map((stu) {
      final codes = stu.days.map((d) {
        return AttendanceUtils.statusFor(
          d,
          data.workingDays.workingDates,
        );
      }).toList();
      return Student.fromCombined('${stu.rollNo} ${stu.name}', codes);
    }).toList();
  }

  void _prevWeek() {
    if (!_mounted) return;
    _loadWeek(
      _currentStart.subtract(const Duration(days: 7)),
      _currentEnd.subtract(const Duration(days: 7)),
    );
  }

  void _nextWeek() {
    if (!_mounted) return;
    _loadWeek(
      _currentStart.add(const Duration(days: 7)),
      _currentEnd.add(const Duration(days: 7)),
    );
  }

  void _refreshCurrentWeek() {
    if (!_mounted) return;
    _loadWeek(_currentStart, _currentEnd);
  }

  void _refreshCheckpointWeek() {
    if (!_mounted) return;
    _loadWeek(_initialStart, _initialEnd);
  }

  void _showRefreshOptions() {
    if (!_mounted) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          'Refresh Options',
          style: TextStyle(color: AppColors.primaryColor),
        ),
        content: const Text('Which week data would you like to refresh?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (_mounted) _refreshCurrentWeek();
            },
            child: Text(
              'REFRESH CURRENT WEEK',
              style: TextStyle(color: AppColors.primaryColor),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (_mounted) _refreshCheckpointWeek();
            },
            child: Text(
              'GO TO LATEST WEEK',
              style: TextStyle(color: AppColors.primaryColor),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL',
                style: TextStyle(color: AppColors.primaryColor)),
          ),
        ],
      ),
    );
  }

  void _showWeekSelector() {
    if (!_mounted) return;

    final now = DateTime.now();
    showDatePicker(
      context: context,
      initialDate: _currentStart,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryColor,
            ),
          ),
          child: child!,
        );
      },
    ).then((selectedDate) {
      if (selectedDate != null && _mounted) {
        // Adjust to start of week (Monday)
        final daysSinceMonday = selectedDate.weekday - 1;
        final startOfWeek = selectedDate.subtract(
          Duration(days: daysSinceMonday),
        );

        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(
              'Refresh Week',
              style: TextStyle(color: AppColors.primaryColor),
            ),
            content: Text(
              'Load data for week of ${DateFormat('MMM dd, yyyy').format(startOfWeek)}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CANCEL',
                    style: TextStyle(color: AppColors.primaryColor)),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  if (_mounted) {
                    final endOfWeek = startOfWeek.add(
                      const Duration(days: 6),
                    );
                    _loadWeek(startOfWeek, endOfWeek);
                  }
                },
                child: Text(
                  'CONFIRM',
                  style: TextStyle(color: AppColors.primaryColor),
                ),
              ),
            ],
          ),
        );
      }
    });
  }

  bool _isClickable(String orig, int si, int di) {
    if (!_mounted || _weekData == null) return false;

    if (['Y', 'Bl', 'Br'].contains(orig)) return false;

    // Make Yellow clickable if both inTime and outTime are present
    if (orig == 'Y') {
      final day = _weekData!.students[si].days[di];
      return day.inTime != null && day.outTime != null;
    }

    return true;
  }

  String _nextState(String cur, String orig) {
    if (orig == 'C') return cur == 'C' ? 'G' : 'C'; // cyan ↔ green
    if (orig == 'P')
      return cur == 'P'
          ? 'G'
          : (cur == 'G' ? 'R' : 'G'); // purple → green → red ↔ green
    if (orig == 'G') return cur == 'G' ? 'R' : 'G'; // green ↔ red
    if (orig == 'R') return cur == 'R' ? 'G' : 'R'; // red ↔ green
    if (orig == 'Y')
      return cur == 'Y' ? 'G' : 'Y'; // yellow ↔ green (for clickable yellow)
    return cur;
  }

  void _tapCell(int si, int di) {
    if (!_mounted) return;

    final orig = _uiStudents[si].originalAttendance[di];
    if (!_isClickable(orig, si, di)) return;
    _safeSetState(() {
      _uiStudents[si].attendance[di] = _nextState(
        _uiStudents[si].attendance[di],
        orig,
      );
    });
  }

  void _applyAll(int si) {
    if (!_mounted) return;

    _safeSetState(() {
      final u = _uiStudents[si];
      for (var i = 0; i < u.attendance.length; i++) {
        if (u.attendance[i] == 'P' &&
            _isClickable(u.originalAttendance[i], si, i)) {
          u.attendance[i] = 'G';
        }
      }
    });
  }

  void _resetStudent(int si) {
    if (!_mounted) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          'Reset',
          style: TextStyle(color: AppColors.primaryColor),
        ),
        content: Text('Reset attendance for ${_uiStudents[si].name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL',
                style: TextStyle(color: AppColors.primaryColor)),
          ),
          TextButton(
            onPressed: () {
              if (_mounted) {
                _safeSetState(() {
                  _uiStudents[si].attendance = List.from(
                    _uiStudents[si].originalAttendance,
                  );
                });
                Navigator.pop(context);
              } else {
                Navigator.pop(context);
              }
            },
            child: Text(
              'RESET',
              style: TextStyle(color: AppColors.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String? hm) {
    if (hm == null || hm.isEmpty) return "--";
    try {
      final dt = DateFormat("HH:mm:ss").parseLoose(hm);
      return DateFormat.jm().format(dt);
    } catch (_) {
      return hm;
    }
  }

  // Then replace the _submitAttendance method with this:
  Future<void> _submitAttendance() async {
    if (_weekData == null || !_mounted) return;

    _safeSetState(() {
      _loading = true;
      _errorMessage = null;
    });

    // Check if any student has Purple status (approval pending)
    if (AttendanceApprovalHelper.hasPendingApprovals(_uiStudents)) {
      // Show warning about pending approval
      AttendanceApprovalHelper.showPendingApprovalWarning(context);
      _safeSetState(() => _loading = false);
      return;
    }

    // Show the submission dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AttendanceSubmitDialog(
        teacherId: widget.teacherId,
        startDate: _currentStart,
        endDate: _currentEnd,
        students: _uiStudents,
        studentData: _weekData!.students,
        onSubmitSuccess: () async {
          // After successful submission, fetch latest week
          try {
            final latest = await _service.fetchInitialWeek(
              widget.teacherId,
            );
            if (!_mounted) return;

            final isLatest = latest.startDate == _currentStart &&
                latest.endDate == _currentEnd;

            if (!_mounted) return;

            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => AlertDialog(
                title: const Text(
                  'Attendance Approved',
                  style: TextStyle(color: AppColors.primaryColor),
                ),
                content: Text(
                  isLatest
                      ? 'ATTENDANCE APPROVED UPTO DATE!'
                      : 'ATTENDANCE APPROVED. GO TO NEXT WEEK?',
                  style: const TextStyle(fontSize: 16),
                ),
                actions: [
                  if (!isLatest)
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        if (_mounted) {
                          _nextWeek();
                        }
                      },
                      child: Text(
                        'GO TO NEXT WEEK',
                        style: TextStyle(color: AppColors.primaryColor),
                      ),
                    )
                  else
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'OK',
                        style: TextStyle(color: AppColors.primaryColor),
                      ),
                    ),
                ],
              ),
            );
          } catch (e) {
            if (_mounted) {
              _safeSetState(
                () => _errorMessage = 'Error fetching latest week data.',
              );
            }
          } finally {
            if (_mounted) {
              _safeSetState(() => _loading = false);
            }
          }
        },
        onCancel: () {
          if (_mounted) {
            _safeSetState(() => _loading = false);
          }
        },
      ),
    );
  }

  String _weekLabel([DateTime? s, DateTime? e]) {
    final a = s ?? _currentStart, b = e ?? _currentEnd;
    String fmt(DateTime d) => '${d.day.toString().padLeft(2, '0')} '
        '${[
          'JAN',
          'FEB',
          'MAR',
          'APR',
          'MAY',
          'JUN',
          'JUL',
          'AUG',
          'SEP',
          'OCT',
          'NOV',
          'DEC'
        ][d.month - 1]}';
    return '${fmt(a)} - ${fmt(b)} | ${b.year}';
  }

  Widget _buildLegend(String code, String label) {
    final colorMap = {
      'G': AppColors.greenStatus,
      'C': AppColors.cyanStatus,
      'Y': AppColors.yellowStatus,
      'R': AppColors.redStatus,
      'P': AppColors.purpleStatus,
      'Bl': const Color.fromARGB(255, 25, 123, 197),
      'Br': Colors.brown,
    };
    return Container(
      margin: const EdgeInsets.only(right: 12, bottom: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: colorMap[code],
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black12, width: 0.5),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Future<bool> _onWillPop() async {
    if (!_mounted) return true;

    // No changes check needed when there's no weekData yet or students list is empty
    if (_weekData == null || _uiStudents.isEmpty) return true;

    // Check for changes (keep this for the dialog message)
    final listEquals = const ListEquality().equals;
    bool hasChanges = _uiStudents.any(
      (student) => !listEquals(student.attendance, student.originalAttendance),
    );

    // Always show dialog, but with different messages based on whether there are changes
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              hasChanges ? 'Discard Changes?' : 'Exit Attendance Page?',
              style: TextStyle(color: AppColors.primaryColor),
            ),
            content: Text(
              hasChanges
                  ? 'Any unsaved changes will be lost. Do you want to go back?'
                  : 'Are you sure you want to exit the attendance page?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('STAY ON PAGE',
                    style: TextStyle(color: AppColors.primaryColor)),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  'YES, EXIT',
                  style: TextStyle(color: AppColors.primaryColor),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  // Create a separate method for the loading state back button confirmation
  Future<bool> _onLoadingWillPop() async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              'Exit Attendance Page?',
              style: TextStyle(color: AppColors.primaryColor),
            ),
            content: const Text(
              'Are you sure you want to exit the attendance page?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'STAY ON PAGE',
                  style: TextStyle(color: AppColors.primaryColor),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  'YES, EXIT',
                  style: TextStyle(color: AppColors.primaryColor),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    // If we've never fetched a week yet, show spinner or retry on error
// Then update the loading scaffold:
    if (_weekData == null) {
      return WillPopScope(
        onWillPop:
            _onLoadingWillPop, // Use the new loading state back confirmation
        child: Scaffold(
          appBar: AppBar(
            leading: BackButton(
              color: Colors.white,
              onPressed: () async {
                if (mounted && _mounted) {
                  if (await _onLoadingWillPop()) {
                    // Use the same confirmation method
                    if (mounted) {
                      Navigator.of(context).pop();
                    }
                  }
                }
              },
            ),
            title: const Text(
              'Biometric Attendance',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: AppColors.primaryColor,
          ),
          body: Center(
            child: _errorMessage != null
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: AppColors.primaryColor),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {
                          if (_mounted) {
                            _loadInitial();
                          }
                        },
                        child: const Text('RETRY',
                            style: TextStyle(color: AppColors.primaryColor)),
                      ),
                    ],
                  )
                : const CircularProgressIndicator(),
          ),
        ),
      );
    }

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(
            color: Colors.white,
            onPressed: () async {
              if (mounted && _mounted) {
                if (await _onWillPop()) {
                  if (mounted) {
                    Navigator.of(context).pop();
                  }
                }
              }
            },
          ),
          title: const Text(
            'Biometric Attendance',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: AppColors.primaryColor,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _loading ? null : _showRefreshOptions,
              tooltip: 'Refresh options',
            ),
          ],
        ),
        body: Column(
          children: [
            // Inline error banner (if any)
            if (_errorMessage != null)
              Container(
                width: double.infinity,
                color: Colors.redAccent,
                padding: const EdgeInsets.symmetric(
                  vertical: 6,
                  horizontal: 12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        // retry load of current week
                        if (_mounted) {
                          _loadWeek(_currentStart, _currentEnd);
                        }
                      },
                      child: const Text(
                        'RETRY',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Week navigator
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 20),
                    color: AppColors.primaryColor,
                    onPressed: _loading ? null : _prevWeek,
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: _loading ? null : _showWeekSelector,
                      child: Text(
                        _weekLabel(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, size: 20),
                    color: AppColors.primaryColor,
                    onPressed: _loading ? null : _nextWeek,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Dates row
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(7, (i) {
                  final d = _weekData!.startDate.add(Duration(days: i));

                  // Check if it's a weekend (Saturday=6 or Sunday=7)
                  final isWeekend = (d.weekday == 6 || d.weekday == 7);

                  // Use blue only for weekends, regardless of holiday/leave status
                  final clr = isWeekend
                      ? const Color.fromARGB(251, 106, 131, 255)
                      : AppColors.textColor;

                  return Column(
                    children: [
                      Text(
                        '${d.day}',
                        style: TextStyle(
                          color: clr,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        [
                          'JAN',
                          'FEB',
                          'MAR',
                          'APR',
                          'MAY',
                          'JUN',
                          'JUL',
                          'AUG',
                          'SEP',
                          'OCT',
                          'NOV',
                          'DEC',
                        ][d.month - 1],
                        style: TextStyle(color: clr, fontSize: 9),
                      ),
                    ],
                  );
                }),
              ),
            ),
            // Main content
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      children: [
                        for (var si = 0; si < _uiStudents.length; si++)
                          _buildStudentCard(si),
                        const SizedBox(height: 8),
                        Center(
                          child: ElevatedButton.icon(
                            onPressed: _submitAttendance,
                            icon: const Icon(
                              Icons.save,
                              size: 18,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'Submit',
                              style: TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryColor,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 12,
                            runSpacing: 6,
                            children: [
                              _buildLegend("G", "Present"),
                              _buildLegend("C", "One Sign"),
                              _buildLegend("R", "Absent (supervisor)"),
                              _buildLegend("Y", "Absent"),
                              _buildLegend("Bl", "Holiday/Leave"),
                              _buildLegend("P", "Approval Pending"),
                              _buildLegend("Br", "Late Registration"),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return "--";
    try {
      // Parse date with periods (2025.04.03)
      final dt = DateTime.parse(dateStr.replaceAll('.', '-'));
      // Format as dd-mm-yyyy
      return "${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year}";
    } catch (_) {
      // Return original string if parsing fails
      return dateStr;
    }
  }

  Widget _buildStudentCard(int si) {
    final u = _uiStudents[si];
    final days = _weekData!.students[si].days;

    // Get status color that will be used for roll number badge instead of whole card
    final statusColor = _getStudentStatusColor(u);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: AppColors.primaryColor.withOpacity(0.15),
          width: 1,
        ),
      ),
      color: Colors.white, // Always white now, status shown in roll number
      elevation: 1,
      child: InkWell(
        onTap: () => _applyAll(si),
        borderRadius: BorderRadius.circular(8),
        splashColor: statusColor.withOpacity(0.3),
        highlightColor: statusColor.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Roll + Name + Reset
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      // Status color now shown here instead of on the whole card
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: statusColor.withOpacity(1),
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      u.rollNumber,
                      style: TextStyle(
                        color: statusColor, // Text color also matches status
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      u.name.replaceAll(RegExp(r'\s+'), ' '),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 20),
                    color: AppColors.primaryColor,
                    onPressed: () => _resetStudent(si),
                    tooltip: 'Reset student',
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Day-cells
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(7, (di) {
                  final code = u.attendance[di];
                  final day = days[di];
                  final statusLabel = {
                    'G': 'Present',
                    'C': 'One Sign',
                    'Y': 'Absent',
                    'R': 'Absent (supervisor)',
                    'P': 'Approval Pending',
                    'Bl': 'Holiday/Leave',
                    'Br': 'Late Registration',
                  }[code]!;

                  final isClickable = _isClickable(
                    u.originalAttendance[di],
                    si,
                    di,
                  );

                  return JustTheTooltip(
                    preferredDirection: AxisDirection.up,
                    tailLength: 10,
                    tailBaseWidth: 18,
                    borderRadius: BorderRadius.circular(6),
                    backgroundColor: AppColors.primaryColor,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    content: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'In: ${_formatTime(day.inTime)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Out: ${_formatTime(day.outTime)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                          if ((day.duration ?? '').isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Duration: ${day.duration}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ],
                          const SizedBox(height: 4),
                          Text(
                            'Status: $statusLabel',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                          // Safe null handling
                          if (day.approvedOn != null &&
                              day.approvedOn!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Approved on: ${_formatDate(day.approvedOn)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ],
                          if ((day.reason ?? '').isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Reason: ${day.reason}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ],
                          if (isClickable) ...[
                            const SizedBox(height: 4),
                            const Text(
                              'Tap to change status',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    child: GestureDetector(
                      onTap: () => _tapCell(si, di),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: {
                            'G': AppColors.greenStatus,
                            'C': AppColors.cyanStatus,
                            'Y': AppColors.yellowStatus,
                            'R': AppColors.redStatus,
                            'P': AppColors.purpleStatus,
                            'Bl': AppColors.blueStatus,
                            'Br': Colors.brown,
                          }[code],
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 1,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${day.date.day}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // New method to get color for roll number based on student status
  Color _getStudentStatusColor(Student student) {
    final attn = student.attendance;

    // Using the same precedence as before: Purple > Red > Cyan > Green > Yellow/Blue > Brown

    // Check for late registration case with non-latest week
    // If any cell has 'Br' (Brown - Late Registration) AND we're not viewing the latest week
    if (attn.contains('Br') &&
        (_currentStart != _initialStart || _currentEnd != _initialEnd)) {
      return AppColors.greenStatus; // Show as green for past weeks
    }

    // 1. Check for Purple (any one cell is enough)
    if (attn.contains('P')) {
      return AppColors.purpleStatus;
    }

    // 2. Check for Red (any one cell is enough)
    if (attn.contains('R')) {
      return AppColors.redStatus;
    }

    // 3. Check for Cyan (any one cell is enough)
    if (attn.contains('C')) {
      return AppColors.cyanStatus;
    }

    // 4. Green cases (multiple scenarios):
    //    - All green
    //    - Green + blue
    //    - Green + yellow
    //    - Green + yellow + blue
    if (attn.contains('G')) {
      bool onlyGreenYellowBlue = attn.every(
        (code) => code == 'G' || code == 'Y' || code == 'Bl',
      );

      if (onlyGreenYellowBlue) {
        return AppColors.greenStatus;
      }
    }

    // 5. Blue case: all cells are blue
    if (attn.every((code) => code == 'Bl')) {
      return AppColors.blueStatus;
    }

    // 6. Yellow case: all cells are yellow
    if (attn.every((code) => code == 'Y')) {
      return AppColors.yellowStatus;
    }

    // 6.1 all cells are yellow and blue
    if (attn.every((code) => code == 'Y' || code == 'Bl')) {
      return AppColors.yellowStatus;
    }

    // 7. Brown case: all cells are brown
    if (attn.every((code) => code == 'Br')) {
      return Colors.brown;
    }

    // 7.1 all cells are brown and some are blue
    if (attn.every((code) => code == 'Br' || code == 'Bl')) {
      return Colors.brown;
    }

    // 8. Fallback: Use primary color
    return AppColors.primaryColor;
  }
}