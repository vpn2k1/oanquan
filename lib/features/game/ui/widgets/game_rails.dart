import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/folk_art.dart';
import '../../../../app/theme.dart';
import '../../../../app/widgets.dart';
import '../../../../core/game_models/game_state.dart';
import '../../../../l10n/strings.dart';

/// Cột rộng (thẻ ngang + hàng nút) cần tối thiểu bề ngang này.
double get _wideMin => 190.r;

/// Bề ngang mỗi cột bên (trái: người chơi, phải: nút) ở màn ngang. Bàn
/// vuông/tam giác chừa nhiều chỗ hai bên → cột rộng; bàn chữ nhật (2 người)
/// gần kín bề ngang → cột hẹp để bàn to nhất có thể.
double gameRailWidth(Size area, int players) {
  var aspect = 1.15;
  if (players == 2) aspect = 2.1;
  final free = (area.width - area.height * aspect) / 2 - 16.r;
  if (free >= _wideMin) return math.min(free, 230.r);
  return 68.r;
}

bool isWideRail(double width) => width >= _wideMin;

/// Cột dọc hai nhóm: nhóm trên dồn lên đỉnh, nhóm dưới dồn xuống đáy.
/// Màn quá thấp thì cuộn thay vì tràn.
class GameRail extends StatelessWidget {
  const GameRail({super.key, required this.top, required this.bottom});

  final List<Widget> top;
  final List<Widget> bottom;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) => SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: c.maxHeight),
        child: IntrinsicHeight(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ..._spaced(top),
              const Spacer(),
              SizedBox(height: 8.r),
              ..._spaced(bottom),
            ],
          ),
        ),
      ),
    ),
  );

  static List<Widget> _spaced(List<Widget> items) => [
    for (var i = 0; i < items.length; i++) ...[
      if (i > 0) SizedBox(height: 8.r),
      items[i],
    ],
  ];
}

/// Thẻ người chơi dạng dọc, hẹp: avatar, tên, điểm. Tới lượt thì viền cam.
class RailPlayerChip extends StatelessWidget {
  const RailPlayerChip({
    super.key,
    required this.state,
    required this.playerId,
    required this.scores,
    this.thinking = false,
  });

  final GameState state;
  final int playerId;
  final ValueNotifier<List<int>> scores;
  final bool thinking;

  @override
  Widget build(BuildContext context) {
    final t = RcTokens.of(context);
    final p = state.players[playerId];
    final isTurn = !state.isOver && state.turnPlayer == playerId;
    var fill = t.surface;
    var borderColor = t.text.withValues(alpha: 0.55);
    var borderWidth = 2.0;
    var shadows = const <BoxShadow>[];
    if (isTurn) {
      fill = Color.alphaBlend(Rc.accentSoft, t.surface);
      borderColor = Rc.accent;
      borderWidth = 2.8;
      shadows = [BoxShadow(color: const Color(0x40FF8F3A), blurRadius: 14.r)];
    }
    var label = p.name;
    var labelColor = t.text;
    if (thinking) {
      label = Strings.thinkingShort;
      labelColor = Rc.accent;
    }
    var opacity = 1.0;
    TextDecoration? decoration;
    if (!p.active) {
      opacity = 0.55;
      decoration = TextDecoration.lineThrough;
    }
    return Semantics(
      label: p.name,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: EdgeInsets.symmetric(horizontal: 4.r, vertical: 4.r),
        decoration: ShapeDecoration(
          color: fill,
          shape: ChalkBorder(color: borderColor, width: borderWidth),
          shadows: shadows,
        ),
        child: Opacity(
          opacity: opacity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(2.r),
                decoration: ShapeDecoration(
                  shape: ChalkBorder(
                    radius: 10.r,
                    color: playerColors[playerId],
                    width: 2.r,
                  ),
                ),
                child: PlayerAvatar(
                  playerId: playerId,
                  size: 22.r,
                  ai: p.isAi,
                  dimmed: !p.active,
                ),
              ),
              SizedBox(height: 2.r),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w800,
                  color: labelColor,
                  decoration: decoration,
                ),
              ),
              _score(p.score, t.text),
            ],
          ),
        ),
      ),
    );
  }

  Widget _score(int fallback, Color color) => ValueListenableBuilder<List<int>>(
    valueListenable: scores,
    builder: (context, v, _) {
      var score = fallback;
      if (playerId < v.length) score = v[playerId];
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
        child: Text(
          '$score',
          key: ValueKey(score),
          style: TextStyle(
            fontSize: 17.sp,
            height: 1.1,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      );
    },
  );
}
