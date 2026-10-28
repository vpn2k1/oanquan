import 'package:flutter/painting.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'widgets/game_rails.dart';

/// Lề chừa quanh bàn cho HUD nổi (thẻ người chơi, nút) trên màn [screen] với
/// vùng an toàn [pad]. Dùng chung cho màn chơi và việc vẽ sẵn bàn trước khi
/// vào ván, để bàn vẽ sẵn khớp đúng bàn thật.
EdgeInsets boardInsetsFor(Size screen, EdgeInsets pad, int players) {
  if (screen.width > screen.height) {
    // Ngang: bàn ở giữa, hai cột bằng nhau hai bên (người chơi | nút).
    final area = Size(
      screen.width - pad.horizontal,
      screen.height - pad.vertical,
    );
    final side = 10.r + gameRailWidth(area, players) + 6.r;
    return EdgeInsets.fromLTRB(
      pad.left + side,
      pad.top + 4.r,
      pad.right + side,
      pad.bottom + 4.r,
    );
  }
  // Dọc: thanh nút + đối thủ ở trên, nút hành động + mình ở dưới.
  var perRow = 1;
  if (players - 1 >= 2) perRow = 2;
  final oppRows = ((players - 1) / perRow).ceil();
  final top = pad.top + (10 + 44 + 10 + 6).r + oppRows * 62.r;
  final bottom = pad.bottom + (10 + 60 + 10 + 44 + 10).r;
  return EdgeInsets.fromLTRB(pad.left + 4.r, top, pad.right + 4.r, bottom);
}
