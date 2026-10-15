import 'dart:math';

import 'package:flutter/painting.dart';

import 'ground_colors.dart';

void paintTiles(Canvas c, Size s, Random r) {
  // Sân gạch bát: gạch vuông đỏ, mạch vữa xám.
  c.drawRect(Offset.zero & s, Paint()..color = const Color(0xFF9E9282));
  final tile = (min(s.width, s.height) / 4.2).clamp(64.0, 130.0);
  const mortar = 4.0;
  final ox = -r.nextDouble() * tile, oy = -r.nextDouble() * tile;
  const palette = [
    Color(0xFFB4553A),
    Color(0xFFC0623F),
    Color(0xFFA84A32),
    Color(0xFFBC6B48),
    Color(0xFFAE5A3E),
  ];
  for (var y = oy; y < s.height; y += tile) {
    for (var x = ox; x < s.width; x += tile) {
      final rect = Rect.fromLTWH(
        x + mortar / 2,
        y + mortar / 2,
        tile - mortar,
        tile - mortar,
      );
      final base = Color.lerp(
        palette[r.nextInt(palette.length)],
        const Color(0xFF8C3F2A),
        r.nextDouble() * 0.25,
      )!;
      final rr = RRect.fromRectAndRadius(rect, const Radius.circular(3));
      c.drawRRect(
        rr,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(base, const Color(0xFFFFFFFF), 0.08)!,
              base,
              Color.lerp(base, const Color(0xFF000000), 0.12)!,
            ],
          ).createShader(rect),
      );
      c.save();
      c.clipRRect(rr);
      // Mòn, rỗ mặt gạch.
      final p = Paint();
      for (var i = 0; i < (tile * tile / 90).round(); i++) {
        p.color = pitColor(r).withValues(alpha: 0.12 + r.nextDouble() * 0.25);
        c.drawCircle(
          rect.topLeft +
              Offset(r.nextDouble() * rect.width, r.nextDouble() * rect.height),
          0.4 + r.nextDouble() * 1.3,
          p,
        );
      }
      for (var i = 0; i < 3; i++) {
        p
          ..color = randomOf(
            r,
            const Color(0xFF5A2414),
            const Color(0xFFE8B090),
          ).withValues(alpha: 0.08)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, tile * 0.12);
        c.drawCircle(
          rect.topLeft +
              Offset(r.nextDouble() * rect.width, r.nextDouble() * rect.height),
          tile * (0.15 + r.nextDouble() * 0.25),
          p,
        );
        p.maskFilter = null;
      }
      // Mẻ góc.
      if (r.nextDouble() < 0.25) {
        final corner = [
          rect.topLeft,
          rect.topRight,
          rect.bottomLeft,
          rect.bottomRight,
        ][r.nextInt(4)];
        c.drawCircle(
          corner,
          3 + r.nextDouble() * 6,
          Paint()..color = const Color(0xFF9E9282),
        );
      }
      c.restore();
    }
  }
  // Rêu trong mạch vữa.
  final moss = Paint();
  for (var i = 0; i < (s.width * s.height / 5000).round(); i++) {
    final onX = r.nextBool();
    final gx = ox + (r.nextInt((s.width / tile).ceil() + 2)) * tile;
    final gy = oy + (r.nextInt((s.height / tile).ceil() + 2)) * tile;
    Offset at;
    if (onX) {
      at = Offset(gx + r.nextDouble() * tile, gy);
    } else {
      at = Offset(gx, gy + r.nextDouble() * tile);
    }
    moss.color = const Color(
      0xFF5E7A3A,
    ).withValues(alpha: 0.25 + r.nextDouble() * 0.35);
    c.drawCircle(at, 1 + r.nextDouble() * 2.2, moss);
  }
}
