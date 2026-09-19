import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import '../providers/user_provider.dart';
import 'auth_screen.dart';
import 'home_dashboard.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Load saved user session first
    await ref.read(userProvider.notifier).loadSavedUser();
    
    // Additional delay for splash screen aesthetics
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (!mounted) return;
    
    final userState = ref.read(userProvider);
    if (userState.isLoggedIn) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeDashboard()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      body: Stack(
        children: [
          // High-Performance Ambient Glows (RadialGradient instead of BackdropFilter blur)
          Positioned(
            top: -150,
            right: -150,
            child: Container(
              width: 384,
              height: 384,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x33FF5A5F), Colors.transparent],
                  stops: [0.0, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -150,
            child: Container(
              width: 384,
              height: 384,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x333B82F6), Colors.transparent],
                  stops: [0.0, 1.0],
                ),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Image.asset('assets/images/logo.png', width: 96, height: 96),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Snap-N-Wrap',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1),
                ),
                const Text(
                  'PREMIUM PHOTO GIFTS',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFFF5A5F), letterSpacing: 3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
