import 'package:flutter/material.dart';
import 'dart:async';
import 'package:returnit/utils/routes.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    // Navigate to Login after 3 seconds
    Timer(const Duration(seconds: 3), () {
      Navigator.of(context).pushReplacementNamed(AppRoutes.login);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Placeholder Logo if asset not ready, or Text
              const Icon(Icons.find_in_page_rounded, size: 80, color: Color(0xFF000B58)),
              const SizedBox(height: 16),
              const Text(
                'ReturnIt',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF000B58),
                ),
              ),
              const SizedBox(height: 24),
              // Hadith Text
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  "قال الرجل للنبي ﷺ: عن اللقطة، فقال: «اعرف عفاصها ووِكاءَها، ثم عرفها سنة، فإن جاء صاحبها وإلا فشأنك بها»",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    fontFamily: 'Roboto', 
                    height: 1.5,
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
