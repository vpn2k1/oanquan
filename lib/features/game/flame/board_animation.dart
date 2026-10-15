import 'dart:math';
import 'dart:ui';

import '../../../app/theme.dart';
import '../../../core/game_models/game_event.dart';
import '../audio/sound_service.dart';
import 'board_game.dart';
import '../game_session.dart';
import 'components.dart';

/// Phát từng sự kiện animation của một lượt.
extension BoardAnimation on OQuanGame {
  Future<void> runBatch(AnimationBatch b) async {
    deselect();
    hint = null;
    animating = true;
    skip = false;
    timeScale = 1;
    refreshLegal();
    state = b.before;
    loadDisplay(b.before);
    final scores = [for (final p in b.before.players) p.score];
    try {
      if (visuals.reducedMotion) {
        for (final e in b.events) {
          reducedEvent(e, scores);
        }
        loadDisplay(b.after);
        await wait(0.35);
      } else {
        for (final e in b.events) {
          if (skip) break;
          await playEvent(e, scores);
        }
      }
    } finally {
      for (final c in children.whereType<FlyingPiece>().toList()) {
        c.finishNow();
      }
      handCell = null;
      state = b.after;
      final keepFlash = [...flash];
      loadDisplay(b.after);
      flash = keepFlash;
      animating = false;
      skip = false;
      timeScale = 1;
      refreshLegal();
      callbacks.onAnimationDone(b.id);
    }
  }

  Color cellStoneColor(int cellId) {
    final owner = topo.ownerOf(cellId);
    if (owner == null) return const Color(0xFFEFE3C8);
    return playerColors[owner];
  }

  void reducedEvent(GameEvent e, List<int> scores) {
    final g = geo;
    switch (e) {
      case CaptureDanEvent(:final playerId, :final cellId, :final count):
        flash[cellId] = 1;
        scores[playerId] += count * state.config.ruleset.danValue;
        if (g != null) {
          floatText('+$count', g.cells[cellId].center, playerColors[playerId]);
        }
        callbacks.onSound(Sfx.capture);
      case CaptureQuanEvent(:final playerId, :final cellId, :final value):
        flash[cellId] = 1;
        scores[playerId] += value;
        pileQuan[playerId]++;
        if (g != null) {
          floatText('+$value', g.cells[cellId].center, AppColors.gold);
        }
        callbacks.onSound(Sfx.quan);
      case RefillEvent(:final playerId, :final cost, :final borrowed):
        for (final b in borrowed.entries) {
          scores[b.key] -= b.value;
          scores[playerId] += b.value;
        }
        scores[playerId] -= cost;
        callbacks.onNotice(e);
      case CollectEvent(:final playerId, :final cellIds, :final count):
        for (final c in cellIds) {
          dan[c] = 0;
        }
        scores[playerId] += count * state.config.ruleset.danValue;
      case RepayEvent(:final fromId, :final toId, :final amount):
        scores[fromId] -= amount;
        scores[toId] += amount;
      case EliminateEvent() || RuleLoopGuardEvent():
        callbacks.onNotice(e);
      case GameOverEvent():
        callbacks.onSound(Sfx.win);
      default:
        break;
    }
    displayScores.value = [...scores];
  }

