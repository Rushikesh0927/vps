import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/user_provider.dart';

import 'products_screen.dart';
import '../widgets/stacked_gallery.dart';
import '../data/product_config.dart';
import 'dynamic_configurator_screen.dart';
import 'cart_screen.dart';
import 'profile_screen.dart';
import 'history_screen.dart';

// Mock Gallery Data (similar to web)
final List<GalleryItem> mockGallery = [
  GalleryItem(id: "1", src: "assets/images/WhatsApp_Image_2026-07-30_at_7.05.14_PM__1_.jpeg", alt: "Wedding Anniversary custom wrapper — front", label: "Anniversary Wrapper", tag: "Wedding"),
  GalleryItem(id: "2", src: "assets/images/WhatsApp_Image_2026-07-30_at_7.05.13_PM.jpeg", alt: "Happy Birthday blue-theme custom wrapper", label: "Birthday · Blue", tag: "Birthday"),
  GalleryItem(id: "3", src: "assets/images/WhatsApp_Image_2026-07-30_at_7.05.13_PM__1_.jpeg", alt: "Kids birthday wrapper with cute animals", label: "Kids Edition", tag: "Birthday"),
  GalleryItem(id: "4", src: "assets/images/WhatsApp_Image_2026-07-30_at_7.05.14_PM.jpeg", alt: "Birthday wrappers stacked side view", label: "Stacked Prints", tag: "Batch"),
  GalleryItem(id: "5", src: "assets/images/WhatsApp_Image_2026-07-30_at_7.05.15_PM.jpeg", alt: "Anniversary wrapper styled on leather book", label: "Anniversary · Styled", tag: "Wedding"),
];

class HomeDashboard extends ConsumerStatefulWidget {
  const HomeDashboard({super.key});

