import '../game_models/player.dart';

class Standing {
  const Standing(this.player, this.rank);
  final Player player;

  /// Hạng kiểu thi đấu: đồng điểm → đồng hạng (1, 1, 3...).
  final int rank;
}

abstract final class Scoring {
  /// Người có điểm cao nhất (có thể nhiều người — hòa đồng hạng).
  static List<int> winners(List<Player> players) {
    if (players.isEmpty) return const [];
    final best = players.map((p) => p.score).reduce((a, b) => a > b ? a : b);
    return [for (final p in players) if (p.score == best) p.id];
  }

  static List<Standing> standings(List<Player> players) {
    final sorted = [...players]..sort((a, b) {
        final c = b.score.compareTo(a.score);
        return c != 0 ? c : a.id.compareTo(b.id);
      });
    final out = <Standing>[];
    for (var i = 0; i < sorted.length; i++) {
      final rank = (i > 0 && sorted[i].score == sorted[i - 1].score)
          ? out[i - 1].rank
          : i + 1;
      out.add(Standing(sorted[i], rank));
    }
    return out;
  }

  /// Điểm đội cho chế độ 2v2 (đồng đội ngồi đối diện: 0&2, 1&3).
  static List<int> teamScores(List<Player> players) {
    assert(players.length == 4);
    return [
      players[0].score + players[2].score,
      players[1].score + players[3].score,
    ];
  }
}
