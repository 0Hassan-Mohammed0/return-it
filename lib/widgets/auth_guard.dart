import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/login_screen.dart';

class AuthGuard extends StatelessWidget {
  final Widget child;

  const AuthGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // Check current user synchronously for immediate decision
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // If no user, redirect to LoginScreen
      // We return LoginScreen directly to prevent the protected page from even mounting/flashing
      return const LoginScreen();
    }

    // User is authenticated, show the protected page
    return child;
  }
}
