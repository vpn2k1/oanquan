import 'dart:math';
import 'dart:ui';

import 'package:flutter/painting.dart' show Alignment, RadialGradient;

import '../../../app/theme.dart';
import '../../../app/folk_art.dart';
import 'board_geometry.dart';
import 'board_game.dart';

/// Ảnh tĩnh của mặt sân + bàn kẻ tay.
extension BoardRaster on OQuanGame {
  /// Mặt sân + bàn kẻ tay → một ảnh (vẽ lại chỉ khi đổi kích thước/kiểu).
  Image rasterStatic(BoardGeometry g) {
    final dpr = PlatformDispatcher.instance.views.first.devicePixelRatio;
    final sz = Size(size.x, size.y);
    final w = max(1, (sz.width * dpr).round());
    final h = max(1, (sz.height * dpr).round());
    final rec = PictureRecorder();
    final canvas = Canvas(rec)..scale(dpr);
    final st = style;
    // Mặt sân dân dã trải kín toàn màn hình (bàn kẻ thẳng lên sân).
    final ground = GroundCache.peek(sz, dpr, st.ground, groundSeed);
    if (ground != null) {
      canvas.drawImageRect(
        ground,
        Rect.fromLTWH(0, 0, ground.width.toDouble(), ground.height.toDouble()),
        Offset.zero & sz,
        Paint(),
      );
    } else {
      // Chưa vẽ sẵn: tô màu nền của mặt sân, vẽ ngầm rồi thay khi xong.
      canvas.drawRect(
        Offset.zero & sz,
        Paint()..color = FolkGround.baseColor(st.ground),
      );
      final key = (st, groundSeed, sz);
      GroundCache.warmUp(sz, dpr, st.ground, groundSeed).then((_) {
        if ((style, groundSeed, Size(size.x, size.y)) == key) {
          boardImage = null;
        }
      });
    }
    // Tối nhẹ các mép màn để HUD nổi và mắt dồn vào bàn.
    final screen = Offset.zero & sz;
    canvas.drawRect(
      screen,
      Paint()
        ..shader = RadialGradient(
          center: Alignment(
            (g.boardOutline.getBounds().center.dx / sz.width) * 2 - 1,
            (g.boardOutline.getBounds().center.dy / sz.height) * 2 - 1,
          ),
          radius: 1.1,
          colors: const [
            Color(0x00000000),
            Color(0x00000000),
            Color(0x80000000),
          ],
          stops: const [0, 0.5, 1],
        ).createShader(screen),
    );
    drawSketchBoard(canvas, g, st);
    final pic = rec.endRecording();
    final img = pic.toImageSync(w, h);
    pic.dispose();
    return img;
  }

  void drawSketchBoard(Canvas canvas, BoardGeometry g, FolkStyle st) {
    final u = g.unit;
    final seed = state.config.seed;
    // Nét mảnh, gọn như Recess; que vạch đất cần dày hơn để thấy rãnh.
    var penWidth = 0.045;
    if (st.pen == PenKind.stick) penWidth = 0.06;
    final lineW = max(1.6, u * penWidth);

    // Ô trên đất được khoét nông; trên xi măng/gạch chỉ là nét kẻ.
    if (st.ground == GroundKind.dirt) {
      for (final c in g.cells) {
        canvas.drawPath(
          c.outline,
          Paint()
            ..color = const Color(0x2E4A2E14)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, u * 0.08),
        );
      }
    }

    // Khung bàn và các ô — mỗi nét có seed riêng nên run tay khác nhau.
    FolkPen.stroke(
      canvas,
      g.boardOutline,
      st.pen,
      width: lineW * 1.1,
      seed: seed * 31 + 1,
    );
    for (final c in g.cells) {
      FolkPen.stroke(
        canvas,
        c.outline,
        st.pen,
        width: lineW,
        seed: seed * 31 + 7 + c.id * 13,
      );
    }

    // Dải phấn màu đánh dấu cạnh của từng người.
    for (var p = 0; p < g.playerEdges.length; p++) {
      final (a, b) = g.playerEdges[p];
      final path = Path()
        ..moveTo(a.dx, a.dy)
        ..lineTo(b.dx, b.dy);
      FolkPen.stroke(
        canvas,
        path,
        PenKind.chalk,
        width: u * 0.07,
        color: playerColors[p],
        seed: seed * 31 + 500 + p,
      );
      if (visuals.colorBlind) {
        paintPlayerSymbol(
          canvas,
          (a + b) / 2,
          u * 0.12,
          symbolOf(p),
          Paint()..color = st.ink,
        );
      }
    }
  }
}
