import '../game_models/game_event.dart';
import '../game_models/game_state.dart';
import '../game_models/move.dart';
import 'move_result.dart';
import 'rules_engine.dart';

class ReplayStep {
  const ReplayStep(this.move, this.events, this.state);
  final Move move;
  final List<GameEvent> events;
  final GameState state;
}

/// Phát lại ván từ trạng thái ban đầu + danh sách nước đi (deterministic).
class Replay {
  const Replay([this.engine = const RulesEngine()]);
  final RulesEngine engine;

  List<ReplayStep> steps(GameState initial, List<Move> moves) {
    final out = <ReplayStep>[];
    var s = initial;
    for (final m in moves) {
      final r = engine.applyMove(s, m);
      switch (r) {
        case MoveAccepted(:final state, :final events):
          out.add(ReplayStep(m, events, state));
          s = state;
        case MoveRejected(:final reason):
          throw StateError('Replay lệch: nước $m bị từ chối (${reason.name})');
      }
    }
    return out;
  }

  GameState replay(GameState initial, List<Move> moves) {
    final st = steps(initial, moves);
    if (st.isEmpty) return initial;
    return st.last.state;
  }
}
