import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../l10n/strings.dart';
import '../hud.dart';

/// Các nút điều khiển trên màn chơi, ghép thành hàng trên và hàng gợi ý/hoàn tác.
class GameHudButtons {
  GameHudButtons({
    required VoidCallback onPause,
    required VoidCallback onShuffleGround,
    required bool soundOn,
    required VoidCallback onToggleSound,
    required VoidCallback onRules,
    required VoidCallback? onUndo,
    required VoidCallback? onHint,
  }) {
    var soundIcon = Icons.volume_off_rounded;
    var soundTip = Strings.soundOn;
    if (soundOn) {
      soundIcon = Icons.volume_up_rounded;
      soundTip = Strings.soundOff;
    }
    pause = HudButton(
      key: const Key('pause'),
      icon: Icons.pause_rounded,
      tooltip: Strings.pause,
      onPressed: onPause,
    );
    ground = HudButton(
      key: const Key('shuffleGround'),
      icon: Icons.palette_rounded,
      tooltip: Strings.shuffleGround,
      onPressed: onShuffleGround,
    );
    sound = HudButton(
      icon: soundIcon,
      tooltip: soundTip,
      onPressed: onToggleSound,
    );
    rules = HudButton(
      icon: Icons.menu_book_rounded,
      tooltip: Strings.rules,
      onPressed: onRules,
    );
    undo = HudButton(
      key: const Key('undo'),
      icon: Icons.undo_rounded,
      tooltip: Strings.undo,
      onPressed: onUndo,
    );
    hint = HudButton(
      key: const Key('hint'),
      icon: Icons.lightbulb_rounded,
      tooltip: Strings.hint,
      label: Strings.hint,
      onPressed: onHint,
    );
    hintIcon = HudButton(
      key: const Key('hint'),
      icon: Icons.lightbulb_rounded,
      tooltip: Strings.hint,
      onPressed: onHint,
    );
  }

  late final Widget pause, ground, sound, rules, undo, hint, hintIcon;

  /// Cột phải ở màn ngang: nhóm trên (tạm dừng, luật, âm thanh, đổi sân)
  /// và nhóm dưới (gợi ý, hoàn tác) — đối xứng với cột người chơi bên trái.
  (List<Widget>, List<Widget>) railGroups() =>
      ([pause, rules, sound, ground], [hintIcon, undo]);

  /// Hàng trên: tạm dừng ... đổi sân, âm thanh, luật.
  Widget topBar(double rulesGap) => Row(
    children: [
      pause,
      const Spacer(),
      ground,
      SizedBox(width: 6.r),
      sound,
      SizedBox(width: rulesGap),
      rules,
    ],
  );

  /// Hàng nút trên của cột rộng (màn ngang, bàn vuông/tam giác).
  Widget railTopRow() => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [pause, rules, sound, ground],
  );

  /// Hàng gợi ý + hoàn tác.
  Widget actionRow() => Row(
    children: [
      Expanded(child: hint),
      SizedBox(width: 8.r),
      undo,
    ],
  );
}
