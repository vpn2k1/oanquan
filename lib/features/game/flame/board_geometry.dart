import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import '../../../core/engine/board_topology.dart';
import '../../../core/game_models/game_config.dart';

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

  static const _danRatio = 0.84;

  /// `area`: vùng đặt bàn bên trong viewport (mặc định toàn viewport) — để
  /// chừa chỗ cho HUD nổi. Mũi tên vẫn được kẹp theo toàn viewport.
  factory BoardGeometry.compute(GameConfig config, Size viewport, {Rect? area}) {
    final raw = config.playerCount == 2
        ? _rectangle(config)
        : _polygon(config);
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
          Offset(tf(a).dx.clamp(8, max(8, viewport.width - 8)),
              tf(a).dy.clamp(8, max(8, viewport.height - 8))),
      ],
      playerEdges: [for (final e in raw.edges) (tf(e.$1), tf(e.$2))],
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
    final fits = (clampToView(a, r) - a).distance < 1 && (clampToView(b, r) - b).distance < 1;
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

  // ---------------------------------------------------------------------------

  static _Raw _rectangle(GameConfig cfg) {
    const u = 1.0;
    final k = cfg.cellsPerPlayer;
    final topo = BoardTopology(cfg);
    final half = k / 2;
    final cells = List<_RawCell?>.filled(cfg.ringLength, null);
    const s = u * _danRatio;
    for (var p = 0; p < 2; p++) {
      final y = p == 0 ? 0.5 * u : -0.5 * u;
      final out = Offset(0, p == 0 ? 1 : -1);
      final tan = Offset(p == 0 ? -1 : 1, 0);
      for (var j = 0; j < k; j++) {
        final x = p == 0 ? (half - 0.5 - j) * u : (j - half + 0.5) * u;
        final c = Offset(x, y);
        cells[topo.danIndex(p, j)] = _RawCell(
          id: topo.danIndex(p, j),
          isQuan: false,
          center: c,
          size: s,
          rotation: 0,
          outward: out,
          tangentCw: tan,
          outline: _roundedSquare(c, s, 0),
          labelAnchor: c + out * (s * 0.32) + const Offset(1, 0) * (s * 0.32),
        );
      }
      // Q0 ở đầu phải, Q1 ở đầu trái.
      final qx = (p == 0 ? 1 : -1) * (half * u + 0.62 * u);
      final qc = Offset(qx, 0);
      cells[topo.quanIndex(p)] = _RawCell(
        id: topo.quanIndex(p),
        isQuan: true,
        center: qc,
        size: 1.9 * u,
        rotation: 0,
        outward: Offset(p == 0 ? 1 : -1, 0),
        tangentCw: Offset(0, p == 0 ? 1 : -1),
        outline: Path()
          ..addOval(Rect.fromCenter(center: qc, width: 1.16 * u, height: 1.86 * u)),
        labelAnchor: qc + const Offset(0, 0.68 * u),
      );
    }
    final bw = (half + 1.32) * u;
    final outline = Path()
      ..addRRect(RRect.fromRectAndRadius(
          Rect.fromLTRB(-bw, -1.18 * u, bw, 1.18 * u), const Radius.circular(1.18 * u)));
    final groove = Path()
      ..addRRect(RRect.fromRectAndRadius(
          Rect.fromLTRB(-bw + 0.13 * u, -1.05 * u, bw - 0.13 * u, 1.05 * u),
          const Radius.circular(1.05 * u)));
    return _Raw(
      unit: u,
      cells: cells.cast<_RawCell>(),
      outline: outline,
      groove: groove,
      anchors: [Offset(0, 2.05 * u), Offset(0, -2.05 * u)],
      edges: [
        (Offset(half * u, 1.12 * u), Offset(-half * u, 1.12 * u)),
        (Offset(-half * u, -1.12 * u), Offset(half * u, -1.12 * u)),
      ],
      // Vùng chứa: bàn + mũi tên chọn hướng phía ngoài mỗi hàng.
      bounds: Rect.fromLTRB(-bw - 0.1, -2.05 * u, bw + 0.1, 2.05 * u),
    );
  }

  static _Raw _polygon(GameConfig cfg) {
    final n = cfg.playerCount;
    final k = cfg.cellsPerPlayer;
    final topo = BoardTopology(cfg);
    const r = 1.0;
    // Đỉnh p: góc tăng = chiều kim đồng hồ trên màn hình (trục y hướng xuống).
    // Người 0 ở cạnh đáy.
    final verts = [
      for (var p = 0; p < n; p++)
        Offset.fromDirection(pi / 2 - pi / n + p * 2 * pi / n, r),
    ];
    final edgeLen = (verts[1] - verts[0]).distance;
    final u = edgeLen / (k + 1.6);
    final s = u * _danRatio;
    final cells = List<_RawCell?>.filled(cfg.ringLength, null);
    final anchors = <Offset>[];
    final edges = <(Offset, Offset)>[];
    final apothem = r * cos(pi / n);
    for (var p = 0; p < n; p++) {
      final a = verts[p];
      final b = verts[(p + 1) % n];
      final dir = (b - a) / edgeLen;
      final mid = (a + b) / 2;
      final out = mid / mid.distance;
      final rot = atan2(dir.dy, dir.dx);
      for (var j = 0; j < k; j++) {
        final c = a + dir * ((1.3 + j) * u);
        cells[topo.danIndex(p, j)] = _RawCell(
          id: topo.danIndex(p, j),
          isQuan: false,
          center: c,
          size: s,
          rotation: rot,
          outward: out,
          tangentCw: dir,
          outline: _roundedSquare(c, s, rot),
          labelAnchor: c + out * (s * 0.32) + dir * (s * 0.32),
        );
      }
      final radial = a / a.distance;
      final qc = a + radial * (0.12 * u);
      cells[topo.quanIndex(p)] = _RawCell(
        id: topo.quanIndex(p),
        isQuan: true,
        center: qc,
        size: 1.3 * u,
        rotation: atan2(radial.dy, radial.dx),
        outward: radial,
        tangentCw: Offset(-radial.dy, radial.dx),
        outline: Path()..addOval(Rect.fromCircle(center: qc, radius: 0.65 * u)),
        labelAnchor: qc - radial * (0.5 * u),
      );
      anchors.add(out * (apothem + 1.6 * u));
      edges.add((a + dir * (0.9 * u) + out * (0.62 * u), b - dir * (0.9 * u) + out * (0.62 * u)));
    }
    // Viền bàn: đa giác giãn ra ngoài, bo góc.
    Path inflated(double d, double radius) {
      final rr = r + d / cos(pi / n);
      return _roundedPolygon([for (final v in verts) v / r * rr], radius);
    }

    final outline = inflated(0.78 * u, 1.0 * u);
    final groove = inflated(0.64 * u, 0.85 * u);
    // Bounds gồm cả mũi tên ngoài các cạnh. Không dùng Path.getBounds vì nó
    // tính cả điểm điều khiển bezier → bàn nhỏ hơn cần thiết.
    final rr = r + 0.78 * u / cos(pi / n);
    final big = [for (final v in verts) v / r * rr];
    var bounds = Rect.fromPoints(big[0], big[1]);
    for (var i = 0; i < n; i++) {
      final prev = big[(i - 1 + n) % n], cur = big[i], next = big[(i + 1) % n];
      final p1 = cur + (prev - cur) / (prev - cur).distance * u;
      final p2 = cur + (next - cur) / (next - cur).distance * u;
      final apex = p1 * 0.25 + cur * 0.5 + p2 * 0.25;
      bounds = bounds
          .expandToInclude(Rect.fromPoints(p1, p2))
          .expandToInclude(Rect.fromCircle(center: apex, radius: 0.01));
    }
    // Mũi tên/đích bay được kẹp vào viewport nên chỉ chừa lề nhỏ quanh bàn.
    return _Raw(
      unit: u,
      cells: cells.cast<_RawCell>(),
      outline: outline,
      groove: groove,
      anchors: anchors,
      edges: edges,
      bounds: bounds.inflate(0.4 * u),
    );
  }

  static Path _roundedSquare(Offset c, double s, double rot) {
    final rect = Rect.fromCenter(center: Offset.zero, width: s, height: s);
    final path = Path()..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(s * 0.26)));
    final cs = cos(rot), sn = sin(rot);
    return path.transform(Float64List.fromList([
      cs, sn, 0, 0, //
      -sn, cs, 0, 0,
      0, 0, 1, 0,
      c.dx, c.dy, 0, 1,
    ]));
  }

  static Path _roundedPolygon(List<Offset> pts, double radius) {
    final path = Path();
    final n = pts.length;
    for (var i = 0; i < n; i++) {
      final prev = pts[(i - 1 + n) % n];
      final cur = pts[i];
      final next = pts[(i + 1) % n];
      final d1 = (prev - cur);
      final d2 = (next - cur);
      final r1 = min(radius, d1.distance / 2);
      final r2 = min(radius, d2.distance / 2);
      final p1 = cur + d1 / d1.distance * r1;
      final p2 = cur + d2 / d2.distance * r2;
      if (i == 0) {
        path.moveTo(p1.dx, p1.dy);
      } else {
        path.lineTo(p1.dx, p1.dy);
      }
      path.quadraticBezierTo(cur.dx, cur.dy, p2.dx, p2.dy);
    }
    path.close();
    return path;
  }
}

class _RawCell {
  const _RawCell({
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
  final double size;
  final double rotation;
  final Offset outward;
  final Offset tangentCw;
  final Path outline;
  final Offset labelAnchor;
}

class _Raw {
  const _Raw({
    required this.unit,
    required this.cells,
    required this.outline,
    required this.groove,
    required this.anchors,
    required this.edges,
    required this.bounds,
  });
  final double unit;
  final List<_RawCell> cells;
  final Path outline;
  final Path groove;
  final List<Offset> anchors;
  final List<(Offset, Offset)> edges;
  final Rect bounds;
}
