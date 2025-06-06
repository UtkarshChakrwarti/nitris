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
            Icon(Icons.exit_to_app, color: AppColors.primaryColor),
            SizedBox(width: 10),
            Text('Exit',
                style: TextStyle(
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text('Are you sure you want to exit?',
            style: TextStyle(fontSize: 16)),
        actions: [
          TextButton(
            child: const Text('No',
                style: TextStyle(
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.bold)),
            onPressed: () {
              Navigator.of(context).pop(false);
            },
          ),
          TextButton(
            child: const Text('Yes',
                style: TextStyle(
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.bold)),
            onPressed: () {
              Navigator.of(context).pop(true);
            },
          ),
        ],
      );
    },
  );
}
