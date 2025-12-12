import 'package:flutter/material.dart';
import '../../utils/routes.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminSidebar extends StatelessWidget {
  final String currentRoute;

  const AdminSidebar({
    super.key,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      color: Colors.indigo[900],
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(24.0),
            child: Text(
              'ReturnIt Admin',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _buildNavItem(context, AppRoutes.dashboard, 'Dashboard', Icons.dashboard),
          _buildNavItem(context, AppRoutes.users, 'Users', Icons.people),
          _buildNavItem(context, AppRoutes.items, 'Items', Icons.inventory_2),
          // _buildNavItem(context, '/reports', 'Reports', Icons.flag), // Placeholder
          const Spacer(),
          // _buildNavItem(context, '/settings', 'Settings', Icons.settings), // Placeholder
           ListTile(
            leading: const Icon(Icons.logout, color: Colors.white70),
            title: const Text('Logout', style: TextStyle(color: Colors.white70)),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                 Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
              }
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, String route, String title, IconData icon) {
    final isSelected = currentRoute == route;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Colors.white : Colors.white70,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.white70,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      tileColor: isSelected ? Colors.white.withOpacity(0.1) : null,
      onTap: () {
        if (!isSelected) {
          Navigator.pushReplacementNamed(context, route);
        }
      },
    );
  }
}
