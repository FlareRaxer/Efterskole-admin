import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:efterskole_admin/utils.dart';
import 'package:flutter/material.dart';
import 'package:efterskole_admin/menu/menu_bar.dart' as custom_menu;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';
import 'package:efterskole_admin/menu/small_menu.dart' as small;
import 'package:efterskole_admin/menu/navbar.dart';

final TextStyle dialogTextStyle = GoogleFonts.poppins();

class MentorScreen extends StatefulWidget {
  const MentorScreen({super.key});

  @override
  _MentorScreenState createState() => _MentorScreenState();
}

class _MentorScreenState extends State<MentorScreen> {
  // Function to accept a mentor request
  Future<void> acceptMentorRequest(String mentorId, Function refresh) async {
    await FirebaseFirestore.instance.collection('users').doc(mentorId).update({
      'is_mentor_approved': 'YES',
    });
    refresh(); // Refresh the screen after action
  }

  // Function to deny a mentor request
  Future<void> denyMentorRequest(String mentorId, Function refresh) async {
    await FirebaseFirestore.instance.collection('users').doc(mentorId).update({
      'is_mentor_approved': 'DENIED',
    });
    refresh(); // Refresh the screen after action
  }

  // Function to delete a mentor
  Future<void> deleteMentor(String mentorId, Function refresh) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(mentorId).delete();
      refresh(); // Refresh the screen after action
    } catch (e) {
      print('Error deleting mentor $mentorId: $e');
      // Optionally, show an error message to the user
    }
  }
 
  // Helper function to fetch the download URL from Firebase Storage
  Future<String> _getImageUrl(String storagePath) async {
    if (storagePath.isEmpty) {
      return '';
    }
    try {
      final ref = FirebaseStorage.instance.ref().child(storagePath);
      final url = await ref.getDownloadURL();
      return url;
    } catch (e) {
      print('Error fetching download URL: $e');
      return '';
    }
  }

  // Helper function to format timestamp
  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Ingen data';
    DateTime date = timestamp.toDate();
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
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
              child: Padding(
                padding: const EdgeInsets.all(0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const custom_menu.MenuBar(),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16.0),
                        child: FutureBuilder<String?>(
                          future: getCurrentAdminSchoolId(),
                          builder: (context, schoolSnapshot) {
                            if (schoolSnapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }
                
                            if (schoolSnapshot.hasData && schoolSnapshot.data != null) {
                              return _buildMentorContent(schoolSnapshot.data!);
                            } else {
                              return const Center(child: Text('Ingen skole ID fundet'));
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          } else {
            // For small screens, use a Stack with SmallMenu overlaid
            return SafeArea(
              child: Stack(
                children: [
                  // Main content with padding to avoid overlap with top bar
                  Padding(
                    padding: const EdgeInsets.only(top: 60.0), // height of SmallMenu's top bar
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: FutureBuilder<String?>(
                          future: getCurrentAdminSchoolId(),
                          builder: (context, schoolSnapshot) {
                            if (schoolSnapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }

                            if (schoolSnapshot.hasData && schoolSnapshot.data != null) {
                              return _buildMentorContent(schoolSnapshot.data!);
                            } else {
                              return const Center(child: Text('Ingen skole ID fundet'));
                            }
                          },
                        ),
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
              currentIndex: 1
              ),
    );
  }

  Widget _buildMentorContent(String schoolId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Pending Mentors Section
        FutureBuilder<QuerySnapshot>(
          future: _getPendingMentors(schoolId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator(); // Show loading indicator
            } else if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Afventer godkendelse',
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                  const SizedBox(height: 10),
                  ...snapshot.data!.docs.map((doc) {
                    var mentorData = doc.data() as Map<String, dynamic>;
                    return FutureBuilder<String>(
                      future: _getImageUrl(mentorData['photo_url'] ?? ''),
                      builder: (context, photoSnapshot) {
                        if (photoSnapshot.connectionState == ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        }
                        return _buildMentorRequestBlock(
                          context,
                          mentorData['full_name'] ?? 'No Name',
                          (photoSnapshot.data ?? ''),
                          doc.id, // Pass document ID to manage accept/deny
                          () => setState(() {}), // Refresh the UI after action
                        );
                      },
                    );
                  }).toList(),
                ],
              );
            } else {
              return const SizedBox.shrink();
            }
          },
        ),
        
        // Approved Mentors Section
        Text(
          'Godkendte mentorer',
          style: Theme.of(context).textTheme.displayMedium,
        ),
        const SizedBox(height: 20),
        FutureBuilder<QuerySnapshot>(
          future: _getApprovedMentors(schoolId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              print("Error fetching approved mentors: ${snapshot.error}"); // Debugging line
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
              print("Fetching approved mentors"); // Debugging line
              return Column(
                children: snapshot.data!.docs.map((doc) {
                  var mentorData = doc.data() as Map<String, dynamic>;
                  String mentorId = doc.id; // Mentor's user ID

                  return FutureBuilder<String>(
                    future: _getImageUrl(mentorData['photo_url'] ?? ''),
                    builder: (context, photoSnapshot) {
                      if (photoSnapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final imageUrl = photoSnapshot.data ?? '';

                      return _buildApprovedMentorItem(
                        context,
                        mentorData,
                        imageUrl,
                        mentorId,
                        () => setState(() {}), // Refresh the UI after action
                      );
                    },
                  );
                }).toList(),
              );
            } else {
              print("No approved mentors found"); // Debugging line
              return const Center(child: Text('Ingen godkendte mentorer'));
            }
          },
        ),
      ],
    );
  }

   // Function to build each mentor request block
  Widget _buildMentorRequestBlock(
    BuildContext context,
    String fullName,
    String photoUrl,
    String mentorId,
    Function refresh,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade200, // Grey background
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row with picture and name aligned horizontally
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Picture
              CircleAvatar(
                radius: 30.0,
                backgroundColor: Colors.grey,
                backgroundImage:
                    (!kIsWeb && photoUrl.isNotEmpty) ? NetworkImage(photoUrl) : null,
                child: (kIsWeb || photoUrl.isEmpty)
                    ? PhosphorIcon(
                        PhosphorIcons.user(),
                        size: 32.0,
                        color: Colors.white,
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              // Name and status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF222222),
                          ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Afventer',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(thickness: 1), // Solid line separator
          const SizedBox(height: 10),
          // Action buttons centered
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              ElevatedButton(
                onPressed: () {
                  acceptMentorRequest(mentorId, refresh); // Accept request
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                ),
                child: Text(
                  'Godkend',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  denyMentorRequest(mentorId, refresh); // Deny request
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE1E1E1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      PhosphorIcons.trash(),
                      size: 16, // Trash icon
                      color: const Color(0xFF222222),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Afvis',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF222222),
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Function to build each approved mentor item
  Widget _buildApprovedMentorItem(
    BuildContext context,
    Map<String, dynamic> mentorData,
    String imageUrl,
    String mentorId,
    Function refresh,
  ) {
    // Define constants for picture size and spacing
    const double pictureRadius = 30.0;
    const double spacing = 16.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade200, // Grey background
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Upper section: picture and name
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Picture
              CircleAvatar(
                radius: pictureRadius,
                backgroundColor: Colors.grey,
                backgroundImage: (!kIsWeb && imageUrl.isNotEmpty) ? NetworkImage(imageUrl) : null,
                child: (kIsWeb || imageUrl.isEmpty)
                    ? PhosphorIcon(
                        PhosphorIcons.user(),
                        size: 32.0,
                        color: Colors.white,
                      )
                    : null,
              ),
              const SizedBox(width: spacing),
              // Name and 'Godkendt'
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mentorData['full_name'] ?? 'No Name',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF222222),
                          ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Godkendt',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.green,
                            fontWeight: FontWeight.normal,
                            fontSize: 16,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(thickness: 1), // Solid line separator

          // Lower section: 'Sidst logget ind', 'Samtaler', and trash bin icon
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sidst logget ind: ${_formatTimestamp(mentorData['last_sign_in_time'])}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    FutureBuilder<int>(
                      future: _getMentorChatCount(mentorId),
                      builder: (context, chatCountSnapshot) {
                        if (chatCountSnapshot.connectionState == ConnectionState.waiting) {
                          return const Text('Samtaler: Loading...');
                        } else if (chatCountSnapshot.hasError) {
                          return const Text('Samtaler: Error');
                        } else {
                          int chatCount = chatCountSnapshot.data ?? 0;
                          return Text(
                            'Samtaler: $chatCount',
                            style: Theme.of(context).textTheme.bodyMedium,
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
              // Trash bin icon at the bottom right
              IconButton(
                icon: Icon(
                  PhosphorIcons.trash(),
                  color: Colors.grey.shade600,
                ),
                onPressed: () {
                  _showDeleteConfirmationDialog(context, mentorId, mentorData['full_name'] ?? 'No Name', refresh);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Function to show delete confirmation dialog
  void _showDeleteConfirmationDialog(
    BuildContext context,
    String mentorId,
    String mentorName,
    Function refresh,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Slet mentor',
            style: dialogTextStyle,
          ),
          content: Text(
            'Er du sikker på, at du vil slette mentoren "$mentorName"? Denne handling kan ikke fortrydes.',
            style: dialogTextStyle,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text(
                'Annuller',
                style: dialogTextStyle,
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close the dialog
                await deleteMentor(mentorId, refresh); // Delete the mentor
              },
              child: Text(
                'Slet',
                style: dialogTextStyle,
              ),
            ),
          ],
        );
      },
    );
  }

  // Function to fetch pending mentors from Firestore
  Future<QuerySnapshot> _getPendingMentors(String schoolId) async {
    return FirebaseFirestore.instance
        .collection('users')
        .where('school_id', isEqualTo: schoolId)
        .where('is_mentor_approved', isEqualTo: 'NO')
        .get();
  }

  // Function to fetch approved mentors from Firestore
  Future<QuerySnapshot> _getApprovedMentors(String schoolId) async {
    return FirebaseFirestore.instance
        .collection('users')
        .where('school_id', isEqualTo: schoolId)
        .where('is_mentor_approved', isEqualTo: 'YES')
        .get();
  }

  // Function to get the number of chats for a mentor
  Future<int> _getMentorChatCount(String mentorId) async {
    try {
      QuerySnapshot chatSnapshot = await FirebaseFirestore.instance
          .collection('chats')
          .where('mentor_id', isEqualTo: mentorId)
          .get();
      return chatSnapshot.docs.length;
    } catch (e) {
      print('Error fetching chat count for mentor $mentorId: $e');
      return 0;
    }
  }
}