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
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: ListView(
                padding: const EdgeInsets.all(20),
                shrinkWrap: true,
                children: [
                  const Center(child: LogoMark(size: 96)),
                  const SizedBox(height: 12),
                  Text(l.gameOver, textAlign: TextAlign.center, style: theme.textTheme.titleMedium),
                  Text(title,
                      key: const Key('resultTitle'),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text(reason, textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
                  const SizedBox(height: 16),
                  for (final st in standings)
                    Card(
                      child: ListTile(
                        leading: PlayerAvatar(playerId: st.player.id, ai: st.player.isAi, dimmed: !st.player.active),
                        title: Text(st.player.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text(
                            '${l.rank(st.rank)} · ${st.player.danCaptured} ${l.danShort} · ${st.player.quanCaptured} ${l.quanShort}'
                            '${st.player.refillSpent > 0 ? ' · −${st.player.refillSpent}' : ''}'
                            '${st.player.active ? '' : ' · ${l.eliminated}'}'),
                        trailing: Text('${st.player.score}',
                            style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: playerColors[st.player.id])),
                      ),
                    ),
                  const SizedBox(height: 16),
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
