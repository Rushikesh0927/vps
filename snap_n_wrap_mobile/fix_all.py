def run():
    # Fix 1: Remove "STEP X" duplication from product_config.dart
    config_content = """import 'package:flutter/material.dart';

class ConfigStep {
  final String title;
  final List<ConfigOption> options;
  final List<ConfigOption> Function(List<int?> selected)? dynamicOptions;

  ConfigStep({required this.title, this.options = const [], this.dynamicOptions});
}

class ConfigOption {
  final String label;
  final String? subLabel;
  final double priceDelta;

  ConfigOption({required this.label, this.subLabel, required this.priceDelta});
}

class ProductConfiguration {
  final String categoryId;
  final String categoryName;
  final String description;
  final String heroImage;
  final double basePrice;
  final List<ConfigStep> steps;
  final double Function(List<int?> selectedIndices)? priceCalculator;

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
        title: 'CHOOSE SIZE',
        options: [
          ConfigOption(label: 'A4', priceDelta: 0),
          ConfigOption(label: 'A5', priceDelta: 0),
          ConfigOption(label: 'A6', priceDelta: 0),
          ConfigOption(label: 'A7', priceDelta: 0),
        ],
      ),
      ConfigStep(
        title: 'CHOOSE FINISH',
        options: [
          ConfigOption(label: 'Glossy', priceDelta: 0),
          ConfigOption(label: 'Matte', priceDelta: 0),
        ],
      ),
      ConfigStep(
        title: 'PAGES',
        options: [
          ConfigOption(label: '20 Pages', subLabel: '40 photos', priceDelta: 0),
          ConfigOption(label: '32 Pages', subLabel: '64 photos', priceDelta: 0),
          ConfigOption(label: '40 Pages', subLabel: '80 photos', priceDelta: 0),
        ],
      ),
    ],
    priceCalculator: (selected) {
      final size = selected[0] ?? 0;
      final finish = selected[1] ?? 0;
      final pages = selected[2] ?? 0;
      
      final glossyPrices = [
        [799, 1278, 1598],
        [479, 766, 958],
        [269, 430, 538],
        [199, 318, 398],
      ];
      
      final mattePrices = [
        [999, 1598, 1998],
        [599, 958, 1198],
        [339, 542, 678],
        [249, 398, 498],
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
        title: 'CHOOSE BRAND',
        options: [
          ConfigOption(label: 'Dairy Milk Silk', priceDelta: 25),
          ConfigOption(label: 'Dairy Milk', priceDelta: 18),
          ConfigOption(label: 'KitKat 2-Finger', priceDelta: 15),
          ConfigOption(label: '5 Star', priceDelta: 18),
          ConfigOption(label: 'Munch', priceDelta: 15),
          ConfigOption(label: 'Perk', priceDelta: 15),
        ],
      ),
      ConfigStep(
        title: 'THEME',
        options: [
          ConfigOption(label: 'Birthday', priceDelta: 0),
          ConfigOption(label: 'Anniversary', priceDelta: 0),
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
        title: 'CHOOSE TYPE',
        options: [
          ConfigOption(label: 'Polaroid Go', priceDelta: 0),
          ConfigOption(label: 'Instax Square', priceDelta: 0),
          ConfigOption(label: 'Polaroid Signature', priceDelta: 0),
        ],
      ),
      ConfigStep(
        title: 'CHOOSE QUANTITY',
        dynamicOptions: (selected) {
          final type = selected.isNotEmpty ? (selected[0] ?? 0) : 0;
          if (type == 0) {
            return [
              ConfigOption(label: '15 Prints', priceDelta: 119),
              ConfigOption(label: '30 Prints', priceDelta: 229),
              ConfigOption(label: '45 Prints', priceDelta: 339),
              ConfigOption(label: '60 Prints', priceDelta: 399),
            ];
          } else if (type == 1) {
            return [
              ConfigOption(label: '24 Prints', priceDelta: 249),
              ConfigOption(label: '32 Prints', priceDelta: 319),
              ConfigOption(label: '40 Prints', priceDelta: 369),
              ConfigOption(label: '64 Prints', priceDelta: 549),
            ];
          } else {
            return [
              ConfigOption(label: '15 Prints', priceDelta: 349),
              ConfigOption(label: '30 Prints', priceDelta: 649),
              ConfigOption(label: '45 Prints', priceDelta: 849),
              ConfigOption(label: '60 Prints', priceDelta: 1099),
            ];
          }
        },
      ),
    ],
  ),
  'photo_prints': ProductConfiguration(
    categoryId: 'photo_prints',
    categoryName: 'Photo Prints',
    description: 'High quality glossy or matte classic photo prints.',
    heroImage: 'assets/images/photo_prints_premium.jpg',
    basePrice: 0,
    steps: [
      ConfigStep(
        title: 'CHOOSE SIZE & QUANTITY',
        options: [
          ConfigOption(label: '4x6 (Min 10)', subLabel: '₹10 / print', priceDelta: 100),
          ConfigOption(label: '5x7 (Min 5)', subLabel: '₹18 / print', priceDelta: 90),
          ConfigOption(label: '6x8 (Min 5)', subLabel: '₹25 / print', priceDelta: 125),
          ConfigOption(label: '8x10', subLabel: '₹49 / print', priceDelta: 49),
          ConfigOption(label: '8x12', subLabel: '₹59 / print', priceDelta: 59),
        ],
      ),
      ConfigStep(
        title: 'CHOOSE FINISH',
        options: [
          ConfigOption(label: 'Glossy', priceDelta: 0),
          ConfigOption(label: 'Matte', priceDelta: 0),
        ],
      ),
    ],
  ),
  'photo_frames': ProductConfiguration(
    categoryId: 'photo_frames',
    categoryName: 'Photo Frames',
    description: 'Elegant wooden frames in black, white & natural.',
    heroImage: 'assets/images/photo_frame_premium.jpg',
    basePrice: 349,
    steps: [
      ConfigStep(
        title: 'CHOOSE SIZE & ORIENTATION',
        options: [
          ConfigOption(label: '8 x 12 inch (Portrait)', priceDelta: 0),
          ConfigOption(label: '12 x 8 inch (Landscape)', priceDelta: 0),
        ],
      ),
      ConfigStep(
        title: 'CHOOSE FRAME COLOR',
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
        title: 'CHOOSE SIZE',
        options: [
          ConfigOption(label: 'A3', subLabel: '11.7 × 16.5 inches', priceDelta: 149),
          ConfigOption(label: 'A2', subLabel: '16.5 × 23.4 inches', priceDelta: 249),
          ConfigOption(label: 'A1', subLabel: '23.4 × 33.1 inches', priceDelta: 399),
          ConfigOption(label: '13 × 19 inches', priceDelta: 199),
        ],
      ),
    ],
  ),
};
"""
    open('lib/data/product_config.dart', 'w', encoding='utf-8').write(config_content)
    
    # Fix 2: Remove progressive disclosure entirely from UI, show all steps at once!
    ui_c = open('lib/screens/dynamic_configurator_screen.dart', 'r', encoding='utf-8').read()
    
    # Remove _maxVisibleStep logic
    ui_c = ui_c.replace("if (stepIndex > _maxVisibleStep) return const SizedBox.shrink();", "")
    ui_c = ui_c.replace("if (_maxVisibleStep < widget.config.steps.length - 1 && _maxVisibleStep == stepIndex) {\n                                            _maxVisibleStep++;\n                                          }", "")
    ui_c = ui_c.replace("if (_maxVisibleStep >= widget.config.steps.length) {\n        _maxVisibleStep = widget.config.steps.length - 1;\n      }", "")
    ui_c = ui_c.replace("_maxVisibleStep = key + 1;", "")
    ui_c = ui_c.replace("int _maxVisibleStep = 0;", "")
    
    # Fix 3: Also update priceCalculator signature in DynamicConfiguratorScreen to pass List<int?>
    ui_c = ui_c.replace("List<int> calcOptions = _selectedOptions.map((e) => e ?? 0).toList();", "List<int?> calcOptions = _selectedOptions;")
    ui_c = ui_c.replace("price = widget.config.priceCalculator!(calcOptions);", "price = widget.config.priceCalculator!(_selectedOptions);")

    open('lib/screens/dynamic_configurator_screen.dart', 'w', encoding='utf-8').write(ui_c)

run()
