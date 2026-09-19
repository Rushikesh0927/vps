import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'checkout_screen.dart';
import '../providers/user_provider.dart';
import 'edit_profile_screen.dart';

class CartScreen extends ConsumerWidget {
  final VoidCallback? onContinueShopping;

  const CartScreen({super.key, this.onContinueShopping});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // For now, Cart is a dummy placeholder as full cart state requires a dedicated provider
    // We will show an empty state or a dummy item leading to checkout.
    
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: AppBar(
              backgroundColor: const Color(0xFF1D1D1F).withOpacity(0.5),
              elevation: 0,
              title: const Text('Your Cart', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.shopping_bag_outlined, size: 80, color: Color(0xFF374151)),
              const SizedBox(height: 24),
              const Text(
                'Your cart is empty',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 12),
              const Text(
                'Add some premium photo gifts to your cart to see them here.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Color(0xFFA1A1A6)),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5A5F),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () {
                    if (onContinueShopping != null) {
                      onContinueShopping!();
                    }
                  },
                  child: const Text('Continue Shopping', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 16),
              // Dummy proceed to checkout for testing
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    final user = ref.read(userProvider).user;
                    if (user != null && (user.mobile.isEmpty || user.savedAddress == null || user.savedAddress!.address.isEmpty)) {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen(isInitialSetup: true)));
                    } else {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const CheckoutScreen()));
                    }
                  },
                  child: const Text('Test Checkout Flow', style: TextStyle(color: Color(0xFFA1A1A6))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
