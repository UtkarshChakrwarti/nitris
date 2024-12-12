import 'dart:convert';
import 'dart:typed_data'; // Required for Uint8List
import 'package:flutter/material.dart';
import 'package:nitris/core/constants/app_colors.dart';

class UserProfilePopup extends StatefulWidget {
  final String userName;
  final String avatarBase64;
  final String designation;
  final String department;
  final String mobile;
  final String workNumber;
  final String residence;
  final String email;
  final String cabinNumber;
  final String quarterNumber;

  const UserProfilePopup({
    super.key,
    required this.userName,
    required this.avatarBase64,
    required this.designation,
    required this.department,
    required this.mobile,
    required this.workNumber,
    required this.residence,
    required this.email,
    required this.cabinNumber,
    required this.quarterNumber,
  });

  @override
  _UserProfilePopupState createState() => _UserProfilePopupState();
}

class _UserProfilePopupState extends State<UserProfilePopup> {
  Uint8List? _decodedImage;

  @override
  void initState() {
    super.initState();
    _decodeImage();
  }

  void _decodeImage() {
    if (widget.avatarBase64.isNotEmpty) {
      try {
        _decodedImage = base64Decode(widget.avatarBase64);
      } catch (e) {
        // Handle decoding error if necessary
        _decodedImage = null;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isImageValid = _decodedImage != null && _decodedImage!.isNotEmpty;
    const List<String> labels = [
      "Mobile",
      "Work Number",
      "Residence",
      "Work Email",
      "Cabin Number",
      "Quarter Number"
    ];
    double labelWidth = _calculateMaxLabelWidth(labels, context);

    return Container(
      width: MediaQuery.of(context).size.width,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.primaryColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.secondaryColor,
                    backgroundImage: isImageValid
                        ? MemoryImage(_decodedImage!)
                        : null,
                    child: !isImageValid
                        ? Text(
                            widget.userName.isNotEmpty
                                ? widget.userName[0].toUpperCase()
                                : '',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                              fontSize: 48,
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.userName,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.designation,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.department,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Divider(
              color: Colors.white.withOpacity(0.3),
              thickness: 1,
            ),
            _buildDetailTile("Mobile",
                widget.mobile.startsWith("+91") ? widget.mobile : "+91 ${widget.mobile}",
                labelWidth),
            _buildDetailTile("Work Number", "+91 661246 ${widget.workNumber}",
                labelWidth),
            _buildDetailTile("Residence", "+91 661246 ${widget.residence}",
                labelWidth),
            _buildDetailTile("Work Email", widget.email, labelWidth),
            Divider(
              color: Colors.white.withOpacity(0.3),
              thickness: 1,
            ),
            _buildDetailTile("Cabin Number", widget.cabinNumber, labelWidth),
            _buildDetailTile("Quarter Number", widget.quarterNumber, labelWidth),
          ],
        ),
      ),
    );
  }

  double _calculateMaxLabelWidth(List<String> labels, BuildContext context) {
    double maxWidth = 0;
    final TextStyle labelStyle = const TextStyle(
      fontFamily: 'Inter',
      fontWeight: FontWeight.w600,
      fontSize: 16,
      letterSpacing: -0.2,
      color: Colors.white,
    );

    for (var label in labels) {
      final TextPainter textPainter = TextPainter(
        text: TextSpan(text: "$label:", style: labelStyle),
        maxLines: 1,
        textDirection: TextDirection.ltr,
      )..layout();
      if (textPainter.size.width > maxWidth) {
        maxWidth = textPainter.size.width;
      }
    }

    return maxWidth + 12;
  }

  Widget _buildDetailTile(String title, String value, double labelWidth) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: labelWidth,
            child: Text(
              "$title:",
              style: const TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                fontSize: 16,
                letterSpacing: -0.2,
                color: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : 'N/A',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w400,
                letterSpacing: -0.2,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}