import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/product_config.dart';
import '../providers/user_provider.dart';
import 'checkout_screen.dart';
import 'edit_profile_screen.dart';
import 'editor_screen.dart';
import '../providers/editor_provider.dart';

class DynamicConfiguratorScreen extends ConsumerStatefulWidget {
  final ProductConfiguration config;
  final Map<int, int>? initialSelection;

  const DynamicConfiguratorScreen({
    super.key,
    required this.config,
    this.initialSelection,
  });

  @override
  ConsumerState<DynamicConfiguratorScreen> createState() => _DynamicConfiguratorScreenState();
}

class _DynamicConfiguratorScreenState extends ConsumerState<DynamicConfiguratorScreen> {
  // Store selected option index for each step
  late List<int> _selectedOptions;

  @override
  void initState() {
    super.initState();
    // Default to the first option for all steps
    _selectedOptions = List.generate(widget.config.steps.length, (index) => 0);
    if (widget.initialSelection != null) {
      widget.initialSelection!.forEach((stepIndex, optionIndex) {
        if (stepIndex >= 0 &&
            stepIndex < _selectedOptions.length &&
            optionIndex >= 0 &&
            optionIndex < widget.config.steps[stepIndex].options.length) {
          _selectedOptions[stepIndex] = optionIndex;
        }
      });
    }
  }

  double get _totalPrice {
    if (widget.config.priceCalculator != null) {
      return widget.config.priceCalculator!(_selectedOptions);
    }
    double total = widget.config.basePrice;
    for (int i = 0; i < widget.config.steps.length; i++) {
      total += widget.config.steps[i].options[_selectedOptions[i]].priceDelta;
    }
    return total;
  }

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
                widget.config.categoryName, 
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 22, letterSpacing: -0.5, color: Colors.white)
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background Image (Hero)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.45,
            child: widget.config.heroImage.startsWith('http')
                ? CachedNetworkImage(
                    imageUrl: widget.config.heroImage,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => Container(color: const Color(0xFF111111)),
                    placeholder: (context, url) => Container(color: const Color(0xFF1D1D1F)),
                  )
                : Image.asset(
                    widget.config.heroImage,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(color: const Color(0xFF111111)),
                  ),
          ),
          
          // Gradient fade to black
          Positioned(
            top: MediaQuery.of(context).size.height * 0.2,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.25,
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
          
          // Content Scroll View
          Positioned.fill(
            child: SafeArea(
              child: ListView(
                padding: const EdgeInsets.only(top: 180, bottom: 120), // Leave space for hero and bottom bar
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.config.categoryName,
                          style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Colors.white, height: 1.1, letterSpacing: -1.0),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.config.description,
                          style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.8), height: 1.5),
                        ),
                        const SizedBox(height: 48),

                        // Dynamic Steps
                        ...List.generate(widget.config.steps.length, (stepIndex) {
                          final step = widget.config.steps[stepIndex];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 32),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  step.title,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                    color: Colors.white.withOpacity(0.5),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: List.generate(step.options.length, (optIndex) {
                                    final option = step.options[optIndex];
                                    final isSelected = _selectedOptions[stepIndex] == optIndex;
                                    
                                    return GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _selectedOptions[stepIndex] = optIndex;
                                        });
                                      },
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                        decoration: BoxDecoration(
                                          color: isSelected ? const Color(0xFF1D1D1F) : Colors.transparent,
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: isSelected ? const Color(0xFFFF5A5F) : Colors.white.withOpacity(0.2),
                                            width: isSelected ? 2 : 1,
                                          ),
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              option.label,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                                color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
                                              ),
                                            ),
                                            if (option.subLabel != null) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                option.subLabel!,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.white.withOpacity(0.5),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Sticky Bottom Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1D1D1F).withOpacity(0.8),
                    border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'TOTAL PRICE',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: Colors.white.withOpacity(0.5)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₹${_totalPrice.toStringAsFixed(0)}',
                              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white),
                            ),
                          ],
                        ),
                      ElevatedButton(
                        onPressed: () {
                          // Save configuration to state or pass as arguments, then go to Editor
                          final editorNotifier = ref.read(editorProvider.notifier);
                          editorNotifier.reset(); // clear old state
                          editorNotifier.setProductContext(
                            widget.config.categoryId, 
                            _selectedOptions,
                          );
                          
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const EditorScreen()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF5A5F),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: const Text('Configure & Add', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
