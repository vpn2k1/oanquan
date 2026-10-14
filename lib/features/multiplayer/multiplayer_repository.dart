import 'dart:async';
import 'dart:convert';

import 'match_server.dart';
import 'protocol.dart';

/// Cổng kết nối online. Bản thật: WebSocket tới backend authoritative.
abstract class MultiplayerRepository {
  Stream<ServerMessage> get messages;
  Future<void> send(ClientMessage message);
  Future<void> close();
}

/// Bản giả lập cục bộ: đi qua JSON encode/decode như trên dây thật,
/// tới một [MatchServer] chạy trong cùng tiến trình. KHÔNG phải mạng thật.
class LocalFakeMultiplayerRepository implements MultiplayerRepository {
  LocalFakeMultiplayerRepository(this.hub, this.clientId) {
    hub._clients[clientId] = _controller;
  }

  final FakeServerHub hub;
  final String clientId;
  final _controller = StreamController<ServerMessage>.broadcast();

  @override
  Stream<ServerMessage> get messages => _controller.stream;

  @override
  Future<void> send(ClientMessage message) async {
    final wire = jsonEncode(message.toJson());
    hub._receive(clientId, wire);
  }

  @override
  Future<void> close() async {
    hub._clients.remove(clientId);
    await _controller.close();
  }
}

class FakeServerHub {
  FakeServerHub([MatchServer? server]) : server = server ?? MatchServer();
  final MatchServer server;
  final Map<String, StreamController<ServerMessage>> _clients = {};

  void _receive(String clientId, String wire) {
    final msg = ClientMessage.fromJson(jsonDecode(wire) as Map<String, dynamic>);
    for (final o in server.handle(clientId, msg)) {
      final c = _clients[o.clientId];
      if (c == null || c.isClosed) continue;
      c.add(ServerMessage.fromJson(jsonDecode(jsonEncode(o.message.toJson())) as Map<String, dynamic>));
    }
  }
}
