import 'package:flutter/material.dart' show InputBorder;
import 'package:flutter/painting.dart';

import 'folk_pen.dart';
import 'folk_style.dart';

/// Gạch chân ô nhập chữ bằng một nét phấn.
class ChalkUnderlineInputBorder extends InputBorder {
  const ChalkUnderlineInputBorder({
    this.color = const Color(0xCCFFF3E2),
    this.width = 2,
    super.borderSide = BorderSide.none,
  });

  final Color color;
  final double width;

  @override
  bool get isOutline => false;

  @override
  ChalkUnderlineInputBorder copyWith({
    BorderSide? borderSide,
    Color? color,
    double? width,
  }) => ChalkUnderlineInputBorder(
    color: color ?? this.color,
    width: width ?? this.width,
    borderSide: borderSide ?? this.borderSide,
  );

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.only(bottom: width);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => Path()
    ..addRect(
      Rect.fromLTRB(rect.left, rect.top, rect.right, rect.bottom - width),
    );

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRect(rect);

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    double? gapStart,
    double gapExtent = 0.0,
    double gapPercentage = 0.0,
    TextDirection? textDirection,
  }) {
    final y = rect.bottom - width / 2;
    final path = Path()
      ..moveTo(rect.left, y)
      ..lineTo(rect.right, y);
    FolkPen.stroke(
      canvas,
      path,
      PenKind.chalk,
      width: width,
      color: color,
      seed: rect.width.round() * 17 + 3,
    );
  }

  @override
  ShapeBorder scale(double t) =>
      ChalkUnderlineInputBorder(color: color, width: width * t);

  @override
  bool operator ==(Object other) =>
      other is ChalkUnderlineInputBorder &&
      other.color == color &&
      other.width == width;

  @override
  int get hashCode => Object.hash(color, width);
}
