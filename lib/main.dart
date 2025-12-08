import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:returnit/pages/splash_page.dart';
import 'package:returnit/pages/home_page.dart';
import 'package:returnit/pages/placeholder_page.dart';
import 'package:returnit/pages/test_db_page.dart';
import 'package:returnit/pages/item_details_page.dart';
import 'package:returnit/utils/theme.dart';
import 'firebase_options.dart';

import 'package:returnit/screens/lost_items_screen.dart';
import 'package:returnit/screens/found_items_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ReturnIt',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.themeData,
      home: const SplashPage(),
      routes: {
        '/home': (context) => const HomePage(),
        '/test_db': (context) => const TestDbPage(),
        '/item_details': (context) => const ItemDetailsPage(),
        '/lost_items': (context) => const LostItemsScreen(),
        '/found_items': (context) => const FoundItemsScreen(),
        '/report_lost': (context) =>
            const PlaceholderPage(title: 'Report Lost Item'),
        '/report_found': (context) =>
            const PlaceholderPage(title: 'Report Found Item'),
        '/profile': (context) => const PlaceholderPage(title: 'Profile'),
        '/notifications': (context) =>
            const PlaceholderPage(title: 'Notifications'),
      },
    );
  }
}
