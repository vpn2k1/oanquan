import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/game_models/game_state.dart';
import '../../core/game_models/player.dart';
import '../settings/settings_controller.dart';

class PlayerStats {
  const PlayerStats({
    this.played = 0,
    this.winsVsAi = 0,
    this.winsVsHard = 0,
    this.bestScore = 0,
    this.quanTotal = 0,
    this.maxQuanInGame = 0,
    this.boardsPlayed = const {},
  });

  final int played;
  final int winsVsAi;
  final int winsVsHard;
  final int bestScore;
  final int quanTotal;
  final int maxQuanInGame;
  final Set<int> boardsPlayed;
}

enum Achievement { firstGame, beatAi, beatHard, quanHunter, highScore, allBoards }

extension AchievementCheck on PlayerStats {
  bool unlocked(Achievement a) => switch (a) {
        Achievement.firstGame => played >= 1,
        Achievement.beatAi => winsVsAi >= 1,
        Achievement.beatHard => winsVsHard >= 1,
        Achievement.quanHunter => maxQuanInGame >= 2,
        Achievement.highScore => bestScore >= 40,
        Achievement.allBoards => boardsPlayed.containsAll(const {2, 3, 4}),
      };
}

/// Thống kê cục bộ (chỉ tính người chơi là người thật trên thiết bị).
class StatsController extends Notifier<PlayerStats> {
  SharedPreferences get _p => ref.read(sharedPrefsProvider);

  @override
  PlayerStats build() => PlayerStats(
        played: _p.getInt('stats.played') ?? 0,
        winsVsAi: _p.getInt('stats.winsVsAi') ?? 0,
        winsVsHard: _p.getInt('stats.winsVsHard') ?? 0,
        bestScore: _p.getInt('stats.bestScore') ?? 0,
        quanTotal: _p.getInt('stats.quanTotal') ?? 0,
        maxQuanInGame: _p.getInt('stats.maxQuanInGame') ?? 0,
        boardsPlayed: {
          for (final s in _p.getStringList('stats.boards') ?? const <String>[])
            int.parse(s),
        },
      );

  void recordGame(GameState s) {
    if (!s.isOver) return;
    final humans = s.players.where((p) => p.type == PlayerType.human).toList();
    final ais = s.players.where((p) => p.type == PlayerType.ai).toList();
    final soloWinner = s.winnerIds.length == 1 ? s.players[s.winnerIds.first] : null;
    final humanWon = soloWinner != null && soloWinner.type == PlayerType.human;
    final best = humans.fold(0, (m, p) => p.score > m ? p.score : m);
    final quan = humans.fold(0, (a, p) => a + p.quanCaptured);
    final maxQuan = humans.fold(0, (m, p) => p.quanCaptured > m ? p.quanCaptured : m);
    final cur = state;
    final next = PlayerStats(
      played: cur.played + 1,
      winsVsAi: cur.winsVsAi + (humanWon && ais.isNotEmpty ? 1 : 0),
      winsVsHard: cur.winsVsHard +
          (humanWon && ais.any((p) => p.aiLevel == AiLevel.hard) ? 1 : 0),
      bestScore: best > cur.bestScore ? best : cur.bestScore,
      quanTotal: cur.quanTotal + quan,
      maxQuanInGame: maxQuan > cur.maxQuanInGame ? maxQuan : cur.maxQuanInGame,
      boardsPlayed: {...cur.boardsPlayed, s.config.playerCount},
    );
    state = next;
    _p
      ..setInt('stats.played', next.played)
      ..setInt('stats.winsVsAi', next.winsVsAi)
      ..setInt('stats.winsVsHard', next.winsVsHard)
      ..setInt('stats.bestScore', next.bestScore)
      ..setInt('stats.quanTotal', next.quanTotal)
      ..setInt('stats.maxQuanInGame', next.maxQuanInGame)
      ..setStringList('stats.boards', [for (final b in next.boardsPlayed) '$b']);
  }
}

final statsProvider = NotifierProvider<StatsController, PlayerStats>(StatsController.new);