  @override
  ConsumerState<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends ConsumerState<HomeDashboard> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userProvider);
    final userNotifier = ref.read(userProvider.notifier);
    final userName = userState.user?.name != null && userState.user!.name.isNotEmpty 
        ? userState.user!.name.split(' ')[0] 
        : 'Guest';

    // The current home view
    final homeView = Scaffold(
      backgroundColor: const Color(0xFF000000), // Apple Dark Mode pure black
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: RepaintBoundary(
          child: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: AppBar(
              backgroundColor: const Color(0xFF1D1D1F).withOpacity(0.5),
              elevation: 0,
              title: const Text(
                'Snap-N-Wrap', 
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 22, letterSpacing: -0.5, color: Colors.white)
              ),
            ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Subtle Ambient Glows (Optimized with RadialGradient)
          Positioned(
            top: -150,
            right: -50,
            child: Container(
              width: 350,
              height: 350,
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
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x330A84FF), Colors.transparent],
                  stops: [0.0, 1.0],
                ),
              ),
            ),
          ),
          
          SafeArea(
            bottom: false,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              children: [
                // Announcement Bar (Scrolling effect using SingleChildScrollView and repeat)
                Container(
                  width: double.infinity,
                  height: 40,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF5A5F).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFF5A5F).withOpacity(0.3)),
                  ),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 10, // Loop a few times for the effect
                    itemBuilder: (context, index) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Center(
                          child: Text(
                            '🎉 GRAND OPENING OFFER - 50% OFF FIRST 100 ORDERS!',
                            style: TextStyle(
                              color: Color(0xFFFF5A5F),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      );
                    }
                  ),
                ),

                // Greeting Section
                Text(
                  'Good Evening,',
                  style: TextStyle(fontSize: 18, color: const Color(0xFFA1A1A6), fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  userName,
                  style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -1.5),
                ),
                const SizedBox(height: 32),

                // Hero Top Section
                const Text(
                  'Your memories,\nbeautifully printed',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, height: 1.1, letterSpacing: -1.0),
                ),
                const SizedBox(height: 24),
                
                // Hero Action Card (Glassmorphism)
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProductsScreen()),
                    );
                  },
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFFF5A5F), Color(0xFFE84F54)],
                      ),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF5A5F).withOpacity(0.3),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                        )
                      ],
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -30,
                          bottom: -30,
                          child: Icon(Icons.style, size: 180, color: Colors.white.withOpacity(0.2)),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(28.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(Icons.add_photo_alternate, color: Colors.white, size: 28),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Start a New Project',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Explore our premium catalog of photobooks, frames & more',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Our Products Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Our Products',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -0.5),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ProductsScreen()),
                        );
                      },
                      child: const Text(
                        'Explore All',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFFFF5A5F)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Vertical Product List matching Web App
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DynamicConfiguratorScreen(config: productConfigs['photobooks']!))),
                  child: _buildProductCard('Photobooks', 'Preserve memories in premium layflat books.', Icons.menu_book, const Color(0xFF1D1D1F)),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DynamicConfiguratorScreen(config: productConfigs['choco_wrappers']!))),
                  child: _buildProductCard('Choco Wrappers', 'Personalized wrapping paper for birthdays & anniversaries.', Icons.card_giftcard, const Color(0xFF1D1D1F)),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DynamicConfiguratorScreen(config: productConfigs['polaroid_prints']!))),
                  child: _buildProductCard('Polaroid Prints', 'Classic white borders for a timeless aesthetic.', Icons.photo_library_outlined, const Color(0xFF1D1D1F)),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DynamicConfiguratorScreen(config: productConfigs['photo_prints']!))),
                  child: _buildProductCard('Photo Prints', 'High quality glossy or matte classic photo prints.', Icons.image_outlined, const Color(0xFF1D1D1F)),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DynamicConfiguratorScreen(config: productConfigs['photo_frames']!))),
                  child: _buildProductCard('Photo Frames', 'Elegant wooden frames in black, white & natural.', Icons.crop_square_outlined, const Color(0xFF1D1D1F)),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DynamicConfiguratorScreen(config: productConfigs['wall_posters']!))),
                  child: _buildProductCard('Wall Posters', 'Large format museum-quality posters.', Icons.wallpaper, const Color(0xFF1D1D1F)),
                ),
                
                const SizedBox(height: 40),
                
                // Our Work / Gallery Section
                const Text(
                  'Our Work',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFFF5A5F), letterSpacing: 2.0),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Real products,\nreal prints',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, height: 1.1, letterSpacing: -1.0),
                ),
                const SizedBox(height: 24),
                
                StackedGallery(
                  gallery: mockGallery,
                  onCardTap: (idx) {
                    showGeneralDialog(
                      context: context,
                      barrierColor: Colors.black.withOpacity(0.9),
                      barrierDismissible: true,
                      barrierLabel: "Lightbox",
                      pageBuilder: (ctx, anim1, anim2) {
                        return Scaffold(
                          backgroundColor: Colors.transparent,
                          body: Stack(
                            fit: StackFit.expand,
                            children: [
                              InteractiveViewer(
                                panEnabled: true,
                                minScale: 1,
                                maxScale: 4,
                                child: CachedNetworkImage(
                                  imageUrl: mockGallery[idx].src,
                                  fit: BoxFit.contain,
                                  placeholder: (context, url) => const Center(child: CircularProgressIndicator(color: Color(0xFFFF5A5F))),
                                  errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.white),
                                ),
                              ),
                              Positioned(
                                top: 50,
                                right: 20,
                                child: IconButton(
                                  icon: const Icon(Icons.close, color: Colors.white, size: 32),
                                  onPressed: () => Navigator.pop(ctx),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),

                const SizedBox(height: 100), // Bottom padding
              ],
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          homeView,
          CartScreen(
            onContinueShopping: () {
              setState(() => _currentIndex = 0);
            },
          ),
          const HistoryScreen(),
          const ProfileScreen(),
        ],
      ),
      extendBody: true,
      bottomNavigationBar: Container(
        margin: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
        child: RepaintBoundary(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFF1D1D1F).withOpacity(0.7),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavItem(Icons.home_filled, 'Home', 0),
                    _buildNavItem(Icons.shopping_bag_outlined, 'Cart', 1),
                    _buildNavItem(Icons.history, 'My Orders', 2),
                    _buildNavItem(Icons.person_outline, 'Profile', 3),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(String title, String subtitle, IconData icon, Color bgColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: const Color(0xFFFF5A5F), size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 13, color: Color(0xFFA1A1A6)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_ios, color: Color(0xFFA1A1A6), size: 16),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isActive ? const Color(0xFFFF5A5F) : const Color(0xFFA1A1A6), size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              color: isActive ? const Color(0xFFFF5A5F) : const Color(0xFFA1A1A6),
            ),
          ),
        ],
      ),
    );
  }
}
