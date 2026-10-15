import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/widgets.dart';
import '../../core/game_models/game_config.dart';
import '../../core/game_models/player.dart';
import '../game/game_session.dart';
import '../../l10n/strings.dart';
import 'widgets/tutorial_row_painter.dart';
import 'widgets/tutorial_step.dart';

class TutorialScreen extends ConsumerStatefulWidget {
  const TutorialScreen({super.key});

  @override
  ConsumerState<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends ConsumerState<TutorialScreen> {
  final _page = PageController();
  int _index = 0;

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  void _tryIt() {
    ref.read(gameSessionProvider.notifier).start(
      GameConfig(
        playerCount: 2,
        seed: DateTime.now().millisecondsSinceEpoch & 0x7fffffff,
      ),
      [
        Player(id: 0, name: Strings.defaultPlayerName(1)),
        Player(
          id: 1,
          name: Strings.aiPlayerName(1),
          type: PlayerType.ai,
          aiLevel: AiLevel.easy,
        ),
      ],
    );
    context.pushReplacement(Routes.game);
  }

  @override
  Widget build(BuildContext context) {
    final steps = tutorialSteps();
    final theme = Theme.of(context);
    VoidCallback? prevPressed;
    if (_index != 0) {
      prevPressed = () => _page.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(Strings.tutorialTitle)),
      body: AppBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 640.r),
              child: Column(
                children: [
                  Expanded(
                    child: PageView.builder(
                      controller: _page,
                      itemCount: steps.length,
                      onPageChanged: (i) => setState(() => _index = i),
                      itemBuilder: (context, i) {
                        final st = steps[i];
                        final illustration = AspectRatio(
                          aspectRatio: 3.2,
                          child: CustomPaint(
                            painter: TutorialRowPainter(
                              st.cells,
                              st.arrows,
                              st.note,
                            ),
                          ),
                        );
                        final texts = <Widget>[
                          Text(
                            '${i + 1}/${steps.length}',
                            style: theme.textTheme.labelLarge,
                          ),
                          Text(
                            st.title,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 12.r),
                          Text(st.body, style: theme.textTheme.bodyLarge),
                          if (i == steps.length - 1) ...[
                            SizedBox(height: 16.r),
                            Text(
                              Strings.tutKeyboard,
                              style: theme.textTheme.bodySmall,
                            ),
                            SizedBox(height: 8.r),
                            Text(
                              Strings.rulesetNote,
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ];
                        // Ngang hay dọc đều xếp một cột: tiêu đề, hình, lời giải.
                        return ListView(
                          padding: EdgeInsets.all(20.r),
                          children: [
                            ...texts.take(2),
                            SizedBox(height: 16.r),
                            illustration,
                            ...texts.skip(2),
                          ],
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(16.r),
                    child: Row(
                      children: [
                        TextButton(
                          onPressed: prevPressed,
                          child: Text(Strings.previous),
                        ),
                        const Spacer(),
                        for (var i = 0; i < steps.length; i++)
                          Container(
                            width: 8.r,
                            height: 8.r,
                            margin: EdgeInsets.symmetric(horizontal: 3.r),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _dotColor(theme, i == _index),
                            ),
                          ),
                        const Spacer(),
                        if (_index == steps.length - 1)
                          FilledButton(
                            onPressed: _tryIt,
                            child: Text(Strings.tutTryIt),
                          )
                        else
                          FilledButton(
                            onPressed: () => _page.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                            ),
                            child: Text(Strings.next),
                          ),
                      ],
                    ),
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

Color _dotColor(ThemeData theme, bool current) {
  if (current) return theme.colorScheme.primary;
  return theme.disabledColor;
}
