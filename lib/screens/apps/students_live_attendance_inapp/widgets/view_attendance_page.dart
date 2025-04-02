// import 'dart:convert';
// import 'dart:ui';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:nitris/core/constants/app_colors.dart';
// import 'package:nitris/core/constants/app_constants.dart';

// // Define attendance statuses
// enum AttendanceStatus { present, absent, leave, presentLate, absentLate }

// // Model for a single day
// class AttendanceDay {
//   final int day;
//   final AttendanceStatus status;
//   final String statusCode;

//   AttendanceDay({
//     required this.day,
//     required this.status,
//     required this.statusCode,
//   });
// }

// // Model for the entire attendance data
// class AttendanceData {
//   final String rollNo;
//   final String name;
//   final String month;
//   final String subjectCode;
//   final String subjectName;
//   final int year;
//   final int totalClass;
//   final int totalPresent;
//   final int totalAbsent;
//   final List<AttendanceDay> attendanceDays;

//   AttendanceData({
//     required this.rollNo,
//     required this.name,
//     required this.month,
//     required this.subjectCode,
//     required this.subjectName,
//     required this.year,
//     required this.totalClass,
//     required this.totalPresent,
//     required this.totalAbsent,
//     required this.attendanceDays,
//   });

//   factory AttendanceData.fromJson(Map<String, dynamic> json) {
//     List<AttendanceDay> days = [];
//     // Loop through potential attendance entries: c1Date, c2Date, ... c20Date
//     for (int i = 1; i <= 20; i++) {
//       final dateKey = 'c${i}Date';
//       final statusKey = 'c$i';
//       if (json[dateKey] != null && json[dateKey].toString().isNotEmpty) {
//         int dayNum = int.tryParse(json[dateKey].toString()) ?? 0;
//         if (dayNum > 0) {
//           String code = json[statusKey] ?? "";
//           AttendanceStatus status;
//           switch (code) {
//             case "G":
//               status = AttendanceStatus.present;
//               break;
//             case "Y":
//               status = AttendanceStatus.presentLate;
//               break;
//             case "L":
//               status = AttendanceStatus.leave;
//               break;
//             case "R":
//               status = AttendanceStatus.absent;
//               break;
//             case "B":
//               status = AttendanceStatus.absentLate;
//               break;
//             default:
//               status = AttendanceStatus.absent;
//               break;
//           }
//           days.add(AttendanceDay(day: dayNum, status: status, statusCode: code));
//         }
//       }
//     }
//     return AttendanceData(
//       rollNo: json['rollNo'] ?? "",
//       name: json['name'] ?? "",
//       month: json['month'] ?? "",
//       subjectCode: json['subjectCode'] ?? "",
//       subjectName: json['subjectName'] ?? "",
//       year: json['year'] is int
//           ? json['year']
//           : int.tryParse(json['year'].toString()) ?? 0,
//       totalClass: json['totalClass'] is int
//           ? json['totalClass']
//           : int.tryParse(json['totalClass'].toString()) ?? 0,
//       totalPresent: json['totalPresent'] is int
//           ? json['totalPresent']
//           : int.tryParse(json['totalPresent'].toString()) ?? 0,
//       totalAbsent: json['totalAbsent'] is int
//           ? json['totalAbsent']
//           : int.tryParse(json['totalAbsent'].toString()) ?? 0,
//       attendanceDays: days,
//     );
//   }
// }

// class AttendancePage extends StatefulWidget {
//   const AttendancePage({Key? key}) : super(key: key);

//   @override
//   State<AttendancePage> createState() => _AttendancePageState();
// }

// class _AttendancePageState extends State<AttendancePage>
//     with SingleTickerProviderStateMixin {
//   AttendanceData? _data;
//   bool _isLoading = false;
//   String _errorMessage = '';
//   late AnimationController _controller;
//   late Animation<double> _animation;

//   // Filters
//   String _selectedSectionId = 'CS6114';
//   String _selectedMonth = 'February';
//   int _selectedYear = 2025;

