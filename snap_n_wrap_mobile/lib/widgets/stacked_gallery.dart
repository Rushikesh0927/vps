import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class GalleryItem {
  final String id;
  final String src;
  final String alt;
  final String tag;
  final String label;

  GalleryItem({
    required this.id,
    required this.src,
    required this.alt,
    required this.tag,
    required this.label,
  });
}

class StackedGallery extends StatefulWidget {
  final List<GalleryItem> gallery;
  final Function(int) onCardTap;

  const StackedGallery({
    super.key,
    required this.gallery,
    required this.onCardTap,
  });

  @override
  State<StackedGallery> createState() => _StackedGalleryState();
}

class _StackedGalleryState extends State<StackedGallery> {
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _autoPlayTimer;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    // Use viewportFraction to allow peeking of neighboring cards
    _pageController = PageController(viewportFraction: 0.7);
    _startAutoPlay();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _autoPlayTimer?.cancel();
    super.dispose();
  }

  void _startAutoPlay() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = Timer.periodic(const Duration(milliseconds: 3500), (timer) {
      if (_isPaused || widget.gallery.isEmpty) return;
      if (_pageController.hasClients) {
        int nextPage = (_currentPage + 1) % widget.gallery.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.fastOutSlowIn,
        );
      }
    });
  }

  void _onInteractionStart() {
    setState(() {
      _isPaused = true;
    });
  }

  void _onInteractionEnd() {
    setState(() {
      _isPaused = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.gallery.isEmpty) return const SizedBox.shrink();

    return GestureDetector(
      onPanDown: (_) => _onInteractionStart(),
      onPanCancel: _onInteractionEnd,
      onPanEnd: (_) => _onInteractionEnd(),
      child: SizedBox(
        height: 450,
        child: PageView.builder(
          controller: _pageController,
          itemCount: widget.gallery.length,
          onPageChanged: (idx) {
            setState(() {
              _currentPage = idx;
            });
          },
          itemBuilder: (context, index) {
            return AnimatedBuilder(
              animation: _pageController,
              builder: (context, child) {
                double value = 1.0;
                if (_pageController.position.haveDimensions) {
                  value = _pageController.page! - index;
                  // Restrict value bounds
                  value = (1 - (value.abs() * 0.3)).clamp(0.0, 1.0);
                } else {
                  // Initial render fallback
                  value = (index == _currentPage) ? 1.0 : 0.7;
                }

                // Compute scale and rotation based on distance from center
                final isCenter = index == _currentPage;
                final scale = Curves.easeOut.transform(value);
                final zOffset = isCenter ? 10.0 : 0.0;

                return Center(
                  child: Transform.scale(
                    scale: scale,
                    child: child,
                  ),
                );
              },
              child: _buildCard(widget.gallery[index], index == _currentPage),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCard(GalleryItem item, bool isTop) {
    return GestureDetector(
      onTap: () {
        if (isTop) {
          widget.onCardTap(widget.gallery.indexOf(item));
        } else {
          // If tapping a side card, scroll to it
          _pageController.animateToPage(
            widget.gallery.indexOf(item),
            duration: const Duration(milliseconds: 600),
            curve: Curves.fastOutSlowIn,
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white, width: 6),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 25,
              offset: const Offset(0, 15),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Use network image in real scenario, fallback to a placeholder color if src is not standard
              item.src.startsWith('assets/')
                  ? Image.asset(item.src, fit: BoxFit.cover)
                  : CachedNetworkImage(
                      imageUrl: item.src,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(color: const Color(0xFF1D1D1F)),
                      errorWidget: (context, url, error) => Container(color: Colors.grey[800], child: const Icon(Icons.error)),
                    ),

              // Glassmorphism overlay for side cards
              if (!isTop)
                RepaintBoundary(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                    child: Container(
                      color: Colors.white.withOpacity(0.15),
                    ),
                  ),
                ),

              // UI overlays for top card
              if (isTop) ...[
                // Vignette gradient
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.8),
                        Colors.black.withOpacity(0.1),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                // Details
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF5A5F),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.tag.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                // Fullscreen button
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: RepaintBoundary(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: const Icon(
                            Icons.fullscreen,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
