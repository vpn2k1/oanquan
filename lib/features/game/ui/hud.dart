import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../app/folk_art.dart';
import '../../../app/theme.dart';
import '../../../app/widgets.dart';
import '../../../core/game_models/game_state.dart';
import '../flame/pieces_painter.dart';
import '../../../l10n/strings.dart';

/// Biểu tượng viên sỏi dân (vẽ bằng code, cùng kiểu với quân trên bàn).
class StoneIcon extends StatelessWidget {
  const StoneIcon({
    super.key,
    double? size,
    this.color = const Color(0xFFEFE3C8),
    // ignore: prefer_initializing_formals — tham số có tên không thể là private.
  }) : _size = size;
  final double? _size;

  /// Mặc định co giãn theo màn hình (.r) — không đặt được làm hằng số mặc định.
  double get size => _size ?? 16.r;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(painter: _StonePainter(color)),
  );
}

class _StonePainter extends CustomPainter {
  _StonePainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width * 0.27;
    final c = size.center(Offset.zero);
    PiecesPainter.pebble(canvas, c + Offset(-r * 0.6, r * 0.35), r, variant: 1);
    PiecesPainter.pebble(canvas, c + Offset(r * 0.65, r * 0.4), r, variant: 2);
    PiecesPainter.pebble(canvas, c + Offset(0, -r * 0.55), r, variant: 3);
  }

  @override
  bool shouldRepaint(_StonePainter old) => false;
}

/// Biểu tượng quan: hòn đá nâu lớn.
class GemIcon extends StatelessWidget {
  // ignore: prefer_initializing_formals — tham số có tên không thể là private.
  const GemIcon({super.key, double? size}) : _size = size;
  final double? _size;

  /// Mặc định co giãn theo màn hình (.r) — không đặt được làm hằng số mặc định.
  double get size => _size ?? 20.r;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(painter: _GemPainter()),
  );
}

class _GemPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) => PiecesPainter.quanStone(
    canvas,
    size.center(Offset.zero),
    size.width * 0.36,
  );

  @override
  bool shouldRepaint(_GemPainter old) => false;
}

/// Số lượng kèm biểu tượng (không dùng chữ "dân"/"quan").
class IconCount extends StatelessWidget {
  const IconCount({
    super.key,
    required this.icon,
    required this.value,
    required this.semantics,
  });
  final Widget icon;
  final int value;
  final String semantics;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$value $semantics',
    excludeSemantics: true,
    child: Tooltip(
      message: semantics,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          SizedBox(width: 3.r),
          Text(
            '$value',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.sp),
          ),
        ],
      ),
    ),
  );
}

/// Thẻ người chơi kiểu Recess: nền nâu, viền kem mờ; tới lượt thì viền cam.
class PlayerChip extends StatelessWidget {
  const PlayerChip({
    super.key,
    required this.state,
    required this.playerId,
    required this.scores,
    this.thinking = false,
    this.width = 150,
  });

  final GameState state;
  final int playerId;
  final ValueNotifier<List<int>> scores;
  final bool thinking;
  final double width;

  @override
  Widget build(BuildContext context) {
    final t = RcTokens.of(context);
    final p = state.players[playerId];
    final isTurn = !state.isOver && state.turnPlayer == playerId;
    final color = playerColors[playerId];
    final status = _status(p.active, thinking, isTurn);
    var fill = t.surface;
    var borderColor = t.text.withValues(alpha: 0.55);
    var borderWidth = 2.0;
    var shadows = const <BoxShadow>[];
    var statusColor = t.muted;
    if (isTurn) {
      fill = Color.alphaBlend(Rc.accentSoft, t.surface);
      borderColor = Rc.accent;
      borderWidth = 2.8;
      shadows = [BoxShadow(color: Color(0x40FF8F3A), blurRadius: 14.r)];
      statusColor = Rc.accent;
    }
    var opacity = 0.55;
    TextDecoration? nameDecoration = TextDecoration.lineThrough;
    if (p.active) {
      opacity = 1;
      nameDecoration = null;
    }
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: width,
      padding: EdgeInsets.fromLTRB(8.r, 7.r, 12.r, 7.r),
      decoration: ShapeDecoration(
        color: fill,
        // Viền phấn: cam đậm khi tới lượt, kem mờ khi chờ.
        shape: ChalkBorder(color: borderColor, width: borderWidth),
        shadows: shadows,
      ),
      child: Opacity(
        opacity: opacity,
        child: Row(
          children: [
            // Ô vuông avatar có viền màu người chơi (đánh dấu cạnh trên bàn).
            Container(
              padding: EdgeInsets.all(2.r),
              decoration: ShapeDecoration(
                shape: ChalkBorder(radius: 11.r, color: color, width: 2.r),
              ),
              child: PlayerAvatar(
                playerId: playerId,
                size: 30.r,
                ai: p.isAi,
                dimmed: !p.active,
              ),
            ),
            SizedBox(width: 8.r),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    p.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14.sp,
                      color: t.text,
                      decoration: nameDecoration,
                    ),
                  ),
                  if (status != null)
                    Text(
                      status,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8.r,
                      children: [
                        IconCount(
                          icon: StoneIcon(size: 14.r),
                          value: p.danCaptured + p.danCollected,
                          semantics: Strings.danShort,
                        ),
                        IconCount(
                          icon: GemIcon(size: 15.r),
                          value: p.quanCaptured,
                          semantics: Strings.quanShort,
                        ),
                      ],
                    ),
                ],
              ),
            ),
            ValueListenableBuilder<List<int>>(
              valueListenable: scores,
              builder: (context, v, _) {
                var score = p.score;
                if (playerId < v.length) score = v[playerId];
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (c, a) =>
                      ScaleTransition(scale: a, child: c),
                  child: Text(
                    '$score',
                    key: ValueKey(score),
                    style: TextStyle(
                      fontSize: 24.sp,
                      height: 1.1,
                      fontWeight: FontWeight.w900,
                      color: t.text,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Nút vuông bo góc kiểu Recess.
class HudButton extends StatelessWidget {
  const HudButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onPressed,
    double? size,
    this.label,
    // ignore: prefer_initializing_formals — tham số có tên không thể là private.
  }) : _size = size;
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final double? _size;

  /// Mặc định co giãn theo màn hình (.r) — không đặt được làm hằng số mặc định.
  double get size => _size ?? 44.r;

  /// Có nhãn → nút dạng viên thuốc (icon + chữ).
  final String? label;

  @override
  Widget build(BuildContext context) {
    final t = RcTokens.of(context);
    final enabled = onPressed != null;
    var fg = t.muted.withValues(alpha: 0.45);
    var borderAlpha = 0.35;
    if (enabled) {
      fg = t.text;
      borderAlpha = 0.85;
    }
    double? boxWidth = size;
    var hPad = 0.0;
    if (label != null) {
      boxWidth = null;
      hPad = 12;
    }
    return Tooltip(
      message: tooltip,
      child: Material(
        color: t.surface,
        shape: ChalkBorder(color: t.text.withValues(alpha: borderAlpha)),
        child: InkWell(
          borderRadius: BorderRadius.circular(16.r),
          onTap: onPressed,
          child: SizedBox(
            height: size,
            width: boxWidth,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FolkIcon(icon, size: size * 0.46, color: fg),
                  if (label != null) ...[
                    SizedBox(width: 6.r),
                    Text(
                      label!,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14.sp,
                        color: fg,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String? _status(bool active, bool thinking, bool isTurn) {
  if (!active) return Strings.eliminatedShort;
  if (thinking) return Strings.thinkingShort;
  if (isTurn) return Strings.yourTurn;
  return null;
}
