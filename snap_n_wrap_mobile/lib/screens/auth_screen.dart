import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/user_provider.dart';
import '../theme.dart';
import 'home_dashboard.dart';
import 'phone_auth_screen.dart';
import 'edit_profile_screen.dart';

class AuthScreen extends ConsumerWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen for auth state changes to navigate
    ref.listen<UserState>(userProvider, (previous, next) {
      if (next.isLoggedIn && next.user != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeDashboard()),
        );
      }
    });

    final userState = ref.watch(userProvider);
    final userNotifier = ref.read(userProvider.notifier);

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
          
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Logo
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Image.asset('assets/images/logo.png', width: 56, height: 56),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Snap-N-Wrap',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5),
                    ),
                    const Text(
                      'PREMIUM PHOTO GIFTS',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFFF5A5F), letterSpacing: 2),
                    ),
                    const SizedBox(height: 48),

                    // Glass Card
                    ClipRRect(
                      borderRadius: BorderRadius.circular(32),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(color: Colors.white.withOpacity(0.1)),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'Welcome',
                                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Sign in to track orders and manage your account',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.6), fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 32),

                              // Google Auth Button
                              InkWell(
                                onTap: userState.isLoading ? null : () => userNotifier.loginWithGoogle(),
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: userState.isLoading
                                      ? const Center(
                                          child: SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(strokeWidth: 3, color: Color(0xFFFF5A5F)),
                                          ),
                                        )
                                      : const Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              'G',
                                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                                            ),
                                            SizedBox(width: 12),
                                            Text(
                                              'Continue with Google',
                                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF374151)),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Mobile Number Auth Button
                              InkWell(
                                onTap: userState.isLoading ? null : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const PhoneAuthScreen()),
                                  );
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.phone_android, color: Colors.white, size: 20),
                                      SizedBox(width: 12),
                                      Text(
                                        'Continue with Mobile',
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              
                              if (userState.error != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 16),
                                  child: Text(
                                    userState.error!,
                                    style: const TextStyle(color: Color(0xFFFF5A5F), fontSize: 12),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
