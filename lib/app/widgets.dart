import 'dart:math';

import 'package:flutter/material.dart';

import '../features/game/flame/pieces_painter.dart';
import 'theme.dart';

/// Nền chung: xanh ngọc đậm (tối) hoặc kem (sáng) với hoa văn mờ.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: dark
              ? const [AppColors.tealMid, AppColors.tealDeep]
              : const [AppColors.cream, AppColors.mint],
        ),
      ),
      child: CustomPaint(painter: _PatternPainter(dark), child: child),
    );
  }
}

class _PatternPainter extends CustomPainter {
  _PatternPainter(this.dark);
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = (dark ? Colors.white : AppColors.turquoise).withValues(
        alpha: dark ? 0.05 : 0.12,
      );
    const step = 56.0;
    for (var y = -step; y < size.height + step; y += step) {
      for (var x = -step; x < size.width + step; x += step) {
        final o = Offset(x + ((y / step).round().isOdd ? step / 2 : 0), y);
        canvas.drawCircle(o, step * 0.28, p);
      }
    }
  }

  @override
  bool shouldRepaint(_PatternPainter old) => old.dark != dark;
}

/// Logo: quan ngọc trên đế sen giữa vòng sỏi 4 màu.
class LogoMark extends StatelessWidget {
  const LogoMark({super.key, this.size = 120, this.spin = 0});
  final double size;
  final double spin;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(painter: _LogoPainter(spin)),
  );
}

class _LogoPainter extends CustomPainter {
  _LogoPainter(this.spin);
  final double spin;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    canvas.drawCircle(c, r * 0.98, Paint()..color = AppColors.wood);
    canvas.drawCircle(
      c,
      r * 0.9,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.04
        ..color = AppColors.groove.withValues(alpha: 0.5),
    );
    for (var i = 0; i < 12; i++) {
      final a = spin + i * pi / 6;
      PiecesPainter.stone(
        canvas,
        c + Offset.fromDirection(a, r * 0.72),
        r * 0.1,
        playerColors[i % 4],
      );
    }
    PiecesPainter.quanFigure(canvas, c, r * 0.4);
  }

  @override
  bool shouldRepaint(_LogoPainter old) => old.spin != spin;
}

/// Hình thu nhỏ bàn 2/3/4 người cho màn chọn.
class BoardShapeIcon extends StatelessWidget {
  const BoardShapeIcon({super.key, required this.players, this.size = 56});
  final int players;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(painter: _ShapePainter(players)),
  );
}

class _ShapePainter extends CustomPainter {
  _ShapePainter(this.n);
  final int n;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width * 0.42;
    final wood = Paint()..color = AppColors.wood;
    final List<Offset> verts;
    if (n == 2) {
      final rect = Rect.fromCenter(
        center: c,
        width: size.width * 0.95,
        height: size.height * 0.42,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(rect.height / 2)),
        wood,
      );
      verts = [
        rect.centerRight - Offset(rect.height * 0.35, 0),
        rect.centerLeft + Offset(rect.height * 0.35, 0),
      ];
      for (var p = 0; p < 2; p++) {
        for (var j = 0; j < 5; j++) {
          final x = rect.left + rect.width * (0.24 + j * 0.13);
          final y = c.dy + (p == 0 ? 1 : -1) * rect.height * 0.22;
          canvas.drawCircle(
            Offset(x, y),
            rect.height * 0.11,
            Paint()..color = playerColors[p],
          );
        }
      }
    } else {
      verts = [
        for (var p = 0; p < n; p++)
          c + Offset.fromDirection(pi / 2 - pi / n + p * 2 * pi / n, r),
      ];
      canvas.drawPath(Path()..addPolygon(verts, true), wood);
      for (var p = 0; p < n; p++) {
        final a = verts[p], b = verts[(p + 1) % n];
        for (var j = 0; j < 5; j++) {
          final t = (j + 1) / 6;
          canvas.drawCircle(
            Offset.lerp(a, b, t)!,
            size.width * 0.04,
            Paint()..color = playerColors[p],
          );
        }
      }
    }
    for (final v in verts) {
      canvas.drawCircle(
        v,
        size.width * 0.07,
        Paint()..color = const Color(0xFFE8325A),
      );
      canvas.drawCircle(
        v,
        size.width * 0.07,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = AppColors.gold,
      );
    }
  }

  @override
  bool shouldRepaint(_ShapePainter old) => old.n != n;
}

/// Chip biểu tượng người chơi (màu + hình dạng).
class PlayerAvatar extends StatelessWidget {
  const PlayerAvatar({
    super.key,
    required this.playerId,
    this.size = 32,
    this.ai = false,
    this.dimmed = false,
  });
  final int playerId;
  final double size;
  final bool ai;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final color = playerColors[playerId];
    return Opacity(
      opacity: dimmed ? 0.4 : 1,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: CustomPaint(
          painter: _SymbolPainter(symbolOf(playerId)),
          child: ai
              ? Icon(
                  Icons.smart_toy_rounded,
                  size: size * 0.5,
                  color: Colors.white,
                )
              : null,
        ),
      ),
    );
  }
}

class _SymbolPainter extends CustomPainter {
  _SymbolPainter(this.symbol);
  final PlayerSymbol symbol;

  @override
  void paint(Canvas canvas, Size size) {
    paintPlayerSymbol(
      canvas,
      Offset(size.width * 0.78, size.height * 0.78),
      size.width * 0.13,
      symbol,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(_SymbolPainter old) => old.symbol != symbol;
}
