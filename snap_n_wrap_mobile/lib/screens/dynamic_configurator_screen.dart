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
  late List<int> _selectedOptions;

  @override
  void initState() {
    super.initState();
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

  List<Color> _parseGradient(String? gradientColors) {
    if (gradientColors == null || !gradientColors.contains(',')) {
      return [const Color(0xFF333333), const Color(0xFF222222)];
    }
    final parts = gradientColors.split(',');
    return parts.map((hex) => Color(int.parse(hex))).toList();
  }

  Widget _buildStepContent(int stepIndex, ConfigStep step) {
    if (step.layout == OptionLayout.themeCard) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.2,
        ),
        itemCount: step.options.length,
        itemBuilder: (context, optIndex) {
          final option = step.options[optIndex];
          final isSelected = _selectedOptions[stepIndex] == optIndex;
          final gradient = _parseGradient(option.gradientColors);

          return GestureDetector(
            onTap: () => setState(() => _selectedOptions[stepIndex] = optIndex),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: isSelected ? Colors.white : Colors.transparent,
                  width: isSelected ? 3 : 0,
                ),
                boxShadow: isSelected ? [
                  BoxShadow(color: gradient[0].withOpacity(0.5), blurRadius: 12, spreadRadius: 2)
                ] : [],
              ),
              child: Stack(
                children: [
                  Positioned(
                    bottom: 12,
                    left: 12,
                    right: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (option.emoji != null) ...[
                          Text(option.emoji!, style: const TextStyle(fontSize: 18)),
                          const SizedBox(height: 4),
                        ],
                        Text(
                          option.label,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        if (option.subLabel != null)
                          Text(
                            option.subLabel!,
                            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    const Positioned(
                      top: 12,
                      right: 12,
                      child: Icon(Icons.check_circle, color: Colors.white, size: 20),
                    ),
                ],
              ),
            ),
          );
        },
      );
    } 
    else if (step.layout == OptionLayout.sizeCard) {
      return SizedBox(
        height: 280,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: step.options.length,
          separatorBuilder: (context, index) => const SizedBox(width: 16),
          itemBuilder: (context, optIndex) {
            final option = step.options[optIndex];
            final isSelected = _selectedOptions[stepIndex] == optIndex;

            return GestureDetector(
              onTap: () => setState(() => _selectedOptions[stepIndex] = optIndex),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 160,
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF1D1D1F) : const Color(0xFF111111),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? const Color(0xFFFF5A5F) : Colors.white.withOpacity(0.1),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                        ),
                        child: option.imageUrl != null
                          ? Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.asset(option.imageUrl!, fit: BoxFit.cover),
                              ),
                            )
                          : const Icon(Icons.image, color: Colors.white24, size: 40),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              option.label,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            if (option.subLabel != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                option.subLabel!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.6),
                                ),
                              ),
                            ],
                            const Spacer(),
                            Text(
                              '₹${option.priceDelta.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: isSelected ? const Color(0xFFFF5A5F) : Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    }
    
    // Default Pill Layout
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: List.generate(step.options.length, (optIndex) {
        final option = step.options[optIndex];
        final isSelected = _selectedOptions[stepIndex] == optIndex;
        
        return GestureDetector(
          onTap: () => setState(() => _selectedOptions[stepIndex] = optIndex),
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
    );
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
          
          Positioned(
            top: MediaQuery.of(context).size.height * 0.15,
            left: 0,
            right: 0,
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
                padding: const EdgeInsets.only(top: 180, bottom: 120),
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

                        ...List.generate(widget.config.steps.length, (stepIndex) {
                          final step = widget.config.steps[stepIndex];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 36),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  step.title.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                    color: Colors.white.withOpacity(0.5),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildStepContent(stepIndex, step),
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
