import 'package:flutter/material.dart';

import '../theme.dart';

/// Bút vẽ biểu tượng trên lưới 24x24: gom canvas, ba loại nét và các hàm vẽ nhanh.
class IconPen {
  IconPen(this.canvas, Color color)
    : ink = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.1
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
      fill = Paint()..color = color,
      gold = Paint()..color = Color.lerp(color, AppColors.gold, 0.65)!;

  final Canvas canvas;

  /// Nét viền tròn đầu.
  final Paint ink;

  /// Nét tô đặc cùng màu.
  final Paint fill;

  /// Nét nhấn ánh vàng.
  final Paint gold;

  void line(double x1, double y1, double x2, double y2, [Paint? paint]) =>
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint ?? ink);

  void dot(double x, double y, double radius, [Paint? paint]) =>
      canvas.drawCircle(Offset(x, y), radius, paint ?? fill);

  void oval(
    double left,
    double top,
    double right,
    double bottom, [
    Paint? paint,
  ]) => canvas.drawOval(Rect.fromLTRB(left, top, right, bottom), paint ?? ink);

  void poly(List<Offset> points, {bool close = false, Paint? paint}) {
    final path = Path()..addPolygon(points, close);
    canvas.drawPath(path, paint ?? ink);
  }

  void rounded(
    double left,
    double top,
    double right,
    double bottom,
    double radius, [
    Paint? paint,
  ]) => canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTRB(left, top, right, bottom),
      Radius.circular(radius),
    ),
    paint ?? ink,
  );
}
