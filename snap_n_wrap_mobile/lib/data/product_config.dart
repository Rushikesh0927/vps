import 'package:flutter/material.dart';

enum OptionLayout {
  pill,         // Regular small outline button
  themeCard,    // Grid card with gradient/image background
  sizeCard,     // Vertical card (image top, info bottom)
}

class ConfigStep {
  final String title;
  final List<ConfigOption> options;
  final OptionLayout layout;

  ConfigStep({
    required this.title, 
    required this.options,
    this.layout = OptionLayout.pill,
  });
}

class ConfigOption {
  final String label;
  final String? subLabel;
  final double priceDelta;
  final String? gradientColors; // Comma separated hex e.g. "0xFF3B82F6,0xFF22D3EE"
  final String? imageUrl;
  final String? emoji;

  ConfigOption({
    required this.label, 
    this.subLabel, 
    required this.priceDelta,
    this.gradientColors,
    this.imageUrl,
    this.emoji,
  });
}

class ProductConfiguration {
  final String categoryId;
  final String categoryName;
  final String description;
  final String heroImage;
  final double basePrice;
  final List<ConfigStep> steps;
  final double Function(List<int> selectedIndices)? priceCalculator;

  ProductConfiguration({
    required this.categoryId,
    required this.categoryName,
    required this.description,
    required this.heroImage,
    required this.basePrice,
    required this.steps,
    this.priceCalculator,
  });
}

