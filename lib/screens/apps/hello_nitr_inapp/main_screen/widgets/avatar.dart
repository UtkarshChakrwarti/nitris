import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:nitris/core/constants/app_colors.dart';
import 'package:nitris/core/utils/image_validator.dart';

class Avatar extends StatelessWidget {
  final String? photoUrl;
  final String? firstName;

  const Avatar({
    super.key,
    required this.photoUrl,
    required this.firstName,
  });

  @override
  Widget build(BuildContext context) {
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      if (ImageValidator().isValidBase64Image(photoUrl!)) {
        return _buildCircleAvatar(
          backgroundImage: MemoryImage(base64Decode(photoUrl!)),
        );
      } else if (Uri.tryParse(photoUrl!)?.hasAbsolutePath ?? false) {
        return _buildCircleAvatar(
          backgroundImage: CachedNetworkImageProvider(photoUrl!),
        );
      }
    }
    return _buildCircleAvatar(
      child: Text(
        firstName?.isNotEmpty == true ? firstName![0] : '',
        style: const TextStyle(
            color: AppColors.primaryColor, fontFamily: 'Roboto'),
      ),
    );
  }

  Widget _buildCircleAvatar({ImageProvider? backgroundImage, Widget? child}) {
    return Container(
      padding: const EdgeInsets.all(1),
      decoration: const BoxDecoration(
        color: AppColors.primaryColor,
        shape: BoxShape.circle,
      ),
      child: CircleAvatar(
        radius: 24,
        backgroundColor: AppColors.secondaryColor,
        backgroundImage: backgroundImage,
        child: child,
      ),
    );
  }
}
