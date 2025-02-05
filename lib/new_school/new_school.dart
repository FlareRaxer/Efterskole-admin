import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class NewSchool extends StatefulWidget {
  const NewSchool({super.key});

  @override
  _NewSchoolState createState() => _NewSchoolState();
}

class _NewSchoolState extends State<NewSchool> {
  // Create controllers for the text fields
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController schoolController = TextEditingController();

  @override
  Widget build(BuildContext context) {
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
      appBar: AppBar(
        title: const Text('Gå tilbage til forsiden'),
      ),
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
                    'assets/images/em_ikon_simple_rod.png', // Use the same image
                    width: imageSize,
                    height: imageSize,
                  ),
                  const SizedBox(height: 40),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Opret din efterskole på efterskolementor',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            fontWeight: FontWeight.w200,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Full Name Field
                  TextFormField(
                    controller: fullNameController,
                    decoration: InputDecoration(
                      labelText: 'Fulde navn',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Email Field
                  TextFormField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 20),

                  // Password Field
                  TextFormField(
                    controller: passwordController,
                    decoration: InputDecoration(
                      labelText: 'Kodeord',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    obscureText: true, // Hide the password text
                  ),
                  const SizedBox(height: 20),

                  // School Field
                  TextFormField(
                    controller: schoolController,
                    decoration: InputDecoration(
                      labelText: 'Efterskolens navn',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Return to Welcome Screen Button
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Navigate back to the welcome screen
                    },
                    child: const Text('Gå tilbage til hovedsiden'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Dispose of the controllers when the widget is disposed
    fullNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    schoolController.dispose();
    super.dispose();
  }
}
