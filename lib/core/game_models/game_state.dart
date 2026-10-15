import 'cell.dart';
import 'game_config.dart';
import 'move.dart';
import 'player.dart';

enum GamePhase { playing, gameOver }

/// Lý do kết thúc ván.
enum EndReason { allQuanCaptured, lastPlayerStanding, moveLimit }

/// Trạng thái ván — bất biến. Chỉ engine tạo trạng thái mới.
class GameState {
  const GameState({
    required this.config,
    required this.cells,
    required this.players,
    required this.turnPlayer,
    required this.phase,
    required this.moveNumber,
    required this.history,
    this.winnerIds = const [],
    this.endReason,
  });

  final GameConfig config;
  final List<Cell> cells;
  final List<Player> players;

  /// Người đang đến lượt (luôn là người active khi phase == playing).
  final int turnPlayer;
  final GamePhase phase;

  /// Số nước đã đi.
  final int moveNumber;

  /// Nhật ký nước đi — cùng trạng thái ban đầu đủ để replay.
  final List<Move> history;

  /// Danh sách người thắng (đồng hạng nhất) khi kết thúc.
  final List<int> winnerIds;
  final EndReason? endReason;

  bool get isOver => phase == GamePhase.gameOver;
  int get ringLength => cells.length;
  Player get currentPlayer => players[turnPlayer];
  int get activeCount => players.where((p) => p.active).length;
  int get quanTokensLeft => cells.where((c) => c.hasQuan).length;
  int get danOnBoard => cells.fold(0, (s, c) => s + c.danCount);

  GameState copyWith({
    List<Cell>? cells,
    List<Player>? players,
    int? turnPlayer,
    GamePhase? phase,
    int? moveNumber,
    List<Move>? history,
    List<int>? winnerIds,
    EndReason? endReason,
  }) => GameState(
    config: config,
    cells: cells ?? this.cells,
    players: players ?? this.players,
    turnPlayer: turnPlayer ?? this.turnPlayer,
    phase: phase ?? this.phase,
    moveNumber: moveNumber ?? this.moveNumber,
    history: history ?? this.history,
    winnerIds: winnerIds ?? this.winnerIds,
    endReason: endReason ?? this.endReason,
  );

  /// Khóa so sánh nội dung bàn (không gồm history) — dùng cho test/AI.
  String get boardKey =>
      '${cells.map((c) => '${c.danCount}${_flag(c.hasQuan, 'q')}').join(',')}'
      '|${players.map((p) => '${p.score}${_flag(!p.active, 'x')}').join(',')}'
      '|$turnPlayer|${phase.index}';
}

/// Trả [mark] khi [on] đúng, ngược lại chuỗi rỗng.
String _flag(bool on, String mark) {
  if (on) return mark;
  return '';
}