  Future<void> playEvent(GameEvent e, List<int> scores) async {
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
        handColor = cellStoneColor(cellId);
        await wait(0.3);
      case DropEvent(:final cellId):
        final to = g.cells[cellId].center;
        final piece = FlyingPiece(
          from: handPos - Offset(0, u * 0.45),
          to: to,
          duration: 0.28 * visuals.speedFactor,
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
        // Nghỉ ngắn sau mỗi viên để người xem đếm kịp.
        await wait(0.08);
      case CaptureDanEvent(:final playerId, :final cellId, :final count):
        flash[cellId] = 1;
        await wait(0.3);
        final from = g.cells[cellId].center;
        dan[cellId] = 0;
        // Mỗi viên bay vào đúng chỗ trống kế tiếp trong đống quân ăn.
        final shown = min(count, 12);
        FlyingPiece? last;
        for (var i = 0; i < shown; i++) {
          last = FlyingPiece(
            from: from + Offset.fromDirection(i * 1.3, u * 0.12),
            to: pileTarget(g, playerId, i),
            duration: 0.5 * visuals.speedFactor,
            kind: FlyKind.stone,
            radius: g.pebbleRadius,
            color: const Color(0xFFC9C1B2),
            lift: 0.25,
            delay: i * 0.06 * visuals.speedFactor,
          );
          add(last);
        }
        floatText('+$count', from, Rc.text);
        callbacks.onSound(Sfx.capture);
        await last?.done.future;
        scores[playerId] += count * state.config.ruleset.danValue;
        displayScores.value = [...scores];
        for (final c in children.whereType<FlyingPiece>().toList()) {
          if (c.done.isCompleted) c.removeFromParent();
        }
        await wait(0.25);
      case CaptureQuanEvent(:final playerId, :final cellId, :final value):
        final from = g.cells[cellId].center;
        flash[cellId] = 1;
        quan[cellId] = false;
        add(Sparkle(from, u * 0.8));
        final gem = FlyingPiece(
          from: from,
          to: g.pileSlot(playerId, pileQuan[playerId] * 3 + 1),
          duration: 0.85 * visuals.speedFactor,
          kind: FlyKind.gem,
          radius: g.pebbleRadius * 2.4,
          lift: 0.3,
        );
        add(gem);
        floatText(
          '+$value',
          from - Offset(0, u * 0.3),
          AppColors.gold,
          big: true,
        );
        callbacks.onSound(Sfx.quan);
        await gem.done.future;
        gem.removeFromParent();
        pileQuan[playerId]++;
        scores[playerId] += value;
        displayScores.value = [...scores];
      case RefillEvent(
        :final playerId,
        :final cellIds,
        :final cost,
        :final borrowed,
      ):
        for (final b in borrowed.entries) {
          scores[b.key] -= b.value;
          scores[playerId] += b.value;
          floatText('−${b.value}', g.playerAnchors[b.key], playerColors[b.key]);
        }
        for (final c in cellIds) {
          dan[c]++;
          pulse[c] = 1;
        }
        scores[playerId] -= cost;
        displayScores.value = [...scores];
        floatText('−$cost', g.playerAnchors[playerId], playerColors[playerId]);
        callbacks.onNotice(e);
        callbacks.onSound(Sfx.refill);
        await wait(0.7);
      case CollectEvent(:final playerId, :final cellIds, :final count):
        for (final c in cellIds) {
          flash[c] = 1;
          final from = g.cells[c].center;
          for (var i = 0; i < min(dan[c], 3); i++) {
            add(
              FlyingPiece(
                from: from + Offset.fromDirection(i * 2.1, u * 0.12),
                to: pileTarget(g, playerId, i),
                duration: 0.5 * visuals.speedFactor,
                kind: FlyKind.stone,
                radius: u * 0.11,
                color: playerColors[playerId],
                lift: 0.25,
                fadeOut: true,
                delay: i * 0.05,
              ),
            );
          }
          dan[c] = 0;
        }
        floatText('+$count', g.pileLabel(playerId), Rc.text);
        callbacks.onSound(Sfx.capture);
        await wait(0.55);
        scores[playerId] += count * state.config.ruleset.danValue;
        displayScores.value = [...scores];
      case RepayEvent(:final fromId, :final toId, :final amount):
        scores[fromId] -= amount;
        scores[toId] += amount;
        displayScores.value = [...scores];
        floatText('−$amount', g.playerAnchors[fromId], playerColors[fromId]);
        floatText('+$amount', g.playerAnchors[toId], playerColors[toId]);
        callbacks.onNotice(e);
        await wait(0.55);
      case EliminateEvent():
        callbacks.onNotice(e);
        await wait(0.6);
      case RuleLoopGuardEvent():
        callbacks.onNotice(e);
        await wait(0.3);
      case EndTurnEvent():
        handCell = null;
        callbacks.onSound(Sfx.turn);
      case GameOverEvent():
        callbacks.onSound(Sfx.win);
        await wait(0.5);
    }
  }

  void floatText(String text, Offset at, Color color, {bool big = false}) {
    final u = geo?.unit ?? 40;
    var scale = 0.48;
    if (big) scale = 0.62;
    add(FloatingText(text, at, color, u * scale));
  }
}
