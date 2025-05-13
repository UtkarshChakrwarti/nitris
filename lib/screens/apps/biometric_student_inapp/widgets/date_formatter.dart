import 'package:flutter/material.dart';
import 'package:nitris/core/constants/app_colors.dart';

/// Displays a DateTime as "Wednesday, 02-APR-2024" without intl
class FormattedDateLabel extends StatelessWidget {
  final DateTime date;
  const FormattedDateLabel({Key? key, required this.date}) : super(key: key);

  static const List<String> _weekdays = [
    'Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'
  ];
  static const List<String> _months = [
    'Jan','Feb','Mar','Apr','May','Jun',
    'Jul','Aug','Sep','Oct','Nov','Dec'
  ];

  @override
  Widget build(BuildContext context) {
    final wd  = _weekdays[date.weekday - 1];
    final day = date.day.toString().padLeft(2, '0');
    final mo  = _months[date.month - 1].toUpperCase();
    final yr  = date.year.toString();
    return Text(
      '$wd, $day-$mo-$yr',
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 13,
        color: AppColors.textColor,
      ),
    );
  }
}
