import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app.dart';
import '../../app/router.dart';
import '../../app/folk_art.dart';
import '../../app/widgets.dart';
import '../../core/game_models/game_config.dart';
import '../../core/game_models/player.dart';
import '../game/game_session.dart';

/// Hai chế độ: đấu với máy, hoặc chơi với bạn trên cùng một máy.
enum PlayMode { ai, local }

/// Chọn 2/3/4 người → Đấu máy / Chơi với bạn → người/AI & độ khó.
class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  int _players = 2;
  PlayMode _mode = PlayMode.ai;
  AiLevel _level = AiLevel.medium;

  /// Tên người chơi cho chế độ "Chơi với bạn" (4 ô, dùng `_players` ô đầu).
  final List<TextEditingController> _names = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_names.isEmpty) {
      final l = context.l10n;
      _names.addAll([
        for (var i = 0; i < 4; i++)
          TextEditingController(text: l.defaultPlayerName(i + 1)),
      ]);
    }
  }

  @override
  void dispose() {
    for (final c in _names) {
      c.dispose();
    }
    super.dispose();
  }

  void _start() {
    final l = context.l10n;
    final players = [
      for (var i = 0; i < _players; i++)
        switch (_mode) {
          // Đấu máy: người 1 là bạn, các ghế còn lại là máy cùng độ khó.
          PlayMode.ai =>
            i == 0
                ? Player(id: 0, name: l.you)
                : Player(
                    id: i,
                    name: l.aiPlayerName(i),
                    type: PlayerType.ai,
                    aiLevel: _level,
                  ),
          PlayMode.local => Player(
            id: i,
            name: _names[i].text.trim().isEmpty
                ? l.defaultPlayerName(i + 1)
                : _names[i].text.trim(),
          ),
        },
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
            value: PlayMode.ai,
            label: Text(l.modeAi),
            icon: const FolkIcon(Icons.smart_toy_rounded),
          ),
          ButtonSegment(
            value: PlayMode.local,
            label: Text(l.modeLocal),
            icon: const FolkIcon(Icons.people_alt_rounded),
          ),
        ],
        selected: {_mode},
        onSelectionChanged: (s) => setState(() => _mode = s.first),
      ),
    ];
    final levels = [
      (AiLevel.easy, l.aiEasy, l.aiEasyDesc, 1),
      (AiLevel.medium, l.aiMedium, l.aiMediumDesc, 2),
      (AiLevel.hard, l.aiHard, l.aiHardDesc, 3),
    ];
    final playersSection = <Widget>[
      if (_mode == PlayMode.ai) ...[
        Text(l.chooseLevel, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final (lv, name, desc, stars) in levels)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _ChoiceCard(
                    key: Key('level_${lv.name}'),
                    selected: _level == lv,
                    onTap: () => setState(() => _level = lv),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (var k = 0; k < 3; k++)
                              Icon(
                                Icons.circle,
                                size: 10,
                                color: k < stars
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.outline,
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          desc,
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
      ] else ...[
        Text(l.playerNames, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        for (var i = 0; i < _players; i++) _nameTile(i),
      ],
    ];
    final start = FilledButton.icon(
      key: const Key('startGame'),
      icon: const FolkIcon(Icons.play_arrow_rounded),
      label: Text(l.startGame),
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

  Widget _nameTile(int i) => Card(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          PlayerAvatar(playerId: i),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              key: Key('name$i'),
              controller: _names[i],
              maxLength: 14,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(isDense: true, counterText: ''),
            ),
          ),
        ],
      ),
    ),
  );
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
      // Viền phấn: phấn cam khi đang chọn, phấn kem mờ khi không.
      shape: ChalkBorder(
        radius: 18,
        color: selected ? cs.primary : cs.onSurface.withValues(alpha: 0.45),
        width: selected ? 2.8 : 2,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(padding: const EdgeInsets.all(10), child: child),
      ),
    );
  }
}
