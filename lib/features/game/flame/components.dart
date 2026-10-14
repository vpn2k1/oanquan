import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';

import '../../../app/theme.dart';
import '../../../core/game_models/move.dart';
import 'board_game.dart';
import 'pieces_painter.dart';

Vector2 v2(Offset o) => Vector2(o.dx, o.dy);

/// Lớp nền nhận chạm "trượt" (tua nhanh animation / bỏ chọn).
class BackgroundTap extends PositionComponent
    with TapCallbacks, HasGameReference<OQuanGame> {
  BackgroundTap() : super(priority: -10);

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size;
  }

  @override
  void onTapDown(TapDownEvent event) => game.onBackgroundTap();
}

/// Vẽ toàn bộ bàn + quân (một lượt render, hiệu năng tốt).
class BoardLayer extends Component with HasGameReference<OQuanGame> {
  BoardLayer() : super(priority: 0);

  @override
  void render(Canvas canvas) => game.renderBoard(canvas);
}

/// Vùng chạm vô hình của một ô (≥ 44 px).
class CellHit extends PositionComponent
    with TapCallbacks, HoverCallbacks, HasGameReference<OQuanGame> {
  CellHit(this.cellId) : super(anchor: Anchor.center, priority: 5);
  final int cellId;

  void place(Offset center, double radius) {
    position = v2(center);
    size = Vector2.all(radius * 2);
  }

  @override
  bool containsLocalPoint(Vector2 point) =>
      (point - size / 2).length <= size.x / 2;

  @override
  void onTapDown(TapDownEvent event) => game.onCellTap(cellId);

  @override
  void onHoverEnter() => game.hoverCell = cellId;

  @override
  void onHoverExit() {
    if (game.hoverCell == cellId) game.hoverCell = null;
  }
}

/// Nút mũi tên chọn hướng rải.
class ArrowButton extends PositionComponent
    with TapCallbacks, HoverCallbacks, HasGameReference<OQuanGame> {
  ArrowButton(this.direction) : super(anchor: Anchor.center, priority: 10);
  final Direction direction;
  Offset tangent = const Offset(1, 0);
  double _appear = 0;
  bool _hover = false;

  void place(Offset center, double radius, Offset tangentDir) {
    position = v2(center);
    size = Vector2.all(radius * 2);
    tangent = tangentDir;
    _appear = 0;
  }

  @override
  bool containsLocalPoint(Vector2 point) =>
      (point - size / 2).length <= size.x / 2;

  @override
  void update(double dt) {
    _appear = min(1, _appear + dt * 7);
  }

  @override
  void onTapDown(TapDownEvent event) => game.onArrowTap(direction);

  @override
  void onHoverEnter() => _hover = true;

  @override
  void onHoverExit() => _hover = false;

  @override
  void render(Canvas canvas) {
    final r = size.x / 2;
    final c = Offset(r, r);
    final s = game.visuals.reducedMotion ? 1.0 : Curves.backOut(_appear);
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.scale(s);
    canvas.drawCircle(
      const Offset(0, 3),
      r * 0.92,
      Paint()..color = const Color(0x55000000),
    );
    canvas.drawCircle(
      Offset.zero,
      r * 0.92,
      Paint()..color = _hover ? const Color(0xFFFFF4DC) : AppColors.cream,
    );
    canvas.drawCircle(
      Offset.zero,
      r * 0.92,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(2, r * 0.12)
        ..color = AppColors.gold,
    );
    final dir = direction == Direction.clockwise ? tangent : -tangent;
    canvas.rotate(atan2(dir.dy, dir.dx));
    final a = r * 0.46;
    final path = Path()
      ..moveTo(-a * 0.9, 0)
      ..lineTo(a * 0.6, 0)
      ..moveTo(a * 0.05, -a * 0.6)
      ..lineTo(a * 0.75, 0)
      ..lineTo(a * 0.05, a * 0.6);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(2.5, r * 0.18)
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = AppColors.teal,
    );
    canvas.restore();
  }
}

enum FlyKind { stone, gem }

