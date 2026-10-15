import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/widgets.dart';
import '../../../core/game_models/game_event.dart';
import '../../settings/settings_controller.dart';
import '../audio/sound_service.dart';
import '../flame/board_game.dart';
import '../game_session.dart';
import 'game_notice.dart';
import 'hud.dart';
import 'widgets/game_dialogs.dart';
import 'widgets/game_hud_buttons.dart';
import 'widgets/game_rails.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  OQuanGame? _game;
  final _sound = SoundService();
  int _lastBatch = -1;
  int _lastSync = -1;
  bool _resultShown = false;

  BoardVisuals _visuals(AppSettings s) => BoardVisuals(
    reducedMotion: s.reducedMotion,
    speedFactor: kAnimSpeedFactor,
    colorBlind: s.colorBlind,
    styleSetting: s.boardStyle,
  );

  @override
  void initState() {
    super.initState();
    final session = ref.read(gameSessionProvider);
    final settings = ref.read(settingsProvider);
    _sound
      ..enabled = settings.sound
      ..haptics = settings.haptics;
    // Tổng hợp sẵn âm thanh sau frame đầu (tránh giật ở lần rải đầu tiên).
    WidgetsBinding.instance.addPostFrameCallback((_) => _sound.init());
    if (session == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go(Routes.home);
      });
      return;
    }
    final notifier = ref.read(gameSessionProvider.notifier);
    _game = OQuanGame(
      initial: session.shown,
      visuals: _visuals(settings),
      callbacks: BoardCallbacks(
        onMove: (m) => notifier.submitMove(m),
        onAnimationDone: notifier.animationDone,
        onNotice: _notice,
        onSound: _sound.play,
      ),
    );
    _lastSync = session.syncToken;
    WidgetsBinding.instance.addPostFrameCallback((_) => _apply(session));
  }

  @override
  void dispose() {
    _sound.dispose();
    super.dispose();
  }

  void _apply(GameSessionState? s) {
    final g = _game;
    if (s == null || g == null || !mounted) return;
    if (s.syncToken != _lastSync) {
      _lastSync = s.syncToken;
      _resultShown = false;
      g.syncTo(s.current);
    }
    final p = s.pending;
    if (p != null && p.id != _lastBatch) {
      _lastBatch = p.id;
      g.playBatch(p);
    }
    g.inputEnabled = s.humanTurn && !s.busy;
    g.showHint(s.hint);
    if (s.current.isOver && s.pending == null && !_resultShown) {
      _resultShown = true;
      Future.delayed(const Duration(milliseconds: 900), () {
        if (mounted && ref.read(gameSessionProvider)?.current.isOver == true) {
          context.pushReplacement(Routes.result);
        }
      });
    }
  }

  void _notice(GameEvent e) {
    if (!mounted) return;
    final st = ref.read(gameSessionProvider)?.current;
    final msg = gameNoticeText(e, (id) => st?.players[id].name ?? '');
    if (msg == null) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
      );
  }

  Future<void> _pauseMenu() async {
    final choice = await showPauseMenu(context);
    if (!mounted) return;
    switch (choice) {
      case 'restart':
        ref.read(gameSessionProvider.notifier).restart();
      case 'rules':
        _showRules();
      case 'settings':
        context.push(Routes.settings);
      case 'exit':
        _exit();
    }
  }

  void _exit() {
    // Ván đã được tự lưu sau mỗi nước; chỉ cần rời màn.
    ref.read(gameSessionProvider.notifier).abandon();
    context.go(Routes.home);
  }

  void _showRules() => showRulesDialog(context);

  @override
  Widget build(BuildContext context) {
    ref.listen(gameSessionProvider, (_, next) => _apply(next));
    ref.listen(settingsProvider, (_, s) {
      _sound
        ..enabled = s.sound
        ..haptics = s.haptics;
      _game?.updateVisuals(_visuals(s));
    });
    final s = ref.watch(gameSessionProvider);
    final settings = ref.watch(settingsProvider);
    final g = _game;
    if (s == null || g == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final shown = s.shown;
    final notifier = ref.read(gameSessionProvider.notifier);
    int? thinkingId;
    if (s.aiThinking) thinkingId = s.current.turnPlayer;

    g.setDark(Theme.of(context).brightness == Brightness.dark);
    VoidCallback? onUndo;
    if (s.canUndo) onUndo = notifier.undo;
    VoidCallback? onHint;
    if (s.humanTurn && !s.busy) onHint = notifier.requestHint;
    final buttons = GameHudButtons(
      onPause: _pauseMenu,
      onShuffleGround: g.shuffleGround,
      soundOn: settings.sound,
      onToggleSound: ref.read(settingsProvider.notifier).toggleSound,
      onRules: _showRules,
      onUndo: onUndo,
      onHint: onHint,
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final ok = await confirmExitDialog(context);
        if (ok == true) _exit();
      },
      child: Scaffold(
        body: AppBackground(
          plain: true,
          child: LayoutBuilder(
            builder: (context, c) {
              // Bố cục kiểu Recess: khay bàn chiếm phần lớn màn hình, bảng
              // điều khiển + thẻ người chơi ở cạnh phải (ngang) hoặc trên/dưới (dọc).
              final pad = MediaQuery.paddingOf(context);
              final landscape = c.maxWidth > c.maxHeight;
              final n = shown.players.length;
              // Đối thủ trước, người ngồi cạnh dưới (P0) sau cùng — giống Recess.
              final order = [for (var i = 1; i < n; i++) i, 0];

              Widget chip(int id, double w) => PlayerChip(
                key: Key('player$id'),
                state: shown,
                playerId: id,
                scores: g.displayScores,
                thinking: thinkingId == id,
                width: w,
              );

              final overlays = <Widget>[];
              if (landscape) {
                // Bàn ở giữa, gần kín màn; hai cột bằng nhau hai bên:
                // trái = người chơi (đối thủ trên, mình dưới), phải = nút.
                final area = Size(
                  c.maxWidth - pad.horizontal,
                  c.maxHeight - pad.vertical,
                );
                final railW = gameRailWidth(area, n);
                final wide = isWideRail(railW);
                final edge = 10.r;
                final side = edge + railW + 6.r;
                g.setBoardInsets(
                  EdgeInsets.fromLTRB(
                    pad.left + side,
                    pad.top + 4.r,
                    pad.right + side,
                    pad.bottom + 4.r,
                  ),
                );
                Widget railChip(int id) {
                  if (wide) return chip(id, railW);
                  return RailPlayerChip(
                    key: Key('player$id'),
                    state: shown,
                    playerId: id,
                    scores: g.displayScores,
                    thinking: thinkingId == id,
                  );
                }

                var (railTop, railBottom) = buttons.railGroups();
                if (wide) {
                  railTop = [buttons.railTopRow()];
                  railBottom = [buttons.actionRow()];
                }
                overlays.addAll([
                  Positioned(
                    left: pad.left + edge,
                    top: pad.top + edge,
                    bottom: pad.bottom + edge,
                    width: railW,
                    child: GameRail(
                      top: [for (final id in order.take(n - 1)) railChip(id)],
                      bottom: [railChip(0)],
                    ),
                  ),
                  Positioned(
                    right: pad.right + edge,
                    top: pad.top + edge,
                    bottom: pad.bottom + edge,
                    width: railW,
                    child: GameRail(top: railTop, bottom: railBottom),
                  ),
                ]);
              } else {
                final w = c.maxWidth - pad.horizontal - 24.r;
                var perRow = 1;
                if (n - 1 >= 2) perRow = 2;
                final oppRows = ((n - 1) / perRow).ceil();
                final oppW = (w - (perRow - 1) * 8.r) / perRow;
                final top = pad.top + (10 + 44 + 10 + 6).r + oppRows * 62.r;
                final bottom = pad.bottom + (10 + 60 + 10 + 44 + 10).r;
                g.setBoardInsets(
                  EdgeInsets.fromLTRB(
                    pad.left + 4.r,
                    top,
                    pad.right + 4.r,
                    bottom,
                  ),
                );
                overlays.addAll([
                  Positioned(
                    left: pad.left + 12.r,
                    right: pad.right + 12.r,
                    top: pad.top + 10.r,
                    child: buttons.topBar(8.r),
                  ),
                  Positioned(
                    left: pad.left + 12.r,
                    right: pad.right + 12.r,
                    top: pad.top + 64.r,
                    child: Wrap(
                      spacing: 8.r,
                      runSpacing: 8.r,
                      children: [for (var i = 1; i < n; i++) chip(i, oppW)],
                    ),
                  ),
                  Positioned(
                    left: pad.left + 12.r,
                    right: pad.right + 12.r,
                    bottom: pad.bottom + 10.r,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        buttons.actionRow(),
                        SizedBox(height: 10.r),
                        chip(0, w),
                      ],
                    ),
                  ),
                ]);
              }
              return Stack(
                children: [
                  Positioned.fill(child: GameWidget(game: g, autofocus: true)),
                  ...overlays,
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
