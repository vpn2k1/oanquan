import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show EdgeInsets;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show KeyEventResult;

import '../../../app/theme.dart';
import '../../../core/engine/board_topology.dart';
import '../../../core/engine/rules_engine.dart';
import '../../../core/game_models/game_state.dart';
import '../../../core/game_models/move.dart';
import '../audio/sound_service.dart';
import '../game_session.dart';
import '../../../app/folk_art.dart';
import 'board_geometry.dart';
import 'components.dart';

import 'board_animation.dart';
import 'board_keys.dart';
import 'board_renderer.dart';
import 'board_types.dart';

export 'board_types.dart';

/// Game Flame hiển thị bàn. Trạng thái logic (GameState) và trạng thái
/// hiển thị (dan/quan đang animate) tách biệt; input bị khóa khi animate.
class OQuanGame extends FlameGame with KeyboardEvents {
  OQuanGame({
    required GameState initial,
    required this.callbacks,
    this.visuals = const BoardVisuals(),
  }) : state = initial {
    loadDisplay(initial);
  }

  final BoardCallbacks callbacks;
  BoardVisuals visuals;

  GameState state;
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
  bool skip = false;
  double clock = 0;
  final List<GameTimer> timers = [];

  int? handCell;
  int handCount = 0;
  Offset handPos = Offset.zero;
  Color handColor = AppColors.cream;

  Image? boardImage;
  Set<int> legal = const {};

  BoardTopology get topo => BoardTopology(state.config);

  @override
  Color backgroundColor() => const Color(0x00000000);

