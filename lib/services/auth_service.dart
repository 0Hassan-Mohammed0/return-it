import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:developer' as dev;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Helper function to hash password
  String _hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  // 1️⃣ Sign In Function
  Future<DocumentSnapshot?> signInUser(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Retrieve user data from Firestore
      if (userCredential.user != null) {
        return await _firestore.collection('users').doc(userCredential.user!.uid).get();
      }
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw Exception('No user found for that email.');
      } else if (e.code == 'wrong-password') {
        try {
          final querySnapshot = await _firestore
              .collection('users')
              .where('email', isEqualTo: email)
              .limit(1)
              .get();

          if (querySnapshot.docs.isNotEmpty) {
            final userDoc = querySnapshot.docs.first;
            final storedHash = userDoc['password'];
            final inputHash = _hashPassword(password);
            
            if (storedHash == inputHash) {
              return userDoc; // Manual login success
            }
          }
        } catch (e) {
          // Ignore Firestore errors during fallback
        }
        throw Exception('Wrong password provided for that user.');
      } else if (e.code == 'invalid-email') {
        throw Exception('The email address is badly formatted.');
      } else if (e.code == 'user-disabled') {
        throw Exception('This user account has been disabled.');
      } else {
        throw Exception(e.message ?? 'An unknown error occurred during login.');
      }
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  // 2️⃣ Register Function
  Future<User?> registerUser({
    required String email,
    required String password,
    required String name,
    required String phoneNumber,
  }) async {
    try {
      // Create Firebase user
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Save user data to Firestore
      if (userCredential.user != null) {
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'id': userCredential.user!.uid,
          'email': email,
          'name': name,
          'phoneNumber': phoneNumber,
          'profileImageUrl': '', // optional, empty by default
          'role': 'user', // default role
          'password': _hashPassword(password),
        });
      }

      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        throw Exception('The password provided is too weak.');
      } else if (e.code == 'email-already-in-use') {
        throw Exception('The account already exists for that email.');
      } else if (e.code == 'invalid-email') {
        throw Exception('The email address is badly formatted.');
      } else {
        throw Exception(e.message ?? 'An unknown error occurred during registration.');
      }

    }
  }

  // 3️⃣ Reset Password Function
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw Exception('No user found for that email.');
      } else if (e.code == 'invalid-email') {
        throw Exception('The email address is badly formatted.');
      } else {
        throw Exception(e.message ?? 'An unknown error occurred during password reset.');
      }
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  // 4️⃣ Update Password in Firestore (For OTP Flow)
  Future<void> updatePasswordInFirestore(String email, String newPassword) async {
    try {
      // Find user by email
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();


      if (querySnapshot.docs.isEmpty) {
        throw Exception('User not found.');
      }

      final docId = querySnapshot.docs.first.id;

      // Update password
      await _firestore.collection('users').doc(docId).update({
        'password': _hashPassword(newPassword),
      });

    } catch (e) {
      throw Exception('Failed to update password: $e');
    }
  }




  // 5.5 Check if Email or Phone Exists
  Future<String?> checkEmailOrPhoneExists(String email, String phone) async {
      // 1. Check Email via Auth Probe
      bool emailExists = await doesEmailExist(email);
      if (emailExists) return 'Email already registered.';

      // 2. Check Phone (Must invoke Firestore)
      // Note: This requires Firestore security rules to allow reading 'users' collection for unauthenticated users
      // or at least querying it.
      try {
        final phoneQuery = await _firestore
            .collection('users')
            .where('phoneNumber', isEqualTo: phone)
            .limit(1)
            .get();
        if (phoneQuery.docs.isNotEmpty) return 'Phone number already registered.';
      } catch (e) {
        // If we can't read the DB, we can't enforce phone uniqueness. 
        // We log it but let it pass to avoid blocking registration if rules are strict.
        dev.log('Warning: Would check phone, but Firestore failed: $e', name: 'AuthService');
      }

      return null; // None exist
  }

  // Helper: reliable check using Auth Probe
  Future<bool> doesEmailExist(String email) async {
    try {
      // Attempt to create a temp user
      UserCredential probe = await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: "ProbePassword123!" 
      );
      // If successful, it DID NOT exist. Clean up.
      await probe.user?.delete();
      return false;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        return true; // Exists
      }
    } catch (_) {
      // Ignore other errors
    }
    return false; // Default
  }

  // 6️⃣ Server-Side Lockout Logic (Firestore)
  Future<bool> isAccountLocked(String email) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) return false; // User not found, can't be locked (or handle as spam)

      final userDoc = querySnapshot.docs.first;
      final data = userDoc.data();

      // Check 'lockoutUntil'
      if (data.containsKey('lockoutUntil') && data['lockoutUntil'] != null) {
        final lockoutTimestamp = (data['lockoutUntil'] as Timestamp).toDate();
        if (DateTime.now().isBefore(lockoutTimestamp)) {
           return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> handleFailedAttempt(String email) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) return; // Can't lock non-existent user

      final userDoc = querySnapshot.docs.first;
      final docId = userDoc.id;
      final data = userDoc.data();

      int attempts = data['failedAttempts'] ?? 0;
      attempts++;

      Map<String, dynamic> updates = {'failedAttempts': attempts};

      if (attempts >= 4) {
        updates['lockoutUntil'] = Timestamp.fromDate(DateTime.now().add(const Duration(hours: 1)));
      }

      await _firestore.collection('users').doc(docId).update(updates);
    } catch (e) {
      // Ignore failed attempt updates
    }
  }
  
  Future<void> resetFailedAttempts(String email) async {
    try {
      final querySnapshot = await _firestore
           .collection('users')
           .where('email', isEqualTo: email)
           .limit(1)
           .get();

      if (querySnapshot.docs.isNotEmpty) {
        await _firestore.collection('users').doc(querySnapshot.docs.first.id).update({
          'failedAttempts': 0,
          'lockoutUntil': null,
        });
      }
    } catch (e) {
      // ignore
    }
  }
  // 7️⃣ Get Current User Data
  Future<Map<String, dynamic>?> getCurrentUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      return doc.data();
    }
    return null;
  }
}
