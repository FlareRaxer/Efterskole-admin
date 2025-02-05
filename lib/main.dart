import 'package:efterskole_admin/screens/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme.dart'; // Import your theme file
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/admin_screen.dart';
import 'screens/elever_screen.dart';
import 'screens/mentor_screen.dart';
import 'screens/udtalelser_screen.dart';
import 'custom_route_settings.dart';
import 'screens/samtaler.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Efterskolementor Admin',
      theme: lightThemeData(), 
       initialRoute: '/',
      onGenerateRoute: (settings) {
        WidgetBuilder builder;
        switch (settings.name) {
          case '/':
            builder = (BuildContext _) => const WelcomeScreen();
            break;
          case '/admin':
            builder = (BuildContext _) => const AdminScreen();
            break;
          case '/samtaler':
            builder = (BuildContext _) => const SamtalerScreen();
            break;
          case '/elever':
            builder = (BuildContext _) => const EleverScreen();
            break;
          case '/mentor':
            builder = (BuildContext _) =>  const MentorScreen();
            break;
          case '/udtalelser':
            builder = (BuildContext _) => const UdtalelserScreen();
            break;
          default:
            throw Exception('Invalid route: ${settings.name}');
        }
        return NoAnimationPageRoute(builder: builder, settings: settings);
      },
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin forside'),
      ),
      body: const Center(
        child: Text('Her kommer admin siden'),
      ),
    );
  }
}