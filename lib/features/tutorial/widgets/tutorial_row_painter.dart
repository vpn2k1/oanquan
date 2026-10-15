import 'dart:math';

import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../game/flame/pieces_painter.dart';
import 'tutorial_step.dart';

double _markWidth(Color? markColor) {
  if (markColor == null) return 1.5;
  return 3;
}

Color _defaultMark(bool quan) {
  if (quan) return AppColors.gold;
  return playerColors[0];
}

class TutorialRowPainter extends CustomPainter {
  TutorialRowPainter(this.cells, this.arrows, this.note);
  final List<TutorialCell> cells;
  final bool arrows;
  final String? note;

  @override
  void paint(Canvas canvas, Size size) {
    final n = cells.length;
    final u = min(size.width / (n + 0.6), size.height / 1.9);
    final y = size.height / 2;
    final x0 = (size.width - u * n) / 2;
    final board = RRect.fromRectAndRadius(
      Rect.fromLTWH(x0 - u * 0.2, y - u * 0.7, u * n + u * 0.4, u * 1.4),
      Radius.circular(u * 0.7),
    );
    canvas.drawRRect(
      board.shift(Offset(0, u * 0.08)),
      Paint()..color = const Color(0x44000000),
    );
    canvas.drawRRect(board, Paint()..color = AppColors.wood);
    for (var i = 0; i < n; i++) {
      final c = cells[i];
      final center = Offset(x0 + u * (i + 0.5), y);
      final Rect rect;
      final Path shape;
      if (c.quan) {
        rect = Rect.fromCenter(
          center: center,
          width: u * 0.86,
          height: u * 1.2,
        );
        shape = Path()..addOval(rect);
      } else {
        rect = Rect.fromCenter(center: center, width: u * 0.8, height: u * 0.8);
        shape = Path()
          ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(u * 0.2)));
      }
      canvas.drawPath(shape, Paint()..color = AppColors.well);
      final markColor = switch (c.mark) {
        'src' => Colors.white,
        'gap' => const Color(0xFF3FE0C5),
        'eat' => AppColors.gold,
        'pick' => const Color(0xFF7FD1C4),
        'stop' => const Color(0xFFE5604D),
        _ => null,
      };
      canvas.drawPath(
        shape,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = _markWidth(markColor)
          ..color = markColor ?? _defaultMark(c.quan),
      );
      if (c.quan && c.token) {
        for (var k = 0; k < c.dan; k++) {
          final a = -pi / 2 + k * 2 * pi / max(c.dan, 1) + 0.3;
          PiecesPainter.pebble(
            canvas,
            center + Offset(cos(a) * u * 0.3, sin(a) * u * 0.45),
            u * 0.07,
            variant: k,
          );
        }
        PiecesPainter.quanStone(canvas, center, u * 0.2);
      } else {
        final pos = PiecesPainter.layout(c.dan, u * 0.26);
        for (var k = 0; k < pos.length; k++) {
          PiecesPainter.pebble(canvas, center + pos[k], u * 0.085, variant: k);
        }
      }
      if (c.dan > 0) {
        PiecesPainter.badge(
          canvas,
          center + Offset(u * 0.28, u * 0.3),
          u * 0.11,
          c.dan,
        );
      }
    }
    if (arrows) {
      final src = cells.indexWhere((c) => c.mark == 'src');
      final c = Offset(x0 + u * (src + 0.5), y + u * 0.95);
      final p = Paint()
        ..color = AppColors.teal
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      for (final d in [-1.0, 1.0]) {
        final a = c + Offset(d * u * 0.15, 0), b = c + Offset(d * u * 0.6, 0);
        canvas.drawLine(a, b, p);
        canvas.drawLine(b, b + Offset(-d * u * 0.15, -u * 0.12), p);
        canvas.drawLine(b, b + Offset(-d * u * 0.15, u * 0.12), p);
      }
    }
    if (note != null) {
      PiecesPainter.text(
        canvas,
        note!,
        Offset(size.width / 2, y - u * 0.95),
        u * 0.3,
        AppColors.gold,
        bold: true,
      );
    }
  }

  @override
  bool shouldRepaint(TutorialRowPainter old) => true;
}
