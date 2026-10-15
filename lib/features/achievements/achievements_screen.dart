import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/widgets.dart';
import 'stats_repository.dart';
import '../../l10n/strings.dart';

Color _iconColor(ThemeData theme, bool ok) {
  if (ok) return theme.colorScheme.secondary;
  return theme.disabledColor;
}

Color? _titleColor(ThemeData theme, bool ok) {
  if (ok) return null;
  return theme.disabledColor;
}

IconData _statusIcon(bool ok) {
  if (ok) return Icons.check_circle_rounded;
  return Icons.lock_rounded;
}

Color _statusColor(ThemeData theme, bool ok) {
  if (ok) return Colors.green;
  return theme.disabledColor;
}

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  static IconData _icon(Achievement a) => switch (a) {
    Achievement.firstGame => Icons.flag_rounded,
    Achievement.beatAi => Icons.smart_toy_rounded,
    Achievement.beatHard => Icons.workspace_premium_rounded,
    Achievement.quanHunter => Icons.diamond_rounded,
    Achievement.highScore => Icons.savings_rounded,
    Achievement.allBoards => Icons.category_rounded,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(statsProvider);
    final theme = Theme.of(context);
    Widget stat(String label, int v) => Expanded(
      child: Card(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 14.r, horizontal: 8.r),
          child: Column(
            children: [
              Text(
                '$v',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                label,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
    return Scaffold(
      appBar: AppBar(title: Text(Strings.achievements)),
      body: AppBackground(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 560.r),
            child: ListView(
              padding: EdgeInsets.all(16.r),
              children: [
                Text(Strings.statsTitle, style: theme.textTheme.titleMedium),
                Row(
                  children: [
                    stat(Strings.statsPlayed, s.played),
                    stat(Strings.statsWinsVsAi, s.winsVsAi),
                  ],
                ),
                Row(
                  children: [
                    stat(Strings.statsBestScore, s.bestScore),
                    stat(Strings.statsQuanTotal, s.quanTotal),
                  ],
                ),
                SizedBox(height: 12.r),
                for (final a in Achievement.values)
                  Builder(
                    builder: (context) {
                      final title = Strings.achievement(a);
                      final desc = Strings.achievementDesc(a);
                      final icon = _icon(a);
                      final ok = s.unlocked(a);
                      return Card(
                        child: ListTile(
                          leading: FolkIcon(
                            icon,
                            color: _iconColor(theme, ok),
                            size: 32.r,
                          ),
                          title: Text(
                            title,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: _titleColor(theme, ok),
                            ),
                          ),
                          subtitle: Text(desc),
                          trailing: FolkIcon(
                            _statusIcon(ok),
                            color: _statusColor(theme, ok),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