  @override
  Future<void> onLoad() async {
    add(BackgroundTap());
    add(BoardLayer());
    for (var i = 0; i < state.ringLength; i++) {
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
    if (!hasLayout || size.x <= 0 || size.y <= 0) return;
    final area = Rect.fromLTRB(
      boardInsets.left,
      boardInsets.top,
      max(boardInsets.left + 50, size.x - boardInsets.right),
      max(boardInsets.top + 50, size.y - boardInsets.bottom),
    );
    geo = BoardGeometry.compute(state.config, Size(size.x, size.y), area: area);
    boardImage = null;
    for (final h in _hits) {
      final c = geo!.cells[h.cellId];
      h.place(c.center, c.hitRadius);
    }
    _placeArrows();
  }

  /// Lề dành cho HUD nổi (bàn vẫn vẽ trên toàn màn hình).
  EdgeInsets boardInsets = EdgeInsets.zero;

  void setBoardInsets(EdgeInsets v) {
    if (v == boardInsets) return;
    boardInsets = v;
    _layout();
  }

  void updateVisuals(BoardVisuals v) {
    final redraw =
        v.colorBlind != visuals.colorBlind ||
        v.styleSetting != visuals.styleSetting;
    visuals = v;
    if (redraw) boardImage = null;
  }

  /// Tông tối/sáng của app (nền ngoài khay).
  bool dark = true;

  void setDark(bool v) {
    if (v == dark) return;
    dark = v;
    boardImage = null;
  }

  /// Mặt sân + nét vẽ của ván này (ngẫu nhiên theo seed ván nếu chọn "ngẫu nhiên").
  FolkStyle get style =>
      styleOverride ??
      FolkStyle.resolve(visuals.styleSetting, state.config.seed);

  /// Mặt sân do người chơi bấm "đổi mặt sân" (chỉ đổi hình, không đổi ván).
  FolkStyle? styleOverride;
  int? groundSeedOverride;
  int get groundSeed => groundSeedOverride ?? state.config.seed;

  /// Bốc ngẫu nhiên kiểu sân khác + bố trí mới; vẽ ngầm xong mới thay (không chớp).
  Future<void> shuffleGround() async {
    final rnd = Random();
    final cur = style;
    final others = [
      for (final s in FolkStyle.all)
        if (s != cur) s,
    ];
    final next = others[rnd.nextInt(others.length)];
    final seed = rnd.nextInt(1 << 30);
    final dpr = PlatformDispatcher.instance.views.first.devicePixelRatio;
    await GroundCache.warmUp(Size(size.x, size.y), dpr, next.ground, seed);
    styleOverride = next;
    groundSeedOverride = seed;
    boardImage = null;
  }

  // ---------------------------------------------------------------------------
  // Đồng bộ trạng thái
  // ---------------------------------------------------------------------------

  void loadDisplay(GameState s) {
    dan = [for (final c in s.cells) c.danCount];
    quan = [for (final c in s.cells) c.hasQuan];
    pulse = List.filled(s.ringLength, 0);
    flash = List.filled(s.ringLength, 0);
    displayScores.value = [for (final p in s.players) p.score];
    pileQuan = [for (final p in s.players) p.quanCaptured];
  }

  /// Số quan đang nằm trong đống quân ăn của từng người (hiển thị).
  List<int> pileQuan = const [];

  /// Số sỏi hiển thị trong đống của người `p` = điểm hiển thị − giá trị quan.
  int pileDan(int p) {
    final sc = displayScores.value;
    if (p >= sc.length) return 0;
    return max(0, sc[p] - pileQuan[p] * state.config.ruleset.quanValue);
  }

  /// Vị trí ô trống kế tiếp trong đống của người `p` (đích bay của quân ăn).
  Offset pileTarget(BoardGeometry g, int p, int extra) =>
      g.pileSlot(p, pileQuan[p] * 3 + pileDan(p) + extra);

  /// Đồng bộ cứng (ván mới, undo, khôi phục).
  void syncTo(GameState s) {
    final shapeChanged = s.config.playerCount != state.config.playerCount;
    skip = true;
    state = s;
    loadDisplay(s);
    handCell = null;
    deselect();
    refreshLegal();
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
    if (!v) deselect();
    refreshLegal();
  }

  bool get inputEnabled => _inputEnabled;

  void showHint(Move? m) => hint = m;

  void refreshLegal() {
    if (_inputEnabled && !animating) {
      legal = {
        for (final m in const RulesEngine().getLegalMoves(state))
          m.sourceCellId,
      };
    } else {
      legal = const {};
    }
  }

  // ---------------------------------------------------------------------------
  // Input
  // ---------------------------------------------------------------------------

  void onBackgroundTap() {
    // Đang rải quân: chạm (kể cả lúc vuốt / zoom) không làm gì, giữ nguyên tốc độ.
    if (animating) return;
    deselect();
  }

  void onCellTap(int id) {
    if (animating || !_inputEnabled) return;
    if (legal.contains(id)) {
      if (selected == id) {
        deselect();
      } else {
        select(id);
      }
    } else {
      deselect();
    }
  }

  void onArrowTap(Direction d) {
    final src = selected;
    if (src == null || !_inputEnabled || animating) return;
    deselect();
    hint = null;
    callbacks.onMove(
      Move(playerId: state.turnPlayer, sourceCellId: src, direction: d),
    );
  }

  void select(int id) {
    selected = id;
    callbacks.onSound(Sfx.select);
    if (_arrowCw.parent == null) add(_arrowCw);
    if (_arrowCcw.parent == null) add(_arrowCcw);
    _placeArrows();
  }

  void deselect() {
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
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    return handleKeyEvent(event);
  }

  // ---------------------------------------------------------------------------
  // Animation
  // ---------------------------------------------------------------------------

  Future<void> wait(double seconds) {
    if (skip || seconds <= 0) return Future.value();
    final t = GameTimer(seconds * visuals.speedFactor);
    timers.add(t);
    return t.c.future;
  }

  @override
  void update(double dt) {
    super.update(dt);
    clock += dt;
    final step = dt * timeScale;
    for (var i = 0; i < pulse.length; i++) {
      if (pulse[i] > 0) pulse[i] = max(0, pulse[i] - dt * 3.5);
      if (flash[i] > 0) flash[i] = max(0, flash[i] - dt * 1.6);
    }
    for (final t in [...timers]) {
      t.left -= step;
      if (t.left <= 0 || skip) {
        timers.remove(t);
        if (!t.c.isCompleted) t.c.complete();
      }
    }
  }

  /// Bỏ qua phần animation còn lại.
  void skipAnimation() {
    if (!animating) return;
    skip = true;
    for (final c in children.whereType<FlyingPiece>().toList()) {
      c.finishNow();
    }
  }

  Future<void> playBatch(AnimationBatch b) => runBatch(b);

  void renderBoard(Canvas canvas) => paintBoard(canvas);

  @override
  void onRemove() {
    displayScores.dispose();
    super.onRemove();
  }
}
