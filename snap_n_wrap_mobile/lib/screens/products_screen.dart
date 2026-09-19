import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/product_config.dart';
import 'dynamic_configurator_screen.dart';
import 'polaroid_configurator_screen.dart';
class ProductsScreen extends ConsumerWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000), // Apple Dark Mode pure black
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
              title: const Text(
                'Our Products', 
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 22, letterSpacing: -0.5, color: Colors.white)
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Subtle Ambient Glows
          Positioned(
            top: 100,
            left: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: const BoxDecoration(
                color: Color(0x15FF5A5F),
                shape: BoxShape.circle,
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                child: Container(),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: const BoxDecoration(
                color: Color(0x150A84FF),
                shape: BoxShape.circle,
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                child: Container(),
              ),
            ),
          ),
          
          SafeArea(
            bottom: false,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              children: [
                const Text(
                  'Explore our catalog',
                  style: TextStyle(fontSize: 16, color: Color(0xFFA1A1A6), fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Premium Prints\n& Gifts',
                  style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Colors.white, height: 1.1, letterSpacing: -1.5),
                ),
                const SizedBox(height: 40),

                // Category: Photobooks
                _buildCategoryHeader('Photobooks', Icons.menu_book_outlined),
                const SizedBox(height: 16),
                _buildProductItem(context, 'A4 Photobook', 'Glossy / 20 Pages', '₹799', Icons.menu_book_outlined, 'photobooks', {0: 0}),
                _buildProductItem(context, 'A5 Photobook', 'Glossy / 20 Pages', '₹479', Icons.menu_book_outlined, 'photobooks', {0: 1}),
                _buildProductItem(context, 'A6 Mini Photobook', 'Glossy / 20 Pages', '₹269', Icons.menu_book_outlined, 'photobooks', {0: 2}),
                
                const SizedBox(height: 40),

                // Category: Choco Wrappers
                _buildCategoryHeader('Choco Wrappers', Icons.card_giftcard_outlined),
                const SizedBox(height: 16),
                _buildProductItem(context, 'Dairy Milk Silk', '60g / 5.5" x 5.5"', '₹25 / piece', Icons.card_giftcard_outlined, 'choco_wrappers', {0: 0}),
                _buildProductItem(context, 'Dairy Milk Regular', '40g / 4" x 4"', '₹18 / piece', Icons.card_giftcard_outlined, 'choco_wrappers', {0: 1}),
                _buildProductItem(context, 'KitKat 2-Finger', '20g / 3.5" x 3"', '₹15 / piece', Icons.card_giftcard_outlined, 'choco_wrappers', {0: 2}),
                _buildProductItem(context, '5 Star', '40g / 4" x 3.5"', '₹18 / piece', Icons.card_giftcard_outlined, 'choco_wrappers', {0: 3}),
                _buildProductItem(context, 'Munch', '35g / 3.5" x 3.5"', '₹15 / piece', Icons.card_giftcard_outlined, 'choco_wrappers', {0: 4}),
                _buildProductItem(context, 'Perk', '35g / 3.5" x 3"', '₹15 / piece', Icons.card_giftcard_outlined, 'choco_wrappers', {0: 5}),
                
                const SizedBox(height: 40),

                // Category: Polaroid Prints
                _buildCategoryHeader('Polaroid Prints', Icons.photo_library_outlined),
                const SizedBox(height: 16),
                _buildProductItem(context, 'Polaroid Go', '15 Prints', '₹149', Icons.photo_library_outlined, 'polaroid_prints', {0: 0}),
                _buildProductItem(context, 'Instax Mini', '20 Prints', '₹199', Icons.photo_library_outlined, 'polaroid_prints', {0: 1}),
                _buildProductItem(context, 'Instax Square', '24 Prints', '₹269', Icons.photo_library_outlined, 'polaroid_prints', {0: 2}),
                _buildProductItem(context, 'Polaroid i-Type', '16 Prints', '₹209', Icons.photo_library_outlined, 'polaroid_prints', {0: 3}),

                const SizedBox(height: 40),
                
                // Category: Photo Prints
                _buildCategoryHeader('Photo Prints', Icons.image_outlined),
                const SizedBox(height: 16),
                _buildProductItem(context, '4x6 inches', 'Classic print size', '₹10 / piece', Icons.image_outlined, 'photo_prints', {0: 0}),
                _buildProductItem(context, '5x7 inches', 'Standard desk size', '₹18 / piece', Icons.image_outlined, 'photo_prints', {0: 1}),
                _buildProductItem(context, '6x8 inches', 'Medium print', '₹25 / piece', Icons.image_outlined, 'photo_prints', {0: 2}),
                _buildProductItem(context, '8x10 inches', 'Large portrait size', '₹49 / piece', Icons.image_outlined, 'photo_prints', {0: 3}),
                _buildProductItem(context, '8x12 inches', 'Premium large prints', '₹59 / piece', Icons.image_outlined, 'photo_prints', {0: 4}),

                const SizedBox(height: 40),
                
                // Category: Photo Frames
                _buildCategoryHeader('Photo Frames', Icons.crop_square_outlined),
                const SizedBox(height: 16),
                _buildProductItem(context, '8x12 inch', 'Available in portrait or landscape', '₹349', Icons.crop_square_outlined, 'photo_frames', {0: 0}),

                const SizedBox(height: 40),
                
                // Category: Wall Posters
                _buildCategoryHeader('Wall Posters', Icons.wallpaper),
                const SizedBox(height: 16),
                _buildProductItem(context, 'A3 Poster', '11.7 x 16.5 inches', '₹149', Icons.wallpaper, 'wall_posters', {0: 0}),
                _buildProductItem(context, 'A2 Poster', '16.5 x 23.4 inches', '₹249', Icons.wallpaper, 'wall_posters', {0: 1}),
                _buildProductItem(context, 'A1 Poster', '23.4 x 33.1 inches', '₹399', Icons.wallpaper, 'wall_posters', {0: 2}),
                _buildProductItem(context, '13 x 19"', '13 x 19 inches', '₹199', Icons.wallpaper, 'wall_posters', {0: 3}),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFFF5A5F), size: 24),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.5),
        ),
      ],
    );
  }

  Widget _buildProductItem(BuildContext context, String name, String desc, String price, IconData icon, String categoryKey, [Map<int, int>? initialSelection]) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DynamicConfiguratorScreen(
              config: productConfigs[categoryKey]!,
              initialSelection: initialSelection,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1D1D1F),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(desc, style: const TextStyle(fontSize: 13, color: Color(0xFFA1A1A6))),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(price, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFFF5A5F))),
            ),
          ],
        ),
      ),
    );
  }
}