//   // Options for filters
//   final List<String> _sectionIds = ['CS6114', 'CS6115', 'CS6116', 'CS6117'];
//   final List<String> _months = [
//     'January',
//     'February',
//     'March',
//     'April',
//     'May',
//     'June',
//     'July',
//     'August',
//     'September',
//     'October',
//     'November',
//     'December'
//   ];
//   final List<int> _years = [2023, 2024, 2025, 2026];

//   // Colors for the UI
//   final Color _primaryColor = AppColors.primaryColor;
//   final Color _secondaryColor = AppColors.secondaryColor;
//   final Color _tertiaryColor = AppColors.lightSecondaryColor;
//   final Color _errorColor = const Color(0xFFB3261E);

//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 800),
//     );
//     _animation = CurvedAnimation(
//       parent: _controller,
//       curve: Curves.easeInOut,
//     );
//     _fetchAttendanceData();
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   Future<void> _fetchAttendanceData() async {
//     setState(() {
//       _isLoading = true;
//       _errorMessage = '';
//     });

//     try {
//       // Simulate an API delay
//       await Future.delayed(const Duration(milliseconds: 800));
//       if (!mounted) return; // Ensure the widget is still mounted
//       final jsonString = '''{
//         "rollNo": "122CS0066",
//         "name": "KRIS CHOUDHURY",
//         "month": "${_selectedMonth}",
//         "subjectCode": "${_selectedSectionId}",
//         "subjectName": "Wireless Sensor Networks",
//         "year": ${_selectedYear},
//         "totalClass": 5,
//         "totalPresent": 5,
//         "totalAbsent": 0,
//         "c1Date": "7",
//         "c2Date": "10",
//         "c3Date": "11",
//         "c4Date": "14",
//         "c5Date": "17",
//         "c6Date": "",
//         "c7Date": "",
//         "c8Date": "",
//         "c9Date": "",
//         "c10Date": "",
//         "c1": "G",
//         "c2": "L",
//         "c3": "L",
//         "c4": "L",
//         "c5": "G",
//         "c6": "",
//         "c7": "",
//         "c8": "",
//         "c9": "",
//         "c10": ""
//       }''';

//       final decoded = jsonDecode(jsonString);
//       _data = AttendanceData.fromJson(decoded);
//       _controller.forward(from: 0.0);
//     } catch (e) {
//       _errorMessage = 'Failed to load attendance data: $e';
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
//   }

//   // Return a color based on attendance status
//   Color _getAttendanceColor(AttendanceStatus status) {
//     switch (status) {
//       case AttendanceStatus.present:
//         return const Color(0xFF4CAF50);
//       case AttendanceStatus.leave:
//         return const Color(0xFFFFB74D);
//       case AttendanceStatus.absent:
//         return const Color(0xFFEF5350);
//       case AttendanceStatus.presentLate:
//         return const Color(0xFF26A69A);
//       case AttendanceStatus.absentLate:
//         return const Color(0xFF9575CD);
//     }
//   }

//   // Build the calendar grid
//   Widget _buildCustomCalendar(AttendanceData data) {
//     int month = _monthNumber(data.month);
//     DateTime firstDay = DateTime(data.year, month, 1);
//     int daysInMonth = DateTime(data.year, month + 1, 0).day;
//     int weekdayOffset = firstDay.weekday % 7;

//     Map<int, AttendanceDay> attendanceMap = {
//       for (var ad in data.attendanceDays) ad.day: ad,
//     };

//     List<Widget> cells = [];
//     for (int i = 0; i < weekdayOffset; i++) {
//       cells.add(Container());
//     }

//     for (int day = 1; day <= daysInMonth; day++) {
//       AttendanceDay? ad = attendanceMap[day];
//       Widget cell;
//       if (ad != null) {
//         cell = FadeTransition(
//           opacity: _animation,
//           child: SlideTransition(
//             position: Tween<Offset>(
//               begin: const Offset(0, 0.2),
//               end: Offset.zero,
//             ).animate(
//               CurvedAnimation(
//                 parent: _controller,
//                 curve: Interval(
//                   0.1 + (0.5 * day / daysInMonth),
//                   0.6 + (0.4 * day / daysInMonth),
//                   curve: Curves.easeOutCubic,
//                 ),
//               ),
//             ),
//             child: Container(
//               margin: const EdgeInsets.all(4),
//               decoration: BoxDecoration(
//                 shape: BoxShape.circle,
//                 color: _getAttendanceColor(ad.status),
//                 boxShadow: [
//                   BoxShadow(
//                     color: _getAttendanceColor(ad.status).withOpacity(0.3),
//                     blurRadius: 8,
//                     offset: const Offset(0, 3),
//                     spreadRadius: 1,
//                   ),
//                 ],
//               ),
//               child: Center(
//                 child: Text(
//                   '$day',
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontWeight: FontWeight.bold,
//                     fontSize: 14,
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         );
//       } else {
//         cell = Container(
//           margin: const EdgeInsets.all(4),
//           decoration: BoxDecoration(
//             shape: BoxShape.circle,
//             color: Colors.grey.shade50,
//             border: Border.all(color: Colors.grey.shade300),
//           ),
//           child: Center(
//             child: Text(
//               '$day',
//               style: TextStyle(
//                 color: Colors.grey.shade400,
//                 fontSize: 14,
//               ),
//             ),
//           ),
//         );
//       }
//       cells.add(cell);
//     }

