// Overbliks siden, man kommer ind på, efter at være logget ind, og "hovedsiden" når man er logget ind
import 'package:efterskole_admin/screens/elever_screen.dart';
import 'package:efterskole_admin/screens/mentor_screen.dart';
import 'package:efterskole_admin/screens/samtaler.dart';
import 'package:efterskole_admin/widgets/blue_chart.dart';
import 'package:efterskole_admin/widgets/red_chart.dart';
//import 'package:efterskole_admin/widgets/diagram.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:efterskole_admin/menu/menu_bar.dart' as custom;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:efterskole_admin/menu/small_menu.dart' as small;
import 'package:efterskole_admin/menu/navbar.dart';
import 'package:flutter/foundation.dart';

final bottomNavBarIndexProvider = StateProvider<int>((ref) => 0);

class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key});

  Future<String?> fetchAdminSchoolId() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      DocumentSnapshot adminSnapshot = await FirebaseFirestore.instance
          .collection('admins')
          .doc(currentUser.uid)
          .get();
      if (adminSnapshot.exists) {
        return adminSnapshot['school_id'];
      }
    }
    return null;
  }

  Future<int> fetchMentorRequests(String? schoolId) async {
    if (schoolId != null) {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('school_id', isEqualTo: schoolId)
          .where('is_mentor', isEqualTo: true)
          .where('is_mentor_approved', isEqualTo: 'NO')
          .get();
      return querySnapshot.docs.length;
    }
    return 0;
  }

  Future<int> fetchStudentCount(String? schoolId) async {
    if (schoolId != null) {
      QuerySnapshot adminSnapshot = await FirebaseFirestore.instance
          .collection('admins')
          .where('school_id', isEqualTo: schoolId)
          .get();

      List<String> adminEmails =
          adminSnapshot.docs.map((doc) => doc['email'] as String).toList();

      QuerySnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('school_id', isEqualTo: schoolId)
          .get();

      int studentCount = userSnapshot.docs.where((doc) {
        String userEmail = doc['email'] as String;
        bool isMentor = doc['is_mentor'] ?? false;
        return !adminEmails.contains(userEmail) && !isMentor;
      }).length;

      return studentCount;
    }
    return 0;
  }

  Future<int> fetchChatCount(String? schoolId) async {
    if (schoolId != null) {
      QuerySnapshot chatSnapshot = await FirebaseFirestore.instance
          .collection('chats')
          .where('school_id', isEqualTo: schoolId)
          .get();
      return chatSnapshot.docs.length;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          double screenWidth = constraints.maxWidth;

          if (screenWidth > 900) {
            // For large screens
            return SafeArea(
              top: false,
              child: Row(
                children: [
                  const custom.MenuBar(),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0), // Modify or reduce padding here
                        child: SingleChildScrollView(
                          child: FutureBuilder<String?>(
                            future: fetchAdminSchoolId(),
                            builder: (context, schoolSnapshot) {
                              if (schoolSnapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              }

                              if (schoolSnapshot.hasData && schoolSnapshot.data != null) {
                                String? schoolId = schoolSnapshot.data;

                                return FutureBuilder<List<int>>(
                                  future: Future.wait([
                                    fetchMentorRequests(schoolId),
                                    fetchStudentCount(schoolId),
                                    fetchChatCount(schoolId),
                                  ]),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState == ConnectionState.waiting) {
                                      return const Center(child: CircularProgressIndicator());
                                    }

                                    if (snapshot.hasData) {
                                      int mentorRequestCount = snapshot.data![0];
                                      int studentCount = snapshot.data![1];
                                      int chatCount = snapshot.data![2];

                                      List<Widget> statBlocks = [];
                                      if (mentorRequestCount > 0) {
                                        statBlocks.add(_buildResponsiveStatBlock(
                                          context,
                                          'Nye mentor',
                                          'anmodninger',
                                          mentorRequestCount.toString(),
                                          () {
                                            Navigator.push(
                                              context,
                                              PageRouteBuilder(
                                                pageBuilder: (context, animation1, animation2) => const MentorScreen(),
                                                transitionDuration: Duration.zero,
                                                reverseTransitionDuration: Duration.zero,
                                              ),
                                            );
                                          },
                                        ));
                                      }
                                      statBlocks.add(_buildResponsiveStatBlock(
                                        context,
                                        'Samtaler',
                                        'dette skoleår',
                                        chatCount.toString(),
                                        () {
                                          Navigator.push(
                                            context,
                                            PageRouteBuilder(
                                              pageBuilder: (context, animation1, animation2) => const SamtalerScreen(),
                                              transitionDuration: Duration.zero,
                                              reverseTransitionDuration: Duration.zero,
                                            ),
                                          );
                                        },
                                      ));
                                      statBlocks.add(_buildResponsiveStatBlock(
                                        context,
                                        'Antal oprettede',
                                        'elever',
                                        studentCount.toString(),
                                        () {
                                          Navigator.push(
                                            context,
                                            PageRouteBuilder(
                                              pageBuilder: (context, animation1, animation2) => const EleverScreen(),
                                              transitionDuration: Duration.zero,
                                              reverseTransitionDuration: Duration.zero,
                                            ),
                                          );
                                        },
                                      ));

                                      return Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          LayoutBuilder(
                                            builder: (context, constraints) {
                                              double maxWidth = constraints.maxWidth;
                                              const double spacing = 20.0;

                                              int itemCount = statBlocks.length;

                                              int maxCrossAxisCount = (maxWidth / 300).floor();
                                              if (maxCrossAxisCount < 1) maxCrossAxisCount = 1;

                                              int crossAxisCount = itemCount < maxCrossAxisCount ? itemCount : maxCrossAxisCount;

                                              double desiredWidth = (maxWidth - (crossAxisCount - 1) * spacing) / crossAxisCount;
                                              double childAspectRatio = desiredWidth / 120;

                                              return GridView(
                                                shrinkWrap: true,
                                                physics: const NeverScrollableScrollPhysics(),
                                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                                  crossAxisCount: crossAxisCount,
                                                  mainAxisSpacing: 20.0,
                                                  crossAxisSpacing: spacing,
                                                  childAspectRatio: childAspectRatio,
                                                ),
                                                children: statBlocks,
                                              );
                                            },
                                          ),
                                          const SizedBox(height: 20),
                                          Text(
                                            'Efterskolementor statistik',
                                            style: Theme.of(context).textTheme.displayMedium,
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            'Antal oprettede samtaler mellem elev og mentor hver måned',
                                            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                              fontSize: 16.0,
                                              fontWeight: FontWeight.w100,
                                              ),
                                          ),
                                          const SizedBox(height: 15),
                                          const SizedBox(
                                            height: 400, // Adjust the height of the diagram
                                            child: LineChartWidget(), // Add the Diagram widget
                                          ),
                                          const SizedBox(height: 20),
                                          Text(
                                            'Antal oprettede elever hver måned',
                                            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                              fontSize: 16.0,
                                              fontWeight: FontWeight.w100,
                                              ),
                                          ),
                                          const SizedBox(height: 15),
                                          const SizedBox(
                                            height: 400, // Adjust the height of the diagram
                                            child: BlueLineChartWidget(), // Add the Diagram widget
                                          ),
                                        ],
                                      );
                                    } else {
                                      return const Text('Failed to load data');
                                    }
                                  },
                                );
                              } else {
                                return const Text('Ingen skole ID fundet');
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          } else {
            // For small screens
            return SafeArea(
              child: SingleChildScrollView( // Wrap the entire body with SingleChildScrollView
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 60.0),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: FutureBuilder<String?>(
                          future: fetchAdminSchoolId(),
                          builder: (context, schoolSnapshot) {
                            if (schoolSnapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }

                            if (schoolSnapshot.hasData && schoolSnapshot.data != null) {
                              String? schoolId = schoolSnapshot.data;

                              return FutureBuilder<List<int>>(
                                future: Future.wait([
                                  fetchMentorRequests(schoolId),
                                  fetchStudentCount(schoolId),
                                  fetchChatCount(schoolId),
                                ]),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return const Center(child: CircularProgressIndicator());
                                  }

                                  if (snapshot.hasData) {
                                    int mentorRequestCount = snapshot.data![0];
                                    int studentCount = snapshot.data![1];
                                    int chatCount = snapshot.data![2];

                                    List<Widget> statBlocks = [];
                                    if (mentorRequestCount > 0) {
                                      statBlocks.add(_buildResponsiveStatBlock(
                                        context,
                                        'Nye mentor',
                                        'anmodninger',
                                        mentorRequestCount.toString(),
                                        () {
                                          Navigator.push(
                                            context,
                                            PageRouteBuilder(
                                              pageBuilder: (context, animation1, animation2) => const MentorScreen(),
                                              transitionDuration: Duration.zero,
                                              reverseTransitionDuration: Duration.zero,
                                            ),
                                          );
                                        },
                                      ));
                                    }
                                    statBlocks.add(_buildResponsiveStatBlock(
                                      context,
                                      'Samtaler',
                                      'dette skoleår',
                                      chatCount.toString(),
                                      () {
                                        Navigator.push(
                                          context,
                                          PageRouteBuilder(
                                            pageBuilder: (context, animation1, animation2) => const SamtalerScreen(),
                                            transitionDuration: Duration.zero,
                                            reverseTransitionDuration: Duration.zero,
                                          ),
                                        );
                                      },
                                    ));
                                    statBlocks.add(_buildResponsiveStatBlock(
                                      context,
                                      'Antal oprettede',
                                      'elever',
                                      studentCount.toString(),
                                      () {
                                        Navigator.push(
                                          context,
                                          PageRouteBuilder(
                                            pageBuilder: (context, animation1, animation2) => const EleverScreen(),
                                            transitionDuration: Duration.zero,
                                            reverseTransitionDuration: Duration.zero,
                                          ),
                                        );
                                      },
                                    ));

                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        LayoutBuilder(
                                          builder: (context, constraints) {
                                            double maxWidth = constraints.maxWidth;
                                            const double spacing = 20.0;

                                            int itemCount = statBlocks.length;

                                            int maxCrossAxisCount = (maxWidth / 300).floor();
                                            if (maxCrossAxisCount < 1) maxCrossAxisCount = 1;

                                            int crossAxisCount = itemCount < maxCrossAxisCount ? itemCount : maxCrossAxisCount;

                                            double desiredWidth = (maxWidth - (crossAxisCount - 1) * spacing) / crossAxisCount;
                                            double childAspectRatio = desiredWidth / 120;

                                            return GridView(
                                              shrinkWrap: true,
                                              physics: const NeverScrollableScrollPhysics(),
                                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                                crossAxisCount: crossAxisCount,
                                                mainAxisSpacing: 20.0,
                                                crossAxisSpacing: spacing,
                                                childAspectRatio: childAspectRatio,
                                              ),
                                              children: statBlocks,
                                            );
                                          },
                                        ),
                                          const SizedBox(height: 20),
                                          Text(
                                            'Efterskolementor statistik',
                                            style: Theme.of(context).textTheme.displayMedium,
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            'Antal oprettede samtaler mellem elev og mentor hver måned',
                                            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                              fontSize: 16.0,
                                              fontWeight: FontWeight.w100,
                                              ),
                                          ),
                                          const SizedBox(height: 15),
                                          const SizedBox(
                                            height: 400, // Adjust the height of the diagram
                                            child: LineChartWidget(), // Add the Diagram widget
                                          ),
                                          const SizedBox(height: 20),
                                          Text(
                                            'Antal oprettede elever hver måned',
                                            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                              fontSize: 16.0,
                                              fontWeight: FontWeight.w100,
                                              ),
                                          ),
                                          const SizedBox(height: 15),
                                          const SizedBox(
                                            height: 400, // Adjust the height of the diagram
                                            child: BlueLineChartWidget(), // Add the Diagram widget
                                          ),
                                      ],
                                    );
                                  } else {
                                    return const Text('Failed to load data');
                                  }
                                },
                              );
                            } else {
                              return const Text('Ingen skole ID fundet');
                            }
                          },
                        ),
                      ),
                    ),
                    const small.SmallMenu(),
                  ],
                ),
              ),
            );
          }
        },
      ),
      bottomNavigationBar: kIsWeb
          ? null // Do not show BottomNavBar on the web
          : const BottomNavBar(
              currentIndex: 0), // Add your BottomNavBar widget here
    );
  }

  Widget _buildResponsiveStatBlock(
    BuildContext context,
    String title,
    String subtitle,
    String number,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 120,
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondary,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w400,
                          color: Colors.black,
                        ),
                  ),
                  const SizedBox(height: 5.0),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10.0),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                number,
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontSize: 28.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}