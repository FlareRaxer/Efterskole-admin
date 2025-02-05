import 'package:efterskole_admin/screens/welcome_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

final selectedScreenProvider =
    StateNotifierProvider<SelectedScreenNotifier, String>((ref) {
  return SelectedScreenNotifier();
});

final hoverProvider = StateProvider<String?>((ref) => null);

final menuOpenProvider = StateProvider<bool>((ref) => false);

class SelectedScreenNotifier extends StateNotifier<String> {
  SelectedScreenNotifier() : super('admin');

  void selectScreen(String screen) {
    state = screen;
  }
}

class SmallMenu extends ConsumerWidget {
  const SmallMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedScreen = ref.watch(selectedScreenProvider);
    final menuOpen = ref.watch(menuOpenProvider);

    return SizedBox(
      height: menuOpen ? MediaQuery.of(context).size.height : 60,
      child: Stack(
        children: [
          // Menu Overlay (Visible when menu is open)
          if (menuOpen)
            Positioned(
              top: 60, // Start below the top bar
              left: 0,
              right: 0,
              bottom: 0,
              child: GestureDetector(
                onTap: () {
                  // Close the menu if user taps outside
                  ref.read(menuOpenProvider.notifier).state = false;
                },
                child: Container(
                  color: kIsWeb
                      ? Colors.black.withOpacity(0.5) // Semi-transparent overlay on web
                      : Colors.transparent, // No overlay on mobile
                ),
              ),
            ),
          // Side Menu (Visible when menu is open)
          if (menuOpen)
            Positioned(
              top: 60, // Start below the top bar
              right: 0, // Align to the right
              bottom: 0, // Extend to bottom on both mobile and web
              child: Container(
                width: kIsWeb
                    ? 300
                    : MediaQuery.of(context).size.width * 0.8, // 80% width on mobile
                color: const Color(0xFFFF6666),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch, // Full width children
                  children: [
                    // Menu Buttons
                    _buildMenuButton(context, ref, 'Overblik', 'admin', selectedScreen),
                    _buildMenuButton(context, ref, 'Mentorer', 'mentor', selectedScreen),
                    _buildMenuButton(context, ref, 'Samtaler', 'samtaler', selectedScreen),
                    _buildMenuButton(context, ref, 'Elever', 'elever', selectedScreen),
                    Expanded(child: Container()), // Pushes the log out button to the bottom
                    // Sign-out button
                    _buildSignOutButton(context, ref),
                  ],
                ),
              ),
            ),
          // Top Bar
          Container(
            color: const Color(0xFFFF6666),
            height: 60,
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Efterskolementor Text
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'Efterskolementor',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontSize:
                              (Theme.of(context).textTheme.bodyLarge?.fontSize ?? 14) + 5,
                          color: Colors.white,
                        ),
                  ),
                ),
                // IconButton
                IconButton(
                  icon: menuOpen
                      ? PhosphorIcon(PhosphorIcons.x(PhosphorIconsStyle.bold),
                          color: Colors.white)
                      : PhosphorIcon(PhosphorIcons.list(PhosphorIconsStyle.bold),
                          color: Colors.white),
                  onPressed: () {
                    // Toggle the menu open state
                    ref.read(menuOpenProvider.notifier).state = !menuOpen;
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context, WidgetRef ref, String title,
      String screen, String selectedScreen) {
    final hoverScreen = ref.watch(hoverProvider);

    return GestureDetector(
      onTap: () {
        // Close the menu
        ref.read(menuOpenProvider.notifier).state = false;
        // Update the selected screen
        ref.read(selectedScreenProvider.notifier).selectScreen(screen);
        Navigator.pushReplacementNamed(context, '/$screen');
      },
      child: MouseRegion(
        onEnter: (_) => ref.read(hoverProvider.notifier).state = screen,
        onExit: (_) => ref.read(hoverProvider.notifier).state = null,
        child: Container(
          width: double.infinity,
          alignment: Alignment.centerRight, // Align content to the right
          color: selectedScreen == screen
              ? Colors.white.withOpacity(0.15)
              : hoverScreen == screen
                  ? Colors.white.withOpacity(0.06)
                  : Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
          child: Text(
            title,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white,
                ),
          ),
        ),
      ),
    );
  }

  Widget _buildSignOutButton(BuildContext context, WidgetRef ref) {
    final hoverScreen = ref.watch(hoverProvider);

    return GestureDetector(
      onTap: () async {
        // Close the menu
        ref.read(menuOpenProvider.notifier).state = false;
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
          width: double.infinity,
          alignment: Alignment.centerRight, // Align content to the right
          color: hoverScreen == 'signOut'
              ? Colors.white.withOpacity(0.06)
              : Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end, // Align content to the right
            children: [
              Text(
                'Log ud',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white,
                    ),
              ),
              const SizedBox(width: 10.0),
              PhosphorIcon(PhosphorIcons.signOut(), color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}