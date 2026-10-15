import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import '../../../core/engine/board_topology.dart';
import '../../../core/game_models/game_config.dart';

// Hình học thô của bàn (đơn vị chuẩn hoá) — BoardGeometry.compute co giãn
// kết quả vào viewport.

/// Tỉ lệ cạnh ô dân so với đơn vị.
const danRatio = 0.84;

RawBoard rawRectangle(GameConfig cfg) {
  const u = 1.0;
  final k = cfg.cellsPerPlayer;
  final topo = BoardTopology(cfg);
  final half = k / 2;
  final cells = List<RawCell?>.filled(cfg.ringLength, null);
  const s = u * danRatio;
  for (var p = 0; p < 2; p++) {
    // Hàng của người 0 ở dưới (dấu +), người 1 ở trên (dấu −).
    var sign = -1.0;
    if (p == 0) sign = 1;
    final y = sign * 0.5 * u;
    final out = Offset(0, sign);
    final tan = Offset(-sign, 0);
    for (var j = 0; j < k; j++) {
      final x = sign * (half - 0.5 - j) * u;
      final c = Offset(x, y);
      cells[topo.danIndex(p, j)] = RawCell(
        id: topo.danIndex(p, j),
        isQuan: false,
        center: c,
        size: s,
        rotation: 0,
        outward: out,
        tangentCw: tan,
        outline: roundedSquare(c, s, 0),
        labelAnchor: c + out * (s * 0.32) + const Offset(1, 0) * (s * 0.32),
      );
    }
    // Q0 ở đầu phải, Q1 ở đầu trái.
    final qx = sign * (half * u + 0.62 * u);
    final qc = Offset(qx, 0);
    cells[topo.quanIndex(p)] = RawCell(
      id: topo.quanIndex(p),
      isQuan: true,
      center: qc,
      size: 1.9 * u,
      rotation: 0,
      outward: Offset(sign, 0),
      tangentCw: Offset(0, sign),
      outline: Path()
        ..addOval(
          Rect.fromCenter(center: qc, width: 1.16 * u, height: 1.86 * u),
        ),
      labelAnchor: qc + const Offset(0, 0.68 * u),
    );
  }
  final bw = (half + 1.32) * u;
  final outline = Path()
    ..addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(-bw, -1.18 * u, bw, 1.18 * u),
        const Radius.circular(1.18 * u),
      ),
    );
  final groove = Path()
    ..addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(-bw + 0.13 * u, -1.05 * u, bw - 0.13 * u, 1.05 * u),
        const Radius.circular(1.05 * u),
      ),
    );
  return RawBoard(
    unit: u,
    cells: cells.cast<RawCell>(),
    outline: outline,
    groove: groove,
    anchors: [Offset(0, 2.05 * u), Offset(0, -2.05 * u)],
    edges: [
      (Offset(half * u, 1.12 * u), Offset(-half * u, 1.12 * u)),
      (Offset(-half * u, -1.12 * u), Offset(half * u, -1.12 * u)),
    ],
    // Như Recess: quân ăn xếp thành hàng ngoài mép bàn, phía người ăn.
    piles: [
      (Offset(-bw + 0.2 * u, 1.62 * u), Offset(bw - 0.9 * u, 1.62 * u)),
      (Offset(-bw + 0.2 * u, -1.62 * u), Offset(bw - 0.9 * u, -1.62 * u)),
    ],
    // Vùng chứa: bàn + hàng quân ăn + lề khay.
    bounds: Rect.fromLTRB(-bw - 0.5 * u, -2.05 * u, bw + 0.5 * u, 2.05 * u),
  );
}

RawBoard rawPolygon(GameConfig cfg) {
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
  final s = u * danRatio;
  final cells = List<RawCell?>.filled(cfg.ringLength, null);
  final anchors = <Offset>[];
  final edges = <(Offset, Offset)>[];
  final piles = <(Offset, Offset)>[];
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
      cells[topo.danIndex(p, j)] = RawCell(
        id: topo.danIndex(p, j),
        isQuan: false,
        center: c,
        size: s,
        rotation: rot,
        outward: out,
        tangentCw: dir,
        outline: roundedSquare(c, s, rot),
        labelAnchor: c + out * (s * 0.32) + dir * (s * 0.32),
      );
    }
    final radial = a / a.distance;
    final qc = a + radial * (0.12 * u);
    cells[topo.quanIndex(p)] = RawCell(
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
    edges.add((
      a + dir * (0.9 * u) + out * (0.62 * u),
      b - dir * (0.9 * u) + out * (0.62 * u),
    ));
    // Bàn đa giác: lòng bàn còn trống → xếp quân ăn ở phía trong, sát cạnh mình.
    final inner = -out * (0.88 * u);
    piles.add((a + dir * (1.9 * u) + inner, b - dir * (2.4 * u) + inner));
  }
  // Viền bàn: đa giác giãn ra ngoài, bo góc.
  Path inflated(double d, double radius) {
    final rr = r + d / cos(pi / n);
    return roundedPolygon([for (final v in verts) v / r * rr], radius);
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
  return RawBoard(
    unit: u,
    cells: cells.cast<RawCell>(),
    outline: outline,
    groove: groove,
    anchors: anchors,
    edges: edges,
    piles: piles,
    bounds: bounds.inflate(0.4 * u),
  );
}

Path roundedSquare(Offset c, double s, double rot) {
  final rect = Rect.fromCenter(center: Offset.zero, width: s, height: s);
  final path = Path()
    ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(s * 0.26)));
  final cs = cos(rot), sn = sin(rot);
  return path.transform(
    Float64List.fromList([
      cs, sn, 0, 0, //
      -sn, cs, 0, 0,
      0, 0, 1, 0,
      c.dx, c.dy, 0, 1,
    ]),
  );
}

Path roundedPolygon(List<Offset> pts, double radius) {
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

class RawCell {
  const RawCell({
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

class RawBoard {
  const RawBoard({
    required this.unit,
    required this.cells,
    required this.outline,
    required this.groove,
    required this.anchors,
    required this.edges,
    required this.piles,
    required this.bounds,
  });
  final double unit;
  final List<RawCell> cells;
  final Path outline;
  final Path groove;
  final List<Offset> anchors;
  final List<(Offset, Offset)> edges;

  /// Hàng đặt quân đã ăn của từng người: (đầu, cuối) — số điểm ở sau đầu cuối.
  final List<(Offset, Offset)> piles;
  final Rect bounds;
}
