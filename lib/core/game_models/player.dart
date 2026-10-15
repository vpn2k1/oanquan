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
    this.danCollected = 0,
    this.debts = const {},
  });

  final int id;
  final String name;
  final PlayerType type;
  final AiLevel aiLevel;

  /// Điểm tổng: dân ăn được + quan * quanValue + dân thu cuối ván
  /// − dân đã dùng để rải lại ± dân đang vay/cho vay.
  final int score;

  /// `false` khi bị loại vì hết dân, không đủ điểm rải lại và không vay được.
  final bool active;

  /// Thống kê tách riêng để hiển thị thành phần điểm.
  final int danCaptured;
  final int quanCaptured;
  final int refillSpent;

  /// Dân còn trên các ô của mình được thu về khi kết thúc ván.
  final int danCollected;

  /// Sổ nợ: chủ nợ → số dân đã vay (trả khi tính điểm cuối ván).
  final Map<int, int> debts;

  int get totalDebt => debts.values.fold(0, (a, b) => a + b);

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
    int? danCollected,
    Map<int, int>? debts,
  }) => Player(
    id: id,
    name: name ?? this.name,
    type: type ?? this.type,
    aiLevel: aiLevel ?? this.aiLevel,
    score: score ?? this.score,
    active: active ?? this.active,
    danCaptured: danCaptured ?? this.danCaptured,
    quanCaptured: quanCaptured ?? this.quanCaptured,
    refillSpent: refillSpent ?? this.refillSpent,
    danCollected: danCollected ?? this.danCollected,
    debts: debts ?? this.debts,
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
    'danCollected': danCollected,
    'debts': {for (final e in debts.entries) '${e.key}': e.value},
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
    danCollected: j['danCollected'] as int? ?? 0,
    debts: {
      for (final e in ((j['debts'] as Map?) ?? const {}).entries)
        int.parse(e.key as String): e.value as int,
    },
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
      other.refillSpent == refillSpent &&
      other.danCollected == danCollected &&
      _mapEq(other.debts, debts);

  @override
  int get hashCode => Object.hash(
    id,
    name,
    type,
    aiLevel,
    score,
    active,
    danCaptured,
    quanCaptured,
    refillSpent,
    danCollected,
    Object.hashAllUnordered(
      debts.entries.map((e) => Object.hash(e.key, e.value)),
    ),
  );
}

bool _mapEq(Map<int, int> a, Map<int, int> b) =>
    a.length == b.length && a.entries.every((e) => b[e.key] == e.value);
