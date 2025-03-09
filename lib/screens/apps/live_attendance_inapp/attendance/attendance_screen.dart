import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';

// QR scanning
import 'package:qr_code_scanner/qr_code_scanner.dart';
// Beep sound
import 'package:flutter_beep/flutter_beep.dart';

// Your existing imports (adjust paths as needed)
import 'package:nitris/core/constants/app_colors.dart';
import 'package:nitris/core/models/student.dart';
import 'package:nitris/core/models/subject.dart';
import 'package:nitris/core/services/remote/api_service.dart';
import 'package:nitris/core/utils/dialogs_and_prompts.dart';
import 'package:nitris/screens/apps/live_attendance_inapp/attendance/widgets/attendance_header.dart';
import 'package:nitris/screens/apps/live_attendance_inapp/attendance/widgets/student_tile.dart';

/// An Attendance Page with two modes:
/// - QR Mode (default): All start as absent; scanning makes them present.
/// - Manual Mode: Tapping the top-right QR icon toggles back to QR mode.
///
/// Switching logic:
///   Manual -> QR:
///     absent -> notMarked
///     present -> present (unchanged)
///     notMarked -> absent
///   QR -> Manual:
///     notMarked -> absent
///     present -> present (unchanged)
///     absent -> notMarked
class AttendancePage extends StatefulWidget {
  final int date;
  final int month;
  final Subject subject;
  final String semester;
  final String currentYear;
  final int classNumber;
  final int sectionId;

  const AttendancePage({
    Key? key,
    required this.date,
    required this.month,
    required this.subject,
    required this.semester,
    required this.currentYear,
    required this.classNumber,
    required this.sectionId,
  }) : super(key: key);

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  // Services and Logging
  final ApiService _apiService = ApiService();
  final Logger _logger = Logger('AttendancePage');

  // State Variables
  List<Student> students = [];
  bool _isLoading = true;
  bool _isAttendanceSaved = false;

  // Track whether we're in QR (automatic) mode or manual mode
  bool _isManualMode = false;

  // For the QR camera
  final GlobalKey _qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? _qrController;

  // Simple cooldown for repeated scans
  String? _lastScannedCode;
  DateTime _lastScanTime = DateTime.now().subtract(const Duration(seconds: 2));

  @override
  void initState() {
    super.initState();
    // Lock orientation to portrait
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _fetchStudents();
  }

