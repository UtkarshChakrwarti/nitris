import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:geolocator/geolocator.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:intl/intl.dart';
import 'package:nitris/core/constants/app_constants.dart';
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
  AnimationController? _animationController;
  Animation<double>? _animation;

  /// Provide a default value to avoid LateInitializationError
  String _localDateString = '';

  @override
  void initState() {
    super.initState();
    _initializeAnimation();
    _getCurrentLocation();
    _formatAttendanceDate();
  }

  void _initializeAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController!,
      curve: Curves.easeInOutBack,
    );
  }

  void _formatAttendanceDate() {
    try {
      final parsedDateTime = DateTime.parse(widget.attendanceDate).toLocal();
      _localDateString = DateFormat('dd MMM yyyy, hh:mm a').format(parsedDateTime);
    } catch (e) {
      // If parsing fails, just keep the original string
      _localDateString = widget.attendanceDate;
    }
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _error = "Location permissions are denied.";
            _isLoading = false;
          });
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _error = "Location permissions are permanently denied.";
          _isLoading = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
        _isLoading = false;
        _animationController?.forward(); // start the animation
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String generateEncryptedQRData(
      String sectionId, String lat, String long, String generated) {
    final rawKey = AppConstants.securityKey;
    final normalizedKey = rawKey.padRight(16, '0').substring(0, 16);
    final key = encrypt.Key.fromUtf8(normalizedKey);
    final iv = encrypt.IV.fromLength(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    final data = '$sectionId|$lat|$long|$generated';
    final encrypted = encrypter.encrypt(data, iv: iv);
    return encrypted.base64;
  }

  @override
  Widget build(BuildContext context) {
    final sectionId = widget.subject.sectionId.toString();
    final generated = DateTime.now().toIso8601String();

    return Scaffold(
      // Title is the subject name
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        title: Text(widget.subject.subjectName),
        centerTitle: true,
      ),
      backgroundColor: AppColors.lightSecondaryColor,
      body: _buildBody(sectionId, generated),
    );
  }

  Widget _buildBody(String sectionId, String generated) {
    if (_isLoading) {
      return Center(
        child: LoadingAnimationWidget.staggeredDotsWave(
          color: AppColors.primaryColor,
          size: 60,
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: AppColors.darkRed, size: 48),
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
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textColor,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final lat = _currentPosition?.latitude.toStringAsFixed(6) ?? "0.0";
    final long = _currentPosition?.longitude.toStringAsFixed(6) ?? "0.0";
    final qrData = generateEncryptedQRData(sectionId, lat, long, generated);

    // Main content when loaded & no error
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Instruction
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.qr_code, size: 28),
                const SizedBox(width: 8),
                Text(
                  "Show this QR to register attendance",
                  style: TextStyle(
                    color: AppColors.textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Animated QR Card
            ScaleTransition(
              scale: _animation ?? kAlwaysCompleteAnimation,
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                color: AppColors.primaryColor,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: QrImageView(
                    data: qrData,
                    version: QrVersions.auto,
                    size: 220,
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.transparent,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Date/Time with Icon
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_today_outlined,
                    size: 18, color: AppColors.textColor),
                const SizedBox(width: 6),
                Text(
                  _localDateString,
                  style: TextStyle(
                    color: AppColors.textColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Section
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.class_, size: 18, color: AppColors.textColor),
                const SizedBox(width: 6),
                Text(
                  "Section: $sectionId",
                  style: TextStyle(
                    color: AppColors.textColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Location with Icon
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_on_outlined,
                    size: 18, color: AppColors.textColor),
                const SizedBox(width: 6),
                Text(
                  "$lat, $long",
                  style: TextStyle(
                    color: AppColors.textColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
