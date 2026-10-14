/// Tham số luật. Preset `multi_v1` là mặc định; ván xếp hạng phải dùng preset.
class RulesetConfig {
  const RulesetConfig({
    this.id = 'multi_v1',
    this.initialDan = 5,
    this.quanValue = 10,
    this.danValue = 1,
    this.quanCaptureThreshold = 5,
    this.refillCost = 5,
    this.maxMovesPerPlayer = 60,
  });

  static const multiV1 = RulesetConfig();

  final String id;
  final int initialDan;
  final int quanValue;
  final int danValue;

  /// Số dân tối thiểu phải có trong ô quan để ăn được token quan.
  final int quanCaptureThreshold;

  /// Số điểm trừ khi nạp 1 dân vào mỗi ô dân (K ô).
  final int refillCost;

  /// Giả định A3 (chống bế tắc): ván tự kết thúc khi tổng số nước đạt
  /// `maxMovesPerPlayer * playerCount`. 0 = không giới hạn.
  final int maxMovesPerPlayer;

  bool get isPreset => this == multiV1;

  Map<String, dynamic> toJson() => {
        'id': id,
        'initialDan': initialDan,
        'quanValue': quanValue,
        'danValue': danValue,
        'quanCaptureThreshold': quanCaptureThreshold,
        'refillCost': refillCost,
        'maxMovesPerPlayer': maxMovesPerPlayer,
      };

  factory RulesetConfig.fromJson(Map<String, dynamic> j) => RulesetConfig(
        id: j['id'] as String,
        initialDan: j['initialDan'] as int,
        quanValue: j['quanValue'] as int,
        danValue: j['danValue'] as int,
        quanCaptureThreshold: j['quanCaptureThreshold'] as int,
        refillCost: j['refillCost'] as int,
        maxMovesPerPlayer: j['maxMovesPerPlayer'] as int? ?? 60,
      );

  @override
  bool operator ==(Object other) =>
      other is RulesetConfig &&
      other.id == id &&
      other.initialDan == initialDan &&
      other.quanValue == quanValue &&
      other.danValue == danValue &&
      other.quanCaptureThreshold == quanCaptureThreshold &&
      other.refillCost == refillCost &&
      other.maxMovesPerPlayer == maxMovesPerPlayer;

  @override
  int get hashCode => Object.hash(
      id, initialDan, quanValue, danValue, quanCaptureThreshold, refillCost,
      maxMovesPerPlayer);
}

/// Hình bàn tương ứng số người.
enum BoardShape { rectangle, triangle, square }

class GameConfig {
  const GameConfig({
    required this.playerCount,
    this.cellsPerPlayer = 5,
    this.ruleset = RulesetConfig.multiV1,
    this.seed = 0,
  }) : assert(playerCount >= 2 && playerCount <= 4);

  factory GameConfig.preset(int playerCount, {int seed = 0}) =>
      GameConfig(playerCount: playerCount, seed: seed);

  /// N ∈ {2,3,4}.
  final int playerCount;

  /// K = 5.
  final int cellsPerPlayer;
  final RulesetConfig ruleset;

  /// Seed xác định cho AI/random — đảm bảo replay được.
  final int seed;

  int get segmentLength => cellsPerPlayer + 1;
  int get ringLength => playerCount * segmentLength;

  BoardShape get shape => switch (playerCount) {
        2 => BoardShape.rectangle,
        3 => BoardShape.triangle,
        _ => BoardShape.square,
      };

  Map<String, dynamic> toJson() => {
        'playerCount': playerCount,
        'cellsPerPlayer': cellsPerPlayer,
        'ruleset': ruleset.toJson(),
        'seed': seed,
      };

  factory GameConfig.fromJson(Map<String, dynamic> j) => GameConfig(
        playerCount: j['playerCount'] as int,
        cellsPerPlayer: j['cellsPerPlayer'] as int,
        ruleset: RulesetConfig.fromJson(j['ruleset'] as Map<String, dynamic>),
        seed: j['seed'] as int,
      );

  @override
  bool operator ==(Object other) =>
      other is GameConfig &&
      other.playerCount == playerCount &&
      other.cellsPerPlayer == cellsPerPlayer &&
      other.ruleset == ruleset &&
      other.seed == seed;

  @override
  int get hashCode => Object.hash(playerCount, cellsPerPlayer, ruleset, seed);
}
