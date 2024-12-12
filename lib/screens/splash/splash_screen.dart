import 'package:flutter/material.dart';
import 'package:nitris/controllers/splash_screen_controller.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:nitris/core/constants/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {
  final SplashScreenController _controller = SplashScreenController();

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    String? route = await _controller.checkLoginStatus(context);
    if (!mounted) return;
    if (route != null) {
      Navigator.pushReplacementNamed(context, route);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: const Image(
                  image: AssetImage('assets/images/nitris.png'),
                  width: 250,
                  height: 250,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 20),
              LoadingAnimationWidget.staggeredDotsWave(
                color: AppColors.primaryColor,
                size: 40,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
