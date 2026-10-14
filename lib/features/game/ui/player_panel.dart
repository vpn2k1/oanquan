import 'package:flutter/material.dart';

import '../../../app/app.dart';
import '../../../app/theme.dart';
import '../../../app/widgets.dart';
import '../../../core/game_models/game_state.dart';

/// Bảng điểm: avatar, tên, điểm (cập nhật theo animation), thành phần điểm.
class PlayerPanel extends StatelessWidget {
  const PlayerPanel({
    super.key,
    required this.state,
    required this.scores,
    required this.colorBlind,
    this.vertical = false,
  });

  final GameState state;
  final ValueNotifier<List<int>> scores;
  final bool colorBlind;
  final bool vertical;

  @override
  Widget build(BuildContext context) {
    List<Widget> chips(bool compact) => [
          for (final p in state.players)
            _PlayerChip(
              key: Key('player${p.id}'),
              state: state,
              playerId: p.id,
              scores: scores,
              compact: compact,
            ),
        ];
    if (vertical) {
      return ListView(padding: const EdgeInsets.all(8), children: chips(false));
    }
    return LayoutBuilder(builder: (context, c) {
      final n = state.players.length;
      // Màn hẹp: lưới 2 cột để tên không bị cắt.
      final perRow = (n > 2 && c.maxWidth < 560) ? 2 : n;
      final w = (c.maxWidth - 12) / perRow;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Wrap(
          children: [
            for (final chip in chips(w < 170))
              SizedBox(width: w, child: chip),
          ],
        ),
      );
    });
  }
}

class _PlayerChip extends StatelessWidget {
  const _PlayerChip({
    super.key,
    required this.state,
    required this.playerId,
    required this.scores,
    required this.compact,
  });

  final GameState state;
  final int playerId;
  final ValueNotifier<List<int>> scores;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = state.players[playerId];
    final isTurn = !state.isOver && state.turnPlayer == playerId;
    final color = playerColors[playerId];
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.all(3),
      padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 10, vertical: 6),
      decoration: BoxDecoration(
        color: isTurn ? color.withValues(alpha: 0.18) : theme.cardTheme.color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isTurn ? color : Colors.transparent, width: 2),
      ),
      child: Row(
        children: [
          PlayerAvatar(playerId: playerId, size: compact ? 26 : 32, ai: p.isAi, dimmed: !p.active),
          SizedBox(width: compact ? 4 : 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: compact ? 12 : 14,
                    decoration: p.active ? null : TextDecoration.lineThrough,
                  ),
                ),
                if (!compact || !p.active)
                  Text(
                    p.active ? '${p.danCaptured} ${l.danShort} · ${p.quanCaptured} ${l.quanShort}' : l.eliminated,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                  ),
              ],
            ),
          ),
          ValueListenableBuilder<List<int>>(
            valueListenable: scores,
            builder: (context, v, _) => AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
              child: Text(
                '${playerId < v.length ? v[playerId] : p.score}',
                key: ValueKey(playerId < v.length ? v[playerId] : p.score),
                style: TextStyle(
                  fontSize: compact ? 18 : 22,
                  fontWeight: FontWeight.w900,
                  color: Color.lerp(color, theme.colorScheme.onSurface, 0.25),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
