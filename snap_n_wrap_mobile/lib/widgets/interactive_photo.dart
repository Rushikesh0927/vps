import 'dart:io';
import 'package:flutter/material.dart';
import '../models/editor_models.dart';

class InteractivePhoto extends StatefulWidget {
  final PhotoEdit photo;
  final VoidCallback onTap;
  final ValueChanged<Matrix4> onTransform;

  const InteractivePhoto({
    super.key,
    required this.photo,
    required this.onTap,
    required this.onTransform,
  });

  @override
  State<InteractivePhoto> createState() => _InteractivePhotoState();
}

class _InteractivePhotoState extends State<InteractivePhoto> {
  late double _x;
  late double _y;
  late double _scale;
  late double _rotation;

  // Captured at gesture start
  double _baseScale = 1.0;
  double _baseRotation = 0.0;
  Offset _baseOffset = Offset.zero;

  // Scale limits
  static const double _minScale = 0.3;
  static const double _maxScale = 6.0;

  @override
  void initState() {
    super.initState();
    _x = widget.photo.x;
    _y = widget.photo.y;
    _scale = widget.photo.scaleX;
    _rotation = widget.photo.rotation;
  }

  @override
  void didUpdateWidget(covariant InteractivePhoto oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync state when a different photo is selected
    if (oldWidget.photo.id != widget.photo.id) {
      _x = widget.photo.x;
      _y = widget.photo.y;
      _scale = widget.photo.scaleX;
      _rotation = widget.photo.rotation;
    }
  }

  void _notifyTransform() {
    final m = Matrix4.identity()
      ..translate(_x, _y)
      ..scale(_scale, _scale)
      ..rotateZ(_rotation);
    widget.onTransform(m);
  }

  @override
  Widget build(BuildContext context) {
    final matrix = Matrix4.identity()
      ..translate(_x, _y)
      ..scale(_scale, _scale)
      ..rotateZ(_rotation);

    return GestureDetector(
      onTap: widget.onTap,
      onScaleStart: (details) {
        // Capture baseline values at gesture start
        _baseScale = _scale;
        _baseRotation = _rotation;
        _baseOffset = Offset(_x, _y);
      },
      onScaleUpdate: (details) {
        setState(() {
          if (details.pointerCount == 1) {
            // 1 finger = PAN only
            _x = _baseOffset.dx + details.focalPointDelta.dx;
            _y = _baseOffset.dy + details.focalPointDelta.dy;
            // Continuously update base so panning is smooth
            _baseOffset = Offset(_x, _y);
          } else {
            // 2+ fingers = ZOOM + ROTATE only (no pan)
            _scale = (_baseScale * details.scale).clamp(_minScale, _maxScale);
            _rotation = _baseRotation + details.rotation;
          }
        });
        _notifyTransform();
      },
      child: Container(
        color: Colors.transparent,
        child: Transform(
          transform: matrix,
          alignment: Alignment.center,
          child: Image.file(
            File(widget.photo.previewUrl),
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
