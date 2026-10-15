import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app.dart';
import '../../../app/router.dart';
import '../../../app/widgets.dart';
import '../../../core/game_models/game_event.dart';
import '../../settings/settings_controller.dart';
import '../audio/sound_service.dart';
import '../flame/board_game.dart';
import '../game_session.dart';
import 'hud.dart';

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
    final l = context.l10n;
    final st = ref.read(gameSessionProvider)?.current;
    String name(int id) => st?.players[id].name ?? '';
    final msg = switch (e) {
      RefillEvent(:final playerId, :final borrowed) =>
        borrowed.isEmpty
            ? l.refillMsg(name(playerId))
            : l.borrowMsg(
                name(playerId),
                borrowed.values.fold(0, (a, b) => a + b),
              ),
      RepayEvent(:final fromId, :final amount) => l.repayMsg(
        name(fromId),
        amount,
      ),
      EliminateEvent(:final playerId) => l.eliminateMsg(name(playerId)),
      RuleLoopGuardEvent() => l.loopGuardMsg,
      _ => null,
    };
    if (msg == null) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
      );
  }

  Future<void> _pauseMenu() async {
    final l = context.l10n;
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const FolkIcon(Icons.play_arrow_rounded),
              title: Text(l.resume),
              onTap: () => Navigator.pop(ctx, 'resume'),
            ),
            ListTile(
              leading: const FolkIcon(Icons.replay_rounded),
              title: Text(l.restart),
              onTap: () => Navigator.pop(ctx, 'restart'),
            ),
            ListTile(
              leading: const FolkIcon(Icons.rule_rounded),
              title: Text(l.rules),
              onTap: () => Navigator.pop(ctx, 'rules'),
            ),
            ListTile(
              leading: const FolkIcon(Icons.settings_rounded),
              title: Text(l.settings),
              onTap: () => Navigator.pop(ctx, 'settings'),
            ),
            ListTile(
              leading: const FolkIcon(Icons.save_alt_rounded),
              title: Text(l.saveAndExit),
              onTap: () => Navigator.pop(ctx, 'exit'),
            ),
          ],
        ),
      ),
    );
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

  void _showRules() {
    final l = context.l10n;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.currentRules),
        content: SingleChildScrollView(
          child: Text('${l.rulesSummary}\n\n${l.rulesetNote}'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.ok)),
        ],
      ),
    );
  }

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
    final l = context.l10n;
    final shown = s.shown;
    final notifier = ref.read(gameSessionProvider.notifier);
    final thinkingId = s.aiThinking ? s.current.turnPlayer : null;

    g.setDark(Theme.of(context).brightness == Brightness.dark);
    final pause = HudButton(
      key: const Key('pause'),
      icon: Icons.pause_rounded,
      tooltip: l.pause,
      onPressed: _pauseMenu,
    );
    final sound = HudButton(
      icon: settings.sound ? Icons.volume_up_rounded : Icons.volume_off_rounded,
      tooltip: settings.sound ? l.soundOff : l.soundOn,
      onPressed: ref.read(settingsProvider.notifier).toggleSound,
    );
    final rules = HudButton(
      icon: Icons.menu_book_rounded,
      tooltip: l.rules,
      onPressed: _showRules,
    );
    final undo = HudButton(
      key: const Key('undo'),
      icon: Icons.undo_rounded,
      tooltip: l.undo,
      onPressed: s.canUndo ? notifier.undo : null,
    );
    final hint = HudButton(
      key: const Key('hint'),
      icon: Icons.lightbulb_outline_rounded,
      tooltip: l.hint,
      label: l.hint,
      onPressed: s.humanTurn && !s.busy ? notifier.requestHint : null,
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            content: Text(l.confirmExit),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l.ok),
              ),
            ],
          ),
        );
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
                final panelW = (c.maxWidth * 0.3).clamp(210.0, 300.0);
                g.setBoardInsets(
                  EdgeInsets.fromLTRB(
                    pad.left + 8,
                    pad.top + 8,
                    pad.right + panelW + 20,
                    pad.bottom + 8,
                  ),
                );
                overlays.add(
                  Positioned(
                    right: pad.right + 12,
                    top: pad.top + 10,
                    bottom: pad.bottom + 10,
                    width: panelW,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            pause,
                            const Spacer(),
                            sound,
                            const SizedBox(width: 6),
                            rules,
                          ],
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: ListView(
                            padding: EdgeInsets.zero,
                            children: [
                              for (final id in order)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: chip(id, panelW),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(child: hint),
                            const SizedBox(width: 8),
                            undo,
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              } else {
                final w = c.maxWidth - pad.horizontal - 24;
                final perRow = n - 1 >= 2 ? 2 : 1;
                final oppRows = ((n - 1) / perRow).ceil();
                final oppW = (w - (perRow - 1) * 8) / perRow;
                final top = pad.top + 10 + 44 + 10 + oppRows * 62 + 6;
                final bottom = pad.bottom + 10 + 60 + 10 + 44 + 10;
                g.setBoardInsets(
                  EdgeInsets.fromLTRB(pad.left + 4, top, pad.right + 4, bottom),
                );
                overlays.addAll([
                  Positioned(
                    left: pad.left + 12,
                    right: pad.right + 12,
                    top: pad.top + 10,
                    child: Row(
                      children: [
                        pause,
                        const Spacer(),
                        sound,
                        const SizedBox(width: 8),
                        rules,
                      ],
                    ),
                  ),
                  Positioned(
                    left: pad.left + 12,
                    right: pad.right + 12,
                    top: pad.top + 64,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [for (var i = 1; i < n; i++) chip(i, oppW)],
                    ),
                  ),
                  Positioned(
                    left: pad.left + 12,
                    right: pad.right + 12,
                    bottom: pad.bottom + 10,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(child: hint),
                            const SizedBox(width: 8),
                            undo,
                          ],
                        ),
                        const SizedBox(height: 10),
                        chip(0, w),
                      ],
                    ),
                  ),
                ]);
              }
              if (s.pending != null) {
                final ins = g.boardInsets;
                overlays.add(
                  Positioned(
                    left: ins.left,
                    right: ins.right,
                    bottom: ins.bottom + 6,
                    child: Center(
                      child: HudButton(
                        key: const Key('skipAnim'),
                        icon: Icons.fast_forward_rounded,
                        tooltip: l.skip,
                        label: l.skip,
                        onPressed: g.skipAnimation,
                      ),
                    ),
                  ),
                );
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
