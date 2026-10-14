import '../engine/board_topology.dart';
import '../game_models/game_state.dart';

/// Hàm đánh giá heuristic thuần.
abstract final class Evaluation {
  static const winBonus = 1000.0;

  /// Giá trị "tài sản" của từng người: điểm + một phần dân bên mình
  /// (tiềm năng đi tiếp) − phạt khi sắp hết dân / bị loại.
  static List<double> playerValues(GameState s) {
    final topo = BoardTopology(s.config);
    final out = <double>[];
    for (final p in s.players) {
      var v = p.score.toDouble();
      if (p.active) {
        final own = topo.playerCells(p.id);
        var dan = 0;
        var filled = 0;
        for (final i in own) {
          final d = s.cells[i].danCount;
          dan += d;
          if (d > 0) filled++;
        }
        v += dan * 0.25 + filled * 0.3;
        if (dan == 0 && p.score < s.config.ruleset.refillCost) v -= 15;
      } else {
        v -= 25;
      }
      out.add(v);
    }
    if (s.isOver) {
      for (final w in s.winnerIds) {
        out[w] += winBonus / s.winnerIds.length;
      }
    }
    return out;
  }

  /// Giá trị tương đối cho người `me` (2 người: hiệu số; N người: so với đối thủ mạnh nhất).
  static double relative(List<double> values, int me) {
    var best = double.negativeInfinity;
    for (var i = 0; i < values.length; i++) {
      if (i != me && values[i] > best) best = values[i];
    }
    return values[me] - best;
  }

  /// Vector đánh giá cho Max-N: mỗi phần tử là giá trị tương đối của người đó.
  static List<double> vector(GameState s) {
    final v = playerValues(s);
    return [for (var i = 0; i < v.length; i++) relative(v, i)];
  }
}
