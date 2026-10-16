import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/layout/fit_to_screen.dart';
import '../../app/layout/screen_layout.dart';
import '../../app/widgets.dart';
import 'stats_repository.dart';
import 'widgets/achievement_tile.dart';
import 'widgets/stat_card.dart';
import '../../l10n/strings.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(statsProvider);
    final theme = Theme.of(context);
    final layout = ScreenLayout.of(context);
    final compact = layout.isCompact;
    final landscape = layout == ScreenLayout.compactLandscape;
    final stats = [
      (Strings.statsPlayed, s.played),
      (Strings.statsWinsVsAi, s.winsVsAi),
      (Strings.statsBestScore, s.bestScore),
      (Strings.statsQuanTotal, s.quanTotal),
    ];
    final tiles = <Widget>[
      for (final a in Achievement.values)
        AchievementTile(
          achievement: a,
          unlocked: s.unlocked(a),
          dense: compact,
        ),
    ];
    // Điện thoại ngang: 4 số liệu một hàng, thành tích lưới 3 cột. Dọc / màn
    // rộng: số liệu 2×2, thành tích một cột.
    var perRow = 2;
    var tilesPerRow = 1;
    if (landscape) {
      perRow = 4;
      tilesPerRow = 3;
    }
    final children = <Widget>[
      Text(Strings.statsTitle, style: theme.textTheme.titleMedium),
      ..._rows([
        for (final (label, v) in stats)
          StatCard(label: label, value: v, dense: compact),
      ], perRow),
      SizedBox(height: 12.r),
      ..._rows(tiles, tilesPerRow),
    ];
    final pad = EdgeInsets.all(16.r);
    // Điện thoại: vừa một màn hình. Màn rộng (web): cuộn khi cần.
    Widget body = ListView(padding: pad, shrinkWrap: true, children: children);
    var maxWidth = 560.r;
    if (compact) {
      body = Padding(
        padding: pad,
        child: FitToScreen(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      );
    }
    if (landscape) maxWidth = 1000.r;
    return Scaffold(
      appBar: AppBar(
        title: Text(Strings.achievements),
        toolbarHeight: toolbarHeightFor(layout),
      ),
      body: AppBackground(
        child: SafeArea(
          top: false,
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: body,
            ),
          ),
        ),
      ),
    );
  }
}

/// Chia [items] thành các hàng [n] ô bằng nhau.
List<Widget> _rows(List<Widget> items, int n) => [
  for (var i = 0; i < items.length; i += n)
    Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [for (final w in items.skip(i).take(n)) Expanded(child: w)],
    ),
];
