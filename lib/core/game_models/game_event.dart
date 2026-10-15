/// Event phát ra từ engine để UI phát animation và để ghi log replay.
/// Engine luôn tính xong trạng thái cuối trước; event chỉ mô tả diễn biến.
sealed class GameEvent {
  const GameEvent();

  String get type;
  Map<String, dynamic> toJson();

  static GameEvent fromJson(Map<String, dynamic> j) {
    final t = j['type'] as String;
    return switch (t) {
      'Pickup' => PickupEvent(j['cellId'] as int, j['count'] as int),
      'Drop' => DropEvent(j['cellId'] as int),
      'CaptureDan' => CaptureDanEvent(
        j['playerId'] as int,
        j['cellId'] as int,
        j['count'] as int,
      ),
      'CaptureQuan' => CaptureQuanEvent(
        j['playerId'] as int,
        j['cellId'] as int,
        j['value'] as int,
      ),
      'Refill' => RefillEvent(
        j['playerId'] as int,
        (j['cellIds'] as List).cast<int>(),
        j['cost'] as int,
        borrowed: {
          for (final e in ((j['borrowed'] as Map?) ?? const {}).entries)
            int.parse(e.key as String): e.value as int,
        },
      ),
      'Collect' => CollectEvent(
        j['playerId'] as int,
        (j['cellIds'] as List).cast<int>(),
        j['count'] as int,
      ),
      'Repay' => RepayEvent(
        j['fromId'] as int,
        j['toId'] as int,
        j['amount'] as int,
      ),
      'EndTurn' => EndTurnEvent(
        j['playerId'] as int,
        j['nextPlayerId'] as int?,
      ),
      'Eliminate' => EliminateEvent(j['playerId'] as int),
      'GameOver' => GameOverEvent(
        (j['winnerIds'] as List).cast<int>(),
        j['reason'] as String,
      ),
      'RuleLoopGuard' => RuleLoopGuardEvent(j['cellId'] as int),
      _ => throw FormatException('Unknown event type $t'),
    };
  }
}

/// Nhấc toàn bộ dân ở ô.
class PickupEvent extends GameEvent {
  const PickupEvent(this.cellId, this.count);
  final int cellId;
  final int count;
  @override
  String get type => 'Pickup';
  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    'cellId': cellId,
    'count': count,
  };
}

/// Rải 1 dân vào ô.
class DropEvent extends GameEvent {
  const DropEvent(this.cellId);
  final int cellId;
  @override
  String get type => 'Drop';
  @override
  Map<String, dynamic> toJson() => {'type': type, 'cellId': cellId};
}

class CaptureDanEvent extends GameEvent {
  const CaptureDanEvent(this.playerId, this.cellId, this.count);
  final int playerId;
  final int cellId;
  final int count;
  @override
  String get type => 'CaptureDan';
  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    'playerId': playerId,
    'cellId': cellId,
    'count': count,
  };
}

class CaptureQuanEvent extends GameEvent {
  const CaptureQuanEvent(this.playerId, this.cellId, this.value);
  final int playerId;
  final int cellId;
  final int value;
  @override
  String get type => 'CaptureQuan';
  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    'playerId': playerId,
    'cellId': cellId,
    'value': value,
  };
}

/// Hết dân: lấy dân đã ăn rải lại mỗi ô 1 dân; thiếu thì vay (`borrowed`:
/// chủ nợ → số dân vay).
class RefillEvent extends GameEvent {
  const RefillEvent(
    this.playerId,
    this.cellIds,
    this.cost, {
    this.borrowed = const {},
  });
  final int playerId;
  final List<int> cellIds;
  final int cost;
  final Map<int, int> borrowed;
  @override
  String get type => 'Refill';
  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    'playerId': playerId,
    'cellIds': cellIds,
    'cost': cost,
    if (borrowed.isNotEmpty)
      'borrowed': {for (final e in borrowed.entries) '${e.key}': e.value},
  };
}

/// Kết thúc ván: dân còn trên các ô của người nào thuộc về người đó.
class CollectEvent extends GameEvent {
  const CollectEvent(this.playerId, this.cellIds, this.count);
  final int playerId;
  final List<int> cellIds;
  final int count;
  @override
  String get type => 'Collect';
  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    'playerId': playerId,
    'cellIds': cellIds,
    'count': count,
  };
}

/// Trả nợ dân đã vay khi tính điểm.
class RepayEvent extends GameEvent {
  const RepayEvent(this.fromId, this.toId, this.amount);
  final int fromId;
  final int toId;
  final int amount;
  @override
  String get type => 'Repay';
  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    'fromId': fromId,
    'toId': toId,
    'amount': amount,
  };
}

class EndTurnEvent extends GameEvent {
  const EndTurnEvent(this.playerId, this.nextPlayerId);
  final int playerId;
  final int? nextPlayerId;
  @override
  String get type => 'EndTurn';
  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    'playerId': playerId,
    'nextPlayerId': nextPlayerId,
  };
}

class EliminateEvent extends GameEvent {
  const EliminateEvent(this.playerId);
  final int playerId;
  @override
  String get type => 'Eliminate';
  @override
  Map<String, dynamic> toJson() => {'type': type, 'playerId': playerId};
}

class GameOverEvent extends GameEvent {
  const GameOverEvent(this.winnerIds, this.reason);
  final List<int> winnerIds;
  final String reason;
  @override
  String get type => 'GameOver';
  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    'winnerIds': winnerIds,
    'reason': reason,
  };
}

/// Phát hiện trạng thái lặp trong cùng lượt → kết thúc lượt cưỡng bức.
class RuleLoopGuardEvent extends GameEvent {
  const RuleLoopGuardEvent(this.cellId);
  final int cellId;
  @override
  String get type => 'RuleLoopGuard';
  @override
  Map<String, dynamic> toJson() => {'type': type, 'cellId': cellId};
}
