import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:o_quan_viet/features/game/flame/pieces_painter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('generated pieces load and render', () async {
    await PiecesPainter.loadPieces();
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    for (var variant = 0; variant < 4; variant++) {
      PiecesPainter.pebble(
        canvas,
        Offset(24.0 + variant * 48, 24),
        16,
        variant: variant,
      );
    }
    PiecesPainter.quanStone(canvas, const Offset(24, 24), 16);
    final picture = recorder.endRecording();
    final image = await picture.toImage(192, 48);
    expect(image.width, 192);
    image.dispose();
    picture.dispose();
  });
}
