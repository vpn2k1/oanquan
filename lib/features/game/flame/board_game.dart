import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show LinearGradient, Alignment;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show KeyEventResult;

import '../../../app/theme.dart';
import '../../../core/engine/board_topology.dart';
import '../../../core/engine/rules_engine.dart';
import '../../../core/game_models/game_event.dart';
import '../../../core/game_models/game_state.dart';
import '../../../core/game_models/move.dart';
import '../audio/sound_service.dart';
import '../game_session.dart';
import 'board_geometry.dart';
import 'components.dart';
import 'pieces_painter.dart';

class BoardVisuals {
  const BoardVisuals({
    this.reducedMotion = false,
    this.speedFactor = 1.0,
    this.colorBlind = false,
  });
  final bool reducedMotion;
  final double speedFactor;
  final bool colorBlind;
}

class BoardCallbacks {
  const BoardCallbacks({
    required this.onMove,
    required this.onAnimationDone,
    required this.onNotice,
    required this.onSound,
  });
  final void Function(Move move) onMove;
  final void Function(int batchId) onAnimationDone;
  final void Function(GameEvent e) onNotice;
  final void Function(Sfx sfx) onSound;
}

class _Timer {
  _Timer(this.left);
  double left;
  final c = Completer<void>();
}

/// Game Flame hiển thị bàn. Trạng thái logic (GameState) và trạng thái
/// hiển thị (dan/quan đang animate) tách biệt; input bị khóa khi animate.
class OQuanGame extends FlameGame with KeyboardEvents {
  OQuanGame({
    required GameState initial,
    required this.callbacks,
    this.visuals = const BoardVisuals(),
  }) : _state = initial {
    _loadDisplay(initial);
  }

  final BoardCallbacks callbacks;
  BoardVisuals visuals;

  GameState _state;
  late List<int> dan;
  late List<bool> quan;
  late List<double> pulse;
  late List<double> flash;
  final displayScores = ValueNotifier<List<int>>(const []);

  BoardGeometry? geo;
  final List<CellHit> _hits = [];
  final _arrowCw = ArrowButton(Direction.clockwise);
  final _arrowCcw = ArrowButton(Direction.counterClockwise);

  int? selected;
  int? hoverCell;
  Move? hint;
  bool _inputEnabled = false;
  bool animating = false;
  double timeScale = 1;
  bool _skip = false;
  double _clock = 0;
  final List<_Timer> _timers = [];

  int? handCell;
  int handCount = 0;
  Offset handPos = Offset.zero;
  Color handColor = AppColors.cream;

  Picture? _boardPicture;
  Set<int> _legal = const {};

  GameState get state => _state;
  BoardTopology get topo => BoardTopology(_state.config);

  @override
  Color backgroundColor() => const Color(0x00000000);

  @override
  Future<void> onLoad() async {
    add(BackgroundTap());
    add(BoardLayer());
    for (var i = 0; i < _state.ringLength; i++) {
      final h = CellHit(i);
      _hits.add(h);
      add(h);
    }
    _layout();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _layout();
  }

  void _layout() {
    if (size.x <= 0 || size.y <= 0) return;
    geo = BoardGeometry.compute(_state.config, Size(size.x, size.y));
    _boardPicture = null;
    for (final h in _hits) {
      final c = geo!.cells[h.cellId];
      h.place(c.center, c.hitRadius);
    }
    _placeArrows();
  }

  void updateVisuals(BoardVisuals v) {
    final cb = v.colorBlind != visuals.colorBlind;
    visuals = v;
    if (cb) _boardPicture = null;
  }

  // ---------------------------------------------------------------------------
  // Đồng bộ trạng thái
  // ---------------------------------------------------------------------------

  void _loadDisplay(GameState s) {
    dan = [for (final c in s.cells) c.danCount];
    quan = [for (final c in s.cells) c.hasQuan];
    pulse = List.filled(s.ringLength, 0);
    flash = List.filled(s.ringLength, 0);
    displayScores.value = [for (final p in s.players) p.score];
  }

  /// Đồng bộ cứng (ván mới, undo, khôi phục).
  void syncTo(GameState s) {
    final shapeChanged = s.config.playerCount != _state.config.playerCount;
    _skip = true;
    _state = s;
    _loadDisplay(s);
    handCell = null;
    _deselect();
    _refreshLegal();
    if (shapeChanged && isLoaded) {
      for (final h in _hits) {
        h.removeFromParent();
      }
      _hits.clear();
      for (var i = 0; i < s.ringLength; i++) {
        final h = CellHit(i);
        _hits.add(h);
        add(h);
      }
      _layout();
    }
  }

