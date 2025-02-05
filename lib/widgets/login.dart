import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:efterskole_admin/login_authentication.dart'; // Import the AuthenticationService class
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';



class LoginPage extends StatefulWidget {
  final VoidCallback onLoginSuccess;

  const LoginPage({super.key, required this.onLoginSuccess});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthenticationService _authService = AuthenticationService(FirebaseAuth.instance, FirebaseFirestore.instance);
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  
  bool _rememberMe = false;

@override
void initState() {
  super.initState();
  _loadSavedCredentials().then((_) {
    // Delay the focus request to ensure the UI is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_emailController.text.isEmpty) {
        _emailFocusNode.requestFocus();
      } else if (_passwordController.text.isEmpty) {
        _passwordFocusNode.requestFocus();
      }
    });
  });
}

@override
void dispose() {
  _emailController.dispose();
  _passwordController.dispose();
  _emailFocusNode.dispose();
  _passwordFocusNode.dispose();
  super.dispose();
}

  Future<void> _loadSavedCredentials() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _emailController.text = prefs.getString('email') ?? '';
      _passwordController.text = prefs.getString('password') ?? '';
      _rememberMe = prefs.getBool('remember_me') ?? false;
    });
  }

  Future<void> _saveCredentials() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setString('email', _emailController.text);
      await prefs.setString('password', _passwordController.text);
      await prefs.setBool('remember_me', true);
    } else {
      await prefs.remove('email');
      await prefs.remove('password');
      await prefs.setBool('remember_me', false);
    }
  }

  Future<void> _login(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      final result = await _authService.signIn(email: email, password: password, context: context);

      if (result == null) {
        await _saveCredentials();
        widget.onLoginSuccess(); 
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result)));
      }
    }
  }

  Future<void> _showForgotPasswordDialog(BuildContext context) {
    final TextEditingController _resetEmailController = TextEditingController();

    return showDialog<void>(
      context: context,
      barrierDismissible: true, // Allow dismissal by tapping outside the dialog
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Nulstil din adgangskode',
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  'Indtast din email for at nulstille og lave en ny adgangskode.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _resetEmailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: Theme.of(context).textTheme.bodyMedium,
                  ),
                  style: Theme.of(context).textTheme.bodyMedium, // Use bodyMedium from theme
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
                child: Text(
                'Annuller',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
                child: Text(
                'Nulstil adgangskode',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              onPressed: () async {
                final email = _resetEmailController.text.trim();
                if (email.isNotEmpty) {
                  try {
                    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                    Navigator.of(context).pop(); // Close the dialog
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Link til nulstilling af adgangskode er sendt til din email')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Email eksisterer ikke. Tjek for fejl og @-tegn')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(0),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              TextFormField(
                controller: _emailController,
                focusNode: _emailFocusNode,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w300, // Custom font weight
                    fontSize: 15.0, // Custom font size
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide.none, // No border initially
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: const BorderSide(color: Colors.transparent), // Transparent border when enabled
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: const BorderSide(color: Colors.red), // Red border when focused
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.secondary,
                ),
                keyboardType: TextInputType.emailAddress,
                style: Theme.of(context).textTheme.bodyMedium,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Din email eksisterer ikke. Tjek for fejl og @-tegn';
                  }
                  return null;
                },
                autofillHints: const [AutofillHints.email],
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _passwordController,
                focusNode: _passwordFocusNode,
                decoration: InputDecoration(
                  labelText: 'Adganskode',
                  labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w300, // Custom font weight
                    fontSize: 15.0, // Custom font size
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide.none, // No border initially
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: const BorderSide(color: Colors.transparent), // Transparent border when enabled
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: const BorderSide(color: Colors.red), // Red border when focused
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.secondary,
                ),
                style: Theme.of(context).textTheme.bodyMedium,
                obscureText: true,
                textInputAction: TextInputAction.done,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Din adgangskode er ikke korrekt. Tjek for fejl og store og små bogstaver';
                  }
                  return null;
                },
                autofillHints: const [AutofillHints.password],
              ),
              const SizedBox(height: 20),
        
              // Align the checkbox and forgot password link
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: _rememberMe,
                        onChanged: (value) {
                          setState(() {
                            _rememberMe = value!;
                          });
                        },
                      ),
                      const Text('Husk mig'),
                    ],
                  ),
                  TextButton(
                    onPressed: () => _showForgotPasswordDialog(context), // Show the dialog when clicked
                    child: Text(
                      'Glemt adgangskode?',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
        
              // Make the login button full width
              SizedBox(
                width: double.infinity, // Take full width
                child: ElevatedButton(
                  onPressed: () => _login(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  child: const Text('Log ind'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}