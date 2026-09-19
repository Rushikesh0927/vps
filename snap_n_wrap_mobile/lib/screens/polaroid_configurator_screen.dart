import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/user_provider.dart';
import 'checkout_screen.dart';
import 'edit_profile_screen.dart';
import 'editor_screen.dart';
import '../providers/editor_provider.dart';

class PolaroidSize {
  final String id;
  final String name;
  final String tagline;
  final List<Map<String, dynamic>> pricing;

  PolaroidSize({required this.id, required this.name, required this.tagline, required this.pricing});
}

final polaroidSizes = [
  PolaroidSize(
    id: "polaroid-go",
    name: "Polaroid Go",
    tagline: "Compact Polaroid-style prints",
    pricing: [
      {"qty": 15, "price": 119},
      {"qty": 30, "price": 229},
      {"qty": 45, "price": 339},
      {"qty": 60, "price": 399},
    ]
  ),
  PolaroidSize(
    id: "instax-square",
    name: "Instax Square",
    tagline: "Square-format instant-style prints",
    pricing: [
      {"qty": 24, "price": 249},
      {"qty": 32, "price": 319},
      {"qty": 40, "price": 369},
      {"qty": 64, "price": 549},
    ]
  ),
  PolaroidSize(
    id: "polaroid-signature",
    name: "Polaroid Signature",
    tagline: "Premium large format prints",
    pricing: [
      {"qty": 24, "price": 349},
      {"qty": 32, "price": 449},
      {"qty": 40, "price": 599},
      {"qty": 64, "price": 679},
    ]
  ),
];

class PolaroidConfiguratorScreen extends ConsumerStatefulWidget {
  const PolaroidConfiguratorScreen({super.key});

  @override
  ConsumerState<PolaroidConfiguratorScreen> createState() => _PolaroidConfiguratorScreenState();
}

class _PolaroidConfiguratorScreenState extends ConsumerState<PolaroidConfiguratorScreen> {
  String? selectedSizeId;

  @override
  Widget build(BuildContext context) {
    final selectedSize = selectedSizeId != null 
        ? polaroidSizes.firstWhere((s) => s.id == selectedSizeId) 
        : null;

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (selectedSizeId != null) {
              setState(() => selectedSizeId = null);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text('Polaroid Prints', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (selectedSizeId == null) ...[
                Row(
                  children: [
                    Container(
                      width: 28, height: 28,
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: const Text('1', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 12),
                    const Text('Choose Polaroid Type', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
                  ],
                ),
                const SizedBox(height: 24),
                ...polaroidSizes.map((size) {
                  return GestureDetector(
                    onTap: () => setState(() => selectedSizeId = size.id),
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1D1D1F),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(size.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(height: 4),
                          Text(size.tagline, style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.5))),
                        ],
                      ),
                    ),
                  );
                }),
              ] else ...[
                Row(
                  children: [
                    Container(
                      width: 28, height: 28,
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: const Text('2', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 12),
                    Text('Choose Package for ${selectedSize!.name}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
                  ],
                ),
                const SizedBox(height: 24),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.85,
                  children: selectedSize.pricing.map((tier) {
                    return GestureDetector(
                      onTap: () {
                        final editorNotifier = ref.read(editorProvider.notifier);
                        editorNotifier.reset();
                        // Store the selected tier in product context
                        editorNotifier.setProductContext(
                          'polaroid_prints',
                          [polaroidSizes.indexOf(selectedSize), selectedSize.pricing.indexOf(tier)]
                        );
                        
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const EditorScreen()));
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1D1D1F),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${tier["qty"]}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
                                Text('Prints', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.5))),
                              ],
                            ),
                            Text('₹${tier["price"]}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFFFF5A5F))),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
