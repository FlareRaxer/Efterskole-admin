// utils.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<String?> getCurrentAdminSchoolId() async {
  User? user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    DocumentSnapshot adminDoc = await FirebaseFirestore.instance.collection('admins').doc(user.uid).get();
    return adminDoc.get('school_id') as String?;
  }
  return null;
}