import 'dart:math';

import '../engine/move_result.dart';
import '../engine/rules_engine.dart';
import '../game_models/game_state.dart';
import '../game_models/move.dart';
import '../game_models/player.dart';
import 'evaluation.dart';

class _Timeout implements Exception {}

class AiSettings {
  const AiSettings({
    required this.maxDepth,
    required this.budget,
    this.noise = 0,
  });

  final int maxDepth;
  final Duration budget;

  /// Xác suất chọn nước ngẫu nhiên (mức Easy).
  final double noise;

  static AiSettings forLevel(AiLevel level, int playerCount) => switch (level) {
    AiLevel.easy => const AiSettings(
      maxDepth: 1,
      budget: Duration(milliseconds: 60),
      noise: 0.35,
    ),
    AiLevel.medium => AiSettings(
      maxDepth: playerCount == 2 ? 3 : 2,
      budget: const Duration(milliseconds: 200),
    ),
    AiLevel.hard => AiSettings(
      maxDepth: playerCount == 2 ? 9 : 4,
      budget: const Duration(milliseconds: 450),
    ),
  };
}

/// AI thuần Dart: Minimax + alpha-beta (2 người), Max-N (3/4 người).
/// Deterministic theo seed; luôn trả về một nước hợp lệ.
class AiPlayer {
  AiPlayer({this.engine = const RulesEngine()});

  final RulesEngine engine;
  late Stopwatch _clock;
  late Duration _budget;
  int nodes = 0;

  Move chooseMove(
    GameState s, {
    AiLevel? level,
    AiSettings? settings,
    int? seed,
  }) {
    final legal = engine.getLegalMoves(s);
    if (legal.isEmpty) {
      throw StateError('Không có nước hợp lệ cho người ${s.turnPlayer}');
    }
    if (legal.length == 1) return legal.first;
    final me = s.turnPlayer;
    final cfg =
        settings ??
        AiSettings.forLevel(
          level ?? s.players[me].aiLevel,
          s.config.playerCount,
        );
    final rng = Random(seed ?? (s.config.seed * 7919 + s.moveNumber * 31 + me));

    if (cfg.noise > 0 && rng.nextDouble() < cfg.noise) {
      return legal[rng.nextInt(legal.length)];
    }

    _clock = Stopwatch()..start();
    _budget = cfg.budget;
    nodes = 0;

    var best = _orderMoves(s, legal, me).first;
    try {
      for (var depth = 1; depth <= cfg.maxDepth; depth++) {
        final r = _searchRoot(s, legal, depth, me, rng);
        if (r != null) best = r;
      }
    } on _Timeout {
      // Giữ kết quả của độ sâu đã hoàn tất gần nhất.
    } catch (_) {
      // Fallback an toàn: nước hợp lệ đầu tiên đã sắp xếp.
    }
    return best;
  }

  Move? _searchRoot(
    GameState s,
    List<Move> legal,
    int depth,
    int me,
    Random rng,
  ) {
    final ordered = _orderMoves(s, legal, me);
    final twoPlayer = s.config.playerCount == 2;
    double bestVal = double.negativeInfinity;
    final bests = <Move>[];
    for (final m in ordered) {
      final child = _apply(s, m);
      final double v;
      if (twoPlayer) {
        // Alpha thấp hơn bestVal một chút để nước đồng giá trả về giá trị đúng,
        // còn nước kém hơn chỉ trả cận trên < bestVal (không lọt vào nhóm đồng hạng).
        v = _alphaBeta(child, depth - 1, bestVal - 1e-6, double.infinity, me);
      } else {
        v = _maxN(child, depth - 1)[me];
      }
      if (v > bestVal + 1e-9) {
        bestVal = v;
        bests
          ..clear()
          ..add(m);
      } else if ((v - bestVal).abs() <= 1e-9) {
        bests.add(m);
      }
    }
    if (bests.isEmpty) return null;
    return bests[rng.nextInt(bests.length)];
  }

  GameState _apply(GameState s, Move m) {
    _tick();
    final r = engine.applyMove(s, m, recordEvents: false, recordHistory: false);
    return (r as MoveAccepted).state;
  }

  void _tick() {
    nodes++;
    if ((nodes & 63) == 0 && _clock.elapsed > _budget) throw _Timeout();
  }

  /// Sắp xếp nước theo đánh giá 1-ply (tăng hiệu quả alpha-beta).
  List<Move> _orderMoves(GameState s, List<Move> moves, int me) {
    final scored = [
      for (final m in moves)
        (
          m,
          Evaluation.relative(Evaluation.playerValues(_applyNoTick(s, m)), me),
        ),
    ]..sort((a, b) => b.$2.compareTo(a.$2));
    return [for (final e in scored) e.$1];
  }

  GameState _applyNoTick(GameState s, Move m) =>
      (engine.applyMove(s, m, recordEvents: false, recordHistory: false)
              as MoveAccepted)
          .state;

  double _alphaBeta(GameState s, int depth, double alpha, double beta, int me) {
    if (depth == 0 || s.isOver) {
      return Evaluation.relative(Evaluation.playerValues(s), me);
    }
    final moves = engine.getLegalMoves(s);
    if (s.turnPlayer == me) {
      var v = double.negativeInfinity;
      for (final m in moves) {
        v = max(v, _alphaBeta(_apply(s, m), depth - 1, alpha, beta, me));
        alpha = max(alpha, v);
        if (alpha >= beta) break;
      }
      return v;
    } else {
      var v = double.infinity;
      for (final m in moves) {
        v = min(v, _alphaBeta(_apply(s, m), depth - 1, alpha, beta, me));
        beta = min(beta, v);
        if (alpha >= beta) break;
      }
      return v;
    }
  }

  List<double> _maxN(GameState s, int depth) {
    if (depth == 0 || s.isOver) return Evaluation.vector(s);
    final p = s.turnPlayer;
    List<double>? best;
    for (final m in engine.getLegalMoves(s)) {
      final v = _maxN(_apply(s, m), depth - 1);
      if (best == null || v[p] > best[p]) best = v;
    }
    return best ?? Evaluation.vector(s);
  }
}
