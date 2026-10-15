import 'package:o_quan_viet/core/engine/rules_engine.dart';
import 'package:o_quan_viet/core/game_models/cell.dart';
import 'package:o_quan_viet/core/game_models/game_config.dart';
import 'package:o_quan_viet/core/game_models/game_state.dart';

const engine = RulesEngine();

GameState initial(int n) => engine.newGame(GameConfig.preset(n));

/// Tạo trạng thái tùy chỉnh: `dan` là danCount từng ô, `quan` là tập ô còn token.
GameState custom(
  int n, {
  required List<int> dan,
  Set<int>? quan,
  List<int>? scores,
  int turn = 0,
  Set<int> inactive = const {},
}) {
  final base = initial(n);
  assert(dan.length == base.ringLength);
  final q =
      quan ??
      {
        for (final c in base.cells)
          if (c.isQuanCell) c.id,
      };
  return base.copyWith(
    cells: [
      for (final c in base.cells)
        c.copyWith(
          danCount: dan[c.id],
          hasQuan: c.kind == CellKind.quan && q.contains(c.id),
        ),
    ],
    players: [
      for (final p in base.players)
        p.copyWith(score: scores?[p.id] ?? 0, active: !inactive.contains(p.id)),
    ],
    turnPlayer: turn,
  );
}

List<int> danOf(GameState s) => [for (final c in s.cells) c.danCount];
