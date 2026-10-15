import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/ai/ai_player.dart';
import '../../core/engine/move_result.dart';
import '../../core/engine/replay.dart';
import '../../core/engine/rules_engine.dart';
import '../../core/game_models/game_config.dart';
import '../../core/game_models/game_event.dart';
import '../../core/game_models/game_state.dart';
import '../../core/game_models/move.dart';
import '../../core/game_models/player.dart';
import '../../core/persistence/game_serializer.dart';
import '../achievements/stats_repository.dart';
import 'data/save_repository.dart';

/// Một lô animation: trạng thái trước, events, trạng thái sau.
class AnimationBatch {
  const AnimationBatch(this.id, this.before, this.events, this.after);
  final int id;
  final GameState before;
  final List<GameEvent> events;
  final GameState after;
}

class GameSessionState {
  const GameSessionState({
    required this.initial,
    required this.current,
    required this.shown,
    this.pending,
    this.aiThinking = false,
    this.hint,
    this.syncToken = 0,
  });

  final GameState initial;

  /// Trạng thái logic có thẩm quyền (đã tính xong).
  final GameState current;

  /// Trạng thái HUD đang hiển thị (trễ hơn `current` khi đang animation).
  final GameState shown;
  final AnimationBatch? pending;
  final bool aiThinking;
  final Move? hint;

  /// Tăng khi bàn cần đồng bộ cứng (ván mới, undo, khôi phục).
  final int syncToken;

  bool get busy => pending != null || aiThinking;
  bool get hasHuman => current.players.any((p) => p.type == PlayerType.human);
  bool get humanTurn =>
      !current.isOver && current.currentPlayer.type == PlayerType.human;
  bool get canUndo =>
      !busy &&
      !current.isOver &&
      current.history.any((m) => !current.players[m.playerId].isAi);

  GameSessionState copyWith({
    GameState? initial,
    GameState? current,
    GameState? shown,
    AnimationBatch? pending,
    bool clearPending = false,
    bool? aiThinking,
    Move? hint,
    bool clearHint = false,
    int? syncToken,
  }) => GameSessionState(
    initial: initial ?? this.initial,
    current: current ?? this.current,
    shown: shown ?? this.shown,
    pending: clearPending ? null : (pending ?? this.pending),
    aiThinking: aiThinking ?? this.aiThinking,
    hint: clearHint ? null : (hint ?? this.hint),
    syncToken: syncToken ?? this.syncToken,
  );
}

/// Chạy AI ngoài UI thread (isolate trên mobile/desktop; trên web `compute`
/// chạy cùng thread nhưng AI có time budget ngắn).
Map<String, dynamic> aiWorker(Map<String, dynamic> req) {
  final s = GameSerializer.stateFromJson(req['state'] as Map<String, dynamic>);
  final level = AiLevel.values.byName(req['level'] as String);
  return AiPlayer().chooseMove(s, level: level).toJson();
}

Future<Move> computeAiMove(GameState s, AiLevel level) async {
  final legal = const RulesEngine().getLegalMoves(s);
  try {
    final r = await compute(aiWorker, {
      'state': GameSerializer.stateToJson(s),
      'level': level.name,
    });
    final m = Move.fromJson(r);
    return legal.contains(m) ? m : legal.first;
  } catch (_) {
    return legal.first; // fallback legal move
  }
}

class GameSessionController extends Notifier<GameSessionState?> {
  final _engine = const RulesEngine();
  int _batchId = 0;
  int _session = 0;

  /// Độ trễ tối thiểu trước nước AI để người xem theo kịp.
  Duration aiDelay = const Duration(milliseconds: 250);

  @override
  GameSessionState? build() => null;

  SaveRepository get _saves => ref.read(saveRepositoryProvider);

  void start(GameConfig config, List<Player> players) {
    final s = _engine.newGame(config, players: players);
    _session++;
    state = GameSessionState(
      initial: s,
      current: s,
      shown: s,
      syncToken: (state?.syncToken ?? 0) + 1,
    );
    _persist();
    _maybeAi();
  }

