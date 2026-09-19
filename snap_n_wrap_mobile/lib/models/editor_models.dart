import 'dart:io';

class TextElement {
  final String id;
  final String text;
  final double x;
  final double y;
  final double rotation;
  final double scaleX;
  final double scaleY;
  final String fill;
  final String fontFamily;
  final double fontSize;
  final String? stroke;
  final double? strokeWidth;

  TextElement({
    required this.id,
    required this.text,
    required this.x,
    required this.y,
    required this.rotation,
    required this.scaleX,
    required this.scaleY,
    required this.fill,
    required this.fontFamily,
    required this.fontSize,
    this.stroke,
    this.strokeWidth,
  });

  TextElement copyWith({
    String? id,
    String? text,
    double? x,
    double? y,
    double? rotation,
    double? scaleX,
    double? scaleY,
    String? fill,
    String? fontFamily,
    double? fontSize,
    String? stroke,
    double? strokeWidth,
  }) {
    return TextElement(
      id: id ?? this.id,
      text: text ?? this.text,
      x: x ?? this.x,
      y: y ?? this.y,
      rotation: rotation ?? this.rotation,
      scaleX: scaleX ?? this.scaleX,
      scaleY: scaleY ?? this.scaleY,
      fill: fill ?? this.fill,
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      stroke: stroke ?? this.stroke,
      strokeWidth: strokeWidth ?? this.strokeWidth,
    );
  }
}

class PhotoEdit {
  final String id;
  final String previewUrl; // Path to local file or network URL
  final double x;
  final double y;
  final double scaleX;
  final double scaleY;
  final double rotation;
  final bool flipH;
  final bool flipV;
  final bool approved;
  final int qty;
  final List<TextElement> texts;

  PhotoEdit({
    required this.id,
    required this.previewUrl,
    required this.x,
    required this.y,
    required this.scaleX,
    required this.scaleY,
    required this.rotation,
    required this.flipH,
    required this.flipV,
    required this.approved,
    required this.qty,
    required this.texts,
  });

  factory PhotoEdit.initial(String id, String previewUrl) {
    return PhotoEdit(
      id: id,
      previewUrl: previewUrl,
      x: 0,
      y: 0,
      scaleX: 1,
      scaleY: 1,
      rotation: 0,
      flipH: false,
      flipV: false,
      approved: false,
      qty: 1,
      texts: [],
    );
  }

  PhotoEdit copyWith({
    String? id,
    String? previewUrl,
    double? x,
    double? y,
    double? scaleX,
    double? scaleY,
    double? rotation,
    bool? flipH,
    bool? flipV,
    bool? approved,
    int? qty,
    List<TextElement>? texts,
  }) {
    return PhotoEdit(
      id: id ?? this.id,
      previewUrl: previewUrl ?? this.previewUrl,
      x: x ?? this.x,
      y: y ?? this.y,
      scaleX: scaleX ?? this.scaleX,
      scaleY: scaleY ?? this.scaleY,
      rotation: rotation ?? this.rotation,
      flipH: flipH ?? this.flipH,
      flipV: flipV ?? this.flipV,
      approved: approved ?? this.approved,
      qty: qty ?? this.qty,
      texts: texts ?? this.texts,
    );
  }
}

class PolaroidSize {
  final String id;
  final String label;
  final double width;
  final double height;
  final double basePrice;

  const PolaroidSize({
    required this.id,
    required this.label,
    required this.width,
    required this.height,
    required this.basePrice,
  });
}

const List<PolaroidSize> polaroidSizes = [
  PolaroidSize(id: 'mini', label: 'Mini (2x3")', width: 2, height: 3, basePrice: 20),
  PolaroidSize(id: 'square', label: 'Square (3.5x3.5")', width: 3.5, height: 3.5, basePrice: 30),
  PolaroidSize(id: 'wide', label: 'Wide (4.2x3.4")', width: 4.2, height: 3.4, basePrice: 40),
];

double getPriceForQty(PolaroidSize size, int qty) {
  return size.basePrice * qty; // Simplified pricing logic
}
