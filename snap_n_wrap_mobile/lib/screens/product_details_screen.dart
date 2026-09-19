import 'dart:ui';
import 'package:flutter/material.dart';

class ProductDetailsScreen extends StatelessWidget {
  final String title;
  final String description;
  final String price;
  final IconData icon;

  const ProductDetailsScreen({
    super.key,
    required this.title,
    required this.description,
    required this.price,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: AppBar(
              backgroundColor: const Color(0xFF1D1D1F).withOpacity(0.5),
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
              title: Text(
                title, 
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 22, letterSpacing: -0.5, color: Colors.white)
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background subtle ambient light
          Positioned(
            top: 0,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: const BoxDecoration(
                color: Color(0x20FF5A5F),
                shape: BoxShape.circle,
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                child: Container(),
              ),
            ),
          ),
          
          Column(
            children: [
              // Image / Icon Hero Section
              Expanded(
                flex: 5,
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFF111111),
                  ),
                  child: SafeArea(
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(48),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: Icon(icon, size: 120, color: const Color(0xFFFF5A5F)),
                      ),
                    ),
                  ),
                ),
              ),
              
              // Bottom Sheet content
              Expanded(
                flex: 4,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1D1D1F),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 30,
                        offset: const Offset(0, -10),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, height: 1.1, letterSpacing: -1.0),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF5A5F).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              price,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFFF5A5F)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        description,
                        style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.7), height: 1.5),
                      ),
                      const Spacer(),
                      
                      // Action Button
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton(
                          onPressed: () {
                            // TODO: Push to specific configurator based on product type
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Configurator for $title coming soon!')),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF5A5F),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Configure & Add',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20), // Bottom safe area padding
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
