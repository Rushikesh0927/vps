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
  late List<int> _selectedOptions;
  double _totalPrice = 0;
  int _currentStepIndex = 0;

  @override
  void initState() {
    super.initState();
    _selectedOptions = List.filled(widget.config.steps.length, 0);
    if (widget.initialSelection != null) {
      widget.initialSelection!.forEach((key, value) {
        if (key < _selectedOptions.length) {
          _selectedOptions[key] = value;
        }
      });
    }
    _calculatePrice();
  }

  void _calculatePrice() {
    double price = widget.config.basePrice;
    if (widget.config.priceCalculator != null) {
      price = widget.config.priceCalculator!(_selectedOptions);
    } else {
      for (int i = 0; i < widget.config.steps.length; i++) {
        price += widget.config.steps[i].options[_selectedOptions[i]].priceDelta;
      }
    }
    setState(() {
      _totalPrice = price;
    });
  }

  void _nextStep() {
    setState(() {
      if (_currentStepIndex < widget.config.steps.length) {
        _currentStepIndex++;
      }
    });
  }

  void _prevStep() {
    setState(() {
      if (_currentStepIndex > 0) {
        _currentStepIndex--;
      } else {
        Navigator.pop(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isSummary = _currentStepIndex == widget.config.steps.length;

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
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _prevStep,
              ),
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
              child: CachedNetworkImage(
                imageUrl: widget.config.heroImage,
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Content
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 140), // space for bottom bar
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

                        if (!isSummary) ...[
                          // SINGLE STEP VIEW
                          Text(
                            'STEP ${_currentStepIndex + 1} OF ${widget.config.steps.length}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2.0,
                              color: Colors.white.withOpacity(0.5),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.config.steps[_currentStepIndex].title,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: List.generate(widget.config.steps[_currentStepIndex].options.length, (optIndex) {
                              final option = widget.config.steps[_currentStepIndex].options[optIndex];
                              final isSelected = _selectedOptions[_currentStepIndex] == optIndex;
                              
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedOptions[_currentStepIndex] = optIndex;
                                    _calculatePrice();
                                  });
                                  // Auto advance after short delay
                                  Future.delayed(const Duration(milliseconds: 300), () {
                                    if (mounted) _nextStep();
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
                        ] else ...[
                          // SUMMARY VIEW
                          const Text(
                            'YOUR CONFIGURATION',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1D1D1F),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withOpacity(0.1)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: List.generate(widget.config.steps.length, (i) {
                                final step = widget.config.steps[i];
                                final selectedOpt = step.options[_selectedOptions[i]];
                                return Padding(
                                  padding: EdgeInsets.only(bottom: i == widget.config.steps.length - 1 ? 0 : 16),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        step.title,
                                        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
                                      ),
                                      Text(
                                        selectedOpt.label,
                                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Center(
                            child: TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _currentStepIndex = 0;
                                });
                              },
                              icon: const Icon(Icons.edit, size: 16, color: Colors.white70),
                              label: const Text('Edit Selections', style: TextStyle(color: Colors.white70)),
                            ),
                          )
                        ],
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
                        if (!isSummary)
                          ElevatedButton(
                            onPressed: _nextStep,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.1),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                            ),
                            child: const Text('Next Step', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                          )
                        else
                          ElevatedButton(
                            onPressed: () {
                              final editorNotifier = ref.read(editorProvider.notifier);
                              editorNotifier.reset();
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
