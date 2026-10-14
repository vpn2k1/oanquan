import 'package:flutter/material.dart';

import '../../../app/app.dart';
import '../../../app/theme.dart';
import '../../../app/widgets.dart';
import '../../../core/game_models/game_state.dart';
import '../flame/pieces_painter.dart';

/// Biểu tượng viên sỏi dân (vẽ bằng code, cùng kiểu với quân trên bàn).
class StoneIcon extends StatelessWidget {
  const StoneIcon({super.key, this.size = 16, this.color = const Color(0xFFEFE3C8)});
  final double size;
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
    final r = size.width * 0.3;
    final c = size.center(Offset.zero);
    PiecesPainter.stone(canvas, c + Offset(-r * 0.6, r * 0.35), r, color);
    PiecesPainter.stone(canvas, c + Offset(r * 0.65, r * 0.4), r, color, tint: 0.08);
    PiecesPainter.stone(canvas, c + Offset(0, -r * 0.55), r, color, tint: 0.15);
  }

  @override
  bool shouldRepaint(_StonePainter old) => old.color != color;
}

/// Biểu tượng quan (ngọc trên đế sen).
class GemIcon extends StatelessWidget {
  const GemIcon({super.key, this.size = 20});
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: size,
        child: CustomPaint(painter: _GemPainter()),
      );
}

class _GemPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) =>
      PiecesPainter.quanGem(canvas, size.center(Offset.zero), size.width * 0.4);

  @override
  bool shouldRepaint(_GemPainter old) => false;
}

/// Số lượng kèm biểu tượng (không dùng chữ "dân"/"quan").
class IconCount extends StatelessWidget {
  const IconCount({super.key, required this.icon, required this.value, required this.semantics});
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
              const SizedBox(width: 3),
              Text('$value', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
            ],
          ),
        ),
      );
}

/// Thẻ người chơi nổi trên bàn: avatar, tên, điểm lớn, sỏi/ngọc đã ăn.
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
    final l = context.l10n;
    final p = state.players[playerId];
    final isTurn = !state.isOver && state.turnPlayer == playerId;
    final color = playerColors[playerId];
    final dark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: width,
      padding: const EdgeInsets.fromLTRB(8, 6, 10, 6),
      decoration: BoxDecoration(
        color: (dark ? const Color(0xFF12403C) : Colors.white).withValues(alpha: isTurn ? 0.97 : 0.82),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isTurn ? color : color.withValues(alpha: 0.25), width: isTurn ? 3 : 1.5),
        boxShadow: [
          BoxShadow(
            color: isTurn ? color.withValues(alpha: 0.45) : const Color(0x22000000),
            blurRadius: isTurn ? 16 : 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Opacity(
        opacity: p.active ? 1 : 0.55,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                PlayerAvatar(playerId: playerId, size: 28, ai: p.isAi, dimmed: !p.active),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    p.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      decoration: p.active ? null : TextDecoration.lineThrough,
                    ),
                  ),
                ),
                if (thinking)
                  SizedBox.square(
                    dimension: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: color),
                  ),
                if (!p.active) Icon(Icons.block_rounded, size: 16, color: Colors.red.shade400),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ValueListenableBuilder<List<int>>(
                  valueListenable: scores,
                  builder: (context, v, _) {
                    final score = playerId < v.length ? v[playerId] : p.score;
                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                      child: Text(
                        '$score',
                        key: ValueKey(score),
                        style: TextStyle(
                          fontSize: 28,
                          height: 1.1,
                          fontWeight: FontWeight.w900,
                          color: color,
                        ),
                      ),
                    );
                  },
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    IconCount(
                      icon: StoneIcon(size: 16, color: color),
                      value: p.danCaptured,
                      semantics: l.danShort,
                    ),
                    IconCount(
                      icon: const GemIcon(size: 18),
                      value: p.quanCaptured,
                      semantics: l.quanShort,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Nút tròn nổi trên bàn.
class HudButton extends StatelessWidget {
  const HudButton({super.key, required this.icon, required this.tooltip, this.onPressed, this.size = 44});
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final enabled = onPressed != null;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: (dark ? const Color(0xFF12403C) : Colors.white).withValues(alpha: enabled ? 0.92 : 0.5),
        shape: const CircleBorder(),
        elevation: enabled ? 3 : 0,
        shadowColor: const Color(0x55000000),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox.square(
            dimension: size,
            child: Icon(
              icon,
              size: size * 0.5,
              color: enabled ? AppColors.teal : Theme.of(context).disabledColor,
            ),
          ),
        ),
      ),
    );
  }
}
