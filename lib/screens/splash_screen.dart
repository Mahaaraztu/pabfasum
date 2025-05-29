import 'package:flutter/material.dart';
import 'dart:async'; // Required for Timer
import 'package:pabfasum/screens/home_screen.dart'; // Adjust path if needed

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  _navigateToHome() async {
    // You can add any initialization logic here, e.g., loading data,
    // checking user login status, etc.
    await Future.delayed(const Duration(seconds: 3)); // Simulate a 3-second loading time

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()), // Navigate to your main app screen
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          // You can add a background image or color here
          // image: DecorationImage(
          //   image: AssetImage('assets/background_splash.png'), // Add your image in assets
          //   fit: BoxFit.cover,
          // ),
          color: Colors.blueAccent, // Example background color
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Your app logo or icon
              FlutterLogo(size: 100), // Example: Flutter logo
              SizedBox(height: 20),
              Text(
                'Fasum App', // Your app name
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 40),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              SizedBox(height: 20),
              Text(
                'Loading...',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}