import '../game_models/cell.dart';
import '../game_models/game_config.dart';
import '../game_models/game_event.dart';
import '../game_models/game_state.dart';
import '../game_models/move.dart';
import '../game_models/player.dart';
import 'board_topology.dart';
import 'move_result.dart';
import 'scoring.dart';

/// Engine luật `multi_v1` — hàm thuần, không mutate state đầu vào,
/// không import Flutter/Flame.
class RulesEngine {
  const RulesEngine({this.maxStepsPerTurn = 100000});

  /// Chốt an toàn tuyệt đối (ngoài hash lặp) — không phải luật chơi.
  final int maxStepsPerTurn;

  // ---------------------------------------------------------------------------
  // Khởi tạo
  // ---------------------------------------------------------------------------

  /// Tạo ván mới theo config. `players` có thể bỏ trống → tạo người chơi mặc định.
  GameState newGame(GameConfig config, {List<Player>? players}) {
    final topo = BoardTopology(config);
    final cells = <Cell>[
      for (var i = 0; i < config.ringLength; i++)
        topo.isQuanIndex(i)
            ? Cell(id: i, kind: CellKind.quan, danCount: 0, hasQuan: true)
            : Cell(
                id: i,
                kind: CellKind.dan,
                ownerId: topo.ownerOf(i),
                danCount: config.ruleset.initialDan,
                hasQuan: false,
              ),
    ];
    final ps =
        players ??
        [
          for (var p = 0; p < config.playerCount; p++)
            Player(id: p, name: 'Người ${p + 1}'),
        ];
    if (ps.length != config.playerCount) {
      throw ArgumentError('Cần đúng ${config.playerCount} người chơi');
    }
    return GameState(
      config: config,
      cells: List.unmodifiable(cells),
      players: List.unmodifiable(ps),
      turnPlayer: 0,
      phase: GamePhase.playing,
      moveNumber: 0,
      history: const [],
    );
  }

  // ---------------------------------------------------------------------------
  // Nước đi hợp lệ
  // ---------------------------------------------------------------------------

  RejectReason? validate(GameState s, Move m) {
    if (s.isOver) return RejectReason.gameOver;
    if (m.playerId != s.turnPlayer) return RejectReason.notYourTurn;
    if (!s.players[m.playerId].active) return RejectReason.playerInactive;
    if (m.sourceCellId < 0 || m.sourceCellId >= s.ringLength) {
      return RejectReason.cellOutOfRange;
    }
    final c = s.cells[m.sourceCellId];
    if (c.isQuanCell) return RejectReason.quanCellAsSource;
    if (c.ownerId != m.playerId) return RejectReason.notOwnCell;
    if (c.danCount <= 0) return RejectReason.emptyCell;
    return null;
  }

  List<Move> getLegalMoves(GameState s) {
    if (s.isOver) return const [];
    final p = s.turnPlayer;
    if (!s.players[p].active) return const [];
    final topo = BoardTopology(s.config);
    return [
      for (final i in topo.playerCells(p))
        if (s.cells[i].danCount > 0)
          for (final d in Direction.values)
            Move(playerId: p, sourceCellId: i, direction: d),
    ];
  }

  // ---------------------------------------------------------------------------
  // Áp dụng nước đi
  // ---------------------------------------------------------------------------

