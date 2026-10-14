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
import 'player_panel.dart';

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
        speedFactor: s.speed.factor,
        colorBlind: s.colorBlind,
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
      RefillEvent(:final playerId) => l.refillMsg(name(playerId)),
      EliminateEvent(:final playerId) => l.eliminateMsg(name(playerId)),
      RuleLoopGuardEvent() => l.loopGuardMsg,
      _ => null,
    };
    if (msg == null) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 2)));
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
            ListTile(leading: const Icon(Icons.play_arrow_rounded), title: Text(l.resume), onTap: () => Navigator.pop(ctx, 'resume')),
            ListTile(leading: const Icon(Icons.replay_rounded), title: Text(l.restart), onTap: () => Navigator.pop(ctx, 'restart')),
            ListTile(leading: const Icon(Icons.rule_rounded), title: Text(l.rules), onTap: () => Navigator.pop(ctx, 'rules')),
            ListTile(leading: const Icon(Icons.settings_rounded), title: Text(l.settings), onTap: () => Navigator.pop(ctx, 'settings')),
            ListTile(leading: const Icon(Icons.save_alt_rounded), title: Text(l.saveAndExit), onTap: () => Navigator.pop(ctx, 'exit')),
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
        content: SingleChildScrollView(child: Text('${l.rulesSummary}\n\n${l.rulesetNote}')),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.ok))],
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
    final String statusText;
    if (shown.isOver) {
      statusText = l.gameOver;
    } else if (s.pending != null) {
      statusText = l.animating;
    } else if (s.current.currentPlayer.isAi) {
      statusText = l.aiThinking(s.current.currentPlayer.name);
    } else {
      statusText = l.hintSelectCell;
    }

    final board = Stack(
      children: [
        Positioned.fill(
          child: GameWidget(game: g, autofocus: true),
        ),
        if (s.pending != null)
          Positioned(
            right: 8,
            bottom: 8,
            child: FilledButton.tonalIcon(
              key: const Key('skipAnim'),
              onPressed: g.skipAnimation,
              icon: const Icon(Icons.fast_forward_rounded),
              label: Text(l.skip),
            ),
          ),
      ],
    );

    final actions = <Widget>[
      IconButton(
        key: const Key('undo'),
        tooltip: l.undo,
        onPressed: s.canUndo ? ref.read(gameSessionProvider.notifier).undo : null,
        icon: const Icon(Icons.undo_rounded),
      ),
      IconButton(
        key: const Key('hint'),
        tooltip: l.hint,
        onPressed: s.humanTurn && !s.busy ? ref.read(gameSessionProvider.notifier).requestHint : null,
        icon: const Icon(Icons.lightbulb_outline_rounded),
      ),
      IconButton(
        tooltip: settings.sound ? l.soundOff : l.soundOn,
        onPressed: ref.read(settingsProvider.notifier).toggleSound,
        icon: Icon(settings.sound ? Icons.volume_up_rounded : Icons.volume_off_rounded),
      ),
      IconButton(tooltip: l.rules, onPressed: _showRules, icon: const Icon(Icons.info_outline_rounded)),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            content: Text(l.confirmExit),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.ok)),
            ],
          ),
        );
        if (ok == true) _exit();
      },
      child: Scaffold(
        body: AppBackground(
          child: SafeArea(
            child: LayoutBuilder(builder: (context, c) {
              final landscape = c.maxWidth > c.maxHeight * 1.25 && c.maxWidth > 640;
              final panel = PlayerPanel(
                state: shown,
                scores: g.displayScores,
                colorBlind: settings.colorBlind,
                vertical: landscape,
              );
              final topBar = Row(
                children: [
                  IconButton(
                    key: const Key('pause'),
                    tooltip: l.pause,
                    onPressed: _pauseMenu,
                    icon: const Icon(Icons.pause_circle_outline_rounded),
                  ),
                  Expanded(
                    child: Text(
                      shown.isOver ? l.gameOver : l.turnOf(shown.currentPlayer.name),
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  ...actions,
                ],
              );
              final status = Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  children: [
                    if (!shown.isOver) PlayerAvatar(playerId: shown.turnPlayer, size: 22, ai: shown.currentPlayer.isAi),
                    const SizedBox(width: 8),
                    Expanded(child: Text(statusText, key: const Key('status'))),
                    Text(l.moveNumber(shown.moveNumber), style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              );
              if (landscape) {
                return Column(
                  children: [
                    topBar,
                    Expanded(
                      child: Row(
                        children: [
                          SizedBox(width: 220, child: panel),
                          Expanded(child: board),
                        ],
                      ),
                    ),
                    status,
                  ],
                );
              }
              return Column(
                children: [
                  topBar,
                  panel,
                  Expanded(child: board),
                  status,
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}
