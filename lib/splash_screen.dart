import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'main.dart'; // To access AuthWrapper/Login

class SplashScreen extends StatefulWidget {
  final String message;
  final bool isLoggingOut;

  const SplashScreen({super.key, required this.message, this.isLoggingOut = false});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // 2-3 second delay as requested
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        if (widget.isLoggingOut) {
          // Send to Login/AuthWrapper after "Visit Again"
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const AuthWrapper()),
                (route) => false,
          );
        } else {
          // Send to Dashboard after "Welcome"
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueAccent,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.account_balance_wallet, size: 100, color: Colors.white),
            const SizedBox(height: 24),
            Text(
              widget.message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}