//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       decoration: BoxDecoration(
//         // “Glossy” effect with a subtle tinted overlay + blur
//         color: Colors.white.withOpacity(0.4),
//         borderRadius: BorderRadius.circular(24),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.04),
//             offset: const Offset(0, 2),
//             blurRadius: 8,
//             spreadRadius: 0,
//           ),
//         ],
//       ),
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(24),
//         child: BackdropFilter(
//           filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
//           child: Padding(
//             padding: const EdgeInsets.all(20),
//             child: Column(
//               children: [
//                 // Header showing month and year
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Container(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 16,
//                         vertical: 8,
//                       ),
//                       decoration: BoxDecoration(
//                         color: _tertiaryColor.withOpacity(0.2),
//                         borderRadius: BorderRadius.circular(20),
//                       ),
//                       child: Text(
//                         '${data.month} ${data.year}',
//                         style: TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.w600,
//                           color: _primaryColor,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 20),
//                 // Weekday headers
//                 Row(
//                   children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
//                       .map(
//                         (d) => Expanded(
//                           child: Center(
//                             child: Text(
//                               d,
//                               style: TextStyle(
//                                 fontWeight: FontWeight.w500,
//                                 color: _primaryColor,
//                                 fontSize: 12,
//                               ),
//                             ),
//                           ),
//                         ),
//                       )
//                       .toList(),
//                 ),
//                 const SizedBox(height: 12),
//                 // Calendar grid
//                 GridView.count(
//                   crossAxisCount: 7,
//                   shrinkWrap: true,
//                   physics: const NeverScrollableScrollPhysics(),
//                   children: cells,
//                   mainAxisSpacing: 4,
//                   crossAxisSpacing: 4,
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   int _monthNumber(String month) {
//     final Map<String, int> monthMap = {
//       'January': 1,
//       'February': 2,
//       'March': 3,
//       'April': 4,
//       'May': 5,
//       'June': 6,
//       'July': 7,
//       'August': 8,
//       'September': 9,
//       'October': 10,
//       'November': 11,
//       'December': 12,
//     };
//     return monthMap[month] ?? 1;
//   }

//   // Build the statistics card
//   Widget _buildStatistics(AttendanceData data) {
//     double percentage = data.totalClass > 0
//         ? (data.totalPresent / data.totalClass) * 100
//         : 0;

//     Color progressColor;
//     if (percentage >= 90) {
//       progressColor = const Color(0xFF4CAF50);
//     } else if (percentage >= 75) {
//       progressColor = const Color(0xFF8BC34A);
//     } else if (percentage >= 65) {
//       progressColor = const Color(0xFFFFC107);
//     } else {
//       progressColor = const Color(0xFFEF5350);
//     }

//     return FadeTransition(
//       opacity: _animation,
//       child: SlideTransition(
//         position: Tween<Offset>(
//           begin: const Offset(0, 0.1),
//           end: Offset.zero,
//         ).animate(
//           CurvedAnimation(
//             parent: _controller,
//             curve: const Interval(0.3, 0.9, curve: Curves.easeOutCubic),
//           ),
//         ),
//         child: Container(
//           margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//           decoration: BoxDecoration(
//             // Subtle “glossy” effect
//             color: Colors.white.withOpacity(0.4),
//             borderRadius: BorderRadius.circular(24),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.04),
//                 offset: const Offset(0, 2),
//                 blurRadius: 8,
//                 spreadRadius: 0,
//               ),
//             ],
//           ),
//           padding: const EdgeInsets.all(24),
//           child: ClipRRect(
//             borderRadius: BorderRadius.circular(24),
//             child: BackdropFilter(
//               filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
//               child: Container(
//                 padding: const EdgeInsets.all(8), // inner content
//                 decoration: BoxDecoration(
//                   color: Colors.white.withOpacity(0.3),
//                   borderRadius: BorderRadius.circular(24),
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // Subject information
//                     Row(
//                       children: [
//                         Container(
//                           padding: const EdgeInsets.all(10),
//                           decoration: BoxDecoration(
//                             color: _primaryColor.withOpacity(0.1),
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                           child: Icon(
//                             Icons.book_outlined,
//                             color: _primaryColor,
//                             size: 24,
//                           ),
//                         ),
//                         const SizedBox(width: 16),
//                         Expanded(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 data.subjectName,
//                                 style: const TextStyle(
//                                   fontWeight: FontWeight.bold,
//                                   fontSize: 18,
//                                   color: Colors.black87,
//                                   height: 1.2,
//                                 ),
//                                 overflow: TextOverflow.ellipsis,
//                               ),
//                               Text(
//                                 data.subjectCode,
//                                 style: const TextStyle(
//                                   fontSize: 14,
//                                   color: Colors.black54,
//                                   height: 1.5,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 24),
//                     // Statistics cards
//                     Row(
//                       children: [
//                         _buildModernStatCard(
//                           'Total Classes',
//                           '${data.totalClass}',
//                           Icons.calendar_today_rounded,
//                           0.4,
//                         ),
//                         const SizedBox(width: 12),
//                         _buildModernStatCard(
//                           'Present',
//                           '${data.totalPresent}',
//                           Icons.check_circle_rounded,
//                           0.5,
//                         ),
//                         const SizedBox(width: 12),
//                         _buildModernStatCard(
//                           'Absent',
//                           '${data.totalAbsent}',
//                           Icons.cancel_rounded,
//                           0.6,
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 24),
//                     // Attendance percentage
//                     Text(
//                       'Attendance Percentage',
//                       style: const TextStyle(
//                         fontWeight: FontWeight.w500,
//                         color: Colors.black54,
//                         fontSize: 14,
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     Row(
//                       children: [
//                         Expanded(
//                           child: TweenAnimationBuilder<double>(
//                             duration: const Duration(milliseconds: 1500),
//                             curve: Curves.easeOutCubic,
//                             tween: Tween<double>(begin: 0, end: percentage / 100),
//                             builder: (context, value, child) {
//                               return Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Row(
//                                     mainAxisAlignment:
//                                         MainAxisAlignment.spaceBetween,
//                                     children: [
//                                       Text(
//                                         '${(value * 100).toStringAsFixed(1)}%',
//                                         style: TextStyle(
//                                           fontWeight: FontWeight.bold,
//                                           fontSize: 24,
//                                           color: progressColor,
//                                         ),
//                                       ),
//                                       Text(
//                                         '${data.totalPresent}/${data.totalClass}',
//                                         style: const TextStyle(
//                                           fontWeight: FontWeight.w500,
//                                           fontSize: 14,
//                                           color: Colors.black54,
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                   const SizedBox(height: 10),
//                                   Stack(
//                                     children: [
//                                       Container(
//                                         height: 12,
//                                         decoration: BoxDecoration(
//                                           color: Colors.grey.shade200,
//                                           borderRadius:
//                                               BorderRadius.circular(10),
//                                         ),
//                                       ),
//                                       FractionallySizedBox(
//                                         widthFactor: value,
//                                         child: Container(
//                                           height: 12,
//                                           decoration: BoxDecoration(
//                                             color: progressColor,
//                                             borderRadius:
//                                                 BorderRadius.circular(10),
//                                             boxShadow: [
//                                               BoxShadow(
//                                                 color: progressColor
//                                                     .withOpacity(0.3),
//                                                 blurRadius: 8,
//                                                 offset: const Offset(0, 3),
//                                               ),
//                                             ],
//                                           ),
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ],
//                               );
//                             },
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildModernStatCard(
//       String title, String value, IconData icon, double delayFactor) {
//     return Expanded(
//       child: SlideTransition(
//         position: Tween<Offset>(
//           begin: const Offset(0, 0.2),
//           end: Offset.zero,
//         ).animate(
//           CurvedAnimation(
//             parent: _controller,
//             curve: Interval(
//               0.2 + (delayFactor * 0.5),
//               0.8 + (delayFactor * 0.2),
//               curve: Curves.easeOutCubic,
//             ),
//           ),
//         ),
//         child: Container(
//           padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
//           decoration: BoxDecoration(
//             color: Colors.white.withOpacity(0.6),
//             borderRadius: BorderRadius.circular(20),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.03),
//                 blurRadius: 8,
//                 offset: const Offset(0, 2),
//               ),
//             ],
//           ),
//           child: Column(
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(8),
//                 decoration: BoxDecoration(
//                   color: _primaryColor.withOpacity(0.1),
//                   shape: BoxShape.circle,
//                 ),
//                 child: Icon(icon, color: _primaryColor, size: 20),
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 value,
//                 style: const TextStyle(
//                   fontWeight: FontWeight.bold,
//                   fontSize: 18,
//                   color: Colors.black87,
//                 ),
//               ),
//               Text(
//                 title,
//                 style: const TextStyle(
//                   fontSize: 12,
//                   color: Colors.black54,
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   // Build the legend widget
//   Widget _buildLegend() {
//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       decoration: BoxDecoration(
//         color: Colors.white.withOpacity(0.4),
//         borderRadius: BorderRadius.circular(24),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.04),
//             offset: const Offset(0, 2),
//             blurRadius: 8,
//             spreadRadius: 0,
//           ),
//         ],
//       ),
//       padding: const EdgeInsets.all(20),
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(24),
//         child: BackdropFilter(
//           filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
//           child: Container(
//             padding: const EdgeInsets.all(8),
//             decoration: BoxDecoration(
//               color: Colors.white.withOpacity(0.3),
//               borderRadius: BorderRadius.circular(24),
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   children: [
//                     Container(
//                       padding: const EdgeInsets.all(8),
//                       decoration: BoxDecoration(
//                         color: _primaryColor.withOpacity(0.1),
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       child: Icon(
//                         Icons.info_outline_rounded,
//                         color: _primaryColor,
//                         size: 16,
//                       ),
//                     ),
//                     const SizedBox(width: 12),
//                     const Text(
//                       'Attendance Legend',
//                       style: TextStyle(
//                         fontWeight: FontWeight.w600,
//                         fontSize: 14,
//                         color: Colors.black87,
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 12),
//                 Wrap(
//                   spacing: 12,
//                   runSpacing: 12,
//                   children: [
//                     _buildModernStatCardLegendItem(
//                       'Present',
//                       _getAttendanceColor(AttendanceStatus.present),
//                     ),
//                     _buildModernStatCardLegendItem(
//                       'Absent',
//                       _getAttendanceColor(AttendanceStatus.absent),
//                     ),
//                     _buildModernStatCardLegendItem(
//                       'Leave',
//                       _getAttendanceColor(AttendanceStatus.leave),
//                     ),
//                     _buildModernStatCardLegendItem(
//                       'Late Present',
//                       _getAttendanceColor(AttendanceStatus.presentLate),
//                     ),
//                     _buildModernStatCardLegendItem(
//                       'Late Absent',
//                       _getAttendanceColor(AttendanceStatus.absentLate),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildModernStatCardLegendItem(String label, Color color) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(30),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.03),
//             blurRadius: 4,
//             offset: const Offset(0, 1),
//           ),
//         ],
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Container(
//             width: 12,
//             height: 12,
//             decoration: BoxDecoration(
//               color: color,
//               shape: BoxShape.circle,
//               boxShadow: [
//                 BoxShadow(
//                   color: color.withOpacity(0.3),
//                   blurRadius: 4,
//                   spreadRadius: 1,
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(width: 6),
//           Text(
//             label,
//             style: const TextStyle(
//               fontSize: 12,
//               color: Colors.black87,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // Build the search filters
//   Widget _buildFilters() {
//     return Container(
//       margin: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         // Subtle “glossy” background
//         color: Colors.white.withOpacity(0.4),
//         borderRadius: BorderRadius.circular(24),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             offset: const Offset(0, 4),
//             blurRadius: 12,
//             spreadRadius: -2,
//           ),
//         ],
//       ),
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(24),
//         child: BackdropFilter(
//           filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
//           child: Padding(
//             padding: const EdgeInsets.all(24),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Search header
//                 Row(
//                   children: [
//                     Container(
//                       padding: const EdgeInsets.all(10),
//                       decoration: BoxDecoration(
//                         color: _primaryColor.withOpacity(0.1),
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: Icon(
//                         Icons.search_rounded,
//                         color: _primaryColor,
//                         size: 24,
//                       ),
//                     ),
//                     const SizedBox(width: 16),
//                     Text(
//                       'Search',
//                       style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         fontSize: 20,
//                         color: _primaryColor,
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 24),
//                 // Subject filter
//                 Text(
//                   'Subject',
//                   style: TextStyle(
//                     fontWeight: FontWeight.w500,
//                     color: Colors.black87.withOpacity(0.7),
//                     fontSize: 14,
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 Container(
//                   padding:
//                       const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
//                   decoration: BoxDecoration(
//                     color: Colors.white.withOpacity(0.7),
//                     borderRadius: BorderRadius.circular(12),
//                     border: Border.all(
//                       color: Colors.grey.shade200,
//                     ),
//                   ),
//                   child: DropdownButtonHideUnderline(
//                     child: DropdownButton<String>(
//                       value: _selectedSectionId,
//                       isExpanded: true,
//                       icon: Icon(Icons.keyboard_arrow_down_rounded,
//                           color: _primaryColor.withOpacity(0.7)),
//                       style: TextStyle(
//                         color: _primaryColor,
//                         fontSize: 16,
//                       ),
//                       items: _sectionIds.map((String id) {
//                         return DropdownMenuItem<String>(
//                           value: id,
//                           child: Text(
//                             id,
//                             style: TextStyle(
//                               color: _primaryColor,
//                             ),
//                           ),
//                         );
//                       }).toList(),
//                       onChanged: (String? newValue) {
//                         setState(() {
//                           _selectedSectionId = newValue!;
//                         });
//                       },
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//                 // Month and Year filters
//                 Row(
//                   children: [
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             'Month',
//                             style: TextStyle(
//                               fontWeight: FontWeight.w500,
//                               color: Colors.black87.withOpacity(0.7),
//                               fontSize: 14,
//                             ),
//                           ),
//                           const SizedBox(height: 8),
//                           Container(
//                             padding: const EdgeInsets.symmetric(
//                                 horizontal: 16, vertical: 4),
//                             decoration: BoxDecoration(
//                               color: Colors.white.withOpacity(0.7),
//                               borderRadius: BorderRadius.circular(12),
//                               border: Border.all(
//                                 color: Colors.grey.shade200,
//                               ),
//                             ),
//                             child: DropdownButtonHideUnderline(
//                               child: DropdownButton<String>(
//                                 value: _selectedMonth,
//                                 isExpanded: true,
//                                 icon: Icon(Icons.keyboard_arrow_down_rounded,
//                                     color: _primaryColor.withOpacity(0.7)),
//                                 style: TextStyle(
//                                   color: _primaryColor,
//                                   fontSize: 16,
//                                 ),
//                                 items: _months.map((String month) {
//                                   return DropdownMenuItem<String>(
//                                     value: month,
//                                     child: Text(
//                                       month,
//                                       style:
//                                           TextStyle(color: _primaryColor),
//                                     ),
//                                   );
//                                 }).toList(),
//                                 onChanged: (String? newValue) {
//                                   setState(() {
//                                     _selectedMonth = newValue!;
//                                   });
//                                 },
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(width: 16),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             'Year',
//                             style: TextStyle(
//                               fontWeight: FontWeight.w500,
//                               color: Colors.black87.withOpacity(0.7),
//                               fontSize: 14,
//                             ),
//                           ),
//                           const SizedBox(height: 8),
//                           Container(
//                             padding: const EdgeInsets.symmetric(
//                                 horizontal: 16, vertical: 4),
//                             decoration: BoxDecoration(
//                               color: Colors.white.withOpacity(0.7),
//                               borderRadius: BorderRadius.circular(12),
//                               border: Border.all(
//                                 color: Colors.grey.shade200,
//                               ),
//                             ),
//                             child: DropdownButtonHideUnderline(
//                               child: DropdownButton<int>(
//                                 value: _selectedYear,
//                                 isExpanded: true,
//                                 icon: Icon(Icons.keyboard_arrow_down_rounded,
//                                     color: _primaryColor.withOpacity(0.7)),
//                                 style: TextStyle(
//                                   color: _primaryColor,
//                                   fontSize: 16,
//                                 ),
//                                 items: _years.map((int year) {
//                                   return DropdownMenuItem<int>(
//                                     value: year,
//                                     child: Text(
//                                       year.toString(),
//                                       style:
//                                           TextStyle(color: _primaryColor),
//                                     ),
//                                   );
//                                 }).toList(),
//                                 onChanged: (int? newValue) {
//                                   setState(() {
//                                     _selectedYear = newValue!;
//                                   });
//                                 },
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 24),
//                 // Apply filters button
//                 ElevatedButton(
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: _primaryColor,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(30),
//                     ),
//                     padding: const EdgeInsets.symmetric(
//                         horizontal: 32, vertical: 12),
//                   ),
//                   onPressed: () {
//                     _fetchAttendanceData();
//                   },
//                   child: const Text(
//                     'Apply Filters',
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontWeight: FontWeight.bold,
//                       fontSize: 16,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       // Main background is now white
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         title: const Text(
//           'View Attendance',
//           style: TextStyle(
//             color: Colors.white,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         backgroundColor: _primaryColor,
//         elevation: 0,
//         iconTheme: const IconThemeData(color: Colors.white, size: 30),
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : _errorMessage.isNotEmpty
//               ? Center(
//                   child: Text(
//                     _errorMessage,
//                     style: const TextStyle(color: Colors.red),
//                   ),
//                 )
//               : SingleChildScrollView(
//                   child: Column(
//                     children: [
//                       _buildFilters(),
//                       if (_data != null) ...[
//                         _buildStatistics(_data!),
//                         _buildCustomCalendar(_data!),
//                         _buildLegend(),
//                       ],
//                     ],
//                   ),
//                 ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nitris/screens/launch_screen/theme/launch_app_theme.dart';
import 'package:nitris/core/constants/app_colors.dart';

class MyAttendancePage extends StatefulWidget {
  const MyAttendancePage({Key? key}) : super(key: key);

  @override
  State<MyAttendancePage> createState() => _MyAttendancePageState();
}

class _MyAttendancePageState extends State<MyAttendancePage> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Set the status bar color to match the AppBar color.
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: AppColors.primaryColor,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "My Attendance",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 28),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primaryColor.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated Calendar Icon
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.calendar_today,
                      size: 70,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                // Coming Soon Text
                Text(
                  "COMING SOON",
                  style: LaunchAppTheme.headlineStyle.copyWith(
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 16),
                // Description
                Text(
                  "We're working on an innovative attendance feature to help you manage and track your attendance.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 40),
                // Progress indicator with Icon
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.timelapse,
                      color: AppColors.primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Development in progress",
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