  /// Convert month number to full month name
  String _getMonthName(int month) {
    const months = [
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
    if (month < 1 || month > 12) return 'Invalid';
    return months[month - 1];
  }

  /// Fetch students from API
  Future<void> _fetchStudents() async {
    setState(() => _isLoading = true);
    try {
      final fetchedStudents = await _apiService.getStudents(widget.sectionId);
      setState(() {
        students = fetchedStudents;
        _isLoading = false;
      });

      // Start in QR mode -> mark all as absent
      if (!_isManualMode) {
        _markAllAbsent();
      }
    } catch (e, st) {
      _logger.severe('Error fetching students: $e', e, st);
      setState(() => _isLoading = false);
      DialogsAndPrompts.showFailureDialog(
          context, 'Failed to load students: $e');
    }
  }

  /// Mark everyone as Absent (for QR mode)
  void _markAllAbsent() {
    for (var s in students) {
      s.status = AttendanceStatus.absent;
    }
  }

  /// Mark everyone as Unmarked (for Manual mode)
  void _markAllUnmarked() {
    for (var s in students) {
      s.status = AttendanceStatus.notMarked;
    }
  }

  /// from Manual -> QR:
  ///   absent -> notMarked
  ///   present -> present
  ///   notMarked -> absent
  void _switchManualToQR() {
    for (var s in students) {
      if (s.status == AttendanceStatus.absent) {
        s.status = AttendanceStatus.notMarked;
      } else if (s.status == AttendanceStatus.notMarked) {
        s.status = AttendanceStatus.absent;
      }
      // present remains present
    }
  }

  /// from QR -> Manual:
  ///   notMarked -> absent
  ///   present -> present
  ///   absent -> notMarked
  void _switchQRToManual() {
    for (var s in students) {
      if (s.status == AttendanceStatus.notMarked) {
        s.status = AttendanceStatus.absent;
      } else if (s.status == AttendanceStatus.absent) {
        s.status = AttendanceStatus.notMarked;
      }
      // present remains present
    }
  }

  /// Attempt to leave page -> check unsaved attendance
  Future<bool> _handleBackNavigation() async {
    if (!_isAttendanceSaved && _isAnyAttendanceMarked()) {
      final shouldPop =
          await DialogsAndPrompts.showUnsavedAttendanceDialog(context) ?? false;
      return shouldPop;
    }
    return true;
  }

  /// Check if any student's attendance has been marked
  bool _isAnyAttendanceMarked() {
    return students.any((s) => s.status != AttendanceStatus.notMarked);
  }

  /// Clear all selections (sets them all to notMarked)
  Future<void> _clearAllSelections() async {
    final confirm =
        await DialogsAndPrompts.showConfirmClearAllDialog(context) ?? false;
    if (confirm) {
      setState(() {
        for (var student in students) {
          student.status = AttendanceStatus.notMarked;
        }
        _isAttendanceSaved = false;
      });
    }
  }

  /// Submit attendance to server
  Future<void> _handleSubmitAttendance() async {
    try {
      // Prepare records
      final attendanceRecords = students
          .map((student) => {
                'attendanceId': student.attendanceId,
                'id': student.id,
                'status':
                    (student.status == AttendanceStatus.present) ? 'G' : 'R',
              })
          .toList();

      final payload = {
        'classNumber': widget.classNumber,
        'date': widget.date,
        'year': widget.currentYear,
        'month': _getMonthName(widget.month),
        'sectionId': widget.sectionId,
        'attendance': attendanceRecords,
      };

      _logger.info('Saving attendance payload: $payload');
      await _apiService.submitAttendance(payload);

      final success = await DialogsAndPrompts.showSuccessDialog(
        context,
        'Attendance saved successfully.',
      );

      if (success == true) {
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/attendanceHome', (r) => false);
      }

      setState(() => _isAttendanceSaved = true);
    } catch (e, st) {
      _logger.severe('Error submitting attendance: $e', e, st);
      DialogsAndPrompts.showFailureDialog(
          context, 'Failed to save attendance: $e');
    }
  }

  /// Confirm before submitting
  Future<void> _handleSubmitButtonPressed() async {
    // If we are in Manual mode, make sure no students are left unmarked.
    if (_isManualMode) {
      final unmarkedCount =
          students.where((s) => s.status == AttendanceStatus.notMarked).length;
      if (unmarkedCount > 0) {
        // Show an error dialog (or snackBar) and block submission
        DialogsAndPrompts.showFailureDialog(context,
            'Please mark all students (none can be "unmarked") before submitting.');
        return;
      }
    }

    // If this check passes, proceed as normal.
    final confirm =
        await DialogsAndPrompts.showConfirmSubmissionDialog(context) ?? false;
    if (confirm) {
      await _handleSubmitAttendance();
    }
  }

  /// "Select All" -> mark all present, or reset to notMarked
  Future<void> _handleSelectAll(bool value) async {
    final confirm =
        await DialogsAndPrompts.showConfirmSelectAllDialog(context) ?? false;
    if (confirm) {
      setState(() {
        for (var student in students) {
          student.status =
              value ? AttendanceStatus.present : AttendanceStatus.notMarked;
        }
        _isAttendanceSaved = false;
      });
    }
  }

  /// Update one student's status
  void _updateStudentStatus(int index, AttendanceStatus status) {
    setState(() {
      students[index].status = status;
      _isAttendanceSaved = false;
    });
  }

  /// Show present students in a dialog
  void _showPresentStudentsDialog() {
    final presentStudents =
        students.where((s) => s.status == AttendanceStatus.present).toList();
    if (presentStudents.isEmpty) {
      showDialog(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: Text(
              "Present Students",
              style: TextStyle(color: AppColors.primaryColor),
            ),
            content: const Center(child: Text("No student marked present.")),
            actions: [
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primaryColor,
                ),
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text("OK"),
              ),
            ],
          );
        },
      );
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: _buildPresentDialogContent(ctx, presentStudents),
        );
      },
    );
  }

  Widget _buildPresentDialogContent(
      BuildContext ctx, List<Student> presentStudents) {
    return StatefulBuilder(
      builder: (context, setStateDialog) {
        // Refresh present list
        final localPresent = students
            .where((s) => s.status == AttendanceStatus.present)
            .toList();
        return SizedBox(
          height: MediaQuery.of(ctx).size.height * 0.85,
          child: Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Present Students (${localPresent.length})",
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: localPresent.length,
                  itemBuilder: (context, i) {
                    final st = localPresent[i];
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: const [
                          BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4,
                              offset: Offset(0, 2))
                        ],
                      ),
                      child: ListTile(
                        title: Text(st.name,
                            style: const TextStyle(
                                fontSize: 16, color: Colors.black)),
                        subtitle: Text("Roll No: ${st.rollNo}",
                            style: const TextStyle(
                                fontSize: 14, color: Colors.grey)),
                        trailing: IconButton(
                          icon: const Icon(Icons.remove_circle_outline,
                              color: AppColors.darkRed, size: 28),
                          tooltip: 'Mark Absent',
                          onPressed: () {
                            final idx =
                                students.indexWhere((s) => s.id == st.id);
                            if (idx != -1) {
                              _updateStudentStatus(
                                  idx, AttendanceStatus.absent);
                              setStateDialog(() {});
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Show absent students in a dialog
  void _showAbsentStudentsDialog() {
    final absentStudents =
        students.where((s) => s.status == AttendanceStatus.absent).toList();
    if (absentStudents.isEmpty) {
      showDialog(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: Text(
              "Absent Students",
              style: TextStyle(color: AppColors.primaryColor),
            ),
            content: const Center(child: Text("No student marked absent.")),
            actions: [
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primaryColor,
                ),
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text("OK"),
              ),
            ],
          );
        },
      );
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: _buildAbsentDialogContent(ctx, absentStudents),
        );
      },
    );
  }

  Widget _buildAbsentDialogContent(
      BuildContext ctx, List<Student> absentStudents) {
    return StatefulBuilder(
      builder: (context, setStateDialog) {
        final localAbsent =
            students.where((s) => s.status == AttendanceStatus.absent).toList();
        return SizedBox(
          height: MediaQuery.of(ctx).size.height * 0.85,
          child: Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Absent Students (${localAbsent.length})",
                        style:
                            const TextStyle(color: Colors.white, fontSize: 12)),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: localAbsent.length,
                  itemBuilder: (context, i) {
                    final st = localAbsent[i];
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: const [
                          BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4,
                              offset: Offset(0, 2))
                        ],
                      ),
                      child: ListTile(
                        title: Text(st.name,
                            style: const TextStyle(
                                fontSize: 16, color: Colors.black)),
                        subtitle: Text("Roll No: ${st.rollNo}",
                            style: const TextStyle(
                                fontSize: 14, color: Colors.grey)),
                        trailing: IconButton(
                          icon: const Icon(Icons.check_circle_outline,
                              color: AppColors.darkGreen, size: 28),
                          tooltip: 'Mark Present',
                          onPressed: () {
                            final idx =
                                students.indexWhere((s) => s.id == st.id);
                            if (idx != -1) {
                              _updateStudentStatus(
                                  idx, AttendanceStatus.present);
                              setStateDialog(() {});
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // -------------------------------------------------------------------------
  // QR Camera Implementation (Automatic/QR mode)
  // -------------------------------------------------------------------------
  void _onQRViewCreated(QRViewController controller) {
    _qrController = controller;
    // Listen to scanning events
    controller.scannedDataStream.listen((scanData) {
      final code = scanData.code ?? '';
      final now = DateTime.now();
      // 1-second cooldown for duplicates
      if (code.isNotEmpty &&
          (code != _lastScannedCode ||
              now.difference(_lastScanTime).inSeconds >= 1)) {
        _lastScannedCode = code;
        _lastScanTime = now;
        _handleScannedCode(code);
      }
    });
  }

  /// Mark scanned student as present if valid
  void _handleScannedCode(String scannedData) {
    _logger.info("Scanned: $scannedData");
    final parts = scannedData.split(' ');
    if (parts.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid QR format: $scannedData')),
      );
      return;
    }
    // Example: "TESTING STUDENT 124TD0000 0"
    final rollNo = parts[2];
    final scannedSectionId = int.tryParse(parts[3]) ?? -1;

    if (scannedSectionId != widget.sectionId) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Code for section $scannedSectionId, not ${widget.sectionId}!')),
      );
      return;
    }

    final idx = students.indexWhere((s) => s.rollNo == rollNo);
    if (idx == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No student found with rollNo: $rollNo')),
      );
      return;
    }

    // Mark present
    setState(() {
      students[idx].status = AttendanceStatus.present;
      _isAttendanceSaved = false;
    });

    // Beep
    FlutterBeep.beep();

    // Notification
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Marked ${students[idx].name} present!')),
    );
  }

  @override
  void reassemble() {
    super.reassemble();
    // Try/catch to avoid camera freeze or crash
    try {
      if (Platform.isAndroid) {
        _qrController?.pauseCamera();
      }
      _qrController?.resumeCamera();
    } catch (e) {
      _logger.warning('Camera reassemble error: $e');
    }
  }

  @override
  void dispose() {
    _qrController?.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // BUILD METHODS
  // -------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _handleBackNavigation,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.primaryColor,
          centerTitle: true,
          elevation: 0,
          title: Text(
            '${widget.subject.subjectCode} - ${widget.subject.subjectName}',
            style: const TextStyle(fontSize: 16, color: Colors.white),
            overflow: TextOverflow.ellipsis,
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () async {
              final shouldPop = await _handleBackNavigation();
              if (shouldPop) Navigator.of(context).pop();
            },
          ),
          // When in manual mode, show the QR icon to switch back
          actions: [
            if (_isManualMode)
              IconButton(
                icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
                tooltip: 'Switch to QR mode',
                onPressed: () {
                  setState(() {
                    _switchManualToQR();
                    _isManualMode = false;
                  });
                },
              )
          ],
        ),
        // Remove floating action button and use bottomNavigationBar for buttons
        bottomNavigationBar: _buildBottomButtons(),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // Subheader with date/semester/class
                  Container(
                    width: double.infinity,
                    color: AppColors.primaryColor,
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: Center(
                      child: Text(
                        '${widget.semester} ${widget.currentYear} | '
                        '${widget.date}-${_getMonthName(widget.month)}-${widget.currentYear} '
                        '| Class ${widget.classNumber}',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 14),
                      ),
                    ),
                  ),

                  // Attendance header with counters, "All Present" toggle, "Reset"
                  _buildAttendanceHeader(),

                  // Body: either the pink QR scanner or the manual list
                  Expanded(
                    child:
                        _isManualMode ? _buildManualListView() : _buildQRView(),
                  ),
                ],
              ),
      ),
    );
  }

  /// The top counters row
  Widget _buildAttendanceHeader() {
    final presentCount =
        students.where((s) => s.status == AttendanceStatus.present).length;
    final absentCount =
        students.where((s) => s.status == AttendanceStatus.absent).length;
    final unmarkedCount =
        students.where((s) => s.status == AttendanceStatus.notMarked).length;

    // "Select All" means mark all present or all notMarked
    final allPresent = students.isNotEmpty &&
        students.every((s) => s.status == AttendanceStatus.present);

    return AttendanceHeader(
      presentCount: presentCount,
      absentCount: absentCount,
      unmarkedCount: unmarkedCount,
      totalStudents: students.length,
      isSelectAll: allPresent,
      onSelectAllChanged: _handleSelectAll,
      onClear: _clearAllSelections,
      onPresentTap: _showPresentStudentsDialog,
      onAbsentTap: _showAbsentStudentsDialog,
    );
  }

  /// The pink container with the QR camera
  Widget _buildQRView() {
    return Container(
      color: const Color(0xFFFFE4E9), // a light pink background
      child: Stack(
        alignment: Alignment.center,
        children: [
          _buildQRScannerWidget(),
          // A scanning overlay line or decoration (optional)
          Positioned(
            width: 200,
            child: Container(
              height: 2,
              color: Colors.redAccent,
            ),
          ),
        ],
      ),
    );
  }

  /// The actual camera preview using qr_code_scanner
  Widget _buildQRScannerWidget() {
    return QRView(
      key: _qrKey,
      onQRViewCreated: (controller) {
        try {
          _onQRViewCreated(controller);
        } catch (e) {
          _logger.severe('Error creating QR view: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Camera error: $e')),
          );
        }
      },
      overlay: QrScannerOverlayShape(
        borderColor: Colors.redAccent,
        borderRadius: 10,
        borderLength: 20,
        borderWidth: 10,
        cutOutSize: 250,
      ),
    );
  }

  /// Manual mode list of students
  Widget _buildManualListView() {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: students.length,
      itemBuilder: (context, index) {
        final student = students[index];
        return StudentTile(
          index: index + 1,
          student: student,
          isSmallDevice: true,
          onMarkPresent: () =>
              _updateStudentStatus(index, AttendanceStatus.present),
          onMarkAbsent: () =>
              _updateStudentStatus(index, AttendanceStatus.absent),
        );
      },
    );
  }

  /// Bottom buttons:
  /// - In QR mode: two rows with "Save Attendance" and "Take Attendance Manually".
  /// - In Manual mode: one row with "Save Attendance".
  Widget _buildBottomButtons() {
    const buttonPadding = EdgeInsets.symmetric(vertical: 16);

    // Common style for both buttons
    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: AppColors.primaryColor,
      foregroundColor: Colors.white,
      padding: buttonPadding,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );

    if (!_isManualMode) {
      // QR mode: two buttons stacked vertically
      return Container(
        padding: const EdgeInsets.all(16),
        color: Colors.white,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: buttonStyle,
                onPressed: () {
                  // Switch from QR to Manual mode
                  setState(() {
                    _switchQRToManual();
                    _isManualMode = true;
                  });
                },
                child: const Text('Take Attendance Manually'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: buttonStyle,
                onPressed: _handleSubmitButtonPressed,
                child: const Text('Save Attendance'),
              ),
            ),
          ],
        ),
      );
    } else {
      // Manual mode: just one button for saving
      return Container(
        padding: const EdgeInsets.all(16),
        color: Colors.white,
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                style: buttonStyle,
                onPressed: _handleSubmitButtonPressed,
                child: const Text('Save Attendance'),
              ),
            ),
          ],
        ),
      );
    }
  }
}
