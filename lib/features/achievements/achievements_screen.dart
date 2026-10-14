import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app.dart';
import '../../app/widgets.dart';
import '../../l10n/app_localizations.dart';
import 'stats_repository.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  static (String, String, IconData) _info(AppLocalizations l, Achievement a) => switch (a) {
        Achievement.firstGame => (l.achFirstGame, l.achFirstGameDesc, Icons.flag_rounded),
        Achievement.beatAi => (l.achBeatAi, l.achBeatAiDesc, Icons.smart_toy_rounded),
        Achievement.beatHard => (l.achBeatHard, l.achBeatHardDesc, Icons.workspace_premium_rounded),
        Achievement.quanHunter => (l.achQuanHunter, l.achQuanHunterDesc, Icons.diamond_rounded),
        Achievement.highScore => (l.achHighScore, l.achHighScoreDesc, Icons.savings_rounded),
        Achievement.allBoards => (l.achAllBoards, l.achAllBoardsDesc, Icons.category_rounded),
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final s = ref.watch(statsProvider);
    final theme = Theme.of(context);
    Widget stat(String label, int v) => Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
              child: Column(children: [
                Text('$v', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                Text(label, textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
              ]),
            ),
          ),
        );
    return Scaffold(
      appBar: AppBar(title: Text(l.achievements)),
      body: AppBackground(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(l.statsTitle, style: theme.textTheme.titleMedium),
                Row(children: [stat(l.statsPlayed, s.played), stat(l.statsWinsVsAi, s.winsVsAi)]),
                Row(children: [stat(l.statsBestScore, s.bestScore), stat(l.statsQuanTotal, s.quanTotal)]),
                const SizedBox(height: 12),
                for (final a in Achievement.values)
                  Builder(builder: (context) {
                    final (title, desc, icon) = _info(l, a);
                    final ok = s.unlocked(a);
                    return Card(
                      child: ListTile(
                        leading: Icon(icon, color: ok ? theme.colorScheme.secondary : theme.disabledColor, size: 32),
                        title: Text(title, style: TextStyle(fontWeight: FontWeight.w700, color: ok ? null : theme.disabledColor)),
                        subtitle: Text(desc),
                        trailing: Icon(ok ? Icons.check_circle_rounded : Icons.lock_rounded,
                            color: ok ? Colors.green : theme.disabledColor),
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
