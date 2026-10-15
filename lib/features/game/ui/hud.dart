import 'package:flutter/material.dart';

import '../../../app/app.dart';
import '../../../app/theme.dart';
import '../../../app/widgets.dart';
import '../../../core/game_models/game_state.dart';
import '../flame/pieces_painter.dart';

/// Biểu tượng viên sỏi dân (vẽ bằng code, cùng kiểu với quân trên bàn).
class StoneIcon extends StatelessWidget {
  const StoneIcon({
    super.key,
    this.size = 16,
    this.color = const Color(0xFFEFE3C8),
  });
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
          const SizedBox(width: 3),
          Text(
            '$value',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
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
    final l = context.l10n;
    final t = RcTokens.of(context);
    final p = state.players[playerId];
    final isTurn = !state.isOver && state.turnPlayer == playerId;
    final color = playerColors[playerId];
    final String? status = !p.active
        ? l.eliminatedShort
        : thinking
            ? l.thinkingShort
            : isTurn
                ? l.yourTurn
                : null;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: width,
      padding: const EdgeInsets.fromLTRB(8, 7, 12, 7),
      decoration: BoxDecoration(
        color: isTurn ? Color.alphaBlend(Rc.accentSoft, t.surface) : t.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isTurn ? Rc.accent : t.line, width: 2),
        boxShadow: isTurn
            ? const [BoxShadow(color: Color(0x40FF8F3A), blurRadius: 14)]
            : const [],
      ),
      child: Opacity(
        opacity: p.active ? 1 : 0.55,
        child: Row(
          children: [
            // Ô vuông avatar có viền màu người chơi (đánh dấu cạnh trên bàn).
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: color, width: 2),
              ),
              child: PlayerAvatar(playerId: playerId, size: 30, ai: p.isAi, dimmed: !p.active),
            ),
            const SizedBox(width: 8),
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
                      fontSize: 14,
                      color: t.text,
                      decoration: p.active ? null : TextDecoration.lineThrough,
                    ),
                  ),
                  if (status != null)
                    Text(
                      status,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isTurn ? Rc.accent : t.muted,
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      children: [
                        IconCount(
                          icon: const StoneIcon(size: 14),
                          value: p.danCaptured + p.danCollected,
                          semantics: l.danShort,
                        ),
                        IconCount(
                          icon: const GemIcon(size: 15),
                          value: p.quanCaptured,
                          semantics: l.quanShort,
                        ),
                      ],
                    ),
                ],
              ),
            ),
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
                    style: TextStyle(fontSize: 24, height: 1.1, fontWeight: FontWeight.w900, color: t.text),
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
    this.size = 44,
    this.label,
  });
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final double size;

  /// Có nhãn → nút dạng viên thuốc (icon + chữ).
  final String? label;

  @override
  Widget build(BuildContext context) {
    final t = RcTokens.of(context);
    final enabled = onPressed != null;
    final fg = enabled ? t.text : t.muted.withValues(alpha: 0.45);
    return Tooltip(
      message: tooltip,
      child: Material(
        color: t.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: t.line, width: 2),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onPressed,
          child: SizedBox(
            height: size,
            width: label == null ? size : null,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: label == null ? 0 : 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FolkIcon(icon, size: size * 0.46, color: fg),
                  if (label != null) ...[
                    const SizedBox(width: 6),
                    Text(label!, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: fg)),
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
