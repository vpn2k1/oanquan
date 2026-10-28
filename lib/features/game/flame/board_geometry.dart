import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/painting.dart' show EdgeInsets;

import '../../../core/game_models/game_config.dart';
import 'board_raw_shapes.dart';

/// Hình học một ô — suy ra từ vòng logic, không phải nguồn sự thật.
class CellGeometry {
  const CellGeometry({
    required this.id,
    required this.isQuan,
    required this.center,
    required this.size,
    required this.rotation,
    required this.outward,
    required this.tangentCw,
    required this.outline,
    required this.labelAnchor,
  });

  final int id;
  final bool isQuan;
  final Offset center;

  /// Ô dân: cạnh hình vuông bo góc. Ô quan: đường kính lớn nhất.
  final double size;

  /// Góc xoay (radian) theo cạnh bàn.
  final double rotation;

  /// Vector đơn vị hướng ra ngoài bàn (phía người sở hữu).
  final Offset outward;

  /// Vector đơn vị hướng tới ô kế tiếp theo chiều kim đồng hồ.
  final Offset tangentCw;
  final Path outline;

  /// Vị trí đặt badge số lượng.
  final Offset labelAnchor;

  /// Bán kính chạm (≥ 22 px để vùng chạm ≥ 44 px khi có thể).
  double get hitRadius => max(size * 0.55, 22);
}

class BoardGeometry {
  BoardGeometry._({
    required this.config,
    required this.viewport,
    required this.unit,
    required this.cells,
    required this.boardOutline,
    required this.innerGroove,
    required this.playerAnchors,
    required this.playerEdges,
    required this.playerPiles,
  });

  final GameConfig config;
  final Size viewport;

  /// Đơn vị kích thước ≈ khoảng cách giữa hai ô dân liền kề.
  final double unit;
  final List<CellGeometry> cells;
  final Path boardOutline;
  final Path innerGroove;

  /// Điểm ngoài cạnh của từng người (đích bay khi ăn quân).
  final List<Offset> playerAnchors;

  /// Đoạn cạnh thuộc từng người (vẽ dải màu chủ sở hữu).
  final List<(Offset, Offset)> playerEdges;

  /// Hàng quân đã ăn của từng người (đầu → cuối), toạ độ màn hình.
  final List<(Offset, Offset)> playerPiles;

  /// Vị trí viên thứ `index` trong đống quân ăn: xếp theo hàng, đầy thì chồng
  /// hàng lệch nửa viên (tối đa 3 lớp).
  Offset pileSlot(int player, int index, {double? radius}) {
    final (a, b) = playerPiles[player];
    final r = radius ?? pebbleRadius;
    final len = (b - a).distance;
    final dir = (b - a) / len;
    final perRow = max(1, (len / (r * 2.15)).floor());
    final row = min(2, index ~/ perRow);
    final slot = index % perRow;
    final n = Offset(-dir.dy, dir.dx);
    var rowShift = 0.0;
    if (row.isOdd) rowShift = r;
    return a + dir * (r + slot * r * 2.15 + rowShift) + n * (row * r * 0.55);
  }

  double get pebbleRadius => unit * 0.11;

  /// Điểm đặt số điểm ở cuối hàng.
  Offset pileLabel(int player) {
    final (a, b) = playerPiles[player];
    final dir = (b - a) / (b - a).distance;
    return b + dir * (unit * 0.42);
  }

  /// `area`: vùng đặt bàn bên trong viewport (mặc định toàn viewport) — để
  /// chừa chỗ cho HUD nổi. Mũi tên vẫn được kẹp theo toàn viewport.
  factory BoardGeometry.compute(
    GameConfig config,
    Size viewport, {
    Rect? area,
  }) {
    var raw = rawPolygon(config);
    if (config.playerCount == 2) raw = rawRectangle(config);
    final box = area ?? Offset.zero & viewport;
    final bb = raw.bounds;
    final scale = min(box.width / bb.width, box.height / bb.height);
    final offset = Offset(
      box.left + (box.width - bb.width * scale) / 2 - bb.left * scale,
      box.top + (box.height - bb.height * scale) / 2 - bb.top * scale,
    );
    Offset tf(Offset p) => p * scale + offset;
    final m = Float64List.fromList([
      scale, 0, 0, 0, //
      0, scale, 0, 0,
      0, 0, 1, 0,
      offset.dx, offset.dy, 0, 1,
    ]);
    final u = raw.unit * scale;
    return BoardGeometry._(
      config: config,
      viewport: viewport,
      unit: u,
      cells: [
        for (final c in raw.cells)
          CellGeometry(
            id: c.id,
            isQuan: c.isQuan,
            center: tf(c.center),
            size: c.size * scale,
            rotation: c.rotation,
            outward: c.outward,
            tangentCw: c.tangentCw,
            outline: c.outline.transform(m),
            labelAnchor: tf(c.labelAnchor),
          ),
      ],
      boardOutline: raw.outline.transform(m),
      innerGroove: raw.groove.transform(m),
      playerAnchors: [
        for (final a in raw.anchors)
          Offset(
            tf(a).dx.clamp(8, max(8, viewport.width - 8)),
            tf(a).dy.clamp(8, max(8, viewport.height - 8)),
          ),
      ],
      playerEdges: [for (final e in raw.edges) (tf(e.$1), tf(e.$2))],
      playerPiles: [for (final e in raw.piles) (tf(e.$1), tf(e.$2))],
    );
  }

  /// Ô gần điểm chạm nhất (trong bán kính chạm), hoặc null.
  int? hitTest(Offset p) {
    int? best;
    var bestD = double.infinity;
    for (final c in cells) {
      final d = (c.center - p).distance;
      if (d <= c.hitRadius && d < bestD) {
        best = c.id;
        bestD = d;
      }
    }
    return best;
  }

  /// Vị trí hai nút chọn hướng cho ô nguồn: (clockwise, counterClockwise).
  /// Đặt phía ngoài cạnh; nếu không đủ chỗ trong viewport thì đặt vào lòng bàn.
  (Offset, Offset) arrowPositions(int cellId) {
    final c = cells[cellId];
    (Offset, Offset) at(double side) {
      final base = c.center + c.outward * (unit * 1.02 * side);
      return (
        base + c.tangentCw * (unit * 0.52),
        base - c.tangentCw * (unit * 0.52),
      );
    }

    final (a, b) = at(1);
    final r = arrowRadius;
    final fits =
        (clampToView(a, r) - a).distance < 1 &&
        (clampToView(b, r) - b).distance < 1;
    if (fits || config.playerCount == 2) {
      return (clampToView(a, r), clampToView(b, r));
    }
    final (ia, ib) = at(-1);
    return (clampToView(ia, r), clampToView(ib, r));
  }

  Offset clampToView(Offset p, double margin) => Offset(
    p.dx.clamp(margin, max(margin, viewport.width - margin)),
    p.dy.clamp(margin, max(margin, viewport.height - margin)),
  );

  double get arrowRadius => max(unit * 0.4, 22);
}

/// Hình học bàn trong viewport [size], chừa lề [insets] cho HUD nổi.
BoardGeometry boardGeometryFor(
  GameConfig config,
  Size size,
  EdgeInsets insets,
) {
  final area = Rect.fromLTRB(
    insets.left,
    insets.top,
    max(insets.left + 50, size.width - insets.right),
    max(insets.top + 50, size.height - insets.bottom),
  );
  return BoardGeometry.compute(config, size, area: area);
}
