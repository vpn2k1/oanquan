/// Hợp đồng mạng (WebSocket JSON) cho chế độ online — Dart thuần.
/// Mọi message có `type`; client gửi `actionId` để server xử lý idempotent.
/// Server là bên duy nhất quyết định nước hợp lệ, điểm và revision.
library;

import '../../core/game_models/move.dart';

const protocolVersion = 1;

sealed class ClientMessage {
  const ClientMessage(this.actionId);
  final String actionId;
  String get type;
  Map<String, dynamic> toJson();

  static ClientMessage fromJson(Map<String, dynamic> j) {
    final a = j['actionId'] as String;
    return switch (j['type']) {
      'CreateRoom' => CreateRoom(
        a,
        j['playerName'] as String,
        j['playerCount'] as int,
      ),
      'JoinRoom' => JoinRoom(
        a,
        j['matchId'] as String,
        j['playerName'] as String,
      ),
      'SubmitMove' => SubmitMove(
        a,
        j['matchId'] as String,
        j['playerId'] as int,
        j['revision'] as int,
        Move.fromJson(j['move'] as Map<String, dynamic>),
      ),
      'PlayerReconnect' => PlayerReconnect(
        a,
        j['matchId'] as String,
        j['playerId'] as int,
        j['sessionToken'] as String,
      ),
      final t => throw FormatException('Unknown client message $t'),
    };
  }
}

class CreateRoom extends ClientMessage {
  const CreateRoom(super.actionId, this.playerName, this.playerCount);
  final String playerName;
  final int playerCount;
  @override
  String get type => 'CreateRoom';
  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    'actionId': actionId,
    'playerName': playerName,
    'playerCount': playerCount,
  };
}

class JoinRoom extends ClientMessage {
  const JoinRoom(super.actionId, this.matchId, this.playerName);
  final String matchId;
  final String playerName;
  @override
  String get type => 'JoinRoom';
  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    'actionId': actionId,
    'matchId': matchId,
    'playerName': playerName,
  };
}

class SubmitMove extends ClientMessage {
  const SubmitMove(
    super.actionId,
    this.matchId,
    this.playerId,
    this.revision,
    this.move,
  );
  final String matchId;
  final int playerId;

  /// Revision mà client nhìn thấy; lệch → bị từ chối (stale).
  final int revision;
  final Move move;
  @override
  String get type => 'SubmitMove';
  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    'actionId': actionId,
    'matchId': matchId,
    'playerId': playerId,
    'revision': revision,
    'move': move.toJson(),
  };
}

class PlayerReconnect extends ClientMessage {
  const PlayerReconnect(
    super.actionId,
    this.matchId,
    this.playerId,
    this.sessionToken,
  );
  final String matchId;
  final int playerId;
  final String sessionToken;
  @override
  String get type => 'PlayerReconnect';
  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    'actionId': actionId,
    'matchId': matchId,
    'playerId': playerId,
    'sessionToken': sessionToken,
  };
}

sealed class ServerMessage {
  const ServerMessage(this.matchId);
  final String matchId;
  String get type;
  Map<String, dynamic> toJson();

  static ServerMessage fromJson(Map<String, dynamic> j) {
    final m = j['matchId'] as String;
    return switch (j['type']) {
      'StateSnapshot' => StateSnapshot(
        m,
        j['revision'] as int,
        j['playerId'] as int?,
        j['sessionToken'] as String?,
        (j['seats'] as List).cast<String>(),
        j['playerCount'] as int,
        j['state'] as Map<String, dynamic>?,
      ),
      'MoveAccepted' => MoveAccepted(
        m,
        j['actionId'] as String,
        j['revision'] as int,
        Move.fromJson(j['move'] as Map<String, dynamic>),
        (j['events'] as List).cast<Map<String, dynamic>>(),
      ),
      'MoveRejected' => MoveRejected(
        m,
        j['actionId'] as String,
        j['reason'] as String,
        j['revision'] as int,
      ),
      'GameEnded' => GameEnded(
        m,
        j['revision'] as int,
        (j['winnerIds'] as List).cast<int>(),
      ),
      final t => throw FormatException('Unknown server message $t'),
    };
  }
}

/// Ảnh chụp trạng thái có thẩm quyền. `state` null khi phòng chưa đủ người.
class StateSnapshot extends ServerMessage {
  const StateSnapshot(
    super.matchId,
    this.revision,
    this.playerId,
    this.sessionToken,
    this.seats,
    this.playerCount,
    this.state,
  );
  final int revision;

  /// Ghế của người nhận (null nếu chỉ xem).
  final int? playerId;
  final String? sessionToken;
  final List<String> seats;
  final int playerCount;
  final Map<String, dynamic>? state;
  @override
  String get type => 'StateSnapshot';
  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    'matchId': matchId,
    'revision': revision,
    'playerId': playerId,
    'sessionToken': sessionToken,
    'seats': seats,
    'playerCount': playerCount,
    'state': state,
  };
}

class MoveAccepted extends ServerMessage {
  const MoveAccepted(
    super.matchId,
    this.actionId,
    this.revision,
    this.move,
    this.events,
  );
  final String actionId;
  final int revision;
  final Move move;
  final List<Map<String, dynamic>> events;
  @override
  String get type => 'MoveAccepted';
  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    'matchId': matchId,
    'actionId': actionId,
    'revision': revision,
    'move': move.toJson(),
    'events': events,
  };
}

/// Từ chối nước đi hoặc thao tác phòng (`reason` là mã máy đọc được).
class MoveRejected extends ServerMessage {
  const MoveRejected(super.matchId, this.actionId, this.reason, this.revision);
  final String actionId;
  final String reason;
  final int revision;
  @override
  String get type => 'MoveRejected';
  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    'matchId': matchId,
    'actionId': actionId,
    'reason': reason,
    'revision': revision,
  };
}

class GameEnded extends ServerMessage {
  const GameEnded(super.matchId, this.revision, this.winnerIds);
  final int revision;
  final List<int> winnerIds;
  @override
  String get type => 'GameEnded';
  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    'matchId': matchId,
    'revision': revision,
    'winnerIds': winnerIds,
  };
}
