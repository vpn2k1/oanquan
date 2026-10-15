/// Hướng rải trên vòng: clockwise = chỉ số tăng, counterClockwise = giảm.
enum Direction {
  clockwise(1),
  counterClockwise(-1);

  const Direction(this.step);
  final int step;

  Direction get opposite => this == clockwise ? counterClockwise : clockwise;
}

class Move {
  const Move({
    required this.playerId,
    required this.sourceCellId,
    required this.direction,
  });

  final int playerId;
  final int sourceCellId;
  final Direction direction;

  Map<String, dynamic> toJson() => {
    'playerId': playerId,
    'sourceCellId': sourceCellId,
    'direction': direction.name,
  };

  factory Move.fromJson(Map<String, dynamic> j) => Move(
    playerId: j['playerId'] as int,
    sourceCellId: j['sourceCellId'] as int,
    direction: Direction.values.byName(j['direction'] as String),
  );

  @override
  bool operator ==(Object other) =>
      other is Move &&
      other.playerId == playerId &&
      other.sourceCellId == sourceCellId &&
      other.direction == direction;

  @override
  int get hashCode => Object.hash(playerId, sourceCellId, direction);

  @override
  String toString() =>
      'Move(p$playerId, #$sourceCellId, ${direction == Direction.clockwise ? '+' : '-'})';
}
