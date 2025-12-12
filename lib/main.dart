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
import 'screens/lost_items_screen.dart';
import 'screens/found_items_screen.dart';
import 'screens/report_lost_screen.dart';
import 'screens/report_found_screen.dart';
import 'screens/item_details_screen.dart';
import 'screens/requests_screen.dart';
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
        scaffoldBackgroundColor: Colors.white, // Standard clean background
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF000B58), // Deep Blue
          primary: const Color(0xFF000B58),   // #000B58
          onPrimary: Colors.white,
          primaryContainer: const Color(0xFF003161), // #003161
          onPrimaryContainer: Colors.white,
          secondary: const Color(0xFF006A67), // #006A67
          onSecondary: Colors.white,
          tertiary: const Color(0xFFFDEB9E),  // #FDEB9E
          onTertiary: const Color(0xFF000B58), // Contrast against yellow
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: Color(0xFF000B58)),
          titleTextStyle: TextStyle(
            color: Color(0xFF000B58), 
            fontSize: 20, 
            fontWeight: FontWeight.bold,
          ),
        ),
        textTheme: GoogleFonts.interTextTheme(
          Theme.of(context).textTheme,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFFDEB9E).withOpacity(0.1), // Subtle yellow tint for inputs
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF000B58), width: 1.5),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF000B58),
            foregroundColor: Colors.white,
            elevation: 2,
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
        AppRoutes.requests: (context) => const AuthGuard(child: RequestsScreen()),
        AppRoutes.notifications: (context) => const AuthGuard(child: NotificationsPage()),
        AppRoutes.testDb: (context) => const AuthGuard(child: TestDbPage()),
      },
    );
  }
}
