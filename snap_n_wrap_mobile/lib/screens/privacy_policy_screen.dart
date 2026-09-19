import 'package:flutter/material.dart';
import 'dart:ui';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: RepaintBoundary(
          child: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: AppBar(
                backgroundColor: const Color(0xFF1D1D1F).withOpacity(0.5),
                elevation: 0,
                iconTheme: const IconThemeData(color: Colors.white),
                title: const Text(
                  'Privacy & Terms',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Terms & Conditions',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 16),
              Text(
                'Welcome to Snap-N-Wrap! By using our app, you agree to these terms. All photo gifts and prints ordered through the app are processed securely. Please ensure that you have the right to use and print any images you upload.',
                style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8), height: 1.5),
              ),
              const SizedBox(height: 32),
              const Text(
                'Privacy Policy',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 16),
              Text(
                'Your privacy is our priority. Uploaded photos are securely transferred to our isolated Google Drive storage. Upon the completion and delivery of your order, the link shared with you will be permanently disabled, and your photos will be securely archived.\n\nArchived photos are automatically and permanently deleted from our systems 15 days after the order is marked as completed.',
                style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8), height: 1.5),
              ),
              const SizedBox(height: 32),
              const Text(
                'Refunds & Cancellations',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 16),
              Text(
                'As our products are highly customized, we do not accept cancellations once the printing process has begun. If your product arrives damaged or with a manufacturing defect, please reach out to our Customer Support via WhatsApp within 48 hours for a replacement.',
                style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8), height: 1.5),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}
