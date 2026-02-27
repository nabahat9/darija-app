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
  @override
  void initState() {
    super.initState();
    _navigateNext();
  }

  Future<void> _navigateNext() async {
    // wait for 4 seconds
    await Future.delayed(Duration(seconds: 4));

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    final name = prefs.getString('name') ?? '';
    final age = prefs.getString('age') ?? '';
    final gender = prefs.getString('gender') ?? '';

    if (userId != null && name.isNotEmpty) {
      // User info exists, go to RecordScreen
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
      // No user info, go to IntroScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => IntroScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // white background
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              "assets/robot_video.gif",
              width: 400,
            ),
            SizedBox(height: 10),
            Text(
              "Darija",
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
