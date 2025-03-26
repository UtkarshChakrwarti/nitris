import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For SystemChrome
import 'package:nitris/core/services/local/local_storage_service.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:intl/intl.dart';
import 'package:nitris/core/constants/app_colors.dart';
import 'package:nitris/core/models/subject.dart';

class StudentSubjectQrScreen extends StatefulWidget {
  final Subject subject;
  final String attendanceDate;

  const StudentSubjectQrScreen({
    required this.subject,
    required this.attendanceDate,
    Key? key,
  }) : super(key: key);

  @override
  _StudentSubjectQrScreenState createState() => _StudentSubjectQrScreenState();
}

class _StudentSubjectQrScreenState extends State<StudentSubjectQrScreen>
    with SingleTickerProviderStateMixin {
  Position? _currentPosition;
  bool _isLoading = true;
  String? _error;
  String? _empCode; // Employee code

  late AnimationController _animationController;
  late Animation<double> _animation;

  String _localDateString = '';
  String get _semester => widget.subject.session;

  @override
  void initState() {
    super.initState();
    // Lock orientation to portrait for this screen
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    _initializeAnimation();
    _formatAttendanceDate();
    _fetchData(); // Start loading employee code and location
  }

  @override
  void dispose() {
    // Restore all orientations when leaving
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    _animationController.dispose();
    super.dispose();
  }

  /// Initialize your animation
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

  /// Fetch employee code and current location
  Future<void> _fetchData() async {
    try {
      // 1) Get employee code from local storage
      _empCode = await LocalStorageService.getCurrentUserEmpCode();

      // 2) Get current location
      await _getCurrentLocation();

      setState(() {
        _isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Format attendance date nicely for display
  void _formatAttendanceDate() {
    try {
      final parsedDateTime = DateTime.parse(widget.attendanceDate).toLocal();
      _localDateString =
          DateFormat('dd MMM yyyy, hh:mm a').format(parsedDateTime);
    } catch (e) {
      _localDateString = widget.attendanceDate;
    }
  }

  /// Get current location with permission checks
  Future<void> _getCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception("Location permissions are denied.");
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception("Location permissions are permanently denied.");
    }
    _currentPosition = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  /// Return a plain string for the QR code: <empCode|long|lat|timestamp|sectionId>
  String generateQRData(
    String empCode,
    String lat,
    String long,
    String timestamp,
    String sectionId,
  ) {
    return '$empCode|$long|$lat|$timestamp|$sectionId';
  }

  @override
  Widget build(BuildContext context) {
    final sectionId = widget.subject.sectionId.toString();
    final generatedTime = DateTime.now().toIso8601String();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.white,         // White background for status bar
        statusBarIconBrightness: Brightness.dark, // Dark icons in status bar
      ),
      child: Scaffold(
        appBar: AppBar(
          elevation: 0.5,
          backgroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.black87,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          centerTitle: true,
          title: const Text(
            'Attendance QR',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          // Ensure dark icons on the status bar area above the AppBar
          systemOverlayStyle: SystemUiOverlayStyle.dark,
        ),
        backgroundColor: Colors.white,
        // SafeArea so content is below the status bar
        body: SafeArea(
          child: _buildBody(sectionId, generatedTime),
        ),
      ),
    );
  }

  Widget _buildBody(String sectionId, String generatedTime) {
    if (_isLoading) return _buildLoadingScreen();
    if (_error != null) return _buildErrorScreen(_error!);

    final empCode = _empCode ?? 'UNKNOWN';
    final lat = _currentPosition?.latitude.toStringAsFixed(6) ?? '0.0';
    final long = _currentPosition?.longitude.toStringAsFixed(6) ?? '0.0';

    // Generate final QR data (no encryption)
    final qrData = generateQRData(empCode, lat, long, generatedTime, sectionId);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          _buildSubjectInfoCard(),
          const SizedBox(height: 20),
          ScaleTransition(
            scale: _animation,
            child: _buildQRCodeCard(qrData),
          ),
          const SizedBox(height: 20),
          _buildDetailsCard(lat, long, widget.subject.subjectCode),
          const SizedBox(height: 30),
          _buildDoneButton(),
        ],
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          LoadingAnimationWidget.staggeredDotsWave(
            color: AppColors.primaryColor,
            size: 50,
          ),
          const SizedBox(height: 16),
          Text(
            'Generating Attendance QR...',
            style: TextStyle(
              color: AppColors.primaryColor,
              fontSize: 16,
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
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: AppColors.darkRed, size: 60),
            const SizedBox(height: 12),
            Text(
              'QR Generation Failed',
              style: TextStyle(
                color: AppColors.darkRed,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textColor,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'Go Back',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectInfoCard() {
    final monthString = DateFormat('MMMM')
        .format(DateTime.parse(widget.attendanceDate).toLocal());

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.subject.subjectName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoChip('Code', widget.subject.subjectCode),
              _buildInfoChip('Semester', _semester),
              _buildInfoChip('Month', monthString),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.primaryColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
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

  Widget _buildQRCodeCard(String qrData) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          QrImageView(
            data: qrData,
            version: QrVersions.auto,
            size: 220,
            foregroundColor: AppColors.primaryColor,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.qr_code_scanner_rounded,
                color: AppColors.primaryColor,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                "Scan to Register Attendance",
                style: TextStyle(
                  color: AppColors.primaryColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(String lat, String long, String subjectCode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildDetailRow(
            Icons.access_time_outlined,
            'Date & Time',
            _localDateString,
          ),
          const Divider(height: 25),
          _buildDetailRow(
            Icons.class_,
            'Subject Code',
            subjectCode,
          ),
          const Divider(height: 25),
          _buildDetailRow(
            Icons.location_on_outlined,
            'Location',
            '$lat, $long',
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryColor, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: AppColors.textColor.withOpacity(0.7),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDoneButton() {
    return ElevatedButton(
      onPressed: () => Navigator.of(context).pop(),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
        elevation: 5,
      ),
      child: const Text(
        'Done',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white, // White text for the button
        ),
      ),
    );
  }
}
