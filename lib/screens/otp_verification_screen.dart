import 'dart:async';
import 'package:flutter/material.dart';
import 'package:returnit/services/auth_service.dart';
import 'package:returnit/utils/routes.dart';
import 'package:email_otp/email_otp.dart';


class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _otpController = TextEditingController();
  final _authService = AuthService();
  // Initialize EmailOTP
  final EmailOTP _emailAuth = EmailOTP();
  
  bool _isLoading = false;
  Timer? _timer;
  int _start = 30; // 30 seconds cooldown
  bool _canResend = false;
  DateTime? _lockoutTime;

  String? _email;
  bool _isRegistration = false;
  Map<String, dynamic>? _registrationData;

  int _resendCount = 0; // Track resend attempts for progressive lockout

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && _email == null) { // Check _email==null to avoid re-running on rebuilds
      _email = args['email'];
      _isRegistration = args['isRegistration'] ?? false;
      _registrationData = args['userData']; // Arguments map might just merge user data? 
      // Wait, in register_screen I passed arguments map directly, so _registrationData IS the map if isRegistration is true
      if (_isRegistration) {
         // In RegisterScreen arguments map keys matched.
         // Let's ensure _registrationData is correctly populated
         _registrationData = args; 
      }

      // Update config based on context
      String appName = _isRegistration ? "ReturnIt Verify" : "ReturnIt Reset";

      _emailAuth.setConfig(
        appEmail: "returnit@noreply.com",
        appName: appName,
        userEmail: _email,
        otpLength: 6,
        otpType: OTPType.digitsOnly,
      );

      _checkLockout();

      // Check if we should send OTP immediately (Registration Flow)
      if (args['sendOtpOnLoad'] == true) {
        _startResend(silent: false); // Send and start timer
      } else {
        startTimer(); 
      }
    }
  }

  void _checkLockout() async {
    if (_email == null) return;

    // Check Server Side Lockout
    bool isLocked = await _authService.isAccountLocked(_email!);
    
    if (isLocked) {
      setState(() {
        _lockoutTime = DateTime.now().add(const Duration(hours: 24)); 
      });
      return;
    }
    
    // Timer is already handled in startTimer or _startResend
  }

  void startTimer() {
    int duration = 30; // Default
    
    if (_resendCount >= 3) {
      duration = 3600; // 1 Hour
      // We will reset _resendCount AFTER the timer completes (in the periodic callback or via logic)
      // Actually, user said "after one hour it should reset".
    }
    
    setState(() {
      _canResend = false;
      _start = duration;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_start <= 0) {
        setState(() {
          _canResend = true;
          _timer?.cancel();
          // Reset count if we just finished the long wait
          if (duration == 3600) {
             _resendCount = 0; 
          }
        });
      } else {
        setState(() {
          _start--;
        });
      }
    });
  }

  // Helper wrapper for Resend
  Future<void> _startResend({bool silent = false}) async {
    if (!silent) {
      // Increment count only on manual/explicit resend or initial
      _resendCount++;
    }
    
    await _emailAuth.sendOTP();
    if (mounted && !silent) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Verification code sent!')));
    }
    startTimer();
  }

  // _handleLockout removed (handled by server logic)

  void _verifyOtp() async {
    if (_lockoutTime != null) return;

    final otp = _otpController.text.trim();
    if (otp.length < 4) { 
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter valid code')));
       return;
    }

    setState(() => _isLoading = true);

    // Verify OTP
    bool verified = _emailAuth.verifyOTP(otp: otp);
    
    if (verified) {
       // Reset failed attempts on server
       if (_email != null) await _authService.resetFailedAttempts(_email!);

       if (_isRegistration && _registrationData != null) {
          try {
            await _authService.registerUser(
              email: _registrationData!['email'],
              password: _registrationData!['password'],
              name: _registrationData!['name'],
              phoneNumber: _registrationData!['phone'],
            );
             if (mounted) {
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account Verified & Created!')));
               Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (route) => false);
             }
           } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Registration Failed: $e')));
           }
       } else {
         if (!mounted) return;
         // "Reset Password" screen is removed as we use Firebase Links.
         // If we ever end up here without _isRegistration, just consider it verified.
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email Verified!')));
         Navigator.pop(context, true); 
       }
    } else {
      // Handle Failure on Server
      if (_email != null) {
        await _authService.handleFailedAttempt(_email!);
        bool isLocked = await _authService.isAccountLocked(_email!);
        
        if (isLocked) {
           setState(() {
             _lockoutTime = DateTime.now().add(const Duration(hours: 24));
           });
           if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Account locked due to too many failed attempts.'), backgroundColor: Colors.red),
            );
           }
        } else {
          if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(content: Text('Invalid OTP.')),
            );
          }
        }
      }
    }

    setState(() => _isLoading = false);
  }



  void _resendOtp() async {
    if (!_canResend || _lockoutTime != null) return;
    
    // Disable immediately
    setState(() => _canResend = false);

    await _startResend(silent: false);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_lockoutTime != null && DateTime.now().isBefore(_lockoutTime!)) {
      final hoursLeft = _lockoutTime!.difference(DateTime.now()).inHours;
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock, size: 80, color: Colors.red),
                const SizedBox(height: 16),
                const Text('Account Locked', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Too many failed attempts. Try again in $hoursLeft hours.', textAlign: TextAlign.center),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Go Back'),
                )
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.mark_email_read, size: 60, color: Theme.of(context).primaryColor),
                const SizedBox(height: 24),
                
                const Text(
                  'Account Verification',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter Verify Code Below\nSent to ${_email ?? "email"}',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                const SizedBox(height: 32),

                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24, letterSpacing: 16, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    counterText: "",
                    hintText: "------",
                    hintStyle: TextStyle(color: Colors.grey[300], letterSpacing: 16),
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _verifyOtp,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                       shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text(
                        'Verify Code',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                  ),
                ),
                const SizedBox(height: 16),

                TextButton(
                  onPressed: _canResend ? _resendOtp : null,
                  child: Text(
                    _canResend ? 'Resend Code' : 'Resend Code in ${_start}s',
                    style: TextStyle(
                      color: _canResend ? Theme.of(context).primaryColor : Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
