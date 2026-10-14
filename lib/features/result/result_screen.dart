import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app.dart';
import '../../app/router.dart';
import '../../app/theme.dart';
import '../../app/widgets.dart';
import '../../core/engine/scoring.dart';
import '../../core/game_models/game_state.dart';
import '../game/game_session.dart';
import '../game/ui/hud.dart';

class ResultScreen extends ConsumerWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final s = ref.watch(gameSessionProvider)?.current;
    if (s == null || !s.isOver) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go(Routes.home);
      });
      return const Scaffold();
    }
    final theme = Theme.of(context);
    final standings = Scoring.standings(s.players);
    final title = s.winnerIds.length > 1
        ? l.draw
        : l.winner(s.players[s.winnerIds.first].name);
    final reason = switch (s.endReason) {
      EndReason.allQuanCaptured => l.endAllQuan,
      EndReason.lastPlayerStanding => l.endLastStanding,
      EndReason.moveLimit => l.endMoveLimit,
      null => '',
    };
    final header = <Widget>[
      const Center(child: LogoMark(size: 96)),
      const SizedBox(height: 12),
      Text(
        l.gameOver,
        textAlign: TextAlign.center,
        style: theme.textTheme.titleMedium,
      ),
      Text(
        title,
        key: const Key('resultTitle'),
        textAlign: TextAlign.center,
        style: theme.textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w900,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        reason,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodySmall,
      ),
    ];
    final standingsList = <Widget>[
      for (final st in standings)
        Card(
          child: ListTile(
            leading: PlayerAvatar(
              playerId: st.player.id,
              ai: st.player.isAi,
              dimmed: !st.player.active,
            ),
            title: Text(
              st.player.name,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Wrap(
              spacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(l.rank(st.rank)),
                IconCount(
                  icon: StoneIcon(size: 16, color: playerColors[st.player.id]),
                  value: st.player.danCaptured,
                  semantics: l.danShort,
                ),
                IconCount(
                  icon: const GemIcon(size: 18),
                  value: st.player.quanCaptured,
                  semantics: l.quanShort,
                ),
                if (st.player.refillSpent > 0) Text('−${st.player.refillSpent}'),
                if (!st.player.active)
                  Icon(Icons.block_rounded, size: 16, color: Colors.red.shade400),
              ],
            ),
            trailing: Text(
              '${st.player.score}',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: playerColors[st.player.id],
              ),
            ),
          ),
        ),
    ];
    final buttons = <Widget>[
      FilledButton.icon(
        key: const Key('playAgain'),
        icon: const Icon(Icons.replay_rounded),
        label: Text(l.playAgain),
        onPressed: () {
          ref.read(gameSessionProvider.notifier).restart();
          context.pushReplacement(Routes.game);
        },
      ),
      const SizedBox(height: 10),
      OutlinedButton.icon(
        icon: const Icon(Icons.home_rounded),
        label: Text(l.home),
        onPressed: () {
          ref.read(gameSessionProvider.notifier).abandon();
          context.go(Routes.home);
        },
      ),
    ];
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, c) {
              if (c.maxWidth > c.maxHeight && c.maxWidth > 560) {
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1000),
                    child: Row(
                      children: [
                        Expanded(
                          child: ListView(
                            padding: const EdgeInsets.all(16),
                            children: [
                              ...header,
                              const SizedBox(height: 16),
                              ...buttons,
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView(
                            padding: const EdgeInsets.all(16),
                            children: standingsList,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    shrinkWrap: true,
                    children: [
                      ...header,
                      const SizedBox(height: 16),
                      ...standingsList,
                      const SizedBox(height: 16),
                      ...buttons,
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
