import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'intro_screen.dart';
import 'record_screen.dart';
import 'theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // Our primary Navy Blue color
  final Color primaryNavy = const Color.fromARGB(255, 51, 73, 112);

  @override
  void initState() {
    super.initState();
    _navigateNext();
  }

  Future<void> _navigateNext() async {
    // Wait for 4 seconds
    await Future.delayed(const Duration(seconds: 4));

    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    final name = prefs.getString('name') ?? '';
    final age = prefs.getString('age') ?? '';
    final gender = prefs.getString('gender') ?? '';

    if (userId != null && name.isNotEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => RecordScreen(
            name: name,
            age: age,
            gender: gender,
            userId: userId,
          ),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => IntroScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Option 1: Solid Navy Background (High Impact)
      // backgroundColor: primaryNavy, 
      
      // Option 2: Pure White with Navy accents (Clean)
      backgroundColor: Colors.white, 
      
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Better than mainAxisSize: min for Splash
          children: [
            // Your Animated Robot
            Image.asset(
              "assets/robot_video.gif",
              width: 320, // Slightly adjusted for better balance
            ),
            
            const SizedBox(height: 20),
            
            // App Title in Navy Blue
            Text(
              "DARIJA",
              style: TextStyle(
                color: primaryNavy, // Replaced AppColors.primary
                fontSize: 36,
                letterSpacing: 4.0, // Space out the letters for a premium look
                fontWeight: FontWeight.w900,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Added a small subtitle for extra polish
            Text(
              "Algerian Speech Project",
              style: TextStyle(
                color: primaryNavy.withOpacity(0.5),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            
            const SizedBox(height: 60),
            
            // A loading indicator that matches your theme
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(primaryNavy),
              strokeWidth: 3,
            ),
          ],
        ),
      ),
    );
  }
}