import 'dart:io';
import 'package:flutter/material.dart';
import 'package:matrix_gesture_detector/matrix_gesture_detector.dart';
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
  late Matrix4 _matrix;

  @override
  void initState() {
    super.initState();
    _matrix = Matrix4.identity()
      ..translate(widget.photo.x, widget.photo.y)
      ..scale(widget.photo.scaleX, widget.photo.scaleY)
      ..rotateZ(widget.photo.rotation);
  }

  @override
  void didUpdateWidget(covariant InteractivePhoto oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.photo.x != widget.photo.x ||
        oldWidget.photo.y != widget.photo.y ||
        oldWidget.photo.scaleX != widget.photo.scaleX ||
        oldWidget.photo.scaleY != widget.photo.scaleY ||
        oldWidget.photo.rotation != widget.photo.rotation) {
      _matrix = Matrix4.identity()
        ..translate(widget.photo.x, widget.photo.y)
        ..scale(widget.photo.scaleX, widget.photo.scaleY)
        ..rotateZ(widget.photo.rotation);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MatrixGestureDetector(
      onMatrixUpdate: (m, tm, sm, rm) {
        setState(() {
          _matrix = m;
        });
        widget.onTransform(_matrix);
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: Transform(
          transform: _matrix,
          child: Image.file(
            File(widget.photo.previewUrl),
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
