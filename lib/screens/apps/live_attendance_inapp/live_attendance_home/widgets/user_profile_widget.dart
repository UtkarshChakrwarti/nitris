import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:logger/logger.dart';
import 'package:nitris/core/constants/app_colors.dart';
import 'package:nitris/core/models/faculty.dart';

class UserProfileWidget extends StatelessWidget {
  final Faculty user;
  static final Logger _logger = Logger();
  
  // Cache for base64 decoded images
  static final Map<String, MemoryImage> _imageCache = {};

  const UserProfileWidget({
    required this.user,
    super.key,
  });

  /// Extracts the first initial of the user's name.
  String _getFirstInitial(String? name) {
    if (name == null || name.isEmpty) {
      return '?';
    }
    return name[0].toUpperCase();
  }

  /// Creates a fallback avatar with initials
  Widget _buildFallbackAvatar() {
    return CircleAvatar(
      radius: 40,
      backgroundColor: AppColors.secondaryColor,
      child: Text(
        _getFirstInitial(user.name),
        style: const TextStyle(
          color: AppColors.primaryColor,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          fontFamily: 'Roboto',
        ),
      ),
    );
  }

  /// Checks and decodes base64 image
  MemoryImage? _getBase64Image(String avatarUrl) {
    try {
      // Check cache first
      if (_imageCache.containsKey(avatarUrl)) {
        return _imageCache[avatarUrl];
      }
      final imageBytes = base64Decode(avatarUrl);
      final memoryImage = MemoryImage(imageBytes);
      // Store in cache
      _imageCache[avatarUrl] = memoryImage;
      return memoryImage;
    } catch (e) {
      _logger.e("Invalid base64 image", error: e);
      return null;
    }
  }

  /// Builds the avatar widget with caching
  Widget _buildAvatar() {
    // Handle empty avatar URL
    if (user.avatarUrl.isEmpty) {
      return _buildFallbackAvatar();
    }
    try {
      // Try processing as base64 first
      final base64Image = _getBase64Image(user.avatarUrl);
      if (base64Image != null) {
        return CircleAvatar(
          radius: 25,
          backgroundImage: base64Image,
          backgroundColor: AppColors.secondaryColor,
        );
      }
      // If not base64, treat as a network image
      return CircleAvatar(
        radius: 25,
        backgroundColor: AppColors.secondaryColor,
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: user.avatarUrl,
            width: 80,
            height: 80,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: AppColors.secondaryColor,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
            errorWidget: (context, url, error) {
              _logger.e("Failed to load network image", error: error);
              return _buildFallbackAvatar();
            },
          ),
        ),
      );
    } catch (error, stackTrace) {
      _logger.e(
        "Exception while building avatar",
        error: error,
        stackTrace: stackTrace,
      );
      return _buildFallbackAvatar();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Clamp text so large system fonts won't push icons off-screen
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: AppColors.primaryColor,
        child: Row(
          children: [
            // Hero avatar
            Hero(
              tag: 'user_avatar_${user.name}',
              child: _buildAvatar(),
            ),
            const SizedBox(width: 12),
            
            // Text info (expanded so it doesn't overflow horizontally)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User name, truncated if too long
                  Text(
                    user.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Semester info, also truncated
                  Text(
                    '${user.semester} ${user.academicYear} | ${user.subjects.length} Subjects',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}