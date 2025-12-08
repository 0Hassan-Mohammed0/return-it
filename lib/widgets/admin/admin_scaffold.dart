import 'package:flutter/material.dart';

import 'admin_sidebar.dart';

class AdminScaffold extends StatelessWidget {
  final Widget body;
  final String title;
  final String currentRoute;

  const AdminScaffold({
    super.key,
    required this.body,
    required this.title,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      appBar: isDesktop
          ? null
          : AppBar(
              title: Text(title),
              backgroundColor: Colors.white,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.black87),
              titleTextStyle: const TextStyle(
                color: Colors.black87,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
      drawer: isDesktop
          ? null
          : Drawer(
              child: AdminSidebar(
                currentRoute: currentRoute,
              ),
            ),
      body: Row(
        children: [
          if (isDesktop)
            AdminSidebar(
              currentRoute: currentRoute,
            ),
          Expanded(
            child: Column(
              children: [
                if (isDesktop)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    color: Colors.white,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const CircleAvatar(
                          backgroundColor: Colors.grey,
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: Container(
                    color: Colors.grey[100],
                    padding: const EdgeInsets.all(24),
                    child: body,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