  set inputEnabled(bool v) {
    if (_inputEnabled == v) return;
    _inputEnabled = v;
    if (!v) _deselect();
    _refreshLegal();
  }

  bool get inputEnabled => _inputEnabled;

  void showHint(Move? m) => hint = m;

  void _refreshLegal() {
    _legal = (_inputEnabled && !animating)
        ? {for (final m in const RulesEngine().getLegalMoves(_state)) m.sourceCellId}
        : const {};
  }

  // ---------------------------------------------------------------------------
  // Input
  // ---------------------------------------------------------------------------

  void onBackgroundTap() {
    if (animating) {
      timeScale = 4;
      return;
    }
    _deselect();
  }

  void onCellTap(int id) {
    if (animating) {
      timeScale = 4;
      return;
    }
    if (!_inputEnabled) return;
    if (_legal.contains(id)) {
      if (selected == id) {
        _deselect();
      } else {
        _select(id);
      }
    } else {
      _deselect();
    }
  }

  void onArrowTap(Direction d) {
    final src = selected;
    if (src == null || !_inputEnabled || animating) return;
    _deselect();
    hint = null;
    callbacks.onMove(Move(playerId: _state.turnPlayer, sourceCellId: src, direction: d));
  }

  void _select(int id) {
    selected = id;
    callbacks.onSound(Sfx.select);
    if (_arrowCw.parent == null) add(_arrowCw);
    if (_arrowCcw.parent == null) add(_arrowCcw);
    _placeArrows();
  }

  void _deselect() {
    selected = null;
    if (_arrowCw.parent != null) _arrowCw.removeFromParent();
    if (_arrowCcw.parent != null) _arrowCcw.removeFromParent();
  }

  void _placeArrows() {
    final g = geo;
    final s = selected;
    if (g == null || s == null) return;
    final (cw, ccw) = g.arrowPositions(s);
    final r = g.arrowRadius;
    final t = g.cells[s].tangentCw;
    _arrowCw.place(cw, r, t);
    _arrowCcw.place(ccw, r, t);
  }

