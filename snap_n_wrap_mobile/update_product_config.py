def run():
    c = open('lib/data/product_config.dart', 'r', encoding='utf-8').read()
    
    # 1. Update ConfigStep class
    old_step = "class ConfigStep {\n  final String title;\n  final List<ConfigOption> options;\n\n  ConfigStep({required this.title, required this.options});\n}"
    new_step = "class ConfigStep {\n  final String title;\n  final List<ConfigOption> options;\n  final List<ConfigOption> Function(List<int?> selected)? dynamicOptions;\n\n  ConfigStep({required this.title, this.options = const [], this.dynamicOptions});\n}"
    c = c.replace(old_step, new_step)
    
    # 2. Update Polaroid Prints logic
    old_polaroid = """  'polaroid_prints': ProductConfiguration(
    categoryId: 'polaroid_prints',
    categoryName: 'Polaroid Prints',
    description: 'Classic white borders for a timeless aesthetic.',
    heroImage: 'https://images.unsplash.com/photo-1511895426328-dc8714191300?q=80&w=2070',
    basePrice: 0,
    steps: [
      ConfigStep(
        title: 'STEP 1 â€” CHOOSE TYPE',
        options: [
          ConfigOption(label: 'Polaroid Go', priceDelta: 119),
          ConfigOption(label: 'Instax Square', priceDelta: 249),
          ConfigOption(label: 'Polaroid Signature', priceDelta: 349),
        ],
      ),
    ],
  ),"""
  
    new_polaroid = """  'polaroid_prints': ProductConfiguration(
    categoryId: 'polaroid_prints',
    categoryName: 'Polaroid Prints',
    description: 'Classic white borders for a timeless aesthetic.',
    heroImage: 'https://images.unsplash.com/photo-1511895426328-dc8714191300?q=80&w=2070',
    basePrice: 0,
    steps: [
      ConfigStep(
        title: 'STEP 1 — CHOOSE TYPE',
        options: [
          ConfigOption(label: 'Polaroid Go', priceDelta: 0),
          ConfigOption(label: 'Instax Square', priceDelta: 0),
          ConfigOption(label: 'Polaroid Signature', priceDelta: 0),
        ],
      ),
      ConfigStep(
        title: 'STEP 2 — CHOOSE QUANTITY',
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
  ),"""
    c = c.replace(old_polaroid, new_polaroid)
    
    # 3. Update Photo Prints logic
    old_prints = """  'photo_prints': ProductConfiguration(
    categoryId: 'photo_prints',
    categoryName: 'Photo Prints',
    description: 'High quality glossy or matte classic photo prints.',
    heroImage: 'assets/images/photo_prints_premium.jpg',
    basePrice: 0,
    steps: [
      ConfigStep(
        title: 'STEP 1 â€” CHOOSE SIZE',
        options: [
          ConfigOption(label: '4x6 inches', priceDelta: 10),
          ConfigOption(label: '5x7 inches', priceDelta: 18),
          ConfigOption(label: '6x8 inches', priceDelta: 25),
          ConfigOption(label: '8x10 inches', priceDelta: 49),
          ConfigOption(label: '8x12 inches', priceDelta: 59),
        ],
      ),
      ConfigStep(
        title: 'STEP 2 â€” CHOOSE FINISH',
        options: [
          ConfigOption(label: 'Glossy', priceDelta: 0),
          ConfigOption(label: 'Matte', priceDelta: 5),
        ],
      ),
    ],
  ),"""
  
    new_prints = """  'photo_prints': ProductConfiguration(
    categoryId: 'photo_prints',
    categoryName: 'Photo Prints',
    description: 'High quality glossy or matte classic photo prints.',
    heroImage: 'assets/images/photo_prints_premium.jpg',
    basePrice: 0,
    steps: [
      ConfigStep(
        title: 'STEP 1 — CHOOSE SIZE & QUANTITY',
        options: [
          ConfigOption(label: '4x6 (Min 10)', subLabel: '₹10 / print', priceDelta: 100),
          ConfigOption(label: '5x7 (Min 5)', subLabel: '₹18 / print', priceDelta: 90),
          ConfigOption(label: '6x8 (Min 5)', subLabel: '₹25 / print', priceDelta: 125),
          ConfigOption(label: '8x10', subLabel: '₹49 / print', priceDelta: 49),
          ConfigOption(label: '8x12', subLabel: '₹59 / print', priceDelta: 59),
        ],
      ),
      ConfigStep(
        title: 'STEP 2 — CHOOSE FINISH',
        options: [
          ConfigOption(label: 'Glossy', priceDelta: 0),
          ConfigOption(label: 'Matte', priceDelta: 0),
        ],
      ),
    ],
  ),"""
    c = c.replace(old_prints, new_prints)
    
    open('lib/data/product_config.dart', 'w', encoding='utf-8').write(c)

run()
