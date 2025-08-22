import 'dart:async';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double progress = 0.0;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(milliseconds: 30), (t) {
      setState(() {
        progress += 0.01;
        if (progress >= 1.0) {
          progress = 1.0;
          timer?.cancel();
          Navigator.pushReplacementNamed(context, '/home');
        }
      });
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: const Color(0xFFC8D5B9),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: SizedBox(
                width: 250,
                height: 250,
                child: Image.asset(
                  'assets/splashscreen-img.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 50.0),
            child: SizedBox(
              width: size.width * 0.7,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 16,
                  backgroundColor: const Color(0xFFCFC1AA),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Color(0xFFF06C54)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
