import 'package:efterskole_admin/utils.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:efterskole_admin/menu/menu_bar.dart' as custom; // Ensure this import is correct
import 'dart:async';
import 'package:efterskole_admin/menu/small_menu.dart' as small;
import 'package:efterskole_admin/menu/navbar.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class SamtalerScreen extends StatefulWidget {
  const SamtalerScreen({super.key});

  @override
  _SamtalerScreenState createState() => _SamtalerScreenState();
}

class _SamtalerScreenState extends State<SamtalerScreen> {
  String? adminSchoolId;
  Map<String, Map<String, dynamic>> userData = {}; // Updated type
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    // Fetch adminSchoolId and user names once
    adminSchoolId = await getCurrentAdminSchoolId();
    if (adminSchoolId == null) {
      print('Admin school ID is null');
      setState(() {
        isLoading = false;
      });
      return;
    }

    // Pre-fetch user names and is_mentor status for mentors and students
    await _fetchAllUserNames();

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _fetchAllUserNames() async {
    try {
      QuerySnapshot userSnapshot =
          await FirebaseFirestore.instance.collection('users').get();

      for (var doc in userSnapshot.docs) {
        userData[doc.id] = {
          'full_name': doc['full_name'] ?? 'Unknown User',
          'is_mentor': doc['is_mentor'] ?? false,
        };
      }
    } catch (e) {
      print('Error fetching user names: $e');
    }
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) {
      return 'Ingen tidsstempel';
    }
    DateTime dateTime = timestamp.toDate();
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute}';
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
                  const custom.MenuBar(),
                  Expanded(
                    child: Column(children: [
                      Expanded(
                        child: isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : SingleChildScrollView(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: _buildContent(),
                                ),
                              ),
                      ),
                    ]),
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
                    padding: const EdgeInsets.only(
                        top: 60.0), // height of SmallMenu's top bar
                    child: isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : SingleChildScrollView(
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
              currentIndex: 2), // Add your BottomNavBar widget here
    );
  }

  Widget _buildContent() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .where('school_id', isEqualTo: adminSchoolId)
          .snapshots(),
      builder: (context, chatSnapshot) {
        if (chatSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (chatSnapshot.hasError) {
          return const Center(child: Text('Error fetching chats'));
        }
        if (!chatSnapshot.hasData || chatSnapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Ingen samtaler fundet'));
        }

        List<QueryDocumentSnapshot> chatDocs = chatSnapshot.data!.docs;
        chatDocs.sort((a, b) {
          Timestamp aTimestamp = a['timestamp'];
          Timestamp bTimestamp = b['timestamp'];
          return bTimestamp.compareTo(aTimestamp);
        });

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Samtaler dette skoleår',
              style: Theme.of(context).textTheme.displayMedium,
            ),
            const SizedBox(height: 20),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: chatDocs.length,
              itemBuilder: (context, index) {
                var chatDoc = chatDocs[index];
                return ChatItemWidget(
                  chatDoc: chatDoc,
                  userData: userData, // Updated line
                  formatTimestamp: _formatTimestamp,
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class ChatItemWidget extends StatefulWidget {
  final QueryDocumentSnapshot chatDoc;
  final Map<String, Map<String, dynamic>> userData; // Updated type
  final String Function(Timestamp?) formatTimestamp;

  const ChatItemWidget({
    super.key,
    required this.chatDoc,
    required this.userData,
    required this.formatTimestamp,
  });

  @override
  _ChatItemWidgetState createState() => _ChatItemWidgetState();
}

class _ChatItemWidgetState extends State<ChatItemWidget> {
  Map<String, dynamic> chatData = {};
  bool isUpdated = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    chatData = widget.chatDoc.data() as Map<String, dynamic>;

    // Listen for changes to this specific chat document
    widget.chatDoc.reference.snapshots().listen((snapshot) {
      if (snapshot.exists) {
        Map<String, dynamic> newChatData =
            snapshot.data() as Map<String, dynamic>;
        if (chatData['timestamp'] != newChatData['timestamp']) {
          setState(() {
            chatData = newChatData;
            isUpdated = true;
          });
          // Reset the highlight after 2 seconds
          _timer?.cancel();
          _timer = Timer(const Duration(seconds: 2), () {
            if (mounted) {
              setState(() {
                isUpdated = false;
              });
            }
          });
        } else {
          setState(() {
            chatData = newChatData;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String mentorName =
        widget.userData[chatData['mentor_id']]?['full_name'] ?? 'Unknown User';
    String studentName =
        widget.userData[chatData['student_id']]?['full_name'] ?? 'Unknown User';
    String lastChatUserName =
        widget.userData[chatData['last_chat_user_id']]?['full_name'] ??
            'Unknown User';

    bool isMentor =
        widget.userData[chatData['last_chat_user_id']]?['is_mentor'] ?? false;

    String formattedTimestamp = 'Ingen tidsstempel';
    if (chatData['timestamp'] != null) {
      Timestamp timestamp = chatData['timestamp'];
      formattedTimestamp = widget.formatTimestamp(timestamp);
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: isUpdated ? Colors.green.shade100 : Colors.grey[200],
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mentor: $mentorName',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF222222),
                ),
          ),
          Text(
            'Elev: $studentName',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF222222),
                ),
          ),
          const SizedBox(height: 10),
          Text(
            'Sidste besked: $formattedTimestamp af $lastChatUserName (${isMentor ? 'Mentor' : 'Elev'})',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}