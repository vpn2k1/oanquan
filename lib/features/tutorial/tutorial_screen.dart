import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/layout/fit_to_screen.dart';
import '../../app/layout/screen_layout.dart';
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
    final layout = ScreenLayout.of(context);
    VoidCallback? prevPressed;
    if (_index != 0) {
      prevPressed = () => _page.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(Strings.tutorialTitle),
        toolbarHeight: toolbarHeightFor(layout),
      ),
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
                        return _TutorialPage(
                          layout: layout,
                          header: texts.take(2).toList(),
                          illustration: illustration,
                          body: texts.skip(2).toList(),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: _navPadding(layout),
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

EdgeInsets _navPadding(ScreenLayout layout) {
  if (layout == ScreenLayout.compactLandscape) {
    return EdgeInsets.fromLTRB(16.r, 0, 16.r, 8.r);
  }
  return EdgeInsets.all(16.r);
}

/// Một trang hướng dẫn. Điện thoại ngang: chữ bên trái, hình bên phải; dọc:
/// một cột — cả hai vừa khung, không cuộn. Màn rộng: một cột, cuộn khi cần.
class _TutorialPage extends StatelessWidget {
  const _TutorialPage({
    required this.layout,
    required this.header,
    required this.illustration,
    required this.body,
  });
  final ScreenLayout layout;
  final List<Widget> header;
  final Widget illustration;
  final List<Widget> body;

  @override
  Widget build(BuildContext context) {
    final column = [...header, SizedBox(height: 16.r), illustration, ...body];
    if (layout == ScreenLayout.wide) {
      return ListView(padding: EdgeInsets.all(20.r), children: column);
    }
    Widget content = _column(column);
    if (layout == ScreenLayout.compactLandscape) {
      content = Row(
        children: [
          Expanded(flex: 5, child: _column([...header, ...body])),
          SizedBox(width: 20.r),
          Expanded(flex: 4, child: illustration),
        ],
      );
    }
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.r, vertical: 12.r),
      child: FitToScreen(child: content),
    );
  }

  Widget _column(List<Widget> children) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: children,
  );
}
