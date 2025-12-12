import 'package:flutter/material.dart';

import '../widgets/custom_text_field.dart';
import '../services/auth_service.dart';
import '../utils/routes.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  

  final _authService = AuthService(); // Needed for checking if email exists

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  // Inline error states (optional if relying purely on validator, but good for async checks like "email taken")
  String? _emailError;

  void _onRegisterPressed() async {
    setState(() {
      _emailError = null;
    });

    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      // 1. Check if email or phone already exists
      String? conflictError = await _authService.checkEmailOrPhoneExists(
        _emailController.text.trim().toLowerCase(),
        _phoneController.text.trim(),
      );

      if (conflictError != null) {
        setState(() {
          _isLoading = false;
          // Show error inline (using _emailError or generic snackbar if phone)
          if (conflictError.contains('Email')) {
            _emailError = conflictError;
          } else {
             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(conflictError)));
          }
        });
        return;
      }

      // 2. Navigate to OTP Screen (Let OTP Screen handle sending)
      // This solves the 'Invalid OTP first time' issue due to instance mismatch
      setState(() => _isLoading = false);

      if (mounted) {
        Navigator.pushNamed(
          context, 
          AppRoutes.verifyOtp,
          arguments: {
            'email': _emailController.text.trim().toLowerCase(),
            'name': _nameController.text.trim(),
            'phone': _phoneController.text.trim(),
            'password': _passwordController.text,
            'isRegistration': true,
            'sendOtpOnLoad': true, // Tell screen to send OTP
          },
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Regex Patterns
    // Password: At least 8 chars, 1 digit, 1 lowercase, 1 uppercase
    final passwordRegex = RegExp(r'^(?=.*\d)(?=.*[a-z])(?=.*[A-Z])(?=.*[a-zA-Z]).{8,}$');
    // Phone: Egypt format starting with +201, 01, or 00201
    final phoneRegex = RegExp(r'^(\+201|01|00201)[0-2,5]{1}[0-9]{8}$');

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction, // Show errors as user types/interacts
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   // Blue Search Icon
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(

                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blueAccent.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.search, color: Colors.white, size: 30),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Create Your Account',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Full Name
                  CustomTextField(
                    label: 'Full Name',
                    controller: _nameController,
                    showLabelAbove: false,
                    prefixIcon: Icons.person,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Please enter your name';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // University Email
                  CustomTextField(
                    label: 'University Email (.edu)',
                    controller: _emailController,
                    showLabelAbove: false,
                    prefixIcon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                    errorText: _emailError,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Please enter your email';
                      if (!value.endsWith('@f-eng.tanta.edu.eg')) {
                        return 'Must be a Tanta Engineering email \n(@f-eng.tanta.edu.eg)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Phone Number
                  CustomTextField(
                    label: 'Phone Number',
                    controller: _phoneController,
                    showLabelAbove: false,
                    prefixIcon: Icons.phone,
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Please enter your phone number';
                      if (!phoneRegex.hasMatch(value)) {
                        return 'Invalid phone format (e.g., 01xxxxxxxxx)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password
                  CustomTextField(
                    label: 'Password',
                    controller: _passwordController,
                    showLabelAbove: false,
                    prefixIcon: Icons.lock,
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey[600],
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Please enter password';
                      if (!passwordRegex.hasMatch(value)) {
                         return 'Min 8 chars, 1 uppercase, 1 lowercase, 1 number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Confirm Password
                  CustomTextField(
                    label: 'Confirm Password',
                    controller: _confirmPasswordController,
                    showLabelAbove: false,
                    prefixIcon: Icons.lock,
                    obscureText: _obscureConfirmPassword,
                     suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey[600],
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Please confirm password';
                      if (value != _passwordController.text) return 'Passwords do not match';
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  // Register Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _onRegisterPressed,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading 
                        ? const SizedBox(
                            width: 20, 
                            height: 20, 
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                          )
                        : const Text(
                          'Register',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Sign In Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Already have an account? ",
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      TextButton(
                        onPressed: () {
                          // Ensure we don't stack pages forever; use replacement or pop if already on stack
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          } else {
                             Navigator.pushReplacementNamed(context, AppRoutes.login);
                          }
                        },
                        child: Text(
                          'Sign In',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
      
                            color: Theme.of(context).primaryColor,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
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
