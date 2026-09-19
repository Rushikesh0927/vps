import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../models/editor_models.dart';
import '../providers/cart_provider.dart';
import '../providers/editor_provider.dart';
import '../providers/user_provider.dart';
import 'checkout_screen.dart';
import 'edit_profile_screen.dart';
import '../widgets/interactive_photo.dart';
import '../data/product_config.dart';

class EditorScreen extends ConsumerStatefulWidget {
  const EditorScreen({super.key});

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  final ImagePicker _picker = ImagePicker();
  String _activeTab = 'photos'; // 'photos', 'edit'

  Future<void> _pickImage() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      ref.read(editorProvider.notifier).addPhotos(images.map((i) => i.path).toList());
    }
  }

  int _getExpectedPhotosCount(String categoryId, List<int> options) {
    if (categoryId == 'photobooks') {
      // options: [size, finish, pages]
      final pagesIndex = options[2];
      if (pagesIndex == 0) return 40; // 20 pages = 40 sides
      if (pagesIndex == 1) return 64; // 32 pages = 64 sides
      if (pagesIndex == 2) return 80; // 40 pages = 80 sides
    }
    if (categoryId == 'polaroid_prints') {
       final sizeIndex = options[0];
       final qtyIndex = options[1];
       final sizes = [
         [15, 30, 45, 60], // Go
         [24, 32, 40, 64], // Square
         [24, 32, 40, 64], // Signature
       ];
       return sizes[sizeIndex][qtyIndex];
    }
    return 0; // variable like prints/frames
  }

  @override
  Widget build(BuildContext context) {
    final editorState = ref.watch(editorProvider);
    final editorNotifier = ref.read(editorProvider.notifier);
    
    final expectedCount = _getExpectedPhotosCount(editorState.categoryId, editorState.selectedOptions);
    final isPolaroid = editorState.categoryId == 'polaroid_prints';
    final isPhotobook = editorState.categoryId == 'photobooks';
    
    final activeIdx = editorState.activePhotoId != null 
        ? editorState.photos.indexWhere((p) => p.id == editorState.activePhotoId)
        : -1;
        
    final activePhoto = activeIdx >= 0 ? editorState.photos[activeIdx] : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text('Editor', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // Top Mobile Pill (Only for Photobooks & Photo Prints conceptually)
                if (editorState.photos.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: editorState.photos.length >= expectedCount && expectedCount > 0
                            ? const Color(0xFFF0FDF4)
                            : Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: editorState.photos.length >= expectedCount && expectedCount > 0
                              ? const Color(0xFFBBF7D0)
                              : const Color(0xFFE5E7EB),
                        ),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8, height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: editorState.photos.length >= expectedCount && expectedCount > 0
                                  ? const Color(0xFF22C55E)
                                  : (isPhotobook ? const Color(0xFFF59E0B) : const Color(0xFF3B82F6)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isPhotobook 
                                ? '${editorState.photos.length} / $expectedCount pages'
                                : '${editorState.photos.length} prints',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: editorState.photos.length >= expectedCount && expectedCount > 0
                                  ? const Color(0xFF15803D)
                                  : const Color(0xFF111827),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Canvas Area
                Expanded(
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: isPolaroid ? 0.8 : (isPhotobook ? 0.7 : 0.67),
                      child: Container(
                        margin: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            )
                          ],
                        ),
                        child: activePhoto == null
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.add_photo_alternate_outlined, size: 48, color: Colors.grey[400]),
                                    const SizedBox(height: 12),
                                    const Text('Upload your photos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: _pickImage,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF4C1D95),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      child: const Text('Choose Photos', style: TextStyle(color: Colors.white)),
                                    )
                                  ],
                                ),
                              )
                            : Column(
                                children: [
                                  Expanded(
                                    child: Container(
                                      margin: EdgeInsets.all(isPolaroid ? 12 : 0),
                                      color: Colors.grey[200],
                                      child: ClipRect(
                                        child: Stack(
                                          children: [
                                            InteractivePhoto(
                                              photo: activePhoto,
                                              onTap: () {},
                                              onTransform: (matrix) {
                                                editorNotifier.updatePhoto(activePhoto.id, (p) => p.copyWith(
                                                  x: matrix.getTranslation().x,
                                                  y: matrix.getTranslation().y,
                                                ));
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (isPolaroid) const SizedBox(height: 48), // Polaroid Lip
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
                
                // Photo Navigation (Arrows + Dots)
                if (editorState.photos.length > 1)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: activeIdx > 0 
                                    ? () => editorNotifier.setActivePhoto(editorState.photos[activeIdx - 1].id) 
                                    : null,
                                child: Icon(Icons.chevron_left, color: activeIdx > 0 ? Colors.white : Colors.white24),
                              ),
                              const SizedBox(width: 12),
                              Builder(builder: (context) {
                                int start = activeIdx - 2;
                                int end = activeIdx + 2;
                                int total = editorState.photos.length;
                                if (start < 0) { end += start.abs(); start = 0; }
                                if (end >= total) { start -= (end - total + 1); end = total - 1; }
                                start = start.clamp(0, total);
                                end = end.clamp(0, total - 1);
                                
                                List<Widget> dotWidgets = [];
                                for (int i = start; i <= end; i++) {
                                  final isActive = i == activeIdx;
                                  dotWidgets.add(Container(
                                    width: isActive ? 16 : 8,
                                    height: 8,
                                    margin: const EdgeInsets.symmetric(horizontal: 2),
                                    decoration: BoxDecoration(
                                      color: isActive ? (isPhotobook ? const Color(0xFF4C1D95) : const Color(0xFF3B82F6)) : Colors.white38,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ));
                                }
                                return Row(children: dotWidgets);
                              }),
                              const SizedBox(width: 12),
                              GestureDetector(
                                onTap: activeIdx < editorState.photos.length - 1 
                                    ? () => editorNotifier.setActivePhoto(editorState.photos[activeIdx + 1].id) 
                                    : null,
                                child: Icon(Icons.chevron_right, color: activeIdx < editorState.photos.length - 1 ? Colors.white : Colors.white24),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Photo ${activeIdx + 1} of ${editorState.photos.length}',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54),
                        )
                      ],
                    ),
                  ),
                  
                // Spacer for Bottom Bar
                const SizedBox(height: 80),
              ],
            ),
          ),
          
          // Bottom Tab Navigation (Black Bar)
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              height: 80,
              color: const Color(0xFF111827), // Dark grey/black
              child: SafeArea(
                top: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _BottomTabButton(
                      icon: Icons.photo_library,
                      label: isPhotobook ? 'PAGES' : 'PHOTOS',
                      isActive: _activeTab == 'photos',
                      onTap: () => setState(() => _activeTab = 'photos'),
                    ),
                    _BottomTabButton(
                      icon: Icons.edit,
                      label: 'EDIT',
                      isActive: _activeTab == 'edit',
                      onTap: () => setState(() => _activeTab = 'edit'),
                    ),
                    _BottomTabButton(
                      icon: Icons.upload,
                      label: 'UPLOAD',
                      isActive: false,
                      onTap: _pickImage,
                    ),
                    // Next Button (Red Pill)
                    GestureDetector(
                      onTap: () {
                        if (expectedCount > 0 && editorState.photos.length < expectedCount) {
                           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please add ${expectedCount - editorState.photos.length} more photos.')));
                           return;
                        }
                        // To Checkout
                        final user = ref.read(userProvider).user;
                        if (user != null && (user.mobile.isEmpty || user.savedAddress == null || user.savedAddress!.address.isEmpty)) {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen(isInitialSetup: true)));
                        } else {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const CheckoutScreen()));
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF5A5F),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('NEXT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward, color: Colors.white, size: 16),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomTabButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _BottomTabButton({required this.icon, required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isActive ? Colors.white : Colors.white38, size: 24),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: isActive ? Colors.white : Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
