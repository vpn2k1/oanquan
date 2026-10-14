import 'dart:math';
import 'dart:ui';

import 'package:flutter/painting.dart' show TextPainter, TextSpan, TextStyle, FontWeight;

import '../../../app/theme.dart';

/// Vẽ quân bằng Canvas — không phụ thuộc file ảnh.
abstract final class PiecesPainter {
  static final _shadow = Paint()..color = const Color(0x55000000);
  static final _spec = Paint()..color = const Color(0xCCFFFFFF);

  /// Sỏi gốm tròn bóng nhẹ.
  static void stone(Canvas c, Offset p, double r, Color base, {double tint = 0}) {
    final col = tint == 0 ? base : Color.lerp(base, const Color(0xFFFFFFFF), tint)!;
    c.drawCircle(p + Offset(r * 0.18, r * 0.28), r * 0.98, _shadow);
    c.drawCircle(p, r, Paint()..color = Color.lerp(col, const Color(0xFF000000), 0.28)!);
    c.drawCircle(p - Offset(r * 0.1, r * 0.12), r * 0.86, Paint()..color = col);
    c.drawCircle(p - Offset(r * 0.28, r * 0.3), r * 0.42,
        Paint()..color = Color.lerp(col, const Color(0xFFFFFFFF), 0.35)!);
    c.drawCircle(p - Offset(r * 0.38, r * 0.42), r * 0.16, _spec);
  }

  static const _golden = 2.39996322972865332;

  /// Bố trí sỏi trong ô theo xoắn ốc vàng (deterministic).
  static List<Offset> layout(int count, double radius) {
    final n = min(count, 14);
    if (n == 1) return const [Offset.zero];
    return [
      for (var i = 0; i < n; i++)
        Offset.fromDirection(i * _golden + 0.6, radius * sqrt((i + 0.6) / n)),
    ];
  }

  static double stoneRadius(double cellSize, int count) =>
      cellSize * (count <= 4 ? 0.13 : count <= 9 ? 0.115 : 0.1);

  /// Quan: viên ngọc giác cắt trên đế hoa sen, khung đồng.
  static void quanGem(Canvas c, Offset p, double r, {double glow = 0}) {
    // Hào quang khi gợi ý / khi bị ăn.
    if (glow > 0) {
      c.drawCircle(
          p,
          r * (1.5 + glow * 0.4),
          Paint()
            ..color = const Color(0xFFFFE08A).withValues(alpha: 0.35 * glow)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    }
    // Đế sen: 8 cánh.
    final petal = Paint()..color = const Color(0xFFF3B6C4);
    final petalDark = Paint()..color = const Color(0xFFD9839A);
    for (var i = 0; i < 8; i++) {
      final a = i * pi / 4 + pi / 8;
      final cpos = p + Offset.fromDirection(a, r * 0.78);
      c.save();
      c.translate(cpos.dx, cpos.dy);
      c.rotate(a);
      c.drawOval(Rect.fromCenter(center: Offset.zero, width: r * 0.95, height: r * 0.52), petalDark);
      c.drawOval(Rect.fromCenter(center: const Offset(-1, -1), width: r * 0.8, height: r * 0.38), petal);
      c.restore();
    }
    // Khung đồng.
    c.drawCircle(p + Offset(0, r * 0.12), r * 0.78, _shadow);
    c.drawCircle(p, r * 0.76, Paint()..color = const Color(0xFF9C6B1E));
    c.drawCircle(p, r * 0.68, Paint()..color = AppColors.gold);
    // Ngọc bát giác giác cắt (hồng ngọc).
    final pts = [
      for (var i = 0; i < 8; i++) p + Offset.fromDirection(i * pi / 4 + pi / 8, r * 0.58),
    ];
    final gem = Path()..addPolygon(pts, true);
    c.drawPath(gem, Paint()..color = const Color(0xFF8E1230));
    const facets = [
      Color(0xFFE23A5E), Color(0xFFC21E45), Color(0xFFA5163A), Color(0xFFB81B41),
      Color(0xFFD42B52), Color(0xFFF0587A), Color(0xFFFF7C98), Color(0xFFEA4567),
    ];
    final inner = [
      for (var i = 0; i < 8; i++) p + Offset.fromDirection(i * pi / 4 + pi / 8, r * 0.3),
    ];
    for (var i = 0; i < 8; i++) {
      final f = Path()
        ..moveTo(pts[i].dx, pts[i].dy)
        ..lineTo(pts[(i + 1) % 8].dx, pts[(i + 1) % 8].dy)
        ..lineTo(inner[(i + 1) % 8].dx, inner[(i + 1) % 8].dy)
        ..lineTo(inner[i].dx, inner[i].dy)
        ..close();
      c.drawPath(f, Paint()..color = facets[i]);
    }
    c.drawPath(Path()..addPolygon(inner, true), Paint()..color = const Color(0xFFE8325A));
    c.drawCircle(p - Offset(r * 0.14, r * 0.16), r * 0.12, _spec);
    c.drawPath(
        gem,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = max(1, r * 0.05)
          ..color = const Color(0xFF5E0A1E));
  }

  /// Badge số lượng; ở chế độ hỗ trợ màu dùng hình dạng của chủ ô.
  static void badge(Canvas c, Offset p, double r, int value,
      {Color color = const Color(0xE62B1D10), PlayerSymbol? symbol}) {
    final paint = Paint()..color = color;
    if (symbol == null) {
      c.drawCircle(p, r, paint);
    } else {
      paintPlayerSymbol(c, p, r * 1.05, symbol, paint);
    }
    c.drawCircle(
        p,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = max(1, r * 0.12)
          ..color = const Color(0x99FFFFFF));
    text(c, '$value', p, r * 1.15, const Color(0xFFFFFFFF), bold: true);
  }

  static final Map<String, TextPainter> _textCache = {};

  static void text(Canvas c, String s, Offset center, double size, Color color,
      {bool bold = false, double opacity = 1}) {
    final key = '$s|${size.toStringAsFixed(1)}|${color.toARGB32()}|$bold';
    final tp = _textCache[key] ??= (TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(
          fontSize: size,
          color: color,
          fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
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
}
