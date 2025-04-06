import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For SystemChrome
import 'package:nitris/core/services/local/local_storage_service.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import 'package:nitris/core/constants/app_colors.dart';
import 'package:nitris/core/models/subject.dart';
import 'package:geolocator/geolocator.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:no_screenshot/no_screenshot.dart';

/// Simple XOR encryption helper.
String simpleXorEncrypt(String plainText, String key) {
  final plainBytes = utf8.encode(plainText);
  final keyBytes = utf8.encode(key);
  final encryptedBytes = <int>[];
  for (int i = 0; i < plainBytes.length; i++) {
    encryptedBytes.add(plainBytes[i] ^ keyBytes[i % keyBytes.length]);
  }
  return base64.encode(encryptedBytes);
}

class StudentSubjectQrScreen extends StatefulWidget {
  final Subject subject;
  final String attendanceDate;
  final Position currentPosition; // Passed from the previous screen

  const StudentSubjectQrScreen({
    required this.subject,
    required this.attendanceDate,
    required this.currentPosition,
    Key? key,
  }) : super(key: key);

  @override
  _StudentSubjectQrScreenState createState() => _StudentSubjectQrScreenState();
}

class _StudentSubjectQrScreenState extends State<StudentSubjectQrScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  bool _isLoading = true;
  String? _error;
  String? _empCode;
  String _empName = '';
  bool _allowPop = false;

  // Flag to indicate a mock (fake) location.
  bool _isMockLocation = false;
  bool _didCheckFakeLocation = false; // To ensure the check runs only once.

  late AnimationController _animationController;
  late Animation<double> _animation;

  String _localDateString = '';
  String get _semester => widget.subject.session;
  String get _acedmicYear => widget.subject.academicYear;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Disable screenshots for this page (Android only)
    _disableScreenshots();

    // Lock orientation to portrait mode.
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _initializeAnimation();
    _formatAttendanceDate();
    _fetchData();
    // _checkFakeLocation will be run in didChangeDependencies.
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didCheckFakeLocation) {
      _checkFakeLocation();
      _didCheckFakeLocation = true;
    }
  }

  Future<void> _checkFakeLocation() async {
    // Only perform the fake location check on Android.
    if (Platform.isAndroid) {
      // Use geolocator's Position.isMocked to detect mock locations.
      if (widget.currentPosition.isMocked) {
        if (!mounted) return;
        // Set flag so that the QR code won't be generated.
        setState(() {
          _isMockLocation = true;
        });

        // Schedule showing the dialog after the current frame.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text('Fake Location Detected'),
              content: const Text(
                  'Your location appears to be faked. Please use a valid location to proceed.'),
              actions: [
                ElevatedButton(
                  onPressed: () => exit(0),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                  ),
                  child: const Text(
                    'OK',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          );
        });
      }
    }
  }

  /// Disables screenshot capture on Android using no_screenshot plugin.
  Future<void> _disableScreenshots() async {
    await NoScreenshot.instance.screenshotOff();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Re-enable screenshots when leaving this screen.
    NoScreenshot.instance.screenshotOn();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // When returning to the app, if this route is current, disable screenshots.
      if (ModalRoute.of(context)?.isCurrent ?? false) {
        _disableScreenshots();
      }
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      // When app goes to background, re-enable screenshots.
      NoScreenshot.instance.screenshotOn();
    }
  }

  void _initializeAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );
  }

  Future<void> _fetchData() async {
    try {
      _empCode = await LocalStorageService.getCurrentUserEmpCode();
      _empName = (await LocalStorageService.getCurrentUserFullName())!;
      setState(() => _isLoading = false);
      _animationController.forward();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _formatAttendanceDate() {
    try {
      final parsedDate = DateTime.parse(widget.attendanceDate);
      _localDateString =
          DateFormat('dd MMM yyyy, hh:mm a').format(parsedDate);
    } catch (e) {
      _localDateString = widget.attendanceDate;
    }
  }

  String generateQRData(String empCode, String lat, String long,
      String timestamp, String sectionId) {
    final plainData = '$empCode|$long|$lat|$timestamp|$sectionId';
    return encryptQRData(plainData);
  }

  String encryptQRData(String plainText) {
    return simpleXorEncrypt(plainText, 'mysecretkey');
  }

  @override
  Widget build(BuildContext context) {
    final sectionId = widget.subject.sectionId.toString();
    final generatedTime = DateTime.now().toIso8601String();

    return WillPopScope(
      onWillPop: () async => _allowPop,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.white,
          statusBarIconBrightness: Brightness.dark,
        ),
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: PreferredSize(
            preferredSize: Size.zero,
            child: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
            ),
          ),
          body: SafeArea(child: _buildBody(sectionId, generatedTime)),
        ),
      ),
    );
  }

  Widget _buildBody(String sectionId, String generatedTime) {
    // If a fake location is detected, display a message and don't generate the QR.
    if (_isMockLocation) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'Fake location detected. QR code generation has been disabled.\nPlease use a valid location to register your attendance.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.darkRed,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    if (_isLoading) return _buildLoadingScreen();
    if (_error != null) return _buildErrorScreen(_error!);

    final empCode = _empCode ?? 'UNKNOWN';
    final lat = widget.currentPosition.latitude.toStringAsFixed(6);
    final long = widget.currentPosition.longitude.toStringAsFixed(6);
    final qrData =
        generateQRData(empCode, lat, long, generatedTime, sectionId);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSubjectInfoCard(),
          const SizedBox(height: 16),
          ScaleTransition(scale: _animation, child: _buildQRCodeCard(qrData)),
          const SizedBox(height: 16),
          _buildDetailsCard(lat, long, widget.subject.subjectCode),
          const SizedBox(height: 16),
          _buildDoneButton(),
        ],
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LoadingAnimationWidget.staggeredDotsWave(
            color: AppColors.primaryColor,
            size: 40,
          ),
          const SizedBox(height: 10),
          Text(
            'Generating Attendance QR...',
            style: TextStyle(
              color: AppColors.primaryColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorScreen(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: AppColors.darkRed, size: 50),
            const SizedBox(height: 10),
            const Text(
              'QR Generation Failed',
              style: TextStyle(
                color: AppColors.darkRed,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textColor,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 10),
              ),
              child: const Text(
                'Go Back',
                style:
                    TextStyle(fontSize: 14, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectInfoCard() {
    String monthString;
    try {
      monthString = DateFormat('MMMM')
          .format(DateTime.parse(widget.attendanceDate).toLocal());
    } catch (e) {
      monthString = 'N/A';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.subject.subjectName,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoPill('Code', widget.subject.subjectCode),
              _buildInfoPill('Semester', '$_semester $_acedmicYear'),
              _buildInfoPill('Month', monthString),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoPill(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
                color: AppColors.primaryColor,
                fontSize: 10,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 1),
          Text(value,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildQRCodeCard(String qrData) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          QrImageView(
            data: qrData,
            version: QrVersions.auto,
            size: 200,
            foregroundColor: AppColors.primaryColor,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.qr_code_scanner_rounded,
                    color: AppColors.primaryColor, size: 18),
                SizedBox(width: 6),
                Text(
                  "Scan to Register Attendance",
                  style: TextStyle(
                      color: AppColors.primaryColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(String lat, String long, String subjectCode) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildDetailRow(Icons.access_time_outlined, 'Date & Time',
              _localDateString),
          const Divider(height: 16),
          _buildDetailRow(Icons.class_, 'Student Details',
              'Roll No: $_empCode\nName: $_empName'),
          const Divider(height: 16),
          _buildDetailRow(
              Icons.location_on_outlined, 'Location', '$lat, $long'),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(icon,
              color: AppColors.primaryColor, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      color: AppColors.textColor.withOpacity(0.7),
                      fontSize: 12)),
              const SizedBox(height: 4),
              Text(value,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDoneButton() {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _allowPop = true;
        });
        Navigator.of(context).pop();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryColor,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30)),
        padding: const EdgeInsets.symmetric(
            horizontal: 24, vertical: 10),
        elevation: 4,
      ),
      child: const Text(
        'Done',
        style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white),
      ),
    );
  }
}
