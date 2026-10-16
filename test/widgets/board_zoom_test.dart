import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:o_quan_viet/features/game/ui/widgets/board_zoom.dart';

double _scale(WidgetTester t) => t
    .widget<InteractiveViewer>(find.byType(InteractiveViewer))
    .transformationController!
    .value
    .getMaxScaleOnAxis();

void main() {
  Future<List<Offset>> pump(WidgetTester t) async {
    final taps = <Offset>[];
    await t.pumpWidget(
      MaterialApp(
        home: BoardZoom(
          child: GestureDetector(
            onTapDown: (d) => taps.add(d.localPosition),
            child: const ColoredBox(color: Colors.brown),
          ),
        ),
      ),
    );
    return taps;
  }

  testWidgets('hai ngón kéo ra thì phóng to, giới hạn 3×', (t) async {
    await pump(t);
    final c = t.getCenter(find.byType(BoardZoom));
    final a = await t.startGesture(c - const Offset(40, 0), pointer: 1);
    final b = await t.startGesture(c + const Offset(40, 0), pointer: 2);
    for (var i = 1; i <= 10; i++) {
      await a.moveTo(c - Offset(40.0 + i * 30, 0));
      await b.moveTo(c + Offset(40.0 + i * 30, 0));
      await t.pump();
    }
    await a.up();
    await b.up();
    await t.pumpAndSettle();
    expect(_scale(t), greaterThan(1.5));
    expect(_scale(t), lessThanOrEqualTo(3.0001));
  });

  testWidgets('một ngón ở 1× không kéo/zoom, chạm vẫn tới bàn', (t) async {
    final taps = await pump(t);
    final c = t.getCenter(find.byType(BoardZoom));
    await t.dragFrom(c, const Offset(120, 0));
    await t.pumpAndSettle();
    expect(_scale(t), closeTo(1, 1e-6));
    await t.tapAt(c);
    expect(taps, isNotEmpty);
  });
}
