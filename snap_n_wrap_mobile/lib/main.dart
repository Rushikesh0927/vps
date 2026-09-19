import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'theme.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize local storage
  final prefs = await SharedPreferences.getInstance();
  
  runApp(
    const ProviderScope(
      child: SnapNWrapApp(),
    ),
  );
}

class SnapNWrapApp extends StatelessWidget {
  const SnapNWrapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Snap-N-Wrap',
      theme: PremiumTheme.darkTheme, // Enforce dark theme
      themeMode: ThemeMode.dark,
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}
