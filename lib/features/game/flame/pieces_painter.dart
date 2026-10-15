import 'dart:math';
import 'dart:ui';
import 'dart:ui' as ui show instantiateImageCodec;

import 'package:flutter/services.dart';

import '../../../app/theme.dart';
import 'pieces_text.dart';
import 'quan_figure_painter.dart';

/// Vẽ quân trên Canvas bằng ảnh, với hình vẽ dự phòng khi ảnh chưa tải.
abstract final class PiecesPainter {
  static Image? _pebbleAtlas;
  static Image? _quanImage;

  static Future<void> loadPieces() async {
    _pebbleAtlas = await _loadImage('assets/pebbles.png');
    _quanImage = await _loadImage('assets/quan_stone.png');
  }

  static Future<Image> _loadImage(String path) async {
    final data = await rootBundle.load(path);
    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
    final image = (await codec.getNextFrame()).image;
    codec.dispose();
    return image;
  }

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
    var col = base;
    if (tint != 0) col = Color.lerp(base, const Color(0xFFFFFFFF), tint)!;
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
    Color(0xFF8F938F),
    Color(0xFFD4AE79),
    Color(0xFF71948C),
    Color(0xFFD5CBB8),
  ];

  /// Viên sỏi tự nhiên. `variant` quyết định màu, dáng, góc xoay, vân —
  /// cùng variant luôn vẽ giống nhau (không nhấp nháy khi animate).
  static void pebble(Canvas c, Offset p, double r, {int variant = 0}) {
    final atlas = _pebbleAtlas;
    if (atlas != null) {
      final half = atlas.width / 2;
      final index = variant.abs() % 4;
      final source = Rect.fromLTWH(
        (index % 2) * half,
        (index ~/ 2) * half,
        half,
        atlas.height / 2,
      );
      c.drawImageRect(
        atlas,
        source,
        Rect.fromCenter(center: p, width: r * 3.7, height: r * 3.7),
        Paint()..filterQuality = FilterQuality.medium,
      );
      return;
    }
    final h = (variant * 2654435761) & 0x7fffffff;
    final base = _pebbleColors[h % _pebbleColors.length];
    final stretch = 1.02 + ((h >> 4) % 23) / 100;
    final rot = ((h >> 9) % 628) / 100;
    final skew = ((h >> 15) % 21 - 10) / 100;
    c.save();
    c.translate(p.dx, p.dy);
    c.rotate(rot);
    c.scale(r * stretch, r / stretch);
    final body = Path()
      ..moveTo(-0.96, -0.12)
      ..cubicTo(-0.94, -0.67, -0.5 + skew, -0.98, 0.04, -0.94)
      ..cubicTo(0.58, -1.03, 0.99, -0.63, 0.96, -0.13)
      ..cubicTo(1.08, 0.34, 0.62 - skew, 0.91, 0.12, 0.96)
      ..cubicTo(-0.48, 1.02, -1.06, 0.62, -0.96, -0.12)
      ..close();
    c.drawPath(
      body.shift(const Offset(0.1, 0.17)),
      Paint()..color = const Color(0x55000000),
    );
    c.drawPath(
      body,
      Paint()
        ..shader = Gradient.radial(
          const Offset(-0.4, -0.55),
          1.55,
          [
            Color.lerp(base, const Color(0xFFFFFFFF), 0.43)!,
            base,
            Color.lerp(base, const Color(0xFF2A241E), 0.46)!,
          ],
          const [0, 0.53, 1],
        ),
    );
    c.drawPath(
      body,
      Paint()
        ..color = Color.lerp(base, const Color(0xFF35291D), 0.4)!
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.055,
    );
    // Vân khoáng rất nhẹ, vẫn đọc được khi quân thu nhỏ.
    final dot = Paint();
    for (var k = 0; k < 3; k++) {
      final hh = (h >> (k * 5)) & 0x3ff;
      final o = Offset(
        ((hh % 100) / 100 - 0.5) * 0.9,
        (((hh >> 3) % 100) / 100 - 0.5) * 0.8,
      );
      if (k.isEven) {
        dot.color = const Color(0x26FFFFFF);
      } else {
        dot.color = const Color(0x24231E18);
      }
      c.drawOval(
        Rect.fromCenter(center: o, width: 0.13 + (hh % 7) / 100, height: 0.045),
        dot,
      );
    }
    c.drawArc(
      const Rect.fromLTRB(-0.75, -0.78, 0.38, 0.2),
      3.55,
      1.15,
      false,
      Paint()
        ..color = const Color(0x99FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.1
        ..strokeCap = StrokeCap.round,
    );
    c.restore();
  }

  /// Quan: hòn đá đất nung lớn, có hoa sen khắc để phân biệt với dân.
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
    final quanImage = _quanImage;
    if (quanImage != null) {
      c.drawImageRect(
        quanImage,
        Rect.fromLTWH(
          0,
          0,
          quanImage.width.toDouble(),
          quanImage.height.toDouble(),
        ),
        Rect.fromCenter(center: p, width: r * 2.9, height: r * 2.9),
        Paint()..filterQuality = FilterQuality.medium,
      );
      return;
    }
    c.save();
    c.translate(p.dx, p.dy);
    c.scale(r * 1.12, r * 0.92);
    final body = Path()
      ..moveTo(-0.99, -0.08)
      ..cubicTo(-0.98, -0.68, -0.5, -1, 0.1, -0.98)
      ..cubicTo(0.71, -0.99, 1.01, -0.53, 0.99, 0.02)
      ..cubicTo(1.04, 0.64, 0.55, 0.99, -0.04, 0.97)
      ..cubicTo(-0.66, 1, -1.04, 0.55, -0.99, -0.08)
      ..close();
    c.drawPath(
      body.shift(const Offset(0.1, 0.18)),
      Paint()..color = const Color(0x66000000),
    );
    c.drawPath(
      body,
      Paint()
        ..shader = Gradient.radial(
          const Offset(-0.4, -0.53),
          1.55,
          const [Color(0xFFEAA775), Color(0xFFBA6140), Color(0xFF713521)],
          const [0, 0.56, 1],
        ),
    );
    c.drawPath(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.065
        ..color = const Color(0xFF67301F),
    );
    // Ba cánh sen khắc chìm; ít nét để còn rõ trong ô quan nhỏ.
    final lotus = Path()
      ..moveTo(0, 0.29)
      ..quadraticBezierTo(-0.25, -0.03, 0, -0.4)
      ..quadraticBezierTo(0.25, -0.03, 0, 0.29)
      ..moveTo(-0.02, 0.27)
      ..quadraticBezierTo(-0.42, 0.17, -0.42, -0.2)
      ..quadraticBezierTo(-0.15, -0.1, -0.02, 0.27)
      ..moveTo(0.02, 0.27)
      ..quadraticBezierTo(0.42, 0.17, 0.42, -0.2)
      ..quadraticBezierTo(0.15, -0.1, 0.02, 0.27);
    c.drawPath(
      lotus.shift(const Offset(0.025, 0.04)),
      Paint()
        ..color = const Color(0x88F7C59B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.075
        ..strokeCap = StrokeCap.round,
    );
    c.drawPath(
      lotus,
      Paint()
        ..color = const Color(0x996A2E20)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.075
        ..strokeCap = StrokeCap.round,
    );
    c.drawArc(
      const Rect.fromLTRB(-0.72, -0.8, 0.25, 0.05),
      3.5,
      1.1,
      false,
      Paint()
        ..color = const Color(0x88FFE5C6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.1
        ..strokeCap = StrokeCap.round,
    );
    c.restore();
  }

  /// Số lượng kiểu Recess: chữ kem nhỏ, có viền tối để đọc rõ trên mọi mặt sân.
  static void count(Canvas c, Offset p, double size, int value) {
    final s = '$value';
    for (final o in const [
      Offset(0, 1.2),
      Offset(1, 0),
      Offset(-1, 0),
      Offset(0, -1),
    ]) {
      text(
        c,
        s,
        p + o * (size * 0.08),
        size,
        const Color(0xCC1B1410),
        bold: true,
      );
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

  static double stoneRadius(double cellSize, int count) {
    if (count <= 4) return cellSize * 0.13;
    if (count <= 9) return cellSize * 0.115;
    return cellSize * 0.1;
  }

  /// Quan chibi mặc áo truyền thống, đội khăn xếp, ngồi trên đài sen.
  static void quanFigure(Canvas c, Offset p, double r, {double glow = 0}) =>
      paintQuanFigure(c, p, r, glow: glow);

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

  static void text(
    Canvas c,
    String s,
    Offset center,
    double size,
    Color color, {
    bool bold = false,
    double opacity = 1,
  }) => paintCenteredText(
    c,
    s,
    center,
    size,
    color,
    bold: bold,
    opacity: opacity,
  );
}
