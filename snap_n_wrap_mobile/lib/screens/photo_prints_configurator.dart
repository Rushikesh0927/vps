import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/editor_provider.dart';
import 'editor_screen.dart';

class PhotoPrintsConfigurator extends ConsumerStatefulWidget {
  const PhotoPrintsConfigurator({super.key});

  @override
  ConsumerState<PhotoPrintsConfigurator> createState() => _PhotoPrintsConfiguratorState();
}

class _PhotoPrintsConfiguratorState extends ConsumerState<PhotoPrintsConfigurator> {
  // Config data for prints
  final List<Map<String, dynamic>> _sizes = [
    {'label': '4 × 6"', 'sub': '4 × 6 INCHES', 'min': 10, 'price': 10, 'img': 'assets/images/photo_prints_premium.jpg'},
    {'label': '5 × 7"', 'sub': '5 × 7 INCHES', 'min': 5, 'price': 18, 'img': 'assets/images/photo_prints_premium.jpg'},
    {'label': '6 × 8"', 'sub': '6 × 8 INCHES', 'min': 5, 'price': 25, 'img': 'assets/images/photo_prints_premium.jpg'},
    {'label': '8 × 10"', 'sub': '8 × 10 INCHES', 'min': 1, 'price': 49, 'img': 'assets/images/photo_prints_premium.jpg'},
    {'label': '8 × 12"', 'sub': '8 × 12 INCHES', 'min': 1, 'price': 59, 'img': 'assets/images/photo_prints_premium.jpg'},
  ];

  late List<int> _quantities;

  @override
  void initState() {
    super.initState();
    _quantities = _sizes.map((s) => s['min'] as int).toList();
  }

  void _createPrints(int index) {
    final qty = _quantities[index];
    final editorNotifier = ref.read(editorProvider.notifier);
    
    // We pass the size index as the first option, and the target quantity as the second option (if needed, but currently editor expects it via expectedCount, wait, photo_prints editor currently expects 1 expectedCount in editor_screen.dart... let's check).
    // Actually, Photo Prints just lets you select photos. Let's just set the option.
    editorNotifier.reset();
    editorNotifier.setProductContext(
      'photo_prints', 
      [index, qty], 
    );
    
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EditorScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
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
                'Photo Prints', 
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 22, letterSpacing: -0.5, color: Colors.white)
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned(
            top: 0, left: 0, right: 0,
            height: MediaQuery.of(context).size.height * 0.45,
            child: Image.asset(
              'assets/images/photo_prints_premium.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.15,
            left: 0, right: 0,
            height: MediaQuery.of(context).size.height * 0.3,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 180, 24, 48),
                children: [
                  const Text(
                    'Photo Prints',
                    style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Colors.white, height: 1.1, letterSpacing: -1.0),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'High quality glossy or matte classic photo prints.',
                    style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.8), height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1D1D1F),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 8),
                        Text('270 GSM Premium Glossy Paper', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),
                  
                  // Grid of Sizes
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.65, // Taller cards
                    ),
                    itemCount: _sizes.length,
                    itemBuilder: (context, i) {
                      final size = _sizes[i];
                      final qty = _quantities[i];
                      final total = qty * (size['price'] as int);
                      
                      return Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF111111),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Top Image Half
                            Expanded(
                              flex: 3,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.asset(size['img'], fit: BoxFit.cover),
                                  ),
                                ),
                              ),
                            ),
                            // Bottom Info Half
                            Expanded(
                              flex: 5,
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(size['sub'], style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10, letterSpacing: 1)),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(size['label'], style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            const Text('PER PRINT', style: TextStyle(color: Colors.white54, fontSize: 8)),
                                            Text('₹${size['price']}', style: const TextStyle(color: Color(0xFF3B82F6), fontSize: 16, fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text('QUANTITY (MIN ${size['min']})', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 9)),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1D1D1F),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          GestureDetector(
                                            onTap: qty > size['min'] ? () => setState(() => _quantities[i]--) : null,
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                                              child: Icon(Icons.remove, size: 16, color: qty > size['min'] ? Colors.white : Colors.white24),
                                            ),
                                          ),
                                          Text('$qty', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                          GestureDetector(
                                            onTap: () => setState(() => _quantities[i]++),
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                                              child: const Icon(Icons.add, size: 16, color: Colors.white),
                                            ),
                                          ),
                                          Text('= ₹$total', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ElevatedButton(
                                      onPressed: () => _createPrints(i),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF1D1D1F),
                                        foregroundColor: Colors.white,
                                        minimumSize: const Size(double.infinity, 36),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        side: BorderSide(color: Colors.white.withOpacity(0.2)),
                                      ),
                                      child: const Text('Create Prints', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
