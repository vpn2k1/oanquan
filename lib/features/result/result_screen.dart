import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../app/widgets.dart';
import '../../core/engine/scoring.dart';
import '../../core/game_models/game_state.dart';
import '../game/game_session.dart';
import '../game/ui/hud.dart';
import '../../l10n/strings.dart';

class ResultScreen extends ConsumerWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(gameSessionProvider)?.current;
    if (s == null || !s.isOver) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go(Routes.home);
      });
      return const Scaffold();
    }
    final theme = Theme.of(context);
    final standings = Scoring.standings(s.players);
    var title = Strings.winner(s.players[s.winnerIds.first].name);
    if (s.winnerIds.length > 1) title = Strings.draw;
    final reason = switch (s.endReason) {
      EndReason.allQuanCaptured => Strings.endAllQuan,
      EndReason.lastPlayerStanding => Strings.endLastStanding,
      EndReason.moveLimit => Strings.endMoveLimit,
      null => '',
    };
    final header = <Widget>[
      Center(child: LogoMark(size: 96.r)),
      SizedBox(height: 12.r),
      Text(
        Strings.gameOver,
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
      SizedBox(height: 4.r),
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
              spacing: 10.r,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(Strings.rank(st.rank)),
                IconCount(
                  icon: StoneIcon(
                    size: 16.r,
                    color: playerColors[st.player.id],
                  ),
                  value: st.player.danCaptured,
                  semantics: Strings.danShort,
                ),
                IconCount(
                  icon: GemIcon(size: 18.r),
                  value: st.player.quanCaptured,
                  semantics: Strings.quanShort,
                ),
                if (st.player.refillSpent > 0)
                  Text('−${st.player.refillSpent}'),
                if (!st.player.active)
                  FolkIcon(
                    Icons.block_rounded,
                    size: 16.r,
                    color: Colors.red.shade400,
                  ),
              ],
            ),
            trailing: Text(
              '${st.player.score}',
              style: TextStyle(
                fontSize: 24.sp,
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
        icon: const FolkIcon(Icons.replay_rounded),
        label: Text(Strings.playAgain),
        onPressed: () {
          ref.read(gameSessionProvider.notifier).restart();
          context.pushReplacement(Routes.game);
        },
      ),
      SizedBox(height: 10.r),
      OutlinedButton.icon(
        icon: const FolkIcon(Icons.home_rounded),
        label: Text(Strings.home),
        onPressed: () {
          ref.read(gameSessionProvider.notifier).abandon();
          context.go(Routes.home);
        },
      ),
    ];
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          // Ngang hay dọc đều xếp một cột: tiêu đề, bảng xếp hạng, các nút.
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 480.r),
              child: ListView(
                padding: EdgeInsets.all(20.r),
                shrinkWrap: true,
                children: [
                  ...header,
                  SizedBox(height: 16.r),
                  ...standingsList,
                  SizedBox(height: 16.r),
                  ...buttons,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
