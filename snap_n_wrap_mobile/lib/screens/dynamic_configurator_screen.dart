import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../data/product_config.dart';
import '../providers/editor_provider.dart';
import 'editor_screen.dart';

class DynamicConfiguratorScreen extends ConsumerStatefulWidget {
  final ProductConfiguration config;
  final Map<int, int>? initialSelection;

  const DynamicConfiguratorScreen({super.key, required this.config, this.initialSelection});

  @override
  ConsumerState<DynamicConfiguratorScreen> createState() => _DynamicConfiguratorScreenState();
}

class _DynamicConfiguratorScreenState extends ConsumerState<DynamicConfiguratorScreen> {
  late List<int?> _selectedOptions;
  double _totalPrice = 0;
  

  @override
  void initState() {
    super.initState();
    _selectedOptions = List.generate(widget.config.steps.length, (index) => 0);
    
    if (widget.initialSelection != null) {
      widget.initialSelection!.forEach((key, value) {
        if (key < _selectedOptions.length) {
          _selectedOptions[key] = value;
          
        }
      });
      
    } else {
      // If polaroid or standard, set default selections to 0 for all steps so it calculates base price immediately?
      // Actually, if we do progressive disclosure, they must select. Let's auto-select option 0 for the very first step.
      if (widget.config.steps.isNotEmpty) {
        _selectedOptions[0] = 0;
      }
    }
    
    _calculatePrice();
  }

  void _calculatePrice() {
    double price = widget.config.basePrice;
    
    // Create a temporary list of selections, falling back to 0 if null for calculation
    List<int?> calcOptions = _selectedOptions;
    
    if (widget.config.priceCalculator != null) {
      price = widget.config.priceCalculator!(_selectedOptions);
    } else {
      for (int i = 0; i < widget.config.steps.length; i++) {
        if (_selectedOptions[i] != null) {
          final optionsList = widget.config.steps[i].dynamicOptions != null ? widget.config.steps[i].dynamicOptions!(_selectedOptions) : widget.config.steps[i].options;
          price += optionsList[_selectedOptions[i]!].priceDelta;
        } else {
           final optionsList = widget.config.steps[i].dynamicOptions != null ? widget.config.steps[i].dynamicOptions!(_selectedOptions) : widget.config.steps[i].options;
           price += optionsList[0].priceDelta;
        }
      }
    }
    setState(() {
      _totalPrice = price;
    });
  }

  bool _isAllSelected() {
    return !_selectedOptions.contains(null);
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
          // Background Image
          Positioned(
            top: 0, left: 0, right: 0,
            height: MediaQuery.of(context).size.height * 0.45,
            child: ShaderMask(
              shaderCallback: (rect) => LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black.withOpacity(0.1), Colors.black],
                stops: const [0.5, 1.0],
              ).createShader(rect),
              blendMode: BlendMode.darken,
              child: widget.config.heroImage.startsWith('http')
                  ? CachedNetworkImage(
                      imageUrl: widget.config.heroImage,
                      fit: BoxFit.cover,
                    )
                  : Image.asset(
                      widget.config.heroImage,
                      fit: BoxFit.cover,
                    ),
            ),
          ),

          // Content
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 140),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                  
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.config.categoryName,
                          style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1.5, height: 1.1),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.config.description,
                          style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.8), height: 1.5),
                        ),
                        const SizedBox(height: 48),

                        // PROGRESSIVE DISCLOSURE STEPS
                        ...List.generate(widget.config.steps.length, (stepIndex) {
                          
                          
                          final step = widget.config.steps[stepIndex];
                          
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 32),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'STEP ${stepIndex + 1} — ${step.title.toUpperCase()}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2.0,
                                    color: Colors.white.withOpacity(0.5),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: List.generate(step.dynamicOptions != null ? step.dynamicOptions!(_selectedOptions).length : step.options.length, (optIndex) {
                                    final optionsList = step.dynamicOptions != null ? step.dynamicOptions!(_selectedOptions) : step.options;
                                    final option = optionsList[optIndex];
                                    final isSelected = _selectedOptions[stepIndex] == optIndex;
                                    
                                    return GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _selectedOptions[stepIndex] = optIndex;
                                          
                                          _calculatePrice();
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
                          onPressed: _isAllSelected() ? () {
                            final editorNotifier = ref.read(editorProvider.notifier);
                            editorNotifier.reset();
                            // Cast safely
                            final List<int> finalSelections = _selectedOptions.map((e) => e!).toList();
                            editorNotifier.setProductContext(
                              widget.config.categoryId, 
                              finalSelections,
                            );
                            
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const EditorScreen()),
                            );
                          } : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF5A5F),
                            disabledBackgroundColor: Colors.white.withOpacity(0.1),
                            foregroundColor: Colors.white,
                            disabledForegroundColor: Colors.white38,
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
