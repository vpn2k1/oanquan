import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show KeyEventResult;

import '../../../core/game_models/move.dart';
import 'board_game.dart';

/// Xử lý phím tắt của bàn.
extension BoardKeys on OQuanGame {
  KeyEventResult handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final k = event.logicalKey;
    if (animating) return KeyEventResult.handled;
    if (!inputEnabled || legal.isEmpty) return KeyEventResult.ignored;
    final order = [
      for (final i in topo.playerCells(state.turnPlayer))
        if (legal.contains(i)) i,
    ];
    if (k == LogicalKeyboardKey.arrowRight ||
        k == LogicalKeyboardKey.arrowLeft) {
      var idx = -1;
      if (selected != null) idx = order.indexOf(selected!);
      var delta = -1;
      if (k == LogicalKeyboardKey.arrowRight) delta = 1;
      int next;
      if (idx >= 0) {
        next = (idx + delta) % order.length;
      } else if (delta > 0) {
        next = 0;
      } else {
        next = order.length - 1;
      }
      select(order[(next + order.length) % order.length]);
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
      deselect();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }
}
