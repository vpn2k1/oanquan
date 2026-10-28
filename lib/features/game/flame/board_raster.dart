import 'dart:math';
import 'dart:ui';

import 'package:flutter/painting.dart'
    show Alignment, EdgeInsets, RadialGradient;

import '../../../app/theme.dart';
import '../../../app/folk_art.dart';
import '../../../core/game_models/game_config.dart';
import 'board_geometry.dart';
import 'board_game.dart';

/// Thông số quyết định ảnh tĩnh của bàn: cùng thông số → cùng ảnh, nên vẽ sẵn
/// được trước khi vào ván (màn chọn, trang chủ) rồi dùng lại ngay frame đầu.
class StaticBoardSpec {
  const StaticBoardSpec({
    required this.config,
    required this.size,
    required this.dpr,
    required this.insets,
    required this.style,
    required this.groundSeed,
    required this.colorBlind,
  });

  final GameConfig config;
  final Size size;
  final double dpr;

  /// Lề chừa cho HUD nổi (xem `boardInsetsFor`).
  final EdgeInsets insets;
  final FolkStyle style;
  final int groundSeed;
  final bool colorBlind;

  String get key =>
      '${size.width}x${size.height}@$dpr|$insets|${style.id}|$groundSeed|'
      '${config.playerCount}|${config.seed}|$colorBlind';

  int get pixelWidth => max(1, (size.width * dpr).round());
  int get pixelHeight => max(1, (size.height * dpr).round());

  BoardGeometry geometry() => boardGeometryFor(config, size, insets);
}

/// Ảnh tĩnh của bàn đã vẽ sẵn ở nền.
abstract final class StaticBoardCache {
  static final _images = <String, Image>{};
  static final _pending = <String, Future<void>>{};

  static Image? peek(StaticBoardSpec s) => _images[s.key];

  /// Vẽ sẵn (mặt sân rồi bàn) — chuyển ảnh trên luồng raster, không chặn UI
  /// lâu. Gọi lại cùng thông số chỉ vẽ một lần.
  static Future<void> warmUp(StaticBoardSpec s) {
    final key = s.key;
    if (_images.containsKey(key)) return Future.value();
    return _pending[key] ??= () async {
      try {
        final ground = await GroundCache.warmUp(
          s.size,
          s.dpr,
          s.style.ground,
          s.groundSeed,
        );
        final pic = recordStaticBoard(s, s.geometry(), ground);
        final img = await pic.toImage(s.pixelWidth, s.pixelHeight);
        pic.dispose();
        // Không dispose ảnh cũ: có thể vẫn đang được vẽ; để GC thu.
        if (_images.length > 4) _images.clear();
        _images[key] = img;
      } finally {
        _pending.remove(key);
      }
    }();
  }
}

/// Ghi lại mặt sân + bàn kẻ tay. [ground] null → tô màu nền của mặt sân.
Picture recordStaticBoard(StaticBoardSpec s, BoardGeometry g, Image? ground) {
  final sz = s.size;
  final st = s.style;
  final rec = PictureRecorder();
  final canvas = Canvas(rec)..scale(s.dpr);
  // Mặt sân dân dã trải kín toàn màn hình (bàn kẻ thẳng lên sân).
  if (ground != null) {
    canvas.drawImageRect(
      ground,
      Rect.fromLTWH(0, 0, ground.width.toDouble(), ground.height.toDouble()),
      Offset.zero & sz,
      Paint(),
    );
  } else {
    canvas.drawRect(
      Offset.zero & sz,
      Paint()..color = FolkGround.baseColor(st.ground),
    );
  }
  // Tối nhẹ các mép màn để HUD nổi và mắt dồn vào bàn.
  final screen = Offset.zero & sz;
  final center = g.boardOutline.getBounds().center;
  canvas.drawRect(
    screen,
    Paint()
      ..shader = RadialGradient(
        center: Alignment(
          (center.dx / sz.width) * 2 - 1,
          (center.dy / sz.height) * 2 - 1,
        ),
        radius: 1.1,
        colors: const [Color(0x00000000), Color(0x00000000), Color(0x80000000)],
        stops: const [0, 0.5, 1],
      ).createShader(screen),
  );
  drawSketchBoard(canvas, g, st, seed: s.config.seed, colorBlind: s.colorBlind);
  return rec.endRecording();
}

/// Ảnh tĩnh của mặt sân + bàn kẻ tay cho ván đang chơi.
extension BoardRaster on OQuanGame {
  StaticBoardSpec get staticSpec => staticSpecFor(Size(size.x, size.y));

  /// Thông số ảnh tĩnh nếu bàn có kích thước [viewport] (trước khi Flame gắn
  /// game, kích thước game còn bằng 0).
  StaticBoardSpec staticSpecFor(Size viewport) => StaticBoardSpec(
    config: state.config,
    size: viewport,
    dpr: devicePixelRatio,
    insets: boardInsets,
    style: style,
    groundSeed: groundSeed,
    colorBlind: visuals.colorBlind,
  );

  /// Dùng ảnh vẽ sẵn nếu có; không thì vẽ ngay (chỉ khi đổi kích thước/kiểu).
  Image rasterStatic(BoardGeometry g) {
    final spec = staticSpec;
    final ready = StaticBoardCache.peek(spec);
    if (ready != null) return ready;
    final st = spec.style;
    final ground = GroundCache.peek(spec.size, spec.dpr, st.ground, groundSeed);
    if (ground == null) {
      // Chưa có mặt sân: tạm tô màu nền, vẽ ngầm rồi thay khi xong.
      final key = spec.key;
      StaticBoardCache.warmUp(spec).then((_) {
        if (staticSpec.key == key) boardImage = null;
      });
    }
    final pic = recordStaticBoard(spec, g, ground);
    final img = pic.toImageSync(spec.pixelWidth, spec.pixelHeight);
    pic.dispose();
    return img;
  }
}

void drawSketchBoard(
  Canvas canvas,
  BoardGeometry g,
  FolkStyle st, {
  required int seed,
  required bool colorBlind,
}) {
  final u = g.unit;
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
    if (colorBlind) {
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
