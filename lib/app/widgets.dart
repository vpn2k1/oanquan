import 'dart:math';

import 'package:flutter/material.dart';

import '../features/game/flame/pieces_painter.dart';
import 'folk_icon.dart';
import 'theme.dart';

export 'folk_icon.dart';

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
    const step = 72.0;
    for (var y = -step; y < size.height + step; y += step) {
      for (var x = -step; x < size.width + step; x += step) {
        final o = Offset(x + ((y / step).round().isOdd ? step / 2 : 0), y);
        canvas.drawOval(
          Rect.fromCenter(
            center: o - const Offset(0, 9),
            width: 12,
            height: 22,
          ),
          p,
        );
        canvas.drawOval(
          Rect.fromCenter(
            center: o + const Offset(-8, 1),
            width: 12,
            height: 19,
          ),
          p,
        );
        canvas.drawOval(
          Rect.fromCenter(
            center: o + const Offset(8, 1),
            width: 12,
            height: 19,
          ),
          p,
        );
        canvas.drawArc(
          Rect.fromCenter(
            center: o + const Offset(0, 8),
            width: 32,
            height: 13,
          ),
          0,
          pi,
          false,
          p,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_PatternPainter old) => old.dark != dark;
}

/// Logo quan chibi đã chọn, dùng chung cho màn chào và màn chính.
class LogoMark extends StatelessWidget {
  const LogoMark({super.key, this.size = 120});
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.24),
      child: Image.asset('assets/app_icon.png', fit: BoxFit.cover),
    ),
  );
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
    final wood = Paint()..color = AppColors.woodLight;
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
            rect.height * 0.14,
            Paint()..color = AppColors.well,
          );
          PiecesPainter.stone(
            canvas,
            Offset(x, y),
            rect.height * 0.085,
            playerColors[p],
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
          final center = Offset.lerp(a, b, t)!;
          canvas.drawCircle(
            center,
            size.width * 0.06,
            Paint()..color = AppColors.well,
          );
          PiecesPainter.stone(
            canvas,
            center,
            size.width * 0.038,
            playerColors[p],
          );
        }
      }
    }
    for (final v in verts) {
      PiecesPainter.quanFigure(canvas, v, size.width * 0.09);
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
              ? FolkIcon(
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
