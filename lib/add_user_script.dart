import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:returnit/services/auth_service.dart';
import 'package:returnit/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  print('Starting manual user addition...');

  final authService = AuthService();

  final usersToAdd = [
    {
      'name': 'Mostafa Moheb',
      'email': 'UG_31157028@f-eng.tanta.edu.eg',
      'password': 'Moheb@123',
      'phoneNumber': '01015134814',
    },
    {
      'name': 'Ahmed Elshennawy',
      'email': 'UG_3117098@f-eng.tanta.edu.eg',
      'password': 'Shennawy@123',
      'phoneNumber': '01019458711',
    },
  ];

  for (final userData in usersToAdd) {
    print('------------------------------------------------');
    print('Registering: ${userData['name']} (${userData['email']})');
    try {
      final user = await authService.registerUser(
        name: userData['name']!,
        email: userData['email']!,
        password: userData['password']!,
        phoneNumber: userData['phoneNumber']!,
      );

      if (user != null) {
        print('SUCCESS: User added successfully.');
        print('UID: ${user.uid}');
      } else {
        print('FAILURE: User creation returned null.');
      }
    } catch (e) {
      print('ERROR: Failed to add user ${userData['name']}.');
      print(e.toString());
    }
  }

  print('------------------------------------------------');
  print('Process finished. Press Ctrl+C to exit if it hangs.');
}
