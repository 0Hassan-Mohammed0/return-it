import 'package:flutter/material.dart';
import 'admin_dashboard_screen.dart';
import 'admin_users_screen.dart';
import 'admin_items_screen.dart';

class AdminRoot extends StatefulWidget {
  const AdminRoot({super.key});

  @override
  State<AdminRoot> createState() => _AdminRootState();
}

class _AdminRootState extends State<AdminRoot> {
  final int _selectedIndex = 0;



  @override
  Widget build(BuildContext context) {
    // Basic routing based on selected index
    switch (_selectedIndex) {
      case 0:
        return const AdminDashboardScreen();
      case 1:
        return const AdminUsersScreen();
      case 2:
        return const AdminItemsScreen();
      default:
        // Placeholder for other screens
        return const AdminDashboardScreen();
    }
  }
}
