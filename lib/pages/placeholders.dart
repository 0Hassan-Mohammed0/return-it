import 'package:flutter/material.dart';

// --- Generic Placeholder ---
class PlaceholderPage extends StatelessWidget {
  final String title;
  const PlaceholderPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text('$title Page\n(Under Construction)', textAlign: TextAlign.center),
      ),
    );
  }
}

// --- Specific Placeholders ---



class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});
  @override
  Widget build(BuildContext context) {
    return const PlaceholderPage(title: 'Notifications');
  }
}

class MyActivityPage extends StatelessWidget {
  const MyActivityPage({super.key});
  @override
  Widget build(BuildContext context) {
    return const PlaceholderPage(title: 'My Activity');
  }
}


