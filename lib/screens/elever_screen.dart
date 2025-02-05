import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:efterskole_admin/menu/menu_bar.dart' as custom; // Ensure this import is correct
import 'package:efterskole_admin/menu/small_menu.dart' as small;
import 'package:efterskole_admin/menu/navbar.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class EleverScreen extends ConsumerStatefulWidget {
  const EleverScreen({super.key});

  @override
  _EleverScreenState createState() => _EleverScreenState();
}

class _EleverScreenState extends ConsumerState<EleverScreen> {
  String? schoolId;
  List<Map<String, dynamic>> students = [];

  @override
  void initState() {
    super.initState();
    _fetchSchoolIdAndStudents();
  }

  Future<void> _fetchSchoolIdAndStudents() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot adminSnapshot =
            await FirebaseFirestore.instance.collection('admins').doc(user.uid).get();
        schoolId = adminSnapshot['school_id'];

        QuerySnapshot studentsSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('school_id', isEqualTo: schoolId)
            .get();

        setState(() {
          students = studentsSnapshot.docs
              .map((doc) => doc.data() as Map<String, dynamic>)
              .toList();
        });
      }
    } catch (e) {
      print('Error fetching school ID and students: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Determine screen width using constraints
          double screenWidth = constraints.maxWidth;

          if (screenWidth > 900) {
            // For large screens, use a Row with MenuBar and content
            return SafeArea(
              child: Row(
                children: [
                  const custom.MenuBar(), // MenuBar on the left side
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: _buildContent(),
                    ),
                  ),
                ],
              ),
            );
          } else {
            // For small screens, use a Stack with SmallMenu overlaid
            return SafeArea(
              child: Stack(
                children: [
                  // Main content with padding to avoid overlap with top bar
                  Padding(
                    padding:
                        const EdgeInsets.only(top: 60.0), // height of SmallMenu's top bar
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: _buildContent(),
                      ),
                    ),
                  ),
                  // SmallMenu overlaid on top
                  const small.SmallMenu(),
                ],
              ),
            );
          }
        },
      ),
      bottomNavigationBar: kIsWeb
          ? null // Do not show BottomNavBar on the web
          : const BottomNavBar(
              currentIndex: -1
              ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Elever',
              style: Theme.of(context).textTheme.displayMedium,
            ),
            const SizedBox(height: 20),
            students.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: students.length,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondary,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Text(
                          students[index]['full_name'] ?? 'Ingen navn',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF222222),
                              ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      
    );
  }
}