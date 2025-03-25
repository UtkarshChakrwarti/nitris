import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:audioplayers/audioplayers.dart';

import 'package:nitris/core/constants/app_colors.dart';
import 'package:nitris/core/models/student.dart';
import 'package:nitris/core/models/subject.dart';
import 'package:nitris/core/services/remote/api_service.dart';
import 'package:nitris/core/utils/dialogs_and_prompts.dart';
import 'package:nitris/screens/apps/live_attendance_inapp/attendance/widgets/attendance_header.dart';
import 'package:nitris/screens/apps/live_attendance_inapp/attendance/widgets/student_tile.dart';

class AttendancePage extends StatefulWidget {
  final int date;
  final int month;
  final Subject subject;
  final String semester;
  final String currentYear;
  final int classNumber;
  final int sectionId;
  final String sessionTime; // session start time in IST format

  const AttendancePage({
    Key? key,
    required this.date,
    required this.month,
    required this.subject,
    required this.semester,
    required this.currentYear,
    required this.classNumber,
    required this.sectionId,
    required this.sessionTime,
  }) : super(key: key);

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  // Services and logging
  final ApiService _apiService = ApiService();
  final Logger _logger = Logger('AttendancePage');

  // State variables
  List<Student> students = [];
  bool _isLoading = true;
  bool _isAttendanceSaved = false;
  bool _isManualMode = false;

  // QR scanner variables
  final GlobalKey _qrViewKey = GlobalKey(debugLabel: 'QR');
  QRViewController? _qrController;
  String? _lastScannedCode;

  final AudioPlayer _audioPlayer = AudioPlayer();

  // Month names constant
  static const List<String> _monthNames = [
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

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _fetchStudents();
    _audioPlayer.setSource(AssetSource('audio/success.mp3'));
    _audioPlayer.setSource(AssetSource('audio/error.mp3'));
  }

