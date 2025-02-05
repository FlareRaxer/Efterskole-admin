import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Import Riverpod
import 'package:efterskole_admin/screens/admin_screen.dart';
import 'package:efterskole_admin/screens/mentor_screen.dart';
import 'package:efterskole_admin/screens/samtaler.dart';
import 'package:efterskole_admin/icons.dart';
import 'package:efterskole_admin/menu/small_menu.dart'; // Import small_menu.dart for the provider

// Custom route that disables page transition animations
class NoAnimationPageRoute<T> extends MaterialPageRoute<T> {
  NoAnimationPageRoute({required WidgetBuilder builder, RouteSettings? settings})
      : super(builder: builder, settings: settings);

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    return child;
  }
}

class BottomNavBar extends ConsumerWidget { // Use ConsumerWidget to interact with Riverpod
  final int currentIndex;
  final bool hideSelection; // Flag to control icon highlighting

  const BottomNavBar({super.key, required this.currentIndex, this.hideSelection = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) { // Use WidgetRef to access Riverpod providers
    final selectedScreen = ref.watch(selectedScreenProvider); // Watch the current screen state
    final TextStyle labelStyle = Theme.of(context).textTheme.bodyMedium!.copyWith(
          fontSize: 14.0,
        );

    // Determine the color for selected and unselected items
    Color selectedItemColor = Theme.of(context).bottomNavigationBarTheme.selectedItemColor ??
        Theme.of(context).colorScheme.primary;
    Color unselectedItemColor = Theme.of(context).bottomNavigationBarTheme.unselectedItemColor ?? Colors.grey;

    // Grey out both selected and unselected items if hideSelection is true
    Color selectedIconColor = hideSelection ? unselectedItemColor : selectedItemColor;
    Color unselectedIconColor = unselectedItemColor;

    return BottomNavigationBar(
      currentIndex: currentIndex, // Ensure the currentIndex is valid
      onTap: (index) {
        if (index == currentIndex && !hideSelection) return; // Prevent re-navigation to the same screen if not hiding selection

        // Update the selected screen in Riverpod when navigation happens
        switch (index) {
          case 0:
            ref.read(selectedScreenProvider.notifier).selectScreen('admin'); // Update Riverpod state
            Navigator.pushReplacement(
              context,
              NoAnimationPageRoute(builder: (context) => const AdminScreen()),
            );
            break;
          case 1:
            ref.read(selectedScreenProvider.notifier).selectScreen('mentor'); // Update Riverpod state
            Navigator.pushReplacement(
              context,
              NoAnimationPageRoute(builder: (context) => const MentorScreen()),
            );
            break;
          case 2:
            ref.read(selectedScreenProvider.notifier).selectScreen('samtaler'); // Update Riverpod state
            Navigator.pushReplacement(
              context,
              NoAnimationPageRoute(builder: (context) => const SamtalerScreen()),
            );
            break;
        }
      },
      items: [
        BottomNavigationBarItem(
          icon: Icon(browsersIcon.icon, color: selectedScreen == 'admin' ? selectedIconColor : unselectedIconColor),
          label: 'Hjem',
        ),
        BottomNavigationBarItem(
          icon: Icon(usersIcon.icon, color: selectedScreen == 'mentor' ? selectedIconColor : unselectedIconColor),
          label: 'Mentorer',
        ),
        BottomNavigationBarItem(
          icon: Icon(chatIcon.icon, color: selectedScreen == 'samtaler' ? selectedIconColor : unselectedIconColor),
          label: 'Samtaler',
        ),
      ],
      selectedLabelStyle: labelStyle,
      unselectedLabelStyle: labelStyle,
      selectedItemColor: selectedIconColor, // Apply correct color for selected item
      unselectedItemColor: unselectedIconColor, // Apply grey for unselected items
      showSelectedLabels: true,
      showUnselectedLabels: true,
    );
  }
}
