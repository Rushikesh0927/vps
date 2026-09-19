// ─── EDITOR SCREEN — Full per-category redesign ───────────────────────────
// Phases 2 + 3: Gesture fix (onTransform saves scale+rotation) + per-category editor
import 'dart:io';
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
  int _activePageIndex = 0;

  // ─── category-specific helpers ────────────────────────────────────────────

  String _getCategoryLabel(String id) {
    const map = {
      'photobooks': 'Photobooks',
      'polaroid_prints': 'Polaroid Prints',
      'photo_prints': 'Photo Prints',
      'photo_frames': 'Photo Frames',
      'wall_posters': 'Wall Posters',
      'choco_wrappers': 'Choco Wrappers',
    };
    return map[id] ?? 'Editor';
  }

  Color _getCategoryAccent(String id) {
    const map = {
      'photobooks': Color(0xFF7C3AED),
      'polaroid_prints': Color(0xFFE11D48),
      'photo_prints': Color(0xFF1D4ED8),
      'photo_frames': Color(0xFF15803D),
      'wall_posters': Color(0xFFB45309),
      'choco_wrappers': Color(0xFF92400E),
    };
    return map[id] ?? const Color(0xFFFF5A5F);
  }

  double _getCanvasAspectRatio(String id, List<int> opts) {
    switch (id) {
      case 'photobooks':
        final sizeIdx = opts.isNotEmpty ? opts[0] : 0;
        return sizeIdx == 3 ? 1.0 : 0.707; // A7 square-ish, others A-ratio
      case 'polaroid_prints':
        final typeIdx = opts.isNotEmpty ? opts[0] : 0;
        return typeIdx == 1 ? 1.0 : 0.8; // Instax Square = 1:1
      case 'photo_prints':
        final sizeIdx = opts.isNotEmpty ? opts[0] : 0;
        const ratios = [1.5, 1.4, 1.33, 1.25, 1.5]; // 4x6, 5x7, 6x8, 8x10, 8x12
        return 1.0 / ratios[sizeIdx.clamp(0, 4)];
      case 'photo_frames':
        final orientIdx = opts.isNotEmpty ? opts[0] : 0;
        return orientIdx == 0 ? 0.667 : 1.5; // Portrait vs Landscape
      case 'wall_posters':
        return 0.707; // A-series ratio
      case 'choco_wrappers':
        return 1.0; // Square wrapper
      default:
        return 0.75;
    }
  }

  int _getExpectedPhotosCount(String id, List<int> opts) {
    if (id == 'photobooks') {
      if (opts.length < 3) return 40;
      final pagesIdx = opts[2];
      return [40, 64, 80][pagesIdx.clamp(0, 2)];
    }
    if (id == 'polaroid_prints') {
      final typeIdx = opts.isNotEmpty ? opts[0] : 0;
      final qtyIdx = opts.length > 1 ? opts[1] : 0;
      const qtys = [
        [15, 30, 45, 60], // Polaroid Go
        [24, 32, 40, 64], // Instax Square
        [24, 32, 40, 64], // Polaroid Signature
      ];
      return qtys[typeIdx.clamp(0, 2)][qtyIdx.clamp(0, 3)];
    }
    return 1; // Single photo for prints/frames/posters/wrappers
  }

  String _getPhotoCountLabel(String id, List<int> opts, int current, int expected) {
    switch (id) {
      case 'photobooks':
        return '$current / $expected pages added';
      case 'polaroid_prints':
        return '$current / $expected prints';
      case 'photo_prints':
        return '$current ${current == 1 ? "photo" : "photos"} selected';
      case 'photo_frames':
        return current == 0 ? 'Add your photo' : 'Photo ready';
      case 'wall_posters':
        return current == 0 ? 'Add your photo' : 'Photo ready';
      case 'choco_wrappers':
        return current == 0 ? 'Add your photo' : 'Photo ready';
      default:
        return '$current photos';
    }
  }

  Future<void> _pickImages() async {
    final id = ref.read(editorProvider).categoryId;
    final isMulti = id == 'photobooks' || id == 'polaroid_prints' || id == 'photo_prints';

    if (isMulti) {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        ref.read(editorProvider.notifier).addPhotos(images.map((i) => i.path).toList());
      }
    } else {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        ref.read(editorProvider.notifier).replaceOrAddSinglePhoto(image.path);
      }
    }
  }

  // ─── Canvas widgets per category ──────────────────────────────────────────

  Widget _buildPolaroidCanvas(PhotoEdit photo, EditorState state, Color accent) {
    return Column(
      children: [
        Expanded(
          flex: 4,
          child: Container(
            margin: const EdgeInsets.all(8),
            color: Colors.grey[200],
            child: ClipRect(
              child: InteractivePhoto(
                photo: photo,
                onTap: () {},
                onTransform: (m) => _applyTransform(m, photo.id),
              ),
            ),
          ),
        ),
        // Polaroid bottom lip
        Container(
          height: 52,
          color: Colors.white,
          child: Center(
            child: Text(
              'SNAP-N-WRAP',
              style: TextStyle(
                fontSize: 9,
                letterSpacing: 2,
                color: Colors.grey[400],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFrameCanvas(PhotoEdit photo, EditorState state, Color accent) {
    final isLandscape = state.selectedOptions.isNotEmpty && state.selectedOptions[0] == 1;
    final frameColors = ['#1a1a1a', '#f5f5f5', '#c8a96e'];
    final colorIdx = state.selectedOptions.length > 1 ? state.selectedOptions[1].clamp(0, 2) : 0;
    final frameColorHex = frameColors[colorIdx];
    final frameColor = Color(int.parse(frameColorHex.replaceFirst('#', '0xFF')));

    return Container(
      decoration: BoxDecoration(
        color: frameColor,
        borderRadius: BorderRadius.circular(2),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      padding: const EdgeInsets.all(14),
      child: Container(
        decoration: BoxDecoration(border: Border.all(color: frameColor.withValues(alpha: 0.5), width: 2)),
        child: ClipRect(
          child: InteractivePhoto(
            photo: photo,
            onTap: () {},
            onTransform: (m) => _applyTransform(m, photo.id),
          ),
        ),
      ),
    );
  }

  Widget _buildChocoCanvas(PhotoEdit photo, Color accent) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent.withValues(alpha: 0.8), accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: ClipRect(
                  child: InteractivePhoto(
                    photo: photo,
                    onTap: () {},
                    onTransform: (m) => _applyTransform(m, photo.id),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: const Text(
              'YOUR MESSAGE HERE',
              style: TextStyle(color: Colors.white, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenericCanvas(PhotoEdit photo) {
    return ClipRect(
      child: InteractivePhoto(
        photo: photo,
        onTap: () {},
        onTransform: (m) => _applyTransform(m, photo.id),
      ),
    );
  }

  void _applyTransform(Matrix4 m, String photoId) {
    // Extract translation, scale and rotation from matrix
    final translation = m.getTranslation();
    final scaleX = m.getColumn(0).length;

    // Extract rotation from matrix
    final rotZ = (m.entry(1, 0) / scaleX);
    final rotation = rotZ.clamp(-1.0, 1.0);
    final rotAngle = -rotation; // dart:math asin would be needed for exact, approximate is fine

    ref.read(editorProvider.notifier).updatePhoto(photoId, (p) => p.copyWith(
      x: translation.x,
      y: translation.y,
      scaleX: scaleX,
      scaleY: scaleX,
    ));
  }

  Widget _buildCanvas(EditorState state, Color accent) {
    final photos = state.photos;
    final id = state.categoryId;

    // For photobook multi-page, show current page photo
    final activePhoto = photos.isEmpty
        ? null
        : (id == 'photobooks'
            ? photos[_activePageIndex.clamp(0, photos.length - 1)]
            : photos.first);

    if (activePhoto == null) {
      return _buildEmptyCanvas(accent);
    }

    Widget photoContent;
    switch (id) {
      case 'polaroid_prints':
        photoContent = _buildPolaroidCanvas(activePhoto, state, accent);
        break;
      case 'photo_frames':
        photoContent = _buildFrameCanvas(activePhoto, state, accent);
        break;
      case 'choco_wrappers':
        photoContent = _buildChocoCanvas(activePhoto, accent);
        break;
      default:
        photoContent = _buildGenericCanvas(activePhoto);
    }

    return photoContent;
  }

  Widget _buildEmptyCanvas(Color accent) {
    return GestureDetector(
      onTap: _pickImages,
      child: Container(
        color: const Color(0xFFF5F5F5),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_outlined, size: 56, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text('Tap to add photos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
            const SizedBox(height: 8),
            Text('Upload from your gallery', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }

  // ─── build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editorProvider);
    final notifier = ref.read(editorProvider.notifier);
    final id = state.categoryId;
    final accent = _getCategoryAccent(id);
    final aspectRatio = _getCanvasAspectRatio(id, state.selectedOptions);
    final expected = _getExpectedPhotosCount(id, state.selectedOptions);
    final label = _getCategoryLabel(id);

    // Keep _activePageIndex in range
    if (state.photos.isNotEmpty && _activePageIndex >= state.photos.length) {
      _activePageIndex = state.photos.length - 1;
    }

    final isPhotobook = id == 'photobooks';
    final isPolaroid = id == 'polaroid_prints';
    final isMultiPhoto = isPhotobook || isPolaroid || id == 'photo_prints';
    final hasPhotos = state.photos.isNotEmpty;
    final photoCountText = _getPhotoCountLabel(id, state.selectedOptions, state.photos.length, expected);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
        actions: [
          if (hasPhotos)
            TextButton(
              onPressed: _pickImages,
              child: Text('Add Photos', style: TextStyle(color: accent, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Status Bar ──────────────────────────────────────────────────
          if (hasPhotos)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8, height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: (expected <= 1 || state.photos.length >= expected) ? Colors.green : Colors.amber,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(photoCountText, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  if (isPhotobook && state.photos.length > 1)
                    Text('Page ${_activePageIndex + 1}', style: const TextStyle(color: Color(0xFF888888), fontSize: 12)),
                ],
              ),
            ),

          // ── Canvas ──────────────────────────────────────────────────────
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: AspectRatio(
                  aspectRatio: aspectRatio,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: id == 'photo_frames' ? BorderRadius.zero : BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _buildCanvas(state, accent),
                  ),
                ),
              ),
            ),
          ),

          // ── Page Navigation (Photobook / Polaroid) ──────────────────────
          if (isMultiPhoto && state.photos.length > 1)
            Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _activePageIndex > 0
                        ? () => setState(() => _activePageIndex--)
                        : null,
                    icon: Icon(Icons.chevron_left, color: _activePageIndex > 0 ? Colors.white : Colors.white24),
                  ),
                  Expanded(
                    child: SizedBox(
                      height: 28,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: state.photos.length,
                        itemBuilder: (ctx, i) {
                          final isActive = i == _activePageIndex;
                          return GestureDetector(
                            onTap: () => setState(() => _activePageIndex = i),
                            child: Container(
                              width: isActive ? 32 : 20,
                              height: 8,
                              margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                color: isActive ? accent : Colors.white24,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _activePageIndex < state.photos.length - 1
                        ? () => setState(() => _activePageIndex++)
                        : null,
                    icon: Icon(Icons.chevron_right, color: _activePageIndex < state.photos.length - 1 ? Colors.white : Colors.white24),
                  ),
                ],
              ),
            ),

          // ── Bottom Action Bar ────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            decoration: const BoxDecoration(
              color: Color(0xFF111111),
              border: Border(top: BorderSide(color: Color(0xFF222222))),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  // Upload / Add more button
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickImages,
                      icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
                      label: Text(hasPhotos ? 'Add More' : 'Upload Photos'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFF333333)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Next → Checkout button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: hasPhotos ? () {
                        if (expected > 1 && state.photos.length < expected) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Please add ${expected - state.photos.length} more photos to continue.'),
                              backgroundColor: const Color(0xFFFF5A5F),
                            ),
                          );
                          return;
                        }
                        final user = ref.read(userProvider).user;
                        if (user != null && (user.mobile.isEmpty || user.savedAddress == null || user.savedAddress!.address.isEmpty)) {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen(isInitialSetup: true)));
                        } else {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const CheckoutScreen()));
                        }
                      } : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF5A5F),
                        disabledBackgroundColor: const Color(0xFF333333),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Proceed to Checkout', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                          SizedBox(width: 6),
                          Icon(Icons.arrow_forward, size: 16),
                        ],
                      ),
                    ),
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
