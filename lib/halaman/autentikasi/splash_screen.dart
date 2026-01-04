import 'dart:async';
import 'package:flutter/material.dart';
import '../../config/manajer_session.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      _navigateToLogin();
    });
  }

  void _navigateToLogin() {
    if (!mounted) return;

    // Clear session sebelumnya untuk memastikan state bersih
    // Ini mencegah sisa session dari login sebelumnya
    ManajerSession.instance.clearSessionSilent();

    // Selalu navigasi ke halaman login
    Navigator.pushReplacementNamed(context, "/login");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5E6D3),
      body: Center(
        child: SizedBox(
          width: 250,
          height: 250,
          child: Image.asset("assets/splash.jpg", fit: BoxFit.contain),
        ),
      ),
    );
  }
}