/// Quân bay theo đường cong bezier bậc 2 (rải, ăn).
class FlyingPiece extends PositionComponent with HasGameReference<OQuanGame> {
  FlyingPiece({
    required this.from,
    required this.to,
    required this.duration,
    required this.kind,
    required this.radius,
    this.color = const Color(0xFFFFFFFF),
    this.lift = 0.5,
    this.fadeOut = false,
    this.delay = 0,
  }) : super(priority: 20);

  final Offset from;
  final Offset to;
  final double duration;
  final FlyKind kind;
  final double radius;
  final Color color;
  final double lift;
  final bool fadeOut;
  double delay;
  double _t = 0;
  final done = Completer<void>();

  Offset get _control {
    final mid = (from + to) / 2;
    final d = (to - from).distance;
    return mid + Offset(0, -max(d * lift, radius * 3));
  }

  Offset _at(double t) {
    final c = _control;
    final u = 1 - t;
    return from * (u * u) + c * (2 * u * t) + to * (t * t);
  }

  @override
  void update(double dt) {
    final step = dt * game.timeScale;
    if (delay > 0) {
      delay -= step;
      return;
    }
    _t += step / duration;
    if (_t >= 1) {
      if (!done.isCompleted) done.complete();
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    if (delay > 0) return;
    final t = Curves.easeInOut(min(1, _t));
    final p = _at(t);
    final scale = 1 + sin(t * pi) * 0.35;
    final double alpha = fadeOut ? 1 - max(0.0, (t - 0.7) / 0.3) : 1.0;
    if (alpha < 1) {
      canvas.saveLayer(null, Paint()..color = Color.fromRGBO(0, 0, 0, alpha));
    }
    if (kind == FlyKind.stone) {
      PiecesPainter.stone(canvas, p, radius * scale, color);
    } else {
      PiecesPainter.quanFigure(canvas, p, radius * scale, glow: sin(t * pi));
    }
    if (alpha < 1) canvas.restore();
  }

  void finishNow() {
    if (!done.isCompleted) done.complete();
    removeFromParent();
  }
}

/// Chữ nổi "+3" bay lên và mờ dần.
class FloatingText extends PositionComponent with HasGameReference<OQuanGame> {
  FloatingText(this.text, this.at, this.color, this.fontSize)
    : super(priority: 30);
  final String text;
  final Offset at;
  final Color color;
  final double fontSize;
  double _t = 0;

  @override
  void update(double dt) {
    _t += dt / 1.1;
    if (_t >= 1) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final rise = game.visuals.reducedMotion
        ? 0.0
        : Curves.easeOut(_t) * fontSize * 1.6;
    final a = _t < 0.7 ? 1.0 : 1 - (_t - 0.7) / 0.3;
    final p = at - Offset(0, rise);
    PiecesPainter.text(
      canvas,
      text,
      p + const Offset(1.5, 1.5),
      fontSize,
      const Color(0xAA000000),
      bold: true,
      opacity: a,
    );
    PiecesPainter.text(
      canvas,
      text,
      p,
      fontSize,
      color,
      bold: true,
      opacity: a,
    );
  }
}

/// Tia lấp lánh khi ăn quan.
class Sparkle extends PositionComponent with HasGameReference<OQuanGame> {
  Sparkle(this.at, this.radius) : super(priority: 25);
  final Offset at;
  final double radius;
  double _t = 0;

  @override
  void update(double dt) {
    _t += dt * game.timeScale / 0.8;
    if (_t >= 1) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = AppColors.gold.withValues(alpha: 1 - _t);
    for (var i = 0; i < 10; i++) {
      final a = i * pi / 5;
      final p = at + Offset.fromDirection(a, radius * (0.4 + _t * 1.4));
      canvas.drawCircle(p, radius * 0.09 * (1 - _t * 0.6), paint);
    }
  }
}

abstract final class Curves {
  static double easeInOut(double t) =>
      t < 0.5 ? 2 * t * t : 1 - pow(-2 * t + 2, 2).toDouble() / 2;
  static double easeOut(double t) => 1 - pow(1 - t, 3).toDouble();
  static double backOut(double t) {
    const c1 = 1.70158, c3 = c1 + 1;
    return (1 + c3 * pow(t - 1, 3) + c1 * pow(t - 1, 2)).toDouble();
  }
}
