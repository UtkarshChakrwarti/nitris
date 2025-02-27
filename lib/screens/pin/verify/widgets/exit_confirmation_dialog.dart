import 'package:flutter/material.dart';
import 'package:nitris/core/constants/app_colors.dart';

Future<bool?> showExitConfirmationDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
        title: const Row(
          children: [
            Icon(Icons.lock_outline, color: AppColors.primaryColor),
            SizedBox(width: 10),
            Text('Unlock',
                style: TextStyle(
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text('You can only use Hello NITR when it\'s unlocked',
            style: TextStyle(fontSize: 16)),
        actions: [
          TextButton(
            child: const Text('Cancel',
                style: TextStyle(
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.bold)),
            onPressed: () {
              Navigator.of(context).pop(true);
            },
          ),
          TextButton(
            child: const Text('Unlock',
                style: TextStyle(
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.bold)),
            onPressed: () {
              Navigator.of(context).pop(false);
            },
          ),
        ],
      );
    },
  );
}