  MoveResult applyMove(
    GameState s,
    Move m, {
    bool recordEvents = true,
    bool recordHistory = true,
  }) {
    final reason = validate(s, m);
    if (reason != null) return MoveRejected(reason);

    final cfg = s.config;
    final rules = cfg.ruleset;
    final topo = BoardTopology(cfg);
    final n = s.ringLength;
    final dan = [for (final c in s.cells) c.danCount];
    final quan = [for (final c in s.cells) c.hasQuan];
    final isQuanCell = [for (final c in s.cells) c.isQuanCell];
    final players = [...s.players];
    final events = <GameEvent>[];
    void emit(GameEvent e) {
      if (recordEvents) events.add(e);
    }

    final step = m.direction.step;
    int next(int i) => ((i + step) % n + n) % n;
    bool isEmpty(int i) => dan[i] == 0 && !quan[i];

    final pid = m.playerId;
    var me = players[pid];

    // --- Pha rải -------------------------------------------------------------
    var pos = m.sourceCellId;
    var hand = dan[pos];
    dan[pos] = 0;
    emit(PickupEvent(pos, hand));

    final seen = <String>{};
    var steps = 0;
    int? gap;

    while (true) {
      while (hand > 0) {
        pos = next(pos);
        dan[pos]++;
        hand--;
        steps++;
        emit(DropEvent(pos));
      }
      final nxt = next(pos);
      if (!isQuanCell[nxt] && dan[nxt] > 0) {
        // Ô dân có dân → nhấc tiếp. Kiểm tra lặp trước khi nhấc.
        final key = '${dan.join(',')}|$nxt|sow|$step';
        if (!seen.add(key) || steps > maxStepsPerTurn) {
          emit(RuleLoopGuardEvent(nxt));
          break;
        }
        hand = dan[nxt];
        dan[nxt] = 0;
        pos = nxt;
        emit(PickupEvent(pos, hand));
        continue;
      }
      if (isEmpty(nxt)) gap = nxt;
      // Ô quan còn tài nguyên → dừng; ô trống → sang pha ăn.
      break;
    }

    // --- Pha ăn --------------------------------------------------------------
    // Ô quan còn quan mà ít dân hơn ngưỡng là "quan non": không được ăn
    // (kể cả dân trong ô) → mất lượt.
    bool capturable(int i) =>
        quan[i] ? dan[i] >= rules.quanCaptureThreshold : dan[i] > 0;

    if (gap != null) {
      var g = gap;
      while (true) {
        final target = next(g);
        if (!capturable(target)) break;
        final danHere = dan[target];
        final takeQuan = quan[target] && danHere >= rules.quanCaptureThreshold;
        if (danHere > 0) {
          dan[target] = 0;
          me = me.copyWith(
            score: me.score + danHere * rules.danValue,
            danCaptured: me.danCaptured + danHere,
          );
          emit(CaptureDanEvent(pid, target, danHere));
        }
        if (takeQuan) {
          quan[target] = false;
          me = me.copyWith(
            score: me.score + rules.quanValue,
            quanCaptured: me.quanCaptured + 1,
          );
          emit(CaptureQuanEvent(pid, target, rules.quanValue));
        }
        g = next(target);
        if (!isEmpty(g)) break;
      }
    }
    players[pid] = me;

    // --- Kết thúc lượt -------------------------------------------------------
    final history = recordHistory
        ? List<Move>.unmodifiable([...s.history, m])
        : s.history;
    var turn = pid;
    EndReason? endReason;
    final moveLimit = rules.maxMovesPerPlayer * cfg.playerCount;
    bool quanCellsCleared() => [
      for (var i = 0; i < n; i++)
        if (isQuanCell[i]) !quan[i] && dan[i] == 0,
    ].every((e) => e);
    if (quanCellsCleared()) {
      endReason = EndReason.allQuanCaptured;
    } else if (players.where((p) => p.active).length <= 1) {
      endReason = EndReason.lastPlayerStanding;
    } else if (moveLimit > 0 && s.moveNumber + 1 >= moveLimit) {
      endReason = EndReason.moveLimit;
    }
    var over = endReason != null;

    if (!over) {
      turn = _nextActive(players, pid);
      // Đầu lượt: hết dân → nạp hoặc bị loại.
      while (true) {
        final cells = topo.playerCells(turn);
        if (cells.any((i) => dan[i] > 0)) break;
        final pl = players[turn];
        final loans = _arrangeLoans(players, turn, rules.refillCost - pl.score);
        if (loans != null) {
          final debts = {...pl.debts};
          for (final e in loans.entries) {
            players[e.key] = players[e.key].copyWith(
              score: players[e.key].score - e.value,
            );
            debts[e.key] = (debts[e.key] ?? 0) + e.value;
          }
          final borrowed = loans.values.fold(0, (a, b) => a + b);
          for (final i in cells) {
            dan[i] += 1;
          }
          players[turn] = pl.copyWith(
            score: pl.score + borrowed - rules.refillCost,
            refillSpent: pl.refillSpent + rules.refillCost,
            debts: debts,
          );
          emit(RefillEvent(turn, cells, rules.refillCost, borrowed: loans));
          break;
        }
        players[turn] = pl.copyWith(active: false);
        emit(EliminateEvent(turn));
        if (players.where((p) => p.active).length <= 1) {
          over = true;
          endReason = EndReason.lastPlayerStanding;
          break;
        }
        turn = _nextActive(players, turn);
      }
    }

    if (over) _settle(topo, dan, players, rules.danValue, emit);

    final newCells = List<Cell>.unmodifiable([
      for (var i = 0; i < n; i++)
        (dan[i] == s.cells[i].danCount && quan[i] == s.cells[i].hasQuan)
            ? s.cells[i]
            : s.cells[i].copyWith(danCount: dan[i], hasQuan: quan[i]),
    ]);
    final newPlayers = List<Player>.unmodifiable(players);

    if (over) {
      final winners = Scoring.winners(newPlayers);
      emit(EndTurnEvent(pid, null));
      emit(GameOverEvent(winners, endReason!.name));
      return MoveAccepted(
        s.copyWith(
          cells: newCells,
          players: newPlayers,
          turnPlayer: pid,
          phase: GamePhase.gameOver,
          moveNumber: s.moveNumber + 1,
          history: history,
          winnerIds: winners,
          endReason: endReason,
        ),
        events,
      );
    }

    emit(EndTurnEvent(pid, turn));
    return MoveAccepted(
      s.copyWith(
        cells: newCells,
        players: newPlayers,
        turnPlayer: turn,
        moveNumber: s.moveNumber + 1,
        history: history,
      ),
      events,
    );
  }

