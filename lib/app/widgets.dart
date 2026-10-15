import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/game/flame/pieces_painter.dart';
import '../features/settings/settings_controller.dart';
import 'folk_art.dart';
import 'folk_icon.dart';
import 'theme.dart';

export 'folk_icon.dart';

/// Nền chung: mặt sân dân dã (đất / xi măng / gạch bát) theo cài đặt,
/// phủ một lớp sáng mỏng để chữ trên menu dễ đọc.
class AppBackground extends ConsumerWidget {
  const AppBackground({super.key, required this.child, this.veil = true});
  final Widget child;

  /// Lớp phủ làm dịu nền.
  final bool veil;

  /// Seed cho chế độ "ngẫu nhiên": cố định trong một lần mở app.
  static final launchSeed = Random().nextInt(1 << 30);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setting = ref.watch(settingsProvider.select((s) => s.boardStyle));
    final style = FolkStyle.resolve(setting, launchSeed);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          child: CustomPaint(painter: GroundPainter(style.ground, launchSeed)),
        ),
        if (veil)
          ColoredBox(
            color: dark ? const Color(0x99102020) : const Color(0x59FFF8EA),
          ),
        child,
      ],
    );
  }
}

/// Vẽ mặt sân từ ảnh đã raster hóa (cache).
class GroundPainter extends CustomPainter {
  GroundPainter(this.kind, this.seed);
  final GroundKind kind;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final dpr = WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;
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