final Map<String, ProductConfiguration> productConfigs = {
  'photobooks': ProductConfiguration(
    categoryId: 'photobooks',
    categoryName: 'Photobooks',
    description: 'Preserve memories in premium layflat books.',
    heroImage: 'assets/images/photobook_premium.jpg',
    basePrice: 0,
    steps: [
      ConfigStep(
        title: 'STEP 1 — CHOOSE A THEME',
        layout: OptionLayout.themeCard,
        options: [
          ConfigOption(label: 'Travel', subLabel: 'Adventures & wanderlust', emoji: '✈️', gradientColors: '0xFF3B82F6,0xFF22D3EE', priceDelta: 0),
          ConfigOption(label: 'Memories', subLabel: 'Cherish every moment', emoji: '📸', gradientColors: '0xFFEC4899,0xFFFB7185', priceDelta: 0),
          ConfigOption(label: 'Family', subLabel: 'Your whole world', emoji: '👨‍👩‍👧‍👦', gradientColors: '0xFFF59E0B,0xFFFB923C', priceDelta: 0),
          ConfigOption(label: 'Friends', subLabel: 'Forever bonds', emoji: '👯‍♂️', gradientColors: '0xFF22C55E,0xFF34D399', priceDelta: 0),
          ConfigOption(label: 'Loved Ones', subLabel: 'For those who matter most', emoji: '❤️', gradientColors: '0xFFEF4444,0xFFE11D48', priceDelta: 0),
          ConfigOption(label: 'Simple', subLabel: 'Clean & minimal', emoji: '✨', gradientColors: '0xFF64748B,0xFF4B5563', priceDelta: 0),
          ConfigOption(label: 'Premium', subLabel: 'Luxury feel', emoji: '💎', gradientColors: '0xFF9333EA,0xFF8B5CF6', priceDelta: 0),
          ConfigOption(label: 'Custom Design', subLabel: 'Start from scratch', emoji: '🎨', gradientColors: '0xFFFF5A5F,0xFFFF8C69', priceDelta: 0),
        ],
      ),
      ConfigStep(
        title: 'STEP 2 — CHOOSE SIZE',
        layout: OptionLayout.pill,
        options: [
          ConfigOption(label: 'A4', priceDelta: 0),
          ConfigOption(label: 'A5', priceDelta: 0),
          ConfigOption(label: 'A6', priceDelta: 0),
          ConfigOption(label: 'A7', priceDelta: 0),
        ],
      ),
      ConfigStep(
        title: 'STEP 3 — PAGES',
        layout: OptionLayout.pill,
        options: [
          ConfigOption(label: '20 Pages', subLabel: '40 photos', priceDelta: 0),
          ConfigOption(label: '32 Pages', subLabel: '64 photos', priceDelta: 0),
          ConfigOption(label: '40 Pages', subLabel: '80 photos', priceDelta: 0),
        ],
      ),
      ConfigStep(
        title: 'STEP 4 — CHOOSE FINISH',
        layout: OptionLayout.pill,
        options: [
          ConfigOption(label: 'Glossy', priceDelta: 0),
          ConfigOption(label: 'Matte', priceDelta: 0),
        ],
      ),
    ],
    priceCalculator: (selected) {
      if (selected.length < 4) return 0;
      final size = selected[1];
      final pages = selected[2];
      final finish = selected[3];
      
      final glossyPrices = [
        [799, 1278, 1598], // A4
        [479, 766,  958],  // A5
        [269, 430,  538],  // A6
        [119, 190,  238],  // A7
      ];
      final mattePrices = [
        [999,  1598, 1998], // A4
        [579,  926,  1158], // A5
        [319,  510,  638],  // A6
        [139,  222,  278],  // A7
      ];
      
      if (finish == 0) return glossyPrices[size][pages].toDouble();
      return mattePrices[size][pages].toDouble();
    }
  ),
  'choco_wrappers': ProductConfiguration(
    categoryId: 'choco_wrappers',
    categoryName: 'Choco Wrappers',
    description: 'Personalized wrapping paper for birthdays & anniversaries.',
    heroImage: 'assets/images/WhatsApp_Image_2026-07-30_at_7.05.13_PM.jpeg',
    basePrice: 0,
    steps: [
      ConfigStep(
        title: 'STEP 1 — CHOOSE A THEME',
        layout: OptionLayout.themeCard,
        options: [
          ConfigOption(label: 'Birthday', subLabel: 'Make their day extra special', emoji: '🎂', gradientColors: '0xFFEC4899,0xFFD946EF', priceDelta: 0),
          ConfigOption(label: 'Anniversary', subLabel: 'Celebrate your love', emoji: '💍', gradientColors: '0xFFF43F5E,0xFFEF4444', priceDelta: 0),
          ConfigOption(label: 'Loved Ones', subLabel: 'For those closest to your heart', emoji: '❤️', gradientColors: '0xFFEF4444,0xFFEC4899', priceDelta: 0),
          ConfigOption(label: 'Family', subLabel: 'Family is everything', emoji: '👨‍👩‍👧‍👦', gradientColors: '0xFFF59E0B,0xFFFACC15', priceDelta: 0),
          ConfigOption(label: 'Friends', subLabel: 'Gift your squad', emoji: '👯‍♂️', gradientColors: '0xFF22C55E,0xFF14B8A6', priceDelta: 0),
          ConfigOption(label: 'Congratulations', subLabel: 'Celebrate achievements', emoji: '🎓', gradientColors: '0xFF3B82F6,0xFF6366F1', priceDelta: 0),
          ConfigOption(label: 'Celebration', subLabel: 'Every moment deserves a treat', emoji: '🎉', gradientColors: '0xFFA855F7,0xFF8B5CF6', priceDelta: 0),
          ConfigOption(label: 'Editors\' Choice', subLabel: 'Curated premium designs', emoji: '✨', gradientColors: '0xFFFF5A5F,0xFFFF8C00', priceDelta: 0),
        ],
      ),
      ConfigStep(
        title: 'STEP 2 — CHOOSE SIZE',
        layout: OptionLayout.pill,
        options: [
          ConfigOption(label: 'Small', priceDelta: 15),
          ConfigOption(label: 'Medium', subLabel: '14 × 12 cm', priceDelta: 25),
          ConfigOption(label: 'Large', subLabel: '20 × 14 cm', priceDelta: 50),
          ConfigOption(label: 'Premium', subLabel: '24 × 20 cm', priceDelta: 70),
        ],
      ),
    ],
  ),
  'polaroid_prints': ProductConfiguration(
    categoryId: 'polaroid_prints',
    categoryName: 'Polaroid Prints',
    description: 'Classic white borders for a timeless aesthetic.',
    heroImage: 'https://images.unsplash.com/photo-1511895426328-dc8714191300?q=80&w=2070',
    basePrice: 0,
    steps: [
      ConfigStep(
        title: 'STEP 1 — CHOOSE TYPE',
        layout: OptionLayout.pill,
        options: [
          ConfigOption(label: 'Polaroid Go', priceDelta: 119),
          ConfigOption(label: 'Instax Square', priceDelta: 249),
          ConfigOption(label: 'Polaroid Signature', priceDelta: 349),
        ],
      ),
    ],
  ),
  'photo_prints': ProductConfiguration(
    // We will bypass DynamicConfiguratorScreen for this in products_screen.dart
    categoryId: 'photo_prints',
    categoryName: 'Photo Prints',
    description: 'High quality glossy or matte classic photo prints.',
    heroImage: 'assets/images/photo_prints_premium.jpg',
    basePrice: 0,
    steps: [], 
  ),
  'photo_frames': ProductConfiguration(
    categoryId: 'photo_frames',
    categoryName: 'Photo Frames',
    description: 'Elegant wooden frames in black, white & natural.',
    heroImage: 'assets/images/photo_frame_premium.jpg',
    basePrice: 349,
    steps: [
      ConfigStep(
        title: 'STEP 1 — CHOOSE A THEME',
        layout: OptionLayout.themeCard,
        options: [
          ConfigOption(label: 'Loved Ones', subLabel: 'For the one you love', emoji: '❤️', gradientColors: '0xFFEF4444,0xFFE11D48', priceDelta: 0),
          ConfigOption(label: 'Family', subLabel: 'Cherish your family', emoji: '👨‍👩‍👧‍👦', gradientColors: '0xFFF59E0B,0xFFFB923C', priceDelta: 0),
          ConfigOption(label: 'Friends', subLabel: 'Forever friends', emoji: '👯‍♂️', gradientColors: '0xFF22C55E,0xFF34D399', priceDelta: 0),
          ConfigOption(label: 'Memories', subLabel: 'Precious moments', emoji: '📸', gradientColors: '0xFFEC4899,0xFFFB7185', priceDelta: 0),
          ConfigOption(label: 'Travel', subLabel: 'Adventures on the wall', emoji: '✈️', gradientColors: '0xFF3B82F6,0xFF22D3EE', priceDelta: 0),
          ConfigOption(label: 'Birthday', subLabel: 'Celebrate the day', emoji: '🎂', gradientColors: '0xFFD946EF,0xFFC026D3', priceDelta: 0),
          ConfigOption(label: 'Anniversary', subLabel: 'Love that lasts', emoji: '💍', gradientColors: '0xFFF43F5E,0xFFE11D48', priceDelta: 0),
          ConfigOption(label: 'Simple', subLabel: 'Clean & minimal', emoji: '✨', gradientColors: '0xFF64748B,0xFF4B5563', priceDelta: 0),
          ConfigOption(label: 'Premium', subLabel: 'Luxury feel', emoji: '💎', gradientColors: '0xFF9333EA,0xFF8B5CF6', priceDelta: 0),
          ConfigOption(label: 'Editors\' Choice', subLabel: 'Curated by us', emoji: '🎨', gradientColors: '0xFFFF5A5F,0xFFFF8C69', priceDelta: 0),
        ],
      ),
      ConfigStep(
        title: 'STEP 2 — CHOOSE SIZE & ORIENTATION',
        layout: OptionLayout.pill,
        options: [
          ConfigOption(label: '8 x 12 inch (Portrait)', priceDelta: 0),
          ConfigOption(label: '12 x 8 inch (Landscape)', priceDelta: 0),
        ],
      ),
      ConfigStep(
        title: 'STEP 3 — CHOOSE FRAME COLOR',
        layout: OptionLayout.pill,
        options: [
          ConfigOption(label: 'Black Frame', priceDelta: 0),
          ConfigOption(label: 'White Frame', priceDelta: 0),
          ConfigOption(label: 'Natural Wood', priceDelta: 0),
        ],
      ),
    ],
  ),
  'wall_posters': ProductConfiguration(
    categoryId: 'wall_posters',
    categoryName: 'Wall Posters',
    description: 'Big, bold prints for your walls.',
    heroImage: 'assets/images/wall_poster_premium.jpg',
    basePrice: 0,
    steps: [
      ConfigStep(
        title: 'STEP 1 — CHOOSE SIZE',
        layout: OptionLayout.sizeCard,
        options: [
          ConfigOption(label: 'A3', subLabel: '11.7 × 16.5 inches', priceDelta: 149, imageUrl: 'assets/images/wall_poster_premium.jpg'),
          ConfigOption(label: 'A2', subLabel: '16.5 × 23.4 inches', priceDelta: 249, imageUrl: 'assets/images/wall_poster_premium.jpg'),
          ConfigOption(label: 'A1', subLabel: '23.4 × 33.1 inches', priceDelta: 399, imageUrl: 'assets/images/wall_poster_premium.jpg'),
          ConfigOption(label: '13 × 19"', subLabel: '13 × 19 inches', priceDelta: 199, imageUrl: 'assets/images/wall_poster_premium.jpg'),
        ],
      ),
    ],
  ),
};
