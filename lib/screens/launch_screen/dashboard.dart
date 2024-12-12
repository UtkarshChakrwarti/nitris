import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nitris/screens/launch_screen/widgets/app_header.dart';
import 'package:nitris/screens/launch_screen/widgets/application_grid.dart';
import 'package:nitris/screens/launch_screen/widgets/applications_bar.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  // Prevent going back to previous screen
  Future<bool> _onWillPop() async {
    return false; // This prevents the back action
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop, // Triggered when the back button is pressed
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.white,
          statusBarIconBrightness: Brightness.dark,
        ),
        child: Scaffold(
          body: SafeArea(
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: const AssetImage('assets/images/watermark.png'),
                  fit: BoxFit.none,
                  colorFilter: ColorFilter.mode(
                    Colors.white.withOpacity(0.8),
                    BlendMode.srcATop,
                  ),
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppHeader(),
                  ApplicationsBar(),
                  Expanded(child: ApplicationGrid()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
