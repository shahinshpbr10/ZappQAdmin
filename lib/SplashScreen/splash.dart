import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  // Separate async method to handle initialization
  void _initializeApp() async {
    final prefs = await SharedPreferences.getInstance();

    // Wait for both the delay and preferences to complete
    await Future.delayed(const Duration(seconds: 2));

    // Check if 'admin' exists and is not empty
    final adminValue = prefs.getString('admin');
    final isLoggedIn = adminValue != null && adminValue.isNotEmpty;

    if (mounted) {
      Navigator.pushReplacementNamed(
        context,
        isLoggedIn ? '/home' : '/auth',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset(
          "assets/images/ZappQ_logo.jpg",
          height: 80,
          width: 80,
        ),
      ),
    );
  }
}
