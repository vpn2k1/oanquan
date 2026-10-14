import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:o_quan_viet/core/engine/board_topology.dart';
import 'package:o_quan_viet/core/game_models/game_config.dart';
import 'package:o_quan_viet/features/game/flame/board_geometry.dart';

void main() {
  const viewports = {
    'mobile-portrait': Size(360, 420),
    'mobile-landscape': Size(640, 300),
    'tablet': Size(768, 760),
    'desktop': Size(1280, 640),
  };

  double extent(CellGeometry c) => c.isQuan ? c.size / 2 * 0.62 : c.size * 0.59;

  for (final n in [2, 3, 4]) {
    for (final e in viewports.entries) {
      test('$n người @ ${e.key}: trong viewport, không đè ô, chiều kim đồng hồ', () {
        final cfg = GameConfig.preset(n);
        final g = BoardGeometry.compute(cfg, e.value);
        final topo = BoardTopology(cfg);
        expect(g.cells.length, cfg.ringLength);
        final view = Offset.zero & e.value;
        for (final c in g.cells) {
          expect(view.inflate(1).contains(c.center), isTrue);
          expect(g.hitTest(c.center), c.id);
        }
        // Không đè nhau (xấp xỉ hình tròn).
        for (var i = 0; i < g.cells.length; i++) {
          for (var j = i + 1; j < g.cells.length; j++) {
            final a = g.cells[i], b = g.cells[j];
            expect((a.center - b.center).distance, greaterThan(extent(a) + extent(b) - 0.5),
                reason: 'ô $i và $j đè nhau');
          }
        }
        // Vòng chỉ số tăng = chiều kim đồng hồ trên màn hình (y hướng xuống → diện tích có dấu > 0).
        var area = 0.0;
        for (var i = 0; i < g.cells.length; i++) {
          final a = g.cells[i].center, b = g.cells[(i + 1) % g.cells.length].center;
          area += a.dx * b.dy - b.dx * a.dy;
        }
        expect(area, greaterThan(0));
        // Người 0 ở cạnh dưới.
        final cy = g.cells.fold(0.0, (s, c) => s + c.center.dy) / g.cells.length;
        final p0y = topo.playerCells(0).fold(0.0, (s, i) => s + g.cells[i].center.dy) / 5;
        expect(p0y, greaterThan(cy));
        // Mũi tên chọn hướng nằm trong viewport.
        for (final i in topo.playerCells(0)) {
          final (a, b) = g.arrowPositions(i);
          expect(view.inflate(2).contains(a) && view.inflate(2).contains(b), isTrue);
        }
      });
    }
  }

  test('ô quan Qp nằm ở góc/đỉnh: xa tâm hơn mọi ô dân', () {
    for (final n in [2, 3, 4]) {
      final cfg = GameConfig.preset(n);
      final g = BoardGeometry.compute(cfg, const Size(800, 800));
      final topo = BoardTopology(cfg);
      final center = g.cells.fold(Offset.zero, (s, c) => s + c.center) / g.cells.length.toDouble();
      final maxDan = g.cells
          .where((c) => !c.isQuan)
          .map((c) => (c.center - center).distance)
          .reduce((a, b) => a > b ? a : b);
      for (final q in topo.quanCells) {
        expect((g.cells[q].center - center).distance, greaterThan(maxDan * 0.98));
      }
    }
    // 4 người: Q0 dưới-phải, Q1 dưới-trái, Q2 trên-trái, Q3 trên-phải.
    final g = BoardGeometry.compute(GameConfig.preset(4), const Size(800, 800));
    final c = g.boardOutline.getBounds().center;
    final q = [0, 6, 12, 18].map((i) => g.cells[i].center - c).toList();
    expect(q[0].dx > 0 && q[0].dy > 0, isTrue);
    expect(q[1].dx < 0 && q[1].dy > 0, isTrue);
    expect(q[2].dx < 0 && q[2].dy < 0, isTrue);
    expect(q[3].dx > 0 && q[3].dy < 0, isTrue);
  });

  test('vùng chạm ô dân ≥ 44 px trên điện thoại dọc 360 px', () {
    for (final n in [2, 3, 4]) {
      final g = BoardGeometry.compute(GameConfig.preset(n), const Size(360, 560));
      for (final c in g.cells) {
        expect(c.hitRadius * 2, greaterThanOrEqualTo(44));
      }
      expect(g.unit, greaterThan(35), reason: 'ô đủ lớn để nhìn rõ ($n người)');
    }
  });

  test('điện thoại ngang (vùng bàn ~590×355): ô đủ lớn, vùng chạm ≥ 44 px', () {
    for (final n in [2, 3, 4]) {
      final g = BoardGeometry.compute(GameConfig.preset(n), const Size(590, 355));
      expect(g.unit, greaterThan(n == 2 ? 60 : 36), reason: '$n người: unit=${g.unit}');
      for (final c in g.cells) {
        expect(c.hitRadius * 2, greaterThanOrEqualTo(44));
      }
    }
  });
}
