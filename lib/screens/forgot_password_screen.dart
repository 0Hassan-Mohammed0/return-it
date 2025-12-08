import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../widgets/custom_text_field.dart';


class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  
  bool _isLoading = false;
  String? _emailError;

  void _onSendPressed() async {
    setState(() {
      _emailError = null;
    });

    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      // 1. Check Lockout
      String email = _emailController.text.trim();
      bool isLocked = await _authService.isAccountLocked(email);
      if (isLocked) {
        setState(() {
          _isLoading = false;
          _emailError = 'Account is temporarily locked. Try again later.';
        });
        return;
      }


      
      // 2. Strict Check: Does user actually exist?
      // User requested "only send to current users".
      bool exists = await _authService.doesEmailExist(email);
      if (!exists) {
        setState(() {
          _isLoading = false;
          _emailError = 'This email is not registered.';
        });
        return;
      }

      // 3. Send Firebase Reset Link
      try {
        await _authService.resetPassword(email);
        
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Password reset link sent to your email!')),
          );
          Navigator.pop(context); // Go back to login
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            // Map common errors
            if (e.toString().contains('user-not-found')) {
               _emailError = 'No user found with this email.';
            } else if (e.toString().contains('invalid-email')) {
               _emailError = 'Invalid email format.';
            } else {
               _emailError = 'Failed to send link. Please try again.';
            }
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('ReturnIt', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Forgot your password',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Enter your email to receive a password reset link.",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  
                  // Email Field
                  CustomTextField(
                    label: 'Email Address', 
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    errorText: _emailError,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Please enter your email';
                      if (!value.endsWith('@f-eng.tanta.edu.eg')) {
                        return 'Must be a Tanta Engineering email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _onSendPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A5F),
                         disabledBackgroundColor: const Color(0xFF1E3A5F).withValues(alpha: 0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text(
                          'Send Reset Link',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Back To Login',
                        style: TextStyle(
                          color: Color(0xFF1E3A5F),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
