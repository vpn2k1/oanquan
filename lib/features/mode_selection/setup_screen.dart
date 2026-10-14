import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app.dart';
import '../../app/router.dart';
import '../../app/widgets.dart';
import '../../core/game_models/game_config.dart';
import '../../core/game_models/player.dart';
import '../game/game_session.dart';

enum PlayMode { local, ai, online }

class _Slot {
  _Slot(this.type, this.level, this.name);
  PlayerType type;
  AiLevel level;
  String name;
}

/// Chọn 2/3/4 người → Local / AI / Online → người/AI & độ khó.
class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  int _players = 2;
  PlayMode _mode = PlayMode.ai;
  final List<_Slot> _slots = [];
  final List<TextEditingController> _names = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_slots.isEmpty) _resetSlots();
  }

  void _resetSlots() {
    final l = context.l10n;
    _slots
      ..clear()
      ..addAll([
        for (var i = 0; i < 4; i++)
          _mode == PlayMode.ai && i > 0
              ? _Slot(PlayerType.ai, AiLevel.medium, l.aiPlayerName(i))
              : _Slot(
                  PlayerType.human,
                  AiLevel.medium,
                  l.defaultPlayerName(i + 1),
                ),
      ]);
    for (final c in _names) {
      c.dispose();
    }
    _names
      ..clear()
      ..addAll([for (final s in _slots) TextEditingController(text: s.name)]);
  }

  @override
  void dispose() {
    for (final c in _names) {
      c.dispose();
    }
    super.dispose();
  }

  void _start() {
    if (_mode == PlayMode.online) {
      context.push(Routes.online);
      return;
    }
    final l = context.l10n;
    final players = [
      for (var i = 0; i < _players; i++)
        Player(
          id: i,
          name: _names[i].text.trim().isEmpty
              ? (_slots[i].type == PlayerType.ai
                    ? l.aiPlayerName(i)
                    : l.defaultPlayerName(i + 1))
              : _names[i].text.trim(),
          type: _slots[i].type,
          aiLevel: _slots[i].level,
        ),
    ];
    ref
        .read(gameSessionProvider.notifier)
        .start(
          GameConfig(
            playerCount: _players,
            seed: DateTime.now().millisecondsSinceEpoch & 0x7fffffff,
          ),
          players,
        );
    context.pushReplacement(Routes.game);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final shapes = [l.boardRectangle, l.boardTriangle, l.boardSquare];
    final countAndMode = <Widget>[
      Text(l.choosePlayers, style: theme.textTheme.titleMedium),
      const SizedBox(height: 8),
      Row(
        children: [
          for (final n in [2, 3, 4])
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _ChoiceCard(
                  key: Key('players$n'),
                  selected: _players == n,
                  onTap: () => setState(() => _players = n),
                  child: Column(
                    children: [
                      BoardShapeIcon(players: n),
                      const SizedBox(height: 6),
                      Text(
                        l.playersCount(n),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        shapes[n - 2],
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      const SizedBox(height: 16),
      Text(l.chooseMode, style: theme.textTheme.titleMedium),
      const SizedBox(height: 8),
      SegmentedButton<PlayMode>(
        segments: [
          ButtonSegment(
            value: PlayMode.local,
            label: Text(l.modeLocal),
            icon: const FolkIcon(Icons.people_alt_rounded),
          ),
          ButtonSegment(
            value: PlayMode.ai,
            label: Text(l.modeAi),
            icon: const FolkIcon(Icons.smart_toy_rounded),
          ),
          ButtonSegment(
            value: PlayMode.online,
            label: Text(l.modeOnline),
            icon: const FolkIcon(Icons.public_rounded),
          ),
        ],
        selected: {_mode},
        onSelectionChanged: (s) => setState(() {
          _mode = s.first;
          _resetSlots();
        }),
      ),
    ];
    final playersSection = <Widget>[
      if (_mode != PlayMode.online) ...[
        Text(l.playersSetup, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        for (var i = 0; i < _players; i++) _slotTile(i),
      ] else
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(l.onlineNotice),
          ),
        ),
    ];
    final start = FilledButton.icon(
      key: const Key('startGame'),
      icon: FolkIcon(
        _mode == PlayMode.online
            ? Icons.public_rounded
            : Icons.play_arrow_rounded,
      ),
      label: Text(_mode == PlayMode.online ? l.onlineTitle : l.startGame),
      onPressed: _start,
    );
    return Scaffold(
      appBar: AppBar(title: Text(l.playNow)),
      extendBodyBehindAppBar: true,
      body: AppBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, c) {
              if (c.maxWidth > c.maxHeight && c.maxWidth > 640) {
                // Màn hình ngang: chọn bàn + chế độ bên trái, người chơi bên phải.
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ListView(
                            padding: const EdgeInsets.all(16),
                            children: [
                              ...countAndMode,
                              const SizedBox(height: 16),
                              start,
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView(
                            padding: const EdgeInsets.all(16),
                            children: playersSection,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      ...countAndMode,
                      const SizedBox(height: 20),
                      ...playersSection,
                      const SizedBox(height: 20),
                      start,
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _slotTile(int i) {
    final l = context.l10n;
    final s = _slots[i];
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            PlayerAvatar(playerId: i, ai: s.type == PlayerType.ai),
            SizedBox(
              width: 140,
              child: TextField(
                controller: _names[i],
                maxLength: 14,
                decoration: const InputDecoration(
                  isDense: true,
                  counterText: '',
                ),
              ),
            ),
            SegmentedButton<PlayerType>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(value: PlayerType.human, label: Text(l.human)),
                ButtonSegment(value: PlayerType.ai, label: Text(l.ai)),
              ],
              selected: {s.type},
              onSelectionChanged: (v) => setState(() {
                s.type = v.first;
                _names[i].text = s.type == PlayerType.ai
                    ? l.aiPlayerName(i)
                    : l.defaultPlayerName(i + 1);
              }),
            ),
            if (s.type == PlayerType.ai)
              DropdownButton<AiLevel>(
                value: s.level,
                items: [
                  DropdownMenuItem(value: AiLevel.easy, child: Text(l.aiEasy)),
                  DropdownMenuItem(
                    value: AiLevel.medium,
                    child: Text(l.aiMedium),
                  ),
                  DropdownMenuItem(value: AiLevel.hard, child: Text(l.aiHard)),
                ],
                onChanged: (v) => setState(() => s.level = v ?? s.level),
              ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    super.key,
    required this.selected,
    required this.onTap,
    required this.child,
  });
  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: selected
          ? cs.primary.withValues(alpha: 0.14)
          : Theme.of(context).cardTheme.color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: selected ? cs.primary : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(padding: const EdgeInsets.all(10), child: child),
      ),
    );
  }
}
