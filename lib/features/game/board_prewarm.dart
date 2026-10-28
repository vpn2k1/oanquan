import 'package:flutter/widgets.dart';

import '../../app/folk_art.dart';
import '../../core/game_models/game_config.dart';
import '../settings/settings_controller.dart';
import 'flame/board_raster.dart';
import 'ui/board_insets.dart';

/// Vẽ sẵn ở nền mặt sân + bàn của ván sắp vào (đúng kích thước màn, kiểu sân,
/// lề HUD) để màn chơi có bàn ngay frame đầu, không trống chờ vẽ.
Future<void> prewarmBoard(
  BuildContext context,
  GameConfig config,
  AppSettings settings,
) {
  final mq = MediaQuery.of(context);
  final spec = StaticBoardSpec(
    config: config,
    size: mq.size,
    dpr: mq.devicePixelRatio,
    insets: boardInsetsFor(mq.size, mq.padding, config.playerCount),
    style: FolkStyle.resolve(settings.boardStyle, config.seed),
    groundSeed: config.seed,
    colorBlind: settings.colorBlind,
  );
  return StaticBoardCache.warmUp(spec);
}
