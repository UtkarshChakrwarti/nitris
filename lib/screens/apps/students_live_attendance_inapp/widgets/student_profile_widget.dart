import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:logger/logger.dart';
import 'package:nitris/core/constants/app_colors.dart';
import 'package:nitris/core/models/login.dart';

class StudentProfileWidget extends StatelessWidget {
  final LoginResponse student;
  static final Logger _logger = Logger();
  static final Map<String, MemoryImage> _imageCache = {};

  const StudentProfileWidget({
    required this.student,
    Key? key,
  }) : super(key: key);

  String _getFullName() {
    return '${student.salutation ?? ''} ${student.firstName ?? ''} ${student.middleName ?? ''} ${student.lastName ?? ''}'
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _getFirstInitial() {
    String fullName = _getFullName();
    return fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';
  }

  MemoryImage? _getBase64Image(String imageData) {
    try {
      if (_imageCache.containsKey(imageData)) return _imageCache[imageData];
      final bytes = base64Decode(imageData);
      final img = MemoryImage(bytes);
      _imageCache[imageData] = img;
      return img;
    } catch (e) {
      _logger.e("Invalid base64 image", error: e);
      return null;
    }
  }

  Widget _buildAvatar() {
    final photo = student.photo;
    if (photo == null || photo.isEmpty) {
      return _buildFallbackAvatar();
    }

    final base64Image = _getBase64Image(photo);
    if (base64Image != null) {
      return CircleAvatar(
        radius: 26,
        backgroundImage: base64Image,
        backgroundColor: AppColors.secondaryColor,
      );
    }

    return CircleAvatar(
      radius: 26,
      backgroundColor: AppColors.secondaryColor,
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: photo,
          width: 52,
          height: 52,
          fit: BoxFit.cover,
          placeholder: (context, url) => const CircularProgressIndicator(),
          errorWidget: (context, url, error) {
            _logger.e("Image load error", error: error);
            return _buildFallbackAvatar();
          },
        ),
      ),
    );
  }

  Widget _buildFallbackAvatar() {
    return CircleAvatar(
      radius: 26,
      backgroundColor: AppColors.secondaryColor,
      child: Text(
        _getFirstInitial(),
        style: const TextStyle(
          color: AppColors.primaryColor,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Hero(
          tag: 'student_avatar_${_getFullName()}',
          child: _buildAvatar(),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getFullName(),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.normal,
                  color: Colors.white,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (student.empCode != null)
                Text(
                  student.empCode!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