  /// Chơi lại cùng cấu hình (seed mới).
  void restart() {
    final st = state;
    if (st == null) return;
    final cfg = GameConfig(
      playerCount: st.initial.config.playerCount,
      ruleset: st.initial.config.ruleset,
      seed: DateTime.now().millisecondsSinceEpoch & 0x7fffffff,
    );
    start(cfg, [
      for (final p in st.initial.players)
        Player(id: p.id, name: p.name, type: p.type, aiLevel: p.aiLevel),
    ]);
  }

  bool resumeSaved() {
    final g = _saves.load();
    if (g == null || g.current.isOver) return false;
    _session++;
    state = GameSessionState(
      initial: g.initial,
      current: g.current,
      shown: g.current,
      syncToken: (state?.syncToken ?? 0) + 1,
    );
    _maybeAi();
    return true;
  }

  /// Người chơi gửi nước. Trả `null` nếu hợp lệ, ngược lại lý do từ chối.
  RejectReason? submitMove(Move m) {
    final st = state;
    if (st == null || st.busy) return RejectReason.gameOver;
    if (st.current.currentPlayer.isAi) return RejectReason.notYourTurn;
    return _apply(m);
  }

  RejectReason? _apply(Move m) {
    final st = state!;
    final r = _engine.applyMove(st.current, m);
    switch (r) {
      case MoveRejected(:final reason):
        return reason;
      case MoveAccepted(:final state, :final events):
        this.state = st.copyWith(
          current: state,
          pending: AnimationBatch(++_batchId, st.current, events, state),
          clearHint: true,
          aiThinking: false,
        );
        return null;
    }
  }

  /// Flame báo đã phát xong animation của lô `id`.
  void animationDone(int id) {
    final st = state;
    if (st == null || st.pending?.id != id) return;
    state = st.copyWith(shown: st.current, clearPending: true);
    if (st.current.isOver) {
      _saves.clear();
      ref.read(statsProvider.notifier).recordGame(st.current);
    } else {
      _persist();
      _maybeAi();
    }
  }

  void undo() {
    final st = state;
    if (st == null || !st.canUndo) return;
    final h = st.current.history;
    var i = h.length - 1;
    while (i >= 0 && st.current.players[h[i].playerId].isAi) {
      i--;
    }
    if (i < 0) return;
    final s = const Replay().replay(st.initial, h.sublist(0, i));
    state = st.copyWith(
      current: s,
      shown: s,
      clearHint: true,
      syncToken: st.syncToken + 1,
    );
    _persist();
  }

  Future<void> requestHint() async {
    final st = state;
    if (st == null || st.busy || !st.humanTurn) return;
    final session = _session;
    final m = await computeAiMove(st.current, AiLevel.medium);
    final now = state;
    if (session != _session || now == null || now.current != st.current) return;
    state = now.copyWith(hint: m);
  }

  void clearHint() {
    if (state?.hint != null) state = state!.copyWith(clearHint: true);
  }

  void abandon() {
    _session++;
    state = null;
  }

  Future<void> _maybeAi() async {
    final st = state;
    if (st == null || st.current.isOver || st.busy) return;
    final p = st.current.currentPlayer;
    if (!p.isAi) return;
    final session = _session;
    final snapshot = st.current;
    state = st.copyWith(aiThinking: true);
    final results = await Future.wait([
      computeAiMove(snapshot, p.aiLevel),
      Future<void>.delayed(aiDelay),
    ]);
    final now = state;
    if (session != _session || now == null || now.current != snapshot) return;
    _apply(results.first as Move);
  }

  void _persist() {
    final st = state;
    if (st == null || st.current.isOver) return;
    _saves.save(
      SavedGame(
        initial: st.initial,
        current: st.current,
        savedAt: DateTime.now(),
      ),
    );
  }
}

final gameSessionProvider =
    NotifierProvider<GameSessionController, GameSessionState?>(
      GameSessionController.new,
    );
