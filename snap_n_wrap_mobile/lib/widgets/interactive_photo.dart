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

  double _baseScale = 1.0;
  double _baseRotation = 0.0;
  Offset _baseOffset = Offset.zero;

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
    if (oldWidget.photo.x != widget.photo.x ||
        oldWidget.photo.y != widget.photo.y ||
        oldWidget.photo.scaleX != widget.photo.scaleX ||
        oldWidget.photo.rotation != widget.photo.rotation) {
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
        _baseScale = _scale;
        _baseRotation = _rotation;
        _baseOffset = Offset(_x, _y);
      },
      onScaleUpdate: (details) {
        setState(() {
          if (details.pointerCount == 1) {
            // Pan only
            _x = _baseOffset.dx + details.focalPointDelta.dx;
            _y = _baseOffset.dy + details.focalPointDelta.dy;
            _baseOffset = Offset(_x, _y); // Update base for continuous panning
          } else if (details.pointerCount >= 2) {
            // Zoom and rotate only (no panning to avoid jumpiness)
            _scale = _baseScale * details.scale;
            _rotation = _baseRotation + details.rotation;
          }
        });
        _notifyTransform();
      },
      child: Container(
        color: Colors.transparent, // Ensure gesture detector catches events
        child: Transform(
          transform: matrix,
          alignment: Alignment.center,
          child: Image.file(
            File(widget.photo.previewUrl),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
