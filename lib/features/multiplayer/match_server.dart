import 'dart:math';

import '../../core/engine/move_result.dart' as engine_result;
import '../../core/engine/rules_engine.dart';
import '../../core/game_models/game_config.dart';
import '../../core/game_models/game_state.dart';
import '../../core/game_models/player.dart';
import '../../core/persistence/game_serializer.dart';
import 'protocol.dart';

/// Gói tin gửi tới một client cụ thể.
class Outgoing {
  const Outgoing(this.clientId, this.message);
  final String clientId;
  final ServerMessage message;
}

class _Room {
  _Room(this.matchId, this.playerCount);
  final String matchId;
  final int playerCount;
  final List<String> names = [];
  final List<String> tokens = [];
  final Map<int, String> clientOf = {};
  GameState? state;
  int revision = 0;

  /// actionId → phản hồi đã gửi (idempotency).
  final Map<String, List<Outgoing>> processed = {};
}

/// Server có thẩm quyền chạy trong tiến trình (dùng cho test và demo).
/// Logic này có thể chạy nguyên vẹn trong backend Dart (shelf/WebSocket)
/// vì chỉ phụ thuộc engine thuần.
class MatchServer {
  MatchServer({Random? random, this.engine = const RulesEngine()})
      : _rng = random ?? Random();

  final RulesEngine engine;
  final Random _rng;
  final Map<String, _Room> _rooms = {};
  final Map<String, (String, int)> _seatOfClient = {};

  int get roomCount => _rooms.length;

  String _code() {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    String c;
    do {
      c = List.generate(5, (_) => alphabet[_rng.nextInt(alphabet.length)]).join();
    } while (_rooms.containsKey(c));
    return c;
  }

  String _token() => List.generate(16, (_) => _rng.nextInt(16).toRadixString(16)).join();

  List<Outgoing> handle(String clientId, ClientMessage msg) {
    switch (msg) {
      case CreateRoom(:final actionId, :final playerName, :final playerCount):
        if (playerCount < 2 || playerCount > 4) {
          return [Outgoing(clientId, MoveRejected('', actionId, 'invalidPlayerCount', 0))];
        }
        final room = _Room(_code(), playerCount);
        _rooms[room.matchId] = room;
        return _seat(room, clientId, playerName, actionId);
      case JoinRoom(:final actionId, :final matchId, :final playerName):
        final room = _rooms[matchId.toUpperCase()];
        if (room == null) {
          return [Outgoing(clientId, MoveRejected(matchId, actionId, 'roomNotFound', 0))];
        }
        final cached = room.processed[actionId];
        if (cached != null) return cached;
        if (room.names.length >= room.playerCount) {
          return [Outgoing(clientId, MoveRejected(matchId, actionId, 'roomFull', room.revision))];
        }
        return _seat(room, clientId, playerName, actionId);
      case PlayerReconnect(:final actionId, :final matchId, :final playerId, :final sessionToken):
        final room = _rooms[matchId];
        if (room == null ||
            playerId < 0 ||
            playerId >= room.tokens.length ||
            room.tokens[playerId] != sessionToken) {
          return [Outgoing(clientId, MoveRejected(matchId, actionId, 'unauthorized', room?.revision ?? 0))];
        }
        room.clientOf[playerId] = clientId;
        _seatOfClient[clientId] = (matchId, playerId);
        return [Outgoing(clientId, _snapshot(room, playerId))];
      case SubmitMove(:final actionId, :final matchId, :final playerId, :final revision, :final move):
        final room = _rooms[matchId];
        if (room == null) {
          return [Outgoing(clientId, MoveRejected(matchId, actionId, 'roomNotFound', 0))];
        }
        final cached = room.processed[actionId];
        if (cached != null) return cached;
        List<Outgoing> reject(String reason) =>
            [Outgoing(clientId, MoveRejected(matchId, actionId, reason, room.revision))];
        final seat = _seatOfClient[clientId];
        // Client chỉ được đi cho ghế của chính mình.
        if (seat == null || seat.$1 != matchId || seat.$2 != playerId || move.playerId != playerId) {
          return reject('unauthorized');
        }
        final state = room.state;
        if (state == null) return reject('notStarted');
        if (revision != room.revision) return reject('staleRevision');
        final r = engine.applyMove(state, move);
        switch (r) {
          case engine_result.MoveRejected(:final reason):
            return reject(reason.name);
          case engine_result.MoveAccepted(state: final next, :final events):
            room.state = next;
            room.revision++;
            final out = <Outgoing>[
              for (final c in room.clientOf.values)
                Outgoing(c, MoveAccepted(matchId, actionId, room.revision, move,
                    [for (final e in events) e.toJson()])),
              if (next.isOver)
                for (final c in room.clientOf.values)
                  Outgoing(c, GameEnded(matchId, room.revision, next.winnerIds)),
            ];
            room.processed[actionId] = out;
            return out;
        }
    }
  }

  List<Outgoing> _seat(_Room room, String clientId, String name, String actionId) {
    final id = room.names.length;
    room.names.add(name);
    room.tokens.add(_token());
    room.clientOf[id] = clientId;
    _seatOfClient[clientId] = (room.matchId, id);
    if (room.names.length == room.playerCount) {
      room.state = engine.newGame(
        GameConfig(playerCount: room.playerCount, seed: _rng.nextInt(1 << 31)),
        players: [for (var i = 0; i < room.playerCount; i++) Player(id: i, name: room.names[i])],
      );
    }
    final out = [
      for (final e in room.clientOf.entries) Outgoing(e.value, _snapshot(room, e.key)),
    ];
    room.processed[actionId] = out;
    return out;
  }

  StateSnapshot _snapshot(_Room room, int playerId) => StateSnapshot(
        room.matchId,
        room.revision,
        playerId,
        room.tokens[playerId],
        List.unmodifiable(room.names),
        room.playerCount,
        room.state == null ? null : GameSerializer.stateToJson(room.state!),
      );
}
