import 'dart:math';
import 'dart:ui';

import 'package:flutter/painting.dart'
    show TextPainter, TextSpan, TextStyle, FontWeight;

import '../../../app/theme.dart';

/// Vẽ quân bằng Canvas — không phụ thuộc file ảnh.
abstract final class PiecesPainter {
  static final _shadow = Paint()..color = const Color(0x44000000);
  static final _ink = Paint()..color = const Color(0xFF38281E);

  /// Viên bi gốm có khuôn mặt nhỏ; vẫn rõ màu khi vẽ nhiều viên trong một ô.
  static void stone(
    Canvas c,
    Offset p,
    double r,
    Color base, {
    double tint = 0,
  }) {
    final col = tint == 0
        ? base
        : Color.lerp(base, const Color(0xFFFFFFFF), tint)!;
    c.save();
    c.translate(p.dx, p.dy);
    c.scale(r);
    c.drawCircle(const Offset(0.12, 0.18), 0.99, _shadow);
    c.drawCircle(
      Offset.zero,
      1,
      Paint()..color = Color.lerp(col, _ink.color, 0.42)!,
    );
    c.drawCircle(
      const Offset(-0.07, -0.09),
      0.87,
      Paint()
        ..shader = Gradient.radial(
          const Offset(-0.38, -0.48),
          1.45,
          [
            Color.lerp(col, const Color(0xFFFFFFFF), 0.42)!,
            col,
            Color.lerp(col, _ink.color, 0.25)!,
          ],
          const [0, 0.58, 1],
        ),
    );
    c.drawArc(
      const Rect.fromLTRB(-0.76, -0.8, 0.28, 0.13),
      3.6,
      1.4,
      false,
      Paint()
        ..color = const Color(0x88FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.1
        ..strokeCap = StrokeCap.round,
    );
    if (r >= 5) {
      c.drawCircle(const Offset(-0.28, 0.12), 0.105, _ink);
      c.drawCircle(const Offset(0.28, 0.12), 0.105, _ink);
      c.drawArc(
        const Rect.fromLTRB(-0.19, 0.2, 0.19, 0.48),
        0.12,
        pi - 0.24,
        false,
        Paint()
          ..color = _ink.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.075
          ..strokeCap = StrokeCap.round,
      );
      c.drawCircle(
        const Offset(-0.53, 0.34),
        0.105,
        Paint()..color = const Color(0x88F48B78),
      );
      c.drawCircle(
        const Offset(0.53, 0.34),
        0.105,
        Paint()..color = const Color(0x88F48B78),
      );
    }
    c.restore();
  }

  /// Bảng màu sỏi tự nhiên: xám, be, trắng ngà, xám xanh, nâu nhạt.
  static const _pebbleColors = [
    Color(0xFF9E9A92),
    Color(0xFFC9C1B2),
    Color(0xFFE6DFD2),
    Color(0xFF7E7A74),
    Color(0xFFB9A88F),
    Color(0xFFA7AEB0),
    Color(0xFFD5CBB8),
  ];

  /// Viên sỏi tự nhiên. `variant` quyết định màu, độ dẹt, góc xoay, đốm —
  /// cùng variant luôn vẽ giống nhau (không nhấp nháy khi animate).
  static void pebble(Canvas c, Offset p, double r, {int variant = 0}) {
    final h = (variant * 2654435761) & 0x7fffffff;
    final base = _pebbleColors[h % _pebbleColors.length];
    final stretch = 1.05 + ((h >> 4) % 25) / 100; // 1.05..1.29
    final rot = ((h >> 9) % 628) / 100;
    c.save();
    c.translate(p.dx, p.dy);
    c.rotate(rot);
    c.scale(r * stretch, r / stretch * 1.08);
    // Bóng đổ.
    c.save();
    c.rotate(-rot);
    c.drawOval(const Rect.fromLTRB(-0.95, -0.7, 1.15, 1.25), Paint()..color = const Color(0x55000000));
    c.restore();
    // Thân sỏi.
    final body = Path()
      ..moveTo(-1, 0.05)
      ..cubicTo(-1, -0.62, -0.5, -1, 0.08, -0.98)
      ..cubicTo(0.7, -0.95, 1.02, -0.5, 1, 0.04)
      ..cubicTo(0.98, 0.62, 0.52, 0.98, -0.04, 0.97)
      ..cubicTo(-0.62, 0.95, -1, 0.6, -1, 0.05)
      ..close();
    c.drawPath(
      body,
      Paint()
        ..shader = Gradient.radial(
          const Offset(-0.35, -0.45),
          1.5,
          [
            Color.lerp(base, const Color(0xFFFFFFFF), 0.35)!,
            base,
            Color.lerp(base, const Color(0xFF2A241E), 0.38)!,
          ],
          const [0, 0.55, 1],
        ),
    );
    // Đốm khoáng.
    final dot = Paint();
    for (var k = 0; k < 4; k++) {
      final hh = (h >> (k * 5)) & 0x3ff;
      final o = Offset(((hh % 100) / 100 - 0.5) * 1.2, (((hh >> 3) % 100) / 100 - 0.5) * 1.1);
      dot.color = (k.isEven ? const Color(0x33231E18) : const Color(0x40FFFFFF));
      c.drawCircle(o, 0.06 + (hh % 7) / 100, dot);
    }
    // Vân sáng.
    c.drawArc(
      const Rect.fromLTRB(-0.72, -0.78, 0.3, 0.1),
      3.5,
      1.3,
      false,
      Paint()
        ..color = const Color(0x66FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.12
        ..strokeCap = StrokeCap.round,
    );
    c.restore();
  }

  /// Quan: hòn đá nâu đỏ lớn, mặt nhẵn bóng.
  static void quanStone(Canvas c, Offset p, double r, {double glow = 0}) {
    if (glow > 0) {
      c.drawCircle(
        p,
        r * 1.5,
        Paint()
          ..color = const Color(0xFFFF8F3A).withValues(alpha: 0.45 * glow)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.5),
      );
    }
    c.save();
    c.translate(p.dx, p.dy);
    c.scale(r * 1.12, r * 0.92);
    c.drawOval(const Rect.fromLTRB(-0.95, -0.72, 1.12, 1.22), Paint()..color = const Color(0x66000000));
    final body = Path()
      ..moveTo(-1, 0)
      ..cubicTo(-1, -0.66, -0.48, -1, 0.1, -0.98)
      ..cubicTo(0.72, -0.94, 1, -0.48, 1, 0.06)
      ..cubicTo(1, 0.66, 0.5, 1, -0.06, 0.98)
      ..cubicTo(-0.66, 0.95, -1, 0.56, -1, 0)
      ..close();
    c.drawPath(
      body,
      Paint()
        ..shader = Gradient.radial(
          const Offset(-0.32, -0.42),
          1.55,
          const [Color(0xFFB0735A), Color(0xFF7E4A36), Color(0xFF4A2A1E)],
          const [0, 0.55, 1],
        ),
    );
    final vein = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.04
      ..color = const Color(0x33FFE3CC);
    c.drawPath(
      Path()
        ..moveTo(-0.7, 0.35)
        ..quadraticBezierTo(-0.1, 0.05, 0.62, 0.42),
      vein,
    );
    c.drawArc(
      const Rect.fromLTRB(-0.72, -0.8, 0.25, 0.05),
      3.5,
      1.3,
      false,
      Paint()
        ..color = const Color(0x77FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.1
        ..strokeCap = StrokeCap.round,
    );
    c.restore();
  }

  /// Số lượng kiểu Recess: chữ kem nhỏ, có viền tối để đọc rõ trên mọi mặt sân.
  static void count(Canvas c, Offset p, double size, int value) {
    final s = '$value';
    for (final o in const [Offset(0, 1.2), Offset(1, 0), Offset(-1, 0), Offset(0, -1)]) {
      text(c, s, p + o * (size * 0.08), size, const Color(0xCC1B1410), bold: true);
    }
    text(c, s, p, size, const Color(0xFFFFF3E2), bold: true);
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
      cellSize *
      (count <= 4
          ? 0.13
          : count <= 9
          ? 0.115
          : 0.1);

  /// Quan chibi mặc áo truyền thống, đội khăn xếp, ngồi trên đài sen.
  static void quanFigure(Canvas c, Offset p, double r, {double glow = 0}) {
    if (glow > 0) {
      c.drawCircle(
        p,
        r * (1.5 + glow * 0.4),
        Paint()
          ..color = const Color(0xFFFFE08A).withValues(alpha: 0.35 * glow)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }
    c.save();
    c.translate(p.dx, p.dy);
    c.scale(r);
    const gold = Color(0xFFFFCD5B);
    const red = Color(0xFFB73343);
    const deepRed = Color(0xFF7E2537);
    const skin = Color(0xFFFFD6AC);
    // Cánh sen và đế tách khỏi áo để hình đọc rõ ở kích thước nhỏ.
    c.drawOval(const Rect.fromLTRB(-1.03, 0.64, 1.03, 1.05), _shadow);
    for (var i = -2; i <= 2; i++) {
      c.drawOval(
        Rect.fromCenter(
          center: Offset(i * 0.36, 0.68),
          width: 0.55,
          height: 0.42,
        ),
        Paint()
          ..color = i.isEven
              ? const Color(0xFFFFB6A6)
              : const Color(0xFFF28D8C),
      );
    }
    c.drawOval(
      const Rect.fromLTRB(-0.85, 0.64, 0.85, 0.9),
      Paint()..color = const Color(0xFFFFD990),
    );
    // Áo dài với nẹp vàng và tay áo xòe.
    final robe = Path()
      ..moveTo(-0.5, 0.12)
      ..quadraticBezierTo(-0.8, 0.28, -0.75, 0.7)
      ..quadraticBezierTo(0, 0.91, 0.75, 0.7)
      ..quadraticBezierTo(0.8, 0.28, 0.5, 0.12)
      ..close();
    c.drawPath(robe, Paint()..color = deepRed);
    c.drawOval(
      const Rect.fromLTRB(-0.72, 0.22, 0.72, 0.79),
      Paint()..color = red,
    );
    c.drawPath(
      Path()
        ..moveTo(-0.19, 0.17)
        ..lineTo(0, 0.31)
        ..lineTo(0.19, 0.17),
      Paint()
        ..color = gold
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.09
        ..strokeJoin = StrokeJoin.round,
    );
    c.drawLine(
      const Offset(0, 0.31),
      const Offset(0, 0.69),
      Paint()
        ..color = gold
        ..strokeWidth = 0.075,
    );
    c.drawCircle(const Offset(0, 0.49), 0.055, Paint()..color = gold);
    // Mặt tròn, tóc và khăn xếp gợi hình ông quan dân gian.
    c.drawCircle(const Offset(0, -0.32), 0.61, Paint()..color = deepRed);
    c.drawCircle(const Offset(0, -0.29), 0.54, Paint()..color = skin);
    c.drawOval(
      const Rect.fromLTRB(-0.52, -0.94, 0.52, -0.52),
      Paint()..color = deepRed,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTRB(-0.66, -0.82, 0.66, -0.56),
        const Radius.circular(0.12),
      ),
      Paint()..color = red,
    );
    c.drawLine(
      const Offset(-0.53, -0.69),
      const Offset(0.53, -0.69),
      Paint()
        ..color = gold
        ..strokeWidth = 0.075,
    );
    c.drawCircle(const Offset(0, -0.7), 0.08, Paint()..color = gold);
    c.drawCircle(const Offset(-0.22, -0.29), 0.055, _ink);
    c.drawCircle(const Offset(0.22, -0.29), 0.055, _ink);
    c.drawCircle(
      const Offset(-0.4, -0.12),
      0.09,
      Paint()..color = const Color(0x99F28F83),
    );
    c.drawCircle(
      const Offset(0.4, -0.12),
      0.09,
      Paint()..color = const Color(0x99F28F83),
    );
    c.drawArc(
      const Rect.fromLTRB(-0.15, -0.2, 0.15, 0.04),
      0.15,
      pi - 0.3,
      false,
      Paint()
        ..color = _ink.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.055
        ..strokeCap = StrokeCap.round,
    );
    c.restore();
  }

  /// Badge số lượng; ở chế độ hỗ trợ màu dùng hình dạng của chủ ô.
  static void badge(
    Canvas c,
    Offset p,
    double r,
    int value, {
    Color color = const Color(0xE6603A16),
    PlayerSymbol? symbol,
  }) {
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
        ..color = const Color(0x99FFFFFF),
    );
    text(c, '$value', p, r * 1.15, const Color(0xFFFFFFFF), bold: true);
  }

  static final Map<String, TextPainter> _textCache = {};

  static void text(
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
