import 'dart:math';

import 'package:flutter/material.dart';

import '../features/game/flame/pieces_painter.dart';
import 'folk_art.dart';
import 'folk_icon.dart';
import 'theme.dart';

export 'folk_icon.dart';

/// Nền các màn menu: sân đất sỏi (sẫm khi tối, sáng khi sáng), cố định seed
/// nên không đổi giữa các màn. `plain` = nền lưới chấm (màn chơi, nơi khay
/// bàn đã có mặt sân riêng).
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child, this.plain = false});
  final Widget child;
  final bool plain;

  static const _seed = 20261015;

  @override
  Widget build(BuildContext context) {
    final t = RcTokens.of(context);
    if (plain) {
      return ColoredBox(
        color: t.bg,
        child: CustomPaint(painter: DotGridPainter(t.dark), child: child),
      );
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          child: CustomPaint(
            painter: GroundPainter(
              t.dark ? GroundKind.darkDirt : GroundKind.dirt,
              _seed,
            ),
          ),
        ),
        // Tối nhẹ các góc để mắt dồn vào giữa.
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              radius: 1.2,
              colors: [Color(0x00000000), Color(0x59000000)],
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class DotGridPainter extends CustomPainter {
  DotGridPainter(this.dark);
  final bool dark;

  static void paintGrid(Canvas canvas, Size size, bool dark) {
    final p = Paint()
      ..color = (dark ? Rc.text : Rc.textLight).withValues(
        alpha: dark ? 0.07 : 0.08,
      );
    const step = 14.0;
    for (var y = step / 2; y < size.height; y += step) {
      for (var x = step / 2; x < size.width; x += step) {
        canvas.drawCircle(Offset(x, y), 1.1, p);
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size) => paintGrid(canvas, size, dark);

  @override
  bool shouldRepaint(DotGridPainter old) => old.dark != dark;
}

/// Vẽ mặt sân từ ảnh đã raster hóa (cache).
class GroundPainter extends CustomPainter {
  GroundPainter(this.kind, this.seed);
  final GroundKind kind;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final dpr =
        WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;
    final img = GroundCache.image(size, dpr, kind, seed);
    canvas.drawImageRect(
      img,
      Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
      Offset.zero & size,
      Paint()..filterQuality = FilterQuality.medium,
    );
  }

  @override
  bool shouldRepaint(GroundPainter old) => old.kind != kind || old.seed != seed;
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
          PiecesPainter.pebble(
            canvas,
            Offset(x, y),
            rect.height * 0.085,
            variant: p * 5 + j,
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
          PiecesPainter.pebble(
            canvas,
            center,
            size.width * 0.038,
            variant: p * 5 + j,
          );
        }
      }
    }
    for (final v in verts) {
      PiecesPainter.quanStone(canvas, v, size.width * 0.07);
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
        decoration: ShapeDecoration(
          color: color,
          // Vòng phấn trắng quanh avatar.
          shape: ChalkBorder(radius: size / 2, color: Colors.white, width: max(1.6, size * 0.06)),
          shadows: const [
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
