import 'package:flutter/painting.dart';

/// Mặt sân dân dã, vẽ thủ tục bằng Canvas (không dùng ảnh).
enum GroundKind {
  dirt,
  concrete,
  tiles,

  /// Đất sỏi tông sẫm — nền các màn menu (chữ kem vẫn đọc rõ).
  darkDirt,
}

/// Dụng cụ kẻ bàn.
enum PenKind { stick, chalk, brick, charcoal }

/// Một tổ hợp mặt sân + nét vẽ.
class FolkStyle {
  const FolkStyle(this.id, this.ground, this.pen);

  final String id;
  final GroundKind ground;
  final PenKind pen;

  static const dirtStick = FolkStyle(
    'dirt_stick',
    GroundKind.dirt,
    PenKind.stick,
  );
  static const concreteChalk = FolkStyle(
    'concrete_chalk',
    GroundKind.concrete,
    PenKind.chalk,
  );
  static const tilesChalk = FolkStyle(
    'tiles_chalk',
    GroundKind.tiles,
    PenKind.chalk,
  );
  static const concreteBrick = FolkStyle(
    'concrete_brick',
    GroundKind.concrete,
    PenKind.brick,
  );
  static const concreteCharcoal = FolkStyle(
    'concrete_charcoal',
    GroundKind.concrete,
    PenKind.charcoal,
  );

  static const all = [
    dirtStick,
    concreteChalk,
    tilesChalk,
    concreteBrick,
    concreteCharcoal,
  ];

  /// Giá trị cài đặt cho "ngẫu nhiên mỗi ván".
  static const randomId = 'random';

  static FolkStyle byId(String id) =>
      all.where((s) => s.id == id).firstOrNull ?? concreteChalk;

  /// `setting` = id cụ thể hoặc [randomId] → chọn theo `seed` (ổn định trong một ván).
  static FolkStyle resolve(String setting, int seed) {
    if (setting == randomId) {
      return all[(seed.abs() * 2654435761) % all.length];
    }
    return byId(setting);
  }

  /// Màu nét chính.
  Color get ink => switch (pen) {
    PenKind.stick => const Color(0xFF5A3A1E),
    PenKind.chalk => const Color(0xFFF7F4EC),
    PenKind.brick => const Color(0xFFB4452C),
    PenKind.charcoal => const Color(0xFF2B2826),
  };

  /// Nét màu cho dải chủ ô: phấn màu, riêng than/gạch giữ dụng cụ nhưng nhuộm màu.
  bool get coloredChalkMarks => true;

  @override
  bool operator ==(Object other) => other is FolkStyle && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

// ---------------------------------------------------------------------------
// Nhiễu mượt (tổng sin, đủ cho nét run tay)
// ---------------------------------------------------------------------------
