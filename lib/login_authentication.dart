import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
//import 'package:efterskole_admin/widgets/login.dart'; // Import the LoginPage widget


class AuthenticationService {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  AuthenticationService(this._firebaseAuth, this._firestore);

  Future<String?> signIn({required String email, required String password, required BuildContext context}) async {
    try {
      // 1. Authenticate with Firebase FIRST
      UserCredential userCredential = await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
      User? user = userCredential.user;

      if (user != null) {
        // 2. Now that the user is authenticated, check if they exist in Firestore
        DocumentSnapshot userSnapshot = await _firestore.collection('admins').doc(user.uid).get();

        if (!userSnapshot.exists) {
          return 'User not found in database.';
        }

              // 3. Update last_sign_in_time in Firestore
      await _firestore.collection('users').doc(user.uid).update({
        'last_sign_in_time': FieldValue.serverTimestamp(),
      });

        // User is authenticated and exists in Firestore
        Navigator.pushReplacementNamed(context, '/admin');
        return null; // Login successful
      } else {
        return 'User authentication failed'; // This should ideally not happen
      }

      
    } on FirebaseAuthException catch (e) {
      // Handle Firebase Authentication errors (e.g., wrong password)
      if (e.code == 'user-not-found') {
        return 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        return 'Wrong password provided for that user.';
      } else {
        return 'Login error: ${e.code}';
      }
    } catch (e) {
      return 'Login error: $e';
    }
    
  }
}