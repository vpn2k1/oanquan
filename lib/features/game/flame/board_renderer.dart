import 'dart:math';
import 'dart:ui';

import '../../../app/theme.dart';
import '../../../core/game_models/move.dart';
import 'board_game.dart';
import 'board_geometry.dart';
import 'board_raster.dart';
import 'pieces_painter.dart';

/// Vẽ động: ô, quân, đống quân ăn.
extension BoardRenderer on OQuanGame {
  void paintBoard(Canvas canvas) {
    final g = geo;
    if (g == null) return;
    final img = boardImage ??= rasterStatic(g);
    canvas.drawImageRect(
      img,
      Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
      Rect.fromLTWH(0, 0, size.x, size.y),
      Paint()..filterQuality = FilterQuality.medium,
    );
    renderPiles(canvas, g);
    final u = g.unit;

    // Dải màu người đến lượt sáng lên.
    if (!state.isOver) {
      final (a, b) = g.playerEdges[state.turnPlayer];
      final glow = 0.55 + 0.35 * sin(clock * 3);
      canvas.drawLine(
        a,
        b,
        Paint()
          ..color = playerColors[state.turnPlayer].withValues(alpha: glow)
          ..strokeWidth = u * 0.2
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }

    for (final c in g.cells) {
      final i = c.id;
      if (hoverCell == i && legal.contains(i)) {
        canvas.drawPath(c.outline, Paint()..color = const Color(0x22FFFFFF));
      }
      if (flash[i] > 0) {
        canvas.drawPath(
          c.outline,
          Paint()..color = AppColors.gold.withValues(alpha: 0.55 * flash[i]),
        );
      }
      if (legal.contains(i)) {
        final a = 0.5 + 0.4 * (0.5 + 0.5 * sin(clock * 4.2 + i * 0.3));
        canvas.drawPath(
          c.outline,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = max(3, u * 0.1)
            ..color = const Color(0xFF3A2410).withValues(alpha: a * 0.35),
        );
        canvas.drawPath(
          c.outline,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = max(2, u * 0.055)
            ..color = const Color(0xFFFFD447).withValues(alpha: a),
        );
      }
      if (hint?.sourceCellId == i) {
        final a = 0.5 + 0.5 * sin(clock * 6);
        canvas.drawPath(
          c.outline,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = max(3, u * 0.09)
            ..color = const Color(0xFF3FE0C5).withValues(alpha: a),
        );
      }
      if (selected == i) {
        canvas.drawPath(
          c.outline,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = max(5, u * 0.16)
            ..color = const Color(0x66000000),
        );
        canvas.drawPath(
          c.outline,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = max(3, u * 0.1)
            ..color = const Color(0xFFFFFFFF),
        );
      }
      renderCellContents(canvas, c, u);
    }

    // Gợi ý hướng.
    final h = hint;
    if (h != null && selected == null) {
      final (cw, ccw) = g.arrowPositions(h.sourceCellId);
      var p = ccw;
      if (h.direction == Direction.clockwise) p = cw;
      final t =
          g.cells[h.sourceCellId].tangentCw * (h.direction.step.toDouble());
      final a = 0.6 + 0.4 * sin(clock * 6);
      final paint = Paint()
        ..color = const Color(0xFF3FE0C5).withValues(alpha: a)
        ..strokeWidth = max(3, u * 0.1)
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      final tip = p + t * (u * 0.3);
      final n = Offset(-t.dy, t.dx);
      canvas.drawLine(p - t * (u * 0.3), tip, paint);
      canvas.drawLine(tip, tip - t * (u * 0.18) + n * (u * 0.16), paint);
      canvas.drawLine(tip, tip - t * (u * 0.18) - n * (u * 0.16), paint);
    }

    // Dân đang cầm trên tay.
    if (handCell != null && handCount > 0) {
      final p = handPos - Offset(0, u * 0.45);
      final r = u * 0.1;
      for (var k = 0; k < min(handCount, 5); k++) {
        PiecesPainter.pebble(
          canvas,
          p + Offset.fromDirection(k * 2.4, r * 0.9 * sqrt(k.toDouble())),
          r,
          variant: 900 + k,
        );
      }
      PiecesPainter.badge(
        canvas,
        p + Offset(u * 0.26, -u * 0.12),
        max(8, u * 0.15),
        handCount,
        color: const Color(0xF0FF8F3A),
      );
    }
  }

  /// Đống quân đã ăn của từng người: quan (đá nâu) đầu hàng, rồi sỏi; số điểm cuối hàng.
  void renderPiles(Canvas canvas, BoardGeometry g) {
    final r = g.pebbleRadius;
    final scores = displayScores.value;
    for (var p = 0; p < g.playerPiles.length && p < pileQuan.length; p++) {
      for (var q = 0; q < pileQuan[p]; q++) {
        PiecesPainter.quanStone(canvas, g.pileSlot(p, q * 3 + 1), r * 1.92);
      }
      final n = min(pileDan(p), 60);
      final start = pileQuan[p] * 3;
      for (var k = 0; k < n; k++) {
        PiecesPainter.pebble(
          canvas,
          g.pileSlot(p, start + k),
          r,
          variant: p * 997 + k,
        );
      }
      if (p < scores.length) {
        PiecesPainter.count(
          canvas,
          g.pileLabel(p),
          max(11, g.unit * 0.26),
          scores[p],
        );
      }
    }
  }

  void renderCellContents(Canvas canvas, CellGeometry c, double u) {
    final i = c.id;
    final count = dan[i];
    final bounce = 1 + 0.22 * sin(pulse[i] * pi);
    if (c.isQuan) {
      final b = c.outline.getBounds();
      final rx = b.width / 2, ry = b.height / 2;
      final gemR = min(rx, ry) * 0.6;
      final n = min(count, 12);
      final sr = u * 0.095;
      var spread = 0.6;
      if (n > 6) spread = 1;
      var ringX = rx * 0.45 * spread;
      var ringY = ry * 0.45 * spread;
      if (quan[i]) {
        ringX = rx * 0.74;
        ringY = ry * 0.74;
      }
      for (var k = 0; k < n; k++) {
        final a = -pi / 2 + k * 2 * pi / max(n, 1) + 0.3;
        final p = c.center + Offset(cos(a) * ringX, sin(a) * ringY);
        PiecesPainter.pebble(canvas, p, sr * bounce, variant: i * 37 + k);
      }
      if (quan[i]) {
        PiecesPainter.quanStone(
          canvas,
          c.center,
          gemR * 0.85 * bounce,
          glow: flash[i],
        );
      }
      if (count > 0) {
        PiecesPainter.count(canvas, c.labelAnchor, max(10, u * 0.24), count);
      }
      return;
    }
    if (count > 0) {
      final positions = PiecesPainter.layout(count, c.size * 0.3);
      final r = PiecesPainter.stoneRadius(c.size, count) * bounce;
      for (var k = 0; k < positions.length; k++) {
        PiecesPainter.pebble(
          canvas,
          c.center + positions[k],
          r,
          variant: i * 37 + k,
        );
      }
      final owner = topo.ownerOf(i)!;
      if (visuals.colorBlind) {
        PiecesPainter.badge(
          canvas,
          c.labelAnchor,
          max(8, u * 0.15),
          count,
          symbol: symbolOf(owner),
          color: Color.lerp(
            playerColors[owner],
            const Color(0xFF000000),
            0.35,
          )!,
        );
      } else {
        PiecesPainter.count(canvas, c.labelAnchor, max(10, u * 0.22), count);
      }
    }
  }
}
