import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:efterskole_admin/widgets/login.dart';
import 'package:efterskole_admin/new_school/new_school.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get the screen width
    final screenWidth = MediaQuery.of(context).size.width;

    // Set the image size based on the screen width
    double imageSize;

    if (kIsWeb) {
      // On web, limit the image size to a maximum value
      imageSize = 75; // Set the maximum image size for web
    } else {
      // On mobile devices, scale the image size based on screen width
      imageSize = screenWidth * 0.3; // Adjust the multiplier as needed
    }

    // Optionally, set a maximum width for the content on web
    double contentWidth = screenWidth;
    if (kIsWeb) {
      contentWidth = 600; // Maximum content width for web
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: contentWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/em_ikon_simple_rod.png',
                    width: imageSize,
                    height: imageSize,
                  ),
                  const SizedBox(height: 40),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Login på Efterskolementors \n admin side',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            fontWeight: FontWeight.w200,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 20),
                  LoginPage(onLoginSuccess: () {
                    Navigator.pushReplacementNamed(context, '/admin');
                  }), // Add the LoginPage widget
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const NewSchool()),
                      );
                    },
                    child: const Text('Create New School'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}