import 'package:efterskole_admin/screens/welcome_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';


final selectedScreenProvider = StateNotifierProvider<SelectedScreenNotifier, String>((ref) {
  return SelectedScreenNotifier();
});

final hoverProvider = StateProvider<String?>((ref) => null);

final schoolNameProvider = FutureProvider<String>((ref) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    return 'Unknown School';
  }

  final doc = await FirebaseFirestore.instance.collection('admins').doc(user.uid).get();

  if (doc.exists) {
    return doc.data()?['school_name'] ?? 'Unknown School';
  } else {
    return 'Unknown School';
  }
});

class SelectedScreenNotifier extends StateNotifier<String> {
  SelectedScreenNotifier() : super('admin');

  void selectScreen(String screen) {
    state = screen;
  }
}

class MenuBar extends ConsumerWidget {
  const MenuBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedScreen = ref.watch(selectedScreenProvider);
    final schoolNameAsyncValue = ref.watch(schoolNameProvider);

    return Container(
      color: const Color(0xFFFF6666), // Use your primary color
      width: 270, // Adjust the width as needed
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Logo and app name
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Row(
                children: [
                  SvgPicture.asset(
                    'assets/images/em_ikon_simple.svg', // Path to your SVG icon image
                    colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn), // Apply white color to the SVG
                    width: 24, // Adjust the width as needed
                    height: 24, // Adjust the height as needed
                  ),
                  const SizedBox(width: 10.0),
                  Text(
                    'Efterskolementor',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontSize: (Theme.of(context).textTheme.bodyLarge?.fontSize ?? 14) + 5,
                        ),
                  ),
                ],
              ),
            ),
          ),
          // School name
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: schoolNameAsyncValue.when(
              data: (schoolName) => Text(
                schoolName,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontSize: (Theme.of(context).textTheme.bodyLarge?.fontSize ?? 14) + 5,
                    ),
              ),
              loading: () => const CircularProgressIndicator(),
              error: (error, stack) => Text('Error: $error'),
            ),
          ),
          const SizedBox(height: 20),
          // Menu Buttons
          _buildMenuButton(context, ref, 'Overblik', 'admin', selectedScreen),
          _buildMenuButton(context, ref, 'Mentorer', 'mentor', selectedScreen),
          _buildMenuButton(context, ref, 'Samtaler', 'samtaler', selectedScreen),
          _buildMenuButton(context, ref, 'Elever', 'elever', selectedScreen),
          // Add a Spacer to push the sign-out button to the bottom
          const Spacer(),
          // Sign-out button
          _buildSignOutButton(context, ref),
        ],
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context, WidgetRef ref, String title, String screen, String selectedScreen) {
    final hoverScreen = ref.watch(hoverProvider);

    return GestureDetector(
      onTap: () {
        ref.read(selectedScreenProvider.notifier).selectScreen(screen);
        Navigator.pushReplacementNamed(context, '/$screen');
      },
      child: MouseRegion(
        onEnter: (_) => ref.read(hoverProvider.notifier).state = screen,
        onExit: (_) => ref.read(hoverProvider.notifier).state = null,
        child: Container(
          color: selectedScreen == screen
              ? Colors.white.withOpacity(0.15)
              : hoverScreen == screen
                  ? Colors.white.withOpacity(0.06)
                  : Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
          child: Row(
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyLarge, // Use BodyLarge from theme
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignOutButton(BuildContext context, WidgetRef ref) {
    final hoverScreen = ref.watch(hoverProvider);

    return GestureDetector(
      onTap: () async {
        // Log out the user
        await FirebaseAuth.instance.signOut();
        // Navigate to the WelcomeScreen without animation
        Navigator.pushAndRemoveUntil(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation1, animation2) => const WelcomeScreen(),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
          (route) => false,
        );
      },
      child: MouseRegion(
        onEnter: (_) => ref.read(hoverProvider.notifier).state = 'signOut',
        onExit: (_) => ref.read(hoverProvider.notifier).state = null,
        child: Container(
          color: hoverScreen == 'signOut'
              ? Colors.white.withOpacity(0.06)
              : Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
          child: Row(
            children: [
              PhosphorIcon(PhosphorIcons.signOut(), color: Colors.white),
              const SizedBox(width: 10.0),
              Text(
                'Log ud',
                style: Theme.of(context).textTheme.bodyLarge, // Use same style as menu buttons
              ),
            ],
          ),
        ),
      ),
    );
  }
}