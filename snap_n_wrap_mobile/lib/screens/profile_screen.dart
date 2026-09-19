import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/user_provider.dart';
import 'edit_profile_screen.dart';
import 'privacy_policy_screen.dart';
import 'auth_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(userProvider);
    final user = userState.user;
    final userNotifier = ref.read(userProvider.notifier);

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
              title: const Text('My Profile', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              actions: [
                TextButton(
                  onPressed: () async {
                    await userNotifier.logout();
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const AuthScreen()),
                        (route) => false,
                      );
                    }
                  },
                  child: const Text('Logout', style: TextStyle(color: Color(0xFFFF5A5F), fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: user == null
            ? const Center(child: Text("Not logged in", style: TextStyle(color: Colors.white)))
            : ListView(
                padding: const EdgeInsets.all(24.0),
                children: [
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      // Avatar Block
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF5A5F),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Text(
                            user.name.isNotEmpty 
                                ? user.name.trim().split(RegExp(r'\s+')).take(2).map((s) => s[0].toUpperCase()).join('')
                                : 'RY',
                            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      // User Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.name.isNotEmpty ? user.name : 'Unknown User',
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            if (user.mobile.isNotEmpty)
                              Text(
                                user.mobile,
                                style: const TextStyle(fontSize: 14, color: Color(0xFFA1A1A6)),
                              ),
                            const SizedBox(height: 2),
                            if (user.email.isNotEmpty)
                              Text(
                                user.email,
                                style: const TextStyle(fontSize: 14, color: Color(0xFFA1A1A6)),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),

                  if (user.savedAddress != null && user.savedAddress!.address.isNotEmpty) ...[
                    const Text(
                      'Saved Address',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1D1D1F),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withOpacity(0.05)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined, color: Color(0xFFFF5A5F), size: 24),
                              const SizedBox(width: 12),
                              const Text(
                                'Default Shipping',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
                                },
                                child: Icon(Icons.edit_outlined, color: Colors.white.withOpacity(0.5), size: 20),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(color: Colors.white10),
                          const SizedBox(height: 16),
                          Text(
                            user.savedAddress!.address,
                            style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8), height: 1.5),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'PIN: ${user.savedAddress!.pincode}',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFA1A1A6)),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // Empty state for address
                    const Text(
                      'Saved Address',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1D1D1F),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withOpacity(0.05)),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.add_location_alt_outlined, size: 40, color: Colors.white.withOpacity(0.2)),
                            const SizedBox(height: 16),
                            Text(
                              'Add Delivery Address',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.8)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 48),
                  
                  // Extra Options
                  const Text(
                    'More Settings',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1D1D1F),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                          leading: const Icon(Icons.chat_bubble_outline, color: Colors.white),
                          title: const Text('Customer Support', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                          subtitle: const Text('Contact us on WhatsApp', style: TextStyle(color: Color(0xFFA1A1A6), fontSize: 13)),
                          trailing: const Icon(Icons.chevron_right, color: Colors.white54),
                          onTap: () async {
                            final url = Uri.parse('https://wa.me/918886223462?text=Hi Snap-N-Wrap, I need help with my account.');
                            try {
                              await launchUrl(url, mode: LaunchMode.externalApplication);
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open WhatsApp.')));
                              }
                            }
                          },
                        ),
                        const Divider(color: Colors.white10, height: 1),
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                          leading: const Icon(Icons.privacy_tip_outlined, color: Colors.white),
                          title: const Text('Privacy Policy', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                          trailing: const Icon(Icons.chevron_right, color: Colors.white54),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
                            );
                          },
                        ),
                        const Divider(color: Colors.white10, height: 1),
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                          leading: const Icon(Icons.description_outlined, color: Colors.white),
                          title: const Text('Terms & Conditions', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                          trailing: const Icon(Icons.chevron_right, color: Colors.white54),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
