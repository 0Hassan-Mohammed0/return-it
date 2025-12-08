import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'widgets/auth_guard.dart';
import 'utils/routes.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'pages/home_page.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/otp_verification_screen.dart';

import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/admin/admin_users_screen.dart';
import 'screens/admin/admin_items_screen.dart';
import 'screens/lost_items_screen.dart';
import 'screens/found_items_screen.dart';
import 'pages/placeholders.dart';
import 'pages/test_db_page.dart';
import 'pages/splash_page.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MainApp());
}


class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ReturnIt',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueAccent,
          primary: Colors.blueAccent,
          secondary: Colors.tealAccent,
        ),
        textTheme: GoogleFonts.interTextTheme(
          Theme.of(context).textTheme,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      initialRoute: AppRoutes.splash,
      routes: {
        AppRoutes.splash: (context) => const SplashPage(),
        AppRoutes.login: (context) => const LoginScreen(),
        AppRoutes.register: (context) => const RegisterScreen(),
        AppRoutes.dashboard: (context) => const AuthGuard(child: AdminDashboardScreen()),
        AppRoutes.users: (context) => const AuthGuard(child: AdminUsersScreen()),
        AppRoutes.items: (context) => const AuthGuard(child: AdminItemsScreen()),
        AppRoutes.home: (context) => const AuthGuard(child: HomePage()),
        AppRoutes.forgotPassword: (context) => const ForgotPasswordScreen(),
        AppRoutes.verifyOtp: (context) => const OtpVerificationScreen(),

        AppRoutes.lostItems: (context) => const AuthGuard(child: LostItemsScreen()),
        AppRoutes.foundItems: (context) => const AuthGuard(child: FoundItemsScreen()),
        AppRoutes.reportLost: (context) => const AuthGuard(child: ReportLostPage()),
        AppRoutes.reportFound: (context) => const AuthGuard(child: ReportFoundPage()),
        AppRoutes.itemDetails: (context) => const AuthGuard(child: ItemDetailsPage()),
        AppRoutes.notifications: (context) => const AuthGuard(child: NotificationsPage()),
        AppRoutes.testDb: (context) => const AuthGuard(child: TestDbPage()),
      },
    );
  }
}
