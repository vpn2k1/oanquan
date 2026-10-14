import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app.dart';
import '../../app/router.dart';
import '../../app/theme.dart';
import '../../app/widgets.dart';
import '../../core/game_models/game_config.dart';
import '../../core/game_models/player.dart';
import '../game/flame/pieces_painter.dart';
import '../game/game_session.dart';

/// Ô minh họa: số dân, ô quan, có token.
class _C {
  const _C(this.dan, {this.quan = false, this.token = false, this.mark});
  final int dan;
  final bool quan;
  final bool token;

  /// 'src' nguồn, 'gap' ô trống, 'eat' bị ăn, 'pick' bốc tiếp, 'stop' dừng.
  final String? mark;
}

class _Step {
  const _Step(
    this.title,
    this.body,
    this.cells, {
    this.arrows = false,
    this.note,
  });
  final String title;
  final String body;
  final List<_C> cells;
  final bool arrows;
  final String? note;
}

class TutorialScreen extends ConsumerStatefulWidget {
  const TutorialScreen({super.key});

  @override
  ConsumerState<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends ConsumerState<TutorialScreen> {
  final _page = PageController();
  int _index = 0;

  List<_Step> _steps(BuildContext context) {
    final l = context.l10n;
    return [
      _Step(l.tutStep1Title, l.tutStep1, const [
        _C(0, quan: true, token: true),
        _C(5),
        _C(5),
        _C(5),
        _C(5),
        _C(5),
        _C(0, quan: true, token: true),
      ]),
      _Step(l.tutStep2Title, l.tutStep2, const [
        _C(0, quan: true, token: true),
        _C(5),
        _C(5, mark: 'src'),
        _C(5),
        _C(5),
        _C(5),
        _C(0, quan: true, token: true),
      ], arrows: true),
      _Step(l.tutStep3Title, l.tutStep3, const [
        _C(0, quan: true, token: true),
        _C(0, mark: 'src'),
        _C(6),
        _C(6),
        _C(6),
        _C(6),
        _C(1, quan: true, token: true, mark: 'stop'),
      ]),
      _Step(l.tutStep4Title, l.tutStep4, const [
        _C(0, quan: true, token: true),
        _C(1, mark: 'src'),
        _C(0, mark: 'gap'),
        _C(3, mark: 'eat'),
        _C(0, mark: 'gap'),
        _C(2, mark: 'eat'),
        _C(4, quan: true, token: true),
      ]),
      _Step(l.tutStep5Title, l.tutStep5, const [
        _C(0, quan: true, token: true),
        _C(0),
        _C(0),
        _C(1, mark: 'src'),
        _C(0),
        _C(0, mark: 'gap'),
        _C(5, quan: true, token: true, mark: 'eat'),
      ], note: '+5 +10'),
      _Step(l.tutStep6Title, l.tutStep6, const [
        _C(2, quan: true, token: true),
        _C(1, mark: 'pick'),
        _C(1, mark: 'pick'),
        _C(1, mark: 'pick'),
        _C(1, mark: 'pick'),
        _C(1, mark: 'pick'),
        _C(0, quan: true),
      ], note: '−5'),
    ];
  }

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  void _tryIt() {
    final l = context.l10n;
    ref.read(gameSessionProvider.notifier).start(
      GameConfig(
        playerCount: 2,
        seed: DateTime.now().millisecondsSinceEpoch & 0x7fffffff,
      ),
      [
        Player(id: 0, name: l.defaultPlayerName(1)),
        Player(
          id: 1,
          name: l.aiPlayerName(1),
          type: PlayerType.ai,
          aiLevel: AiLevel.easy,
        ),
      ],
    );
    context.pushReplacement(Routes.game);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final steps = _steps(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.tutorialTitle)),
      body: AppBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
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
                            painter: _RowPainter(st.cells, st.arrows, st.note),
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
                          const SizedBox(height: 12),
                          Text(st.body, style: theme.textTheme.bodyLarge),
                          if (i == steps.length - 1) ...[
                            const SizedBox(height: 16),
                            Text(
                              l.tutKeyboard,
                              style: theme.textTheme.bodySmall,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l.rulesetNote,
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ];
                        return LayoutBuilder(
                          builder: (context, c) {
                            if (c.maxWidth > c.maxHeight && c.maxWidth > 560) {
                              // Màn hình ngang: hình bên trái, chữ bên phải.
                              return Row(
                                children: [
                                  Expanded(
                                    flex: 5,
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Center(child: illustration),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 4,
                                    child: ListView(
                                      padding: const EdgeInsets.all(16),
                                      children: texts,
                                    ),
                                  ),
                                ],
                              );
                            }
                            return ListView(
                              padding: const EdgeInsets.all(20),
                              children: [
                                ...texts.take(2),
                                const SizedBox(height: 16),
                                illustration,
                                ...texts.skip(2),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        TextButton(
                          onPressed: _index == 0
                              ? null
                              : () => _page.previousPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeOut,
                                ),
                          child: Text(l.previous),
                        ),
                        const Spacer(),
                        for (var i = 0; i < steps.length; i++)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: i == _index
                                  ? theme.colorScheme.primary
                                  : theme.disabledColor,
                            ),
                          ),
                        const Spacer(),
                        _index == steps.length - 1
                            ? FilledButton(
                                onPressed: _tryIt,
                                child: Text(l.tutTryIt),
                              )
                            : FilledButton(
                                onPressed: () => _page.nextPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeOut,
                                ),
                                child: Text(l.next),
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

class _RowPainter extends CustomPainter {
  _RowPainter(this.cells, this.arrows, this.note);
  final List<_C> cells;
  final bool arrows;
  final String? note;

  @override
  void paint(Canvas canvas, Size size) {
    final n = cells.length;
    final u = min(size.width / (n + 0.6), size.height / 1.9);
    final y = size.height / 2;
    final x0 = (size.width - u * n) / 2;
    final board = RRect.fromRectAndRadius(
      Rect.fromLTWH(x0 - u * 0.2, y - u * 0.7, u * n + u * 0.4, u * 1.4),
      Radius.circular(u * 0.7),
    );
    canvas.drawRRect(
      board.shift(Offset(0, u * 0.08)),
      Paint()..color = const Color(0x44000000),
    );
    canvas.drawRRect(board, Paint()..color = AppColors.wood);
    for (var i = 0; i < n; i++) {
      final c = cells[i];
      final center = Offset(x0 + u * (i + 0.5), y);
      final rect = c.quan
          ? Rect.fromCenter(center: center, width: u * 0.86, height: u * 1.2)
          : Rect.fromCenter(center: center, width: u * 0.8, height: u * 0.8);
      final shape = c.quan
          ? (Path()..addOval(rect))
          : (Path()..addRRect(
              RRect.fromRectAndRadius(rect, Radius.circular(u * 0.2)),
            ));
      canvas.drawPath(shape, Paint()..color = AppColors.well);
      final markColor = switch (c.mark) {
        'src' => Colors.white,
        'gap' => const Color(0xFF3FE0C5),
        'eat' => AppColors.gold,
        'pick' => const Color(0xFF7FD1C4),
        'stop' => const Color(0xFFE5604D),
        _ => null,
      };
      canvas.drawPath(
        shape,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = markColor == null ? 1.5 : 3
          ..color = markColor ?? (c.quan ? AppColors.gold : playerColors[0]),
      );
      final color = c.quan ? const Color(0xFFEFE3C8) : playerColors[0];
      if (c.quan && c.token) {
        for (var k = 0; k < c.dan; k++) {
          final a = -pi / 2 + k * 2 * pi / max(c.dan, 1) + 0.3;
          PiecesPainter.stone(
            canvas,
            center + Offset(cos(a) * u * 0.3, sin(a) * u * 0.45),
            u * 0.07,
            color,
          );
        }
        PiecesPainter.quanFigure(canvas, center, u * 0.24);
      } else {
        final pos = PiecesPainter.layout(c.dan, u * 0.26);
        for (final p in pos) {
          PiecesPainter.stone(canvas, center + p, u * 0.085, color);
        }
      }
      if (c.dan > 0) {
        PiecesPainter.badge(
          canvas,
          center + Offset(u * 0.28, u * 0.3),
          u * 0.11,
          c.dan,
        );
      }
    }
    if (arrows) {
      final src = cells.indexWhere((c) => c.mark == 'src');
      final c = Offset(x0 + u * (src + 0.5), y + u * 0.95);
      final p = Paint()
        ..color = AppColors.teal
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      for (final d in [-1.0, 1.0]) {
        final a = c + Offset(d * u * 0.15, 0), b = c + Offset(d * u * 0.6, 0);
        canvas.drawLine(a, b, p);
        canvas.drawLine(b, b + Offset(-d * u * 0.15, -u * 0.12), p);
        canvas.drawLine(b, b + Offset(-d * u * 0.15, u * 0.12), p);
      }
    }
    if (note != null) {
      PiecesPainter.text(
        canvas,
        note!,
        Offset(size.width / 2, y - u * 0.95),
        u * 0.3,
        AppColors.gold,
        bold: true,
      );
    }
  }

  @override
  bool shouldRepaint(_RowPainter old) => true;
}
