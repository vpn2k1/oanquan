import '../game_models/game_config.dart';
import '../game_models/move.dart';

/// Ánh xạ chỉ số trên vòng:
/// `Q0, P0C0..P0C4, Q1, P1C0..P1C4, ..., Q(N-1), P(N-1)C0..P(N-1)C4`.
/// Chỉ số tăng = chiều kim đồng hồ. Không phụ thuộc pixel.
class BoardTopology {
  const BoardTopology(this.config);

  final GameConfig config;

  int get n => config.ringLength;
  int get k => config.cellsPerPlayer;
  int get segment => config.segmentLength;

  /// Ô quan `Qp` — ô góc đứng trước đoạn ô dân của người `p`.
  int quanIndex(int p) => p * segment;

  /// Ô dân `PpCj`.
  int danIndex(int p, int j) {
    assert(j >= 0 && j < k);
    return p * segment + 1 + j;
  }

  bool isQuanIndex(int i) => i % segment == 0;

  /// Chủ ô dân; `null` với ô quan.
  int? ownerOf(int i) => isQuanIndex(i) ? null : i ~/ segment;

  /// Vị trí j (0..K-1) của ô dân trong đoạn của chủ.
  int danSlot(int i) => i % segment - 1;

  List<int> playerCells(int p) => [for (var j = 0; j < k; j++) danIndex(p, j)];

  List<int> get quanCells => [
    for (var p = 0; p < config.playerCount; p++) quanIndex(p),
  ];

  /// Ô kế tiếp theo hướng, wrap modulo cả hai chiều.
  int next(int i, Direction d) => wrap(i + d.step);

  int wrap(int i) => ((i % n) + n) % n;
}