  /// Thiếu `deficit` dân để rải lại → vay các người chơi khác (ưu tiên người
  /// nhiều điểm nhất). Trả `{}` nếu không cần vay, `null` nếu không vay đủ.
  Map<int, int>? _arrangeLoans(
    List<Player> players,
    int borrower,
    int deficit,
  ) {
    if (deficit <= 0) return const {};
    final lenders =
        [
          for (final p in players)
            if (p.id != borrower && p.active && p.score > 0) p,
        ]..sort((a, b) {
          final c = b.score.compareTo(a.score);
          return c != 0 ? c : a.id.compareTo(b.id);
        });
    if (lenders.fold(0, (a, p) => a + p.score) < deficit) return null;
    final loans = <int, int>{};
    var need = deficit;
    for (final l in lenders) {
      if (need == 0) break;
      final amt = l.score < need ? l.score : need;
      loans[l.id] = amt;
      need -= amt;
    }
    return loans;
  }

  /// Tính điểm cuối ván: dân còn trên ô của ai thuộc về người đó (dân trong
  /// ô quan không thuộc ai), sau đó trả nợ đã vay.
  void _settle(
    BoardTopology topo,
    List<int> dan,
    List<Player> players,
    int danValue,
    void Function(GameEvent) emit,
  ) {
    for (var p = 0; p < players.length; p++) {
      final cells = [
        for (final i in topo.playerCells(p))
          if (dan[i] > 0) i,
      ];
      final count = cells.fold(0, (a, i) => a + dan[i]);
      if (count == 0) continue;
      for (final i in cells) {
        dan[i] = 0;
      }
      final pl = players[p];
      players[p] = pl.copyWith(
        score: pl.score + count * danValue,
        danCollected: pl.danCollected + count,
      );
      emit(CollectEvent(p, cells, count));
    }
    for (var p = 0; p < players.length; p++) {
      for (final e in players[p].debts.entries) {
        players[p] = players[p].copyWith(score: players[p].score - e.value);
        players[e.key] = players[e.key].copyWith(
          score: players[e.key].score + e.value,
        );
        emit(RepayEvent(p, e.key, e.value));
      }
      players[p] = players[p].copyWith(debts: const {});
    }
  }

  int _nextActive(List<Player> players, int from) {
    final n = players.length;
    for (var k = 1; k <= n; k++) {
      final c = (from + k) % n;
      if (players[c].active) return c;
    }
    return from;
  }
}