  @override
  KeyEventResult onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final k = event.logicalKey;
    if (animating) {
      timeScale = 4;
      return KeyEventResult.handled;
    }
    if (!_inputEnabled || _legal.isEmpty) return KeyEventResult.ignored;
    final order = [
      for (final i in topo.playerCells(_state.turnPlayer))
        if (_legal.contains(i)) i,
    ];
    if (k == LogicalKeyboardKey.arrowRight || k == LogicalKeyboardKey.arrowLeft) {
      final idx = selected == null ? -1 : order.indexOf(selected!);
      final delta = k == LogicalKeyboardKey.arrowRight ? 1 : -1;
      final next = idx < 0 ? (delta > 0 ? 0 : order.length - 1) : (idx + delta) % order.length;
      _select(order[(next + order.length) % order.length]);
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.keyX && selected != null) {
      onArrowTap(Direction.clockwise);
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.keyZ && selected != null) {
      onArrowTap(Direction.counterClockwise);
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.escape) {
      _deselect();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  // ---------------------------------------------------------------------------
  // Animation
  // ---------------------------------------------------------------------------

  Future<void> _wait(double seconds) {
    if (_skip || seconds <= 0) return Future.value();
    final t = _Timer(seconds * visuals.speedFactor);
    _timers.add(t);
    return t.c.future;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _clock += dt;
    final step = dt * timeScale;
    for (var i = 0; i < pulse.length; i++) {
      if (pulse[i] > 0) pulse[i] = max(0, pulse[i] - dt * 3.5);
      if (flash[i] > 0) flash[i] = max(0, flash[i] - dt * 1.6);
    }
    for (final t in [..._timers]) {
      t.left -= step;
      if (t.left <= 0 || _skip) {
        _timers.remove(t);
        if (!t.c.isCompleted) t.c.complete();
      }
    }
  }

  /// Bỏ qua phần animation còn lại.
  void skipAnimation() {
    if (!animating) return;
    _skip = true;
    for (final c in children.whereType<FlyingPiece>().toList()) {
      c.finishNow();
    }
  }

  Future<void> playBatch(AnimationBatch b) async {
    _deselect();
    hint = null;
    animating = true;
    _skip = false;
    timeScale = 1;
    _refreshLegal();
    _state = b.before;
    _loadDisplay(b.before);
    final scores = [for (final p in b.before.players) p.score];
    try {
      if (visuals.reducedMotion) {
        for (final e in b.events) {
          _reducedEvent(e, scores);
        }
        _loadDisplay(b.after);
        await _wait(0.35);
      } else {
        for (final e in b.events) {
          if (_skip) break;
          await _playEvent(e, scores);
        }
      }
    } finally {
      for (final c in children.whereType<FlyingPiece>().toList()) {
        c.finishNow();
      }
      handCell = null;
      _state = b.after;
      final keepFlash = [...flash];
      _loadDisplay(b.after);
      flash = keepFlash;
      animating = false;
      _skip = false;
      timeScale = 1;
      _refreshLegal();
      callbacks.onAnimationDone(b.id);
    }
  }

  Color _cellStoneColor(int cellId) {
    final owner = topo.ownerOf(cellId);
    return owner == null ? const Color(0xFFEFE3C8) : playerColors[owner];
  }

  void _reducedEvent(GameEvent e, List<int> scores) {
    final g = geo;
    switch (e) {
      case CaptureDanEvent(:final playerId, :final cellId, :final count):
        flash[cellId] = 1;
        scores[playerId] += count * _state.config.ruleset.danValue;
        if (g != null) _float('+$count', g.cells[cellId].center, playerColors[playerId]);
        callbacks.onSound(Sfx.capture);
      case CaptureQuanEvent(:final playerId, :final cellId, :final value):
        flash[cellId] = 1;
        scores[playerId] += value;
        if (g != null) _float('+$value', g.cells[cellId].center, AppColors.gold);
        callbacks.onSound(Sfx.quan);
      case RefillEvent() || EliminateEvent() || RuleLoopGuardEvent():
        callbacks.onNotice(e);
      case GameOverEvent():
        callbacks.onSound(Sfx.win);
      default:
        break;
    }
    displayScores.value = [...scores];
  }

  Future<void> _playEvent(GameEvent e, List<int> scores) async {
    final g = geo;
    if (g == null) return;
    final u = g.unit;
    switch (e) {
      case PickupEvent(:final cellId, :final count):
        dan[cellId] = 0;
        pulse[cellId] = 1;
        handCell = cellId;
        handCount = count;
        handPos = g.cells[cellId].center;
        handColor = _cellStoneColor(cellId);
        await _wait(0.16);
      case DropEvent(:final cellId):
        final to = g.cells[cellId].center;
        final piece = FlyingPiece(
          from: handPos - Offset(0, u * 0.45),
          to: to,
          duration: 0.17 * visuals.speedFactor,
          kind: FlyKind.stone,
          radius: u * 0.1,
          color: handColor,
          lift: 0.35,
        );
        handCount = max(0, handCount - 1);
        add(piece);
        await piece.done.future;
        dan[cellId]++;
        pulse[cellId] = 1;
        handPos = to;
        if (handCount == 0) handCell = null;
        callbacks.onSound(Sfx.drop);
      case CaptureDanEvent(:final playerId, :final cellId, :final count):
        flash[cellId] = 1;
        await _wait(0.12);
        final from = g.cells[cellId].center;
        final color = _cellStoneColor(cellId);
        dan[cellId] = 0;
        for (var i = 0; i < min(count, 6); i++) {
          add(FlyingPiece(
            from: from + Offset.fromDirection(i * 1.3, u * 0.12),
            to: g.playerAnchors[playerId],
            duration: 0.42 * visuals.speedFactor,
            kind: FlyKind.stone,
            radius: u * 0.11,
            color: color,
            lift: 0.25,
            fadeOut: true,
            delay: i * 0.04,
          ));
        }
        _float('+$count', from, playerColors[playerId]);
        scores[playerId] += count * _state.config.ruleset.danValue;
        displayScores.value = [...scores];
        callbacks.onSound(Sfx.capture);
        await _wait(0.5);
      case CaptureQuanEvent(:final playerId, :final cellId, :final value):
        final from = g.cells[cellId].center;
        flash[cellId] = 1;
        quan[cellId] = false;
        add(Sparkle(from, u * 0.8));
        final gem = FlyingPiece(
          from: from,
          to: g.playerAnchors[playerId],
          duration: 0.75 * visuals.speedFactor,
          kind: FlyKind.gem,
          radius: u * 0.42,
          lift: 0.3,
          fadeOut: true,
        );
        add(gem);
        _float('+$value', from - Offset(0, u * 0.3), AppColors.gold, big: true);
        scores[playerId] += value;
        displayScores.value = [...scores];
        callbacks.onSound(Sfx.quan);
        await gem.done.future;
      case RefillEvent(:final playerId, :final cellIds, :final cost):
        for (final c in cellIds) {
          dan[c]++;
          pulse[c] = 1;
        }
        scores[playerId] -= cost;
        displayScores.value = [...scores];
        _float('−$cost', g.playerAnchors[playerId], playerColors[playerId]);
        callbacks.onNotice(e);
        callbacks.onSound(Sfx.refill);
        await _wait(0.6);
      case EliminateEvent():
        callbacks.onNotice(e);
        await _wait(0.5);
      case RuleLoopGuardEvent():
        callbacks.onNotice(e);
        await _wait(0.3);
      case EndTurnEvent():
        handCell = null;
        callbacks.onSound(Sfx.turn);
      case GameOverEvent():
        callbacks.onSound(Sfx.win);
        await _wait(0.4);
    }
  }

  void _float(String text, Offset at, Color color, {bool big = false}) {
    final u = geo?.unit ?? 40;
    add(FloatingText(text, at, color, u * (big ? 0.62 : 0.48)));
  }

  // ---------------------------------------------------------------------------
  // Render
  // ---------------------------------------------------------------------------

  void renderBoard(Canvas canvas) {
    final g = geo;
    if (g == null) return;
    canvas.drawPicture(_boardPicture ??= _recordStatic(g));
    final u = g.unit;

    // Dải màu người đến lượt sáng lên.
    if (!_state.isOver) {
      final (a, b) = g.playerEdges[_state.turnPlayer];
      final glow = 0.55 + 0.35 * sin(_clock * 3);
      canvas.drawLine(
          a,
          b,
          Paint()
            ..color = playerColors[_state.turnPlayer].withValues(alpha: glow)
            ..strokeWidth = u * 0.2
            ..strokeCap = StrokeCap.round
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
    }

    for (final c in g.cells) {
      final i = c.id;
      if (hoverCell == i && _legal.contains(i)) {
        canvas.drawPath(c.outline, Paint()..color = const Color(0x22FFFFFF));
      }
      if (flash[i] > 0) {
        canvas.drawPath(c.outline,
            Paint()..color = AppColors.gold.withValues(alpha: 0.55 * flash[i]));
      }
      if (_legal.contains(i)) {
        final a = 0.45 + 0.4 * (0.5 + 0.5 * sin(_clock * 4.2 + i * 0.3));
        canvas.drawPath(
            c.outline,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = max(2, u * 0.06)
              ..color = const Color(0xFFFFE6A0).withValues(alpha: a));
      }
      if (hint?.sourceCellId == i) {
        final a = 0.5 + 0.5 * sin(_clock * 6);
        canvas.drawPath(
            c.outline,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = max(3, u * 0.09)
              ..color = const Color(0xFF3FE0C5).withValues(alpha: a));
      }
      if (selected == i) {
        canvas.drawPath(
            c.outline,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = max(3, u * 0.1)
              ..color = const Color(0xFFFFFFFF));
      }
      _renderCellContents(canvas, c, u);
    }

    // Gợi ý hướng.
    final h = hint;
    if (h != null && selected == null) {
      final (cw, ccw) = g.arrowPositions(h.sourceCellId);
      final p = h.direction == Direction.clockwise ? cw : ccw;
      final t = g.cells[h.sourceCellId].tangentCw * (h.direction.step.toDouble());
      final a = 0.6 + 0.4 * sin(_clock * 6);
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
        PiecesPainter.stone(canvas, p + Offset.fromDirection(k * 2.4, r * 0.9 * sqrt(k.toDouble())), r, handColor);
      }
      PiecesPainter.badge(canvas, p + Offset(u * 0.26, -u * 0.12), max(8, u * 0.15), handCount,
          color: const Color(0xEE0E4D4A));
    }
  }

  void _renderCellContents(Canvas canvas, CellGeometry c, double u) {
    final i = c.id;
    final count = dan[i];
    final bounce = 1 + 0.22 * sin(pulse[i] * pi);
    final stoneColor = _cellStoneColor(i);
    if (c.isQuan) {
      final b = c.outline.getBounds();
      final rx = b.width / 2, ry = b.height / 2;
      final gemR = min(rx, ry) * 0.6;
      final n = min(count, 12);
      final sr = u * 0.095;
      for (var k = 0; k < n; k++) {
        final a = -pi / 2 + k * 2 * pi / max(n, 1) + 0.3;
        final ringX = quan[i] ? rx * 0.74 : rx * 0.45 * (n > 6 ? 1 : 0.6);
        final ringY = quan[i] ? ry * 0.74 : ry * 0.45 * (n > 6 ? 1 : 0.6);
        final p = c.center + Offset(cos(a) * ringX, sin(a) * ringY);
        PiecesPainter.stone(canvas, p, sr * bounce, stoneColor, tint: (k % 3) * 0.05);
      }
      if (quan[i]) PiecesPainter.quanGem(canvas, c.center, gemR * bounce, glow: flash[i]);
      if (count > 0) {
        PiecesPainter.badge(canvas, c.labelAnchor, max(8, u * 0.17), count);
      }
      return;
    }
    if (count > 0) {
      final positions = PiecesPainter.layout(count, c.size * 0.3);
      final r = PiecesPainter.stoneRadius(c.size, count) * bounce;
      for (var k = 0; k < positions.length; k++) {
        PiecesPainter.stone(canvas, c.center + positions[k], r, stoneColor,
            tint: ((k * 7) % 4) * 0.06);
      }
      final owner = topo.ownerOf(i)!;
      PiecesPainter.badge(canvas, c.labelAnchor, max(8, u * 0.15), count,
          symbol: visuals.colorBlind ? symbolOf(owner) : null,
          color: visuals.colorBlind
              ? Color.lerp(playerColors[owner], const Color(0xFF000000), 0.35)!
              : const Color(0xE62B1D10));
    }
  }

  Picture _recordStatic(BoardGeometry g) {
    final rec = PictureRecorder();
    final canvas = Canvas(rec);
    final u = g.unit;
    final bounds = g.boardOutline.getBounds();

    // Bóng mềm.
    canvas.drawPath(
        g.boardOutline.shift(Offset(0, u * 0.18)),
        Paint()
          ..color = const Color(0x66000000)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, u * 0.3));
    // Gỗ mật ong.
    canvas.drawPath(
        g.boardOutline,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.woodLight, AppColors.wood, Color(0xFFB0712F)],
          ).createShader(bounds));
    // Vân gỗ.
    canvas.save();
    canvas.clipPath(g.boardOutline);
    final grain = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1, u * 0.03)
      ..color = const Color(0x18000000);
    final rnd = Random(7);
    for (var k = 0; k < 14; k++) {
      final y = bounds.top + bounds.height * (k + rnd.nextDouble() * 0.6) / 14;
      final path = Path()..moveTo(bounds.left - 10, y);
      for (var x = bounds.left; x <= bounds.right + 20; x += u) {
        path.quadraticBezierTo(x + u * 0.5, y + (rnd.nextDouble() - 0.5) * u * 0.25, x + u, y);
      }
      canvas.drawPath(path, grain);
    }
    canvas.restore();
    // Rãnh khắc thủ công.
    canvas.drawPath(
        g.innerGroove,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = max(1.5, u * 0.05)
          ..color = AppColors.groove.withValues(alpha: 0.55));
    canvas.drawPath(
        g.innerGroove.shift(Offset(0, max(1, u * 0.03))),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = max(1, u * 0.025)
          ..color = const Color(0x40FFFFFF));
    canvas.drawPath(
        g.boardOutline,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = max(1.5, u * 0.04)
          ..color = AppColors.woodDark);

    // Dải màu chủ sở hữu.
    for (var p = 0; p < g.playerEdges.length; p++) {
      final (a, b) = g.playerEdges[p];
      canvas.drawLine(
          a,
          b,
          Paint()
            ..color = playerColors[p].withValues(alpha: 0.5)
            ..strokeWidth = u * 0.12
            ..strokeCap = StrokeCap.round);
      if (visuals.colorBlind) {
        final mid = (a + b) / 2;
        paintPlayerSymbol(canvas, mid, u * 0.12, symbolOf(p), Paint()..color = const Color(0xFFFFFFFF));
      }
    }

    // Hố ô.
    for (final c in g.cells) {
      canvas.drawPath(c.outline.shift(Offset(0, -u * 0.025)),
          Paint()..color = const Color(0x40FFFFFF));
      canvas.drawPath(c.outline, Paint()..color = const Color(0xFF6E4219));
      canvas.drawPath(
          c.outline.shift(Offset(0, u * 0.04)),
          Paint()
            ..color = const Color(0xFF8C5826)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, u * 0.05));
      final owner = topo.ownerOf(c.id);
      canvas.drawPath(
          c.outline,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = max(1.5, u * (c.isQuan ? 0.06 : 0.05))
            ..color = owner == null
                ? const Color(0xFFB8862F)
                : playerColors[owner].withValues(alpha: 0.85));
    }
    return rec.endRecording();
  }

  @override
  void onRemove() {
    _boardPicture?.dispose();
    displayScores.dispose();
    super.onRemove();
  }
}
