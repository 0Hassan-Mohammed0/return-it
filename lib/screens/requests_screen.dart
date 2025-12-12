import 'package:flutter/material.dart';

class RequestsScreen extends StatelessWidget {
  const RequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Requests'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF000B58),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mark_email_unread_outlined, size: 64, color: Color(0xFF000B58)),
            SizedBox(height: 16),
            Text(
              'Requests Page',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF000B58)),
            ),
            SizedBox(height: 8),
            Text(
              'To be implemented by Moheb',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