  @override
  void dispose() {
    _qrController?.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playSound(String fileName) async {
    await _audioPlayer.stop();
    await _audioPlayer.play(AssetSource('audio/$fileName'));
  }

  @override
  void reassemble() {
    super.reassemble();
    try {
      if (Platform.isAndroid) _qrController?.pauseCamera();
      _qrController?.resumeCamera();
    } catch (e) {
      _logger.warning('Camera reassemble error: $e');
    }
  }

  String _getMonthName(int month) =>
      (month >= 1 && month <= 12) ? _monthNames[month - 1] : 'Invalid';

  Future<void> _fetchStudents() async {
    setState(() => _isLoading = true);
    try {
      final fetchedStudents = await _apiService.getStudents(widget.sectionId);
      setState(() {
        students = fetchedStudents;
        _isLoading = false;
      });
      if (!_isManualMode) {
        _markAllAbsent();
      }
    } catch (e, st) {
      _logger.severe('Error fetching students: $e', e, st);
      setState(() => _isLoading = false);
      // On error, vibrate and play error sound.
      HapticFeedback.vibrate();
      await _playSound('error.mp3');
      DialogsAndPrompts.showFailureDialog(
          context, 'Failed to load students: $e');
    }
  }

  void _markAllAbsent() {
    for (var student in students) {
      student.status = AttendanceStatus.absent;
    }
  }

  /// Swaps student statuses between `absent` and `notMarked`
  void _swapAbsentNotMarked() {
    for (var student in students) {
      if (student.status == AttendanceStatus.absent) {
        student.status = AttendanceStatus.notMarked;
      } else if (student.status == AttendanceStatus.notMarked) {
        student.status = AttendanceStatus.absent;
      }
    }
  }

  /// When navigating back, terminate the active session.
  /// If there is unsaved attendance, prompt the user first.
  Future<bool> _handleBackNavigation() async {
    bool shouldPop = true;
    if (!_isAttendanceSaved &&
        students.any((s) => s.status != AttendanceStatus.notMarked)) {
      shouldPop =
          await DialogsAndPrompts.showUnsavedAttendanceDialog(context) ?? false;
    }
    if (shouldPop) {
      try {
        _logger.info(
            "Terminating active session on back navigation for section ${widget.sectionId}");
        await _apiService.endLiveSession(widget.sectionId.toString());
        _logger.info("Active session terminated successfully.");
      } catch (e) {
        _logger
            .severe("Error terminating active session on back navigation: $e");
      }
    }
    return shouldPop;
  }

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

  /// First close the session and then save the attendance.
  Future<void> _handleSubmitAttendance() async {
    try {
      // First, close the live session.
      _logger.info("Closing session for section ${widget.sectionId}");
      await _apiService.endLiveSession(widget.sectionId.toString());
      _logger.info("Session closed successfully.");

      // Now, prepare and submit the attendance.
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

      // On successful save, trigger light haptic and play success sound.
      HapticFeedback.lightImpact();
      await _playSound('success.mp3');

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
      // On error, vibrate and play error sound.
      HapticFeedback.vibrate();
      await _playSound('error.mp3');
      DialogsAndPrompts.showFailureDialog(
          context, 'Failed to save attendance: $e');
    }
  }

  Future<void> _handleSubmitButtonPressed() async {
    if (_isManualMode &&
        students
            .where((s) => s.status == AttendanceStatus.notMarked)
            .isNotEmpty) {
      DialogsAndPrompts.showFailureDialog(
        context,
        'Please mark all students (none can be "unmarked") before submitting.',
      );
      return;
    }
    final confirm =
        await DialogsAndPrompts.showConfirmSubmissionDialog(context) ?? false;
    if (confirm) await _handleSubmitAttendance();
  }

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

  void _updateStudentStatus(int index, AttendanceStatus status) {
    setState(() {
      students[index].status = status;
      _isAttendanceSaved = false;
    });
  }

  /// Generic method to show an attendance dialog.
  void _showAttendanceDialog({
    required String title,
    required bool Function(Student) filter,
    required IconData actionIcon,
    required String actionTooltip,
    required AttendanceStatus newStatus,
    Color? iconColor,
  }) {
    final count = students.where(filter).length;
    if (count == 0) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(title, style: TextStyle(color: AppColors.primaryColor)),
          content: Center(
              child: Text(
                  'No student marked ${title.toLowerCase().split(" ")[0]}.')),
          actions: [
            TextButton(
              style:
                  TextButton.styleFrom(foregroundColor: AppColors.primaryColor),
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: StatefulBuilder(
            builder: (ctx, setStateDialog) {
              final localStudents = students.where(filter).toList();
              return SizedBox(
                height: MediaQuery.of(ctx).size.height * 0.85,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
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
                            "$title (${localStudents.length})",
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12),
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
                        itemCount: localStudents.length,
                        itemBuilder: (context, i) {
                          final student = localStudents[i];
                          final idx =
                              students.indexWhere((s) => s.id == student.id);
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
                              title: Text(
                                student.name,
                                style: const TextStyle(
                                    fontSize: 16, color: Colors.black),
                              ),
                              subtitle: Text(
                                "Roll No: ${student.rollNo}",
                                style: const TextStyle(
                                    fontSize: 14, color: Colors.grey),
                              ),
                              trailing: IconButton(
                                icon: Icon(actionIcon,
                                    color: iconColor, size: 28),
                                tooltip: actionTooltip,
                                onPressed: () {
                                  if (idx != -1) {
                                    _updateStudentStatus(idx, newStatus);
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
          ),
        );
      },
    );
  }

  void _showPresentStudentsDialog() {
    _showAttendanceDialog(
      title: "Present Students",
      filter: (s) => s.status == AttendanceStatus.present,
      actionIcon: Icons.remove_circle_outline,
      actionTooltip: 'Mark Absent',
      newStatus: AttendanceStatus.absent,
      iconColor: AppColors.darkRed,
    );
  }

  void _showAbsentStudentsDialog() {
    _showAttendanceDialog(
      title: "Absent Students",
      filter: (s) => s.status == AttendanceStatus.absent,
      actionIcon: Icons.check_circle_outline,
      actionTooltip: 'Mark Present',
      newStatus: AttendanceStatus.present,
      iconColor: AppColors.darkGreen,
    );
  }

  /// Helper function to calculate the distance (in meters) between two coordinates.
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000; // Earth's radius in meters
    final dLat = (lat2 - lat1) * (pi / 180);
    final dLon = (lon2 - lon1) * (pi / 180);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * (pi / 180)) *
            cos(lat2 * (pi / 180)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  /// Fetches the current device (teacher's) location.
  Future<Position> _getTeacherLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied.');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied.');
    }
    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  /// Updated QR code scanned handler.
  /// Expects a QR code in the format:
  ///   <roll number, long, lat, timestamp, sectionid>
  /// Performs the following checks:
  ///   - Validates QR code format.
  ///   - Ensures the QR code's timestamp (4th value) is after the session start time.
  ///   - Checks student location against teacher's location.
  Future<void> _handleScannedCode(String scannedData) async {
    _logger.info("Scanned: $scannedData");
    String data = scannedData.trim();
    // Remove angle brackets if present.
    if (data.startsWith('<') && data.endsWith('>')) {
      data = data.substring(1, data.length - 1);
    }
    final parts = data.split(',');
    if (parts.length != 5) {
      HapticFeedback.vibrate();
      await _playSound('error.mp3');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red[700],
          content: Text(
            'Invalid QR format: $scannedData',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
      return;
    }

    final rollNo = parts[0].trim();
    final studentLong = double.tryParse(parts[1].trim());
    final studentLat = double.tryParse(parts[2].trim());
    final qrTimestampStr = parts[3].trim();
    // parts[4] is sectionId (ignored)

    if (studentLong == null || studentLat == null) {
      HapticFeedback.vibrate();
      await _playSound('error.mp3');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red[700],
          content: const Text(
            'Invalid location data in QR code.',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
      return;
    }

    // Convert the QR timestamp and sessionTime to DateTime objects.
    final qrTimestamp = DateTime.tryParse(qrTimestampStr.replaceAll(' ', 'T'));
    final sessionTimestamp =
        DateTime.tryParse(widget.sessionTime.replaceAll(' ', 'T'));
    if (qrTimestamp == null || sessionTimestamp == null) {
      HapticFeedback.vibrate();
      await _playSound('error.mp3');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red[700],
          content: const Text(
            'Invalid timestamp format.',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
      return;
    }

    // Check that the QR code timestamp is after (or equal to) the session start time.
    if (qrTimestamp.isBefore(sessionTimestamp)) {
      HapticFeedback.vibrate();
      await _playSound('error.mp3');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red[700],
          content: Text(
            'QR code generated before session start. Please use a valid QR code.',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
      return;
    }

    // Get teacher's current location (device location)
    late Position teacherPosition;
    try {
      teacherPosition = await _getTeacherLocation();
      _logger.info(
          "Teacher location: lat: ${teacherPosition.latitude}, long: ${teacherPosition.longitude}");
    } catch (e) {
      HapticFeedback.vibrate();
      await _playSound('error.mp3');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red[700],
          content: Text(
            'Error fetching teacher location: $e',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
      return;
    }
    final teacherLat = teacherPosition.latitude;
    final teacherLong = teacherPosition.longitude;
    final distance =
        calculateDistance(teacherLat, teacherLong, studentLat, studentLong);

// distance Adjustment in mtrs

    if (distance > 100) {
      HapticFeedback.vibrate();
      await _playSound('error.mp3');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red[700],
          content: Text(
            'Student is not within the required range (distance: ${distance.toStringAsFixed(2)} m)',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
      return;
    }

    // Look up the student using a case‑insensitive roll number match.
    final idx = students
        .indexWhere((s) => s.rollNo.toLowerCase() == rollNo.toLowerCase());
    if (idx == -1) {
      HapticFeedback.vibrate();
      await _playSound('error.mp3');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red[700],
          content: Text(
            'No student found with rollNo: $rollNo',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
      return;
    }

    setState(() {
      students[idx].status = AttendanceStatus.present;
      _isAttendanceSaved = false;
    });
    // On successfully marking present, trigger heavy impact and play success sound.
    HapticFeedback.heavyImpact();
    await _playSound('success.mp3');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.green[600],
        content: Text(
          'Marked ${students[idx].name} present!',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    _qrController = controller;
    controller.scannedDataStream.listen((scanData) {
      final code = scanData.code ?? '';
      // Process only if a new QR code is scanned
      if (code.isNotEmpty && code != _lastScannedCode) {
        _lastScannedCode = code;
        _handleScannedCode(code);
      }
    });
  }

  Widget _buildAttendanceHeader() {
    final presentCount =
        students.where((s) => s.status == AttendanceStatus.present).length;
    final absentCount =
        students.where((s) => s.status == AttendanceStatus.absent).length;
    final unmarkedCount =
        students.where((s) => s.status == AttendanceStatus.notMarked).length;
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

  Widget _buildQRView() {
    return Container(
      color: const Color(0xFFFFE4E9),
      child: Stack(
        alignment: Alignment.center,
        children: [
          QRView(
            key: _qrViewKey,
            onQRViewCreated: (controller) {
              try {
                _onQRViewCreated(controller);
              } catch (e) {
                _logger.severe('Error creating QR view: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: Colors.red[700],
                    content: Text(
                      'Camera error: $e',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
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
          ),
          const Positioned(
            width: 200,
            child: Divider(
              thickness: 2,
              color: Colors.redAccent,
            ),
          ),
        ],
      ),
    );
  }

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

  Widget _buildBottomButtons() {
    const buttonPadding = EdgeInsets.symmetric(vertical: 16);
    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: AppColors.primaryColor,
      foregroundColor: Colors.white,
      padding: buttonPadding,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );

    if (!_isManualMode) {
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
                  setState(() {
                    _swapAbsentNotMarked();
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
      return Container(
        padding: const EdgeInsets.all(16),
        color: Colors.white,
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: buttonStyle,
            onPressed: _handleSubmitButtonPressed,
            child: const Text('Save Attendance'),
          ),
        ),
      );
    }
  }

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
              if (await _handleBackNavigation()) Navigator.of(context).pop();
            },
          ),
          actions: [
            if (_isManualMode)
              IconButton(
                icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
                tooltip: 'Switch to QR mode',
                onPressed: () {
                  setState(() {
                    _swapAbsentNotMarked();
                    _isManualMode = false;
                  });
                },
              )
          ],
        ),
        bottomNavigationBar: _buildBottomButtons(),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Container(
                    width: double.infinity,
                    color: AppColors.primaryColor,
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: Center(
                      child: Text(
                        '${widget.semester} ${widget.currentYear} | ${widget.date}-${_getMonthName(widget.month)}-${widget.currentYear} | Class ${widget.classNumber}',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 14),
                      ),
                    ),
                  ),
                  _buildAttendanceHeader(),
                  Expanded(
                    child:
                        _isManualMode ? _buildManualListView() : _buildQRView(),
                  ),
                ],
              ),
      ),
    );
  }
}
