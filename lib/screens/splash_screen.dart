import 'package:flutter/material.dart';
import 'package:real_galaxy/theme/app_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:real_galaxy/services/auth_service.dart';
import 'package:real_galaxy/services/firebase_messaging_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _animation = Tween(begin: 0.0, end: 2 * 3.14159).animate(_controller);
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Initialize Firebase and services in background
    try {
      await Firebase.initializeApp();
      await FirebaseMessagingService.initializeStatic();
      await AuthService().initializeDefaultOwner();
    } catch (e) {
      // Log error but proceed anyway
      debugPrint('Initialization error: $e');
    }

    // Ensure splash screen is visible for at least 3 seconds
    await Future.delayed(const Duration(seconds: 3));

    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/auth');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated app logo
            RotationTransition(
              turns: _animation,
              child: Icon(
                Icons.sports_soccer,
                size: 100,
                color: AppTheme.primaryColor,
              ),
            ),
            SizedBox(height: 24),
            // App name
            Text(
              'Real Galaxy FC',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppTheme.onBackgroundColor,
                letterSpacing: 2.0,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Football Academy Management',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.onBackgroundMuted,
                letterSpacing: 1.0,
              ),
            ),
            SizedBox(height: 48),
            // Loading indicator
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              strokeWidth: 3,
            ),
          ],
        ),
      ),
    );
  }
}

