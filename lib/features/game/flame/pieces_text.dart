import 'dart:ui';

import 'package:flutter/painting.dart'
    show TextPainter, TextSpan, TextStyle, FontWeight;

final Map<String, TextPainter> _textCache = {};

/// Chữ căn giữa tại `center`, có cache TextPainter.
void paintCenteredText(
  Canvas c,
  String s,
  Offset center,
  double size,
  Color color, {
  bool bold = false,
  double opacity = 1,
}) {
  final key = '$s|${size.toStringAsFixed(1)}|${color.toARGB32()}|$bold';
  final tp = _textCache[key] ??= (TextPainter(
    text: TextSpan(
      text: s,
      style: TextStyle(
        fontSize: size,
        color: color,
        fontWeight: _textWeight(bold),
        height: 1,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout());
  if (_textCache.length > 400) _textCache.clear();
  if (opacity < 1) {
    c.saveLayer(null, Paint()..color = Color.fromRGBO(0, 0, 0, opacity));
    tp.paint(c, center - Offset(tp.width / 2, tp.height / 2));
    c.restore();
  } else {
    tp.paint(c, center - Offset(tp.width / 2, tp.height / 2));
  }
}

FontWeight _textWeight(bool bold) {
  if (bold) return FontWeight.w800;
  return FontWeight.w600;
}
