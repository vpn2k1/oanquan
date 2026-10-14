enum PlayerType { human, ai }

enum AiLevel { easy, medium, hard }

class Player {
  const Player({
    required this.id,
    required this.name,
    this.type = PlayerType.human,
    this.aiLevel = AiLevel.medium,
    this.score = 0,
    this.active = true,
    this.danCaptured = 0,
    this.quanCaptured = 0,
    this.refillSpent = 0,
  });

  final int id;
  final String name;
  final PlayerType type;
  final AiLevel aiLevel;

  /// Điểm tổng: dân ăn được + quan * quanValue - điểm đã dùng để nạp.
  final int score;

  /// `false` khi bị loại vì hết dân và không đủ điểm nạp.
  final bool active;

  /// Thống kê tách riêng để hiển thị thành phần điểm.
  final int danCaptured;
  final int quanCaptured;
  final int refillSpent;

  bool get isAi => type == PlayerType.ai;

  Player copyWith({
    String? name,
    PlayerType? type,
    AiLevel? aiLevel,
    int? score,
    bool? active,
    int? danCaptured,
    int? quanCaptured,
    int? refillSpent,
  }) =>
      Player(
        id: id,
        name: name ?? this.name,
        type: type ?? this.type,
        aiLevel: aiLevel ?? this.aiLevel,
        score: score ?? this.score,
        active: active ?? this.active,
        danCaptured: danCaptured ?? this.danCaptured,
        quanCaptured: quanCaptured ?? this.quanCaptured,
        refillSpent: refillSpent ?? this.refillSpent,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'aiLevel': aiLevel.name,
        'score': score,
        'active': active,
        'danCaptured': danCaptured,
        'quanCaptured': quanCaptured,
        'refillSpent': refillSpent,
      };

  factory Player.fromJson(Map<String, dynamic> j) => Player(
        id: j['id'] as int,
        name: j['name'] as String,
        type: PlayerType.values.byName(j['type'] as String),
        aiLevel: AiLevel.values.byName(j['aiLevel'] as String),
        score: j['score'] as int,
        active: j['active'] as bool,
        danCaptured: j['danCaptured'] as int,
        quanCaptured: j['quanCaptured'] as int,
        refillSpent: j['refillSpent'] as int,
      );

  @override
  bool operator ==(Object other) =>
      other is Player &&
      other.id == id &&
      other.name == name &&
      other.type == type &&
      other.aiLevel == aiLevel &&
      other.score == score &&
      other.active == active &&
      other.danCaptured == danCaptured &&
      other.quanCaptured == quanCaptured &&
      other.refillSpent == refillSpent;

  @override
  int get hashCode => Object.hash(id, name, type, aiLevel, score, active,
      danCaptured, quanCaptured, refillSpent);
}
