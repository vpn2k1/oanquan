import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:o_quan_viet/core/engine/rules_engine.dart';
import 'package:o_quan_viet/core/game_models/move.dart';
import 'package:o_quan_viet/core/persistence/game_serializer.dart';
import 'package:o_quan_viet/features/multiplayer/match_server.dart';
import 'package:o_quan_viet/features/multiplayer/multiplayer_repository.dart';
import 'package:o_quan_viet/features/multiplayer/protocol.dart';

void main() {
  late MatchServer server;
  setUp(() => server = MatchServer(random: Random(1)));

  final tokens = <String, String>{};

  String startRoom() {
    final created = server.handle('a', const CreateRoom('a1', 'An', 2));
    final snap = created.single.message as StateSnapshot;
    expect(snap.state, isNull, reason: 'chưa đủ người');
    final joined = server.handle('b', JoinRoom('b1', snap.matchId, 'Bình'));
    expect(joined.map((o) => o.clientId).toSet(), {'a', 'b'});
    for (final o in joined) {
      final s = o.message as StateSnapshot;
      expect(s.state, isNotNull);
      expect(s.revision, 0);
      tokens[o.clientId] = s.sessionToken!;
    }
    return snap.matchId;
  }

  test('tạo phòng, vào phòng, đủ người thì server phát snapshot', () {
    final id = startRoom();
    expect(id.length, 5);
    final full = server.handle('c', JoinRoom('c1', id, 'Chi'));
    expect((full.single.message as MoveRejected).reason, 'roomFull');
    final missing = server.handle('c', const JoinRoom('c2', 'ZZZZZ', 'Chi'));
    expect((missing.single.message as MoveRejected).reason, 'roomNotFound');
  });

  test(
    'server xác thực nước đi: sai ghế, sai lượt, revision cũ, nước phạm luật',
    () {
      final id = startRoom();
      const m0 = Move(
        playerId: 0,
        sourceCellId: 1,
        direction: Direction.clockwise,
      );
      // b cố đi thay a
      expect(
        (server.handle('b', SubmitMove('x1', id, 0, 0, m0)).single.message
                as MoveRejected)
            .reason,
        'unauthorized',
      );
      // b đi ngoài lượt
      const m1 = Move(
        playerId: 1,
        sourceCellId: 7,
        direction: Direction.clockwise,
      );
      expect(
        (server.handle('b', SubmitMove('x2', id, 1, 0, m1)).single.message
                as MoveRejected)
            .reason,
        'notYourTurn',
      );
      // a chọn ô đối thủ
      const bad = Move(
        playerId: 0,
        sourceCellId: 8,
        direction: Direction.clockwise,
      );
      expect(
        (server.handle('a', SubmitMove('x3', id, 0, 0, bad)).single.message
                as MoveRejected)
            .reason,
        'notOwnCell',
      );
      // revision cũ
      expect(
        (server.handle('a', SubmitMove('x4', id, 0, 5, m0)).single.message
                as MoveRejected)
            .reason,
        'staleRevision',
      );
      // hợp lệ → cả hai nhận MoveAccepted revision 1
      final ok = server.handle('a', SubmitMove('x5', id, 0, 0, m0));
      expect(ok.length, 2);
      for (final o in ok) {
        final acc = o.message as MoveAccepted;
        expect(acc.revision, 1);
        expect(acc.events, isNotEmpty);
      }
    },
  );

  test('idempotency: gửi lại cùng actionId không áp dụng hai lần', () {
    final id = startRoom();
    const m0 = Move(
      playerId: 0,
      sourceCellId: 1,
      direction: Direction.clockwise,
    );
    final first = server.handle('a', SubmitMove('dup', id, 0, 0, m0));
    final again = server.handle('a', SubmitMove('dup', id, 0, 0, m0));
    expect(identical(first, again), isTrue);
    expect((again.first.message as MoveAccepted).revision, 1);
    // nước tiếp theo vẫn dựa trên revision 1
    final snap = server.handle('a', PlayerReconnect('r', id, 0, tokens['a']!));
    expect((snap.single.message as StateSnapshot).revision, 1);
  });

  test('reconnect cần sessionToken đúng', () {
    final id = startRoom();
    final bad = server.handle('z', PlayerReconnect('r1', id, 0, 'sai'));
    expect((bad.single.message as MoveRejected).reason, 'unauthorized');
  });

  test('reconnect thu hồi quyền của kết nối cũ', () {
    final id = startRoom();
    final r = server.handle('a2', PlayerReconnect('r1', id, 0, tokens['a']!));
    expect(r.single.message, isA<StateSnapshot>());
    const m0 = Move(
      playerId: 0,
      sourceCellId: 1,
      direction: Direction.clockwise,
    );
    expect(
      (server.handle('a', SubmitMove('y1', id, 0, 0, m0)).single.message
              as MoveRejected)
          .reason,
      'unauthorized',
    );
    expect(
      server.handle('a2', SubmitMove('y2', id, 0, 0, m0)).first.message,
      isA<MoveAccepted>(),
    );
  });

  test(
    'một client không giữ hai ghế; actionId trùng giữa các client không lẫn cache',
    () {
      final created = server.handle('a', const CreateRoom('a1', 'An', 3));
      final id = (created.single.message as StateSnapshot).matchId;
      expect(
        (server.handle('a', JoinRoom('a2', id, 'An 2')).single.message
                as MoveRejected)
            .reason,
        'alreadySeated',
      );
      final j = server.handle('b', JoinRoom('a1', id.toLowerCase(), 'Bình'));
      expect(j.map((o) => o.clientId).toSet(), {'a', 'b'});
    },
  );

  test('chơi hết ván qua server → GameEnded; state client khớp engine', () {
    final id = startRoom();
    const engine = RulesEngine();
    final tokenA = tokens['a']!;
    var snap =
        server.handle('a', PlayerReconnect('s0', id, 0, tokenA)).single.message
            as StateSnapshot;
    var state = GameSerializer.stateFromJson(snap.state!);
    var rev = 0;
    var ended = false;
    final rng = Random(3);
    var n = 0;
    while (!ended) {
      final moves = engine.getLegalMoves(state);
      final m = moves[rng.nextInt(moves.length)];
      var client = 'b';
      if (m.playerId == 0) client = 'a';
      final out = server.handle(
        client,
        SubmitMove('m${n++}', id, m.playerId, rev, m),
      );
      expect(out.first.message, isA<MoveAccepted>());
      rev = (out.first.message as MoveAccepted).revision;
      ended = out.any((o) => o.message is GameEnded);
      state = (engine.applyMove(state, m) as dynamic).state;
    }
    snap =
        server.handle('a', PlayerReconnect('s1', id, 0, tokenA)).single.message
            as StateSnapshot;
    expect(GameSerializer.stateFromJson(snap.state!).boardKey, state.boardKey);
  });

  test('protocol JSON round-trip', () {
    final msgs = <ClientMessage>[
      const CreateRoom('1', 'An', 3),
      const JoinRoom('2', 'ABCDE', 'Bình'),
      const SubmitMove(
        '3',
        'ABCDE',
        1,
        4,
        Move(
          playerId: 1,
          sourceCellId: 8,
          direction: Direction.counterClockwise,
        ),
      ),
      const PlayerReconnect('4', 'ABCDE', 1, 'tok'),
    ];
    for (final m in msgs) {
      expect(
        ClientMessage.fromJson(jsonDecode(jsonEncode(m.toJson()))).toJson(),
        m.toJson(),
      );
    }
  });

  test('LocalFakeMultiplayerRepository đi qua JSON tới server', () async {
    final hub = FakeServerHub(MatchServer(random: Random(2)));
    final a = LocalFakeMultiplayerRepository(hub, 'a');
    final b = LocalFakeMultiplayerRepository(hub, 'b');
    final aMsgs = <ServerMessage>[];
    a.messages.listen(aMsgs.add);
    await a.send(const CreateRoom('1', 'An', 2));
    await Future<void>.delayed(Duration.zero);
    final code = (aMsgs.single as StateSnapshot).matchId;
    await b.send(JoinRoom('2', code, 'Bình'));
    await Future<void>.delayed(Duration.zero);
    expect((aMsgs.last as StateSnapshot).state, isNotNull);
    await a.close();
    await b.close();
  });
}
