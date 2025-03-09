import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import 'package:nitris/core/constants/app_colors.dart';
import 'package:nitris/core/models/faculty.dart';
import 'package:nitris/core/utils/dialogs_and_prompts.dart';
import 'package:nitris/screens/apps/live_attendance_inapp/live_attendance_controller/home_controller.dart';
import 'package:nitris/screens/apps/live_attendance_inapp/live_attendance_home/widgets/subject_card_widget.dart';
import 'package:nitris/screens/apps/live_attendance_inapp/live_attendance_home/widgets/user_profile_widget.dart';

class AttendanceHomeScreen extends StatefulWidget {
  const AttendanceHomeScreen({super.key});

  @override
  _AttendanceHomeScreenState createState() => _AttendanceHomeScreenState();
}

class _AttendanceHomeScreenState extends State<AttendanceHomeScreen> {
  final Logger _logger = Logger();

  @override
  void initState() {
    super.initState();
        // Lock the orientation to portrait mode
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final homeController = context.read<AttendanceHomeController>();
      homeController.refreshData();
    });
  }

  Future<bool> _onWillPop() async {
    final shouldExit = await DialogsAndPrompts.showExitConfirmationDialog(context);
    if (shouldExit ?? false) {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      return false;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    _logger.i("Building AttendanceHomeScreen");

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.primaryColor,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            tooltip: 'Back',
            onPressed: () async {
              final shouldExit = await DialogsAndPrompts.showExitConfirmationDialog(context);
              if (shouldExit ?? false) {
                Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
              }
            },
          ),

          // Clamped text scale + single line + ellipsis
          title: MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
            child: const Text(
              'Class Overview',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),

          actions: [
            Consumer<AttendanceHomeController>(
              builder: (context, homeController, child) {
                return IconButton(
                  icon: const Icon(Icons.sync),
                  color: Colors.white,
                  tooltip: 'Refresh',
                  onPressed: () async {
                    _logger.i("Refresh button pressed");
                    await homeController.refreshData();
                  },
                );
              },
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(70),
            child: Consumer<AttendanceHomeController>(
              builder: (context, homeController, child) {
                if (homeController.isLoading) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  );
                } else if (homeController.errorMessage != null) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      homeController.errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                } else {
                  final user = homeController.user ?? Faculty.defaultUser();
                  return UserProfileWidget(user: user);
                }
              },
            ),
          ),
        ),
        body: Consumer<AttendanceHomeController>(
          builder: (context, homeController, child) {
            if (homeController.isLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (homeController.errorMessage != null) {
              return Center(
                child: Text(
                  homeController.errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                ),
              );
            } else if (homeController.user == null ||
                homeController.user!.subjects.isEmpty) {
              return const Center(
                child: Text(
                  "No subjects available.",
                  style: TextStyle(fontSize: 16),
                ),
              );
            } else {
              final user = homeController.user!;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: AnimationLimiter(
                  child: ListView.builder(
                    itemCount: user.subjects.length,
                    padding: const EdgeInsets.only(top: 16),
                    itemBuilder: (context, index) {
                      final subject = user.subjects[index];
                      final String? attendanceDate = homeController.attendanceDate;
                      return SubjectCardWidget(
                        subject: subject,
                        index: index,
                        attendanceDate: attendanceDate ?? '',
                      );
                    },
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
