import '../game_models/game_event.dart';
import '../game_models/game_state.dart';

enum RejectReason {
  gameOver,
  notYourTurn,
  playerInactive,
  cellOutOfRange,
  quanCellAsSource,
  notOwnCell,
  emptyCell,
}

/// Kết quả `applyMove`: chấp nhận (trạng thái mới + events) hoặc từ chối.
sealed class MoveResult {
  const MoveResult();
}

class MoveAccepted extends MoveResult {
  const MoveAccepted(this.state, this.events);
  final GameState state;
  final List<GameEvent> events;
}

class MoveRejected extends MoveResult {
  const MoveRejected(this.reason);
  final RejectReason reason;

  @override
  String toString() => 'MoveRejected(${reason.name})';
}
