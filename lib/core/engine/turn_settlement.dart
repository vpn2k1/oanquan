import 'dart:math' as math;

import '../game_models/game_event.dart';
import '../game_models/player.dart';
import 'board_topology.dart';

// Các bước phụ của RulesEngine: vay dân, tính điểm cuối ván, tìm lượt kế.

/// Thiếu `deficit` dân để rải lại → vay các người chơi khác (ưu tiên người
/// nhiều điểm nhất). Trả `{}` nếu không cần vay, `null` nếu không vay đủ.
Map<int, int>? arrangeLoans(List<Player> players, int borrower, int deficit) {
  if (deficit <= 0) return const {};
  final lenders =
      [
        for (final p in players)
          if (p.id != borrower && p.active && p.score > 0) p,
      ]..sort((a, b) {
        final c = b.score.compareTo(a.score);
        if (c != 0) return c;
        return a.id.compareTo(b.id);
      });
  if (lenders.fold(0, (a, p) => a + p.score) < deficit) return null;
  final loans = <int, int>{};
  var need = deficit;
  for (final l in lenders) {
    if (need == 0) break;
    final amt = math.min(l.score, need);
    loans[l.id] = amt;
    need -= amt;
  }
  return loans;
}

/// Tính điểm cuối ván: dân còn trên ô của ai thuộc về người đó (dân trong
/// ô quan không thuộc ai), sau đó trả nợ đã vay.
void settleGame(
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

int nextActive(List<Player> players, int from) {
  final n = players.length;
  for (var k = 1; k <= n; k++) {
    final c = (from + k) % n;
    if (players[c].active) return c;
  }
  return from;
}
