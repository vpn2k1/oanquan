import 'package:flutter_test/flutter_test.dart';
import 'package:o_quan_viet/core/engine/move_result.dart';
import 'package:o_quan_viet/core/game_models/game_state.dart';
import 'package:o_quan_viet/core/game_models/move.dart';

import 'fixtures.dart';

const cw = Direction.clockwise;
const ccw = Direction.counterClockwise;

/// Áp nước đi và khẳng định được chấp nhận.
MoveAccepted ok(GameState s, Move m) {
  final r = engine.applyMove(s, m);
  expect(r, isA<MoveAccepted>(), reason: '$m bị từ chối: $r');
  return r as MoveAccepted;
}

Move mv(int p, int cell, Direction d) =>
    Move(playerId: p, sourceCellId: cell, direction: d);
