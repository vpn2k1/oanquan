/// Loại ô trên vòng: ô dân (thuộc một người) hoặc ô quan (ô chung ở góc/đỉnh).
enum CellKind { dan, quan }

/// Một ô trên vòng. Bất biến (immutable); engine tạo bản sao khi thay đổi.
class Cell {
  const Cell({
    required this.id,
    required this.kind,
    this.ownerId,
    required this.danCount,
    required this.hasQuan,
  });

  /// Chỉ số trên vòng (0..ringLength-1), tăng theo chiều kim đồng hồ.
  final int id;
  final CellKind kind;

  /// Chủ sở hữu (chỉ với ô dân). Ô quan luôn `null` — ô chung.
  final int? ownerId;
  final int danCount;

  /// Ô quan còn token quan hay không. Ô dân luôn `false`.
  final bool hasQuan;

  bool get isQuanCell => kind == CellKind.quan;
  bool get isDanCell => kind == CellKind.dan;

  /// "Ô trống" theo luật: không có dân và không có token quan.
  bool get isEmpty => danCount == 0 && !hasQuan;

  Cell copyWith({int? danCount, bool? hasQuan}) => Cell(
        id: id,
        kind: kind,
        ownerId: ownerId,
        danCount: danCount ?? this.danCount,
        hasQuan: hasQuan ?? this.hasQuan,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.name,
        if (ownerId != null) 'ownerId': ownerId,
        'danCount': danCount,
        'hasQuan': hasQuan,
      };

  factory Cell.fromJson(Map<String, dynamic> j) => Cell(
        id: j['id'] as int,
        kind: CellKind.values.byName(j['kind'] as String),
        ownerId: j['ownerId'] as int?,
        danCount: j['danCount'] as int,
        hasQuan: j['hasQuan'] as bool,
      );

  @override
  bool operator ==(Object other) =>
      other is Cell &&
      other.id == id &&
      other.kind == kind &&
      other.ownerId == ownerId &&
      other.danCount == danCount &&
      other.hasQuan == hasQuan;

  @override
  int get hashCode => Object.hash(id, kind, ownerId, danCount, hasQuan);

  @override
  String toString() =>
      '${kind == CellKind.quan ? 'Q' : 'P${ownerId}C'}#$id(dan=$danCount${hasQuan ? ',quan' : ''})';
}
