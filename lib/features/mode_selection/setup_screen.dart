import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/folk_art.dart';
import '../../app/layout/adaptive_panels.dart';
import '../../app/layout/screen_layout.dart';
import '../../app/widgets.dart';
import '../../core/game_models/game_config.dart';
import '../../core/game_models/player.dart';
import '../game/game_session.dart';
import '../settings/settings_controller.dart';
import '../../l10n/strings.dart';
import 'widgets/choice_card.dart';
import 'widgets/level_picker.dart';

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

  /// Seed ván được bốc ngay khi mở màn này để vẽ sẵn mặt sân ở nền.
  final int _seed = DateTime.now().millisecondsSinceEpoch & 0x7fffffff;
  bool _warmed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_warmed) {
      _warmed = true;
      final size = MediaQuery.sizeOf(context);
      final dpr = MediaQuery.devicePixelRatioOf(context);
      final style = FolkStyle.resolve(
        ref.read(settingsProvider).boardStyle,
        _seed,
      );
      // Chờ frame đầu của màn này vẽ xong rồi mới vẽ sân (không giật lúc chuyển màn).
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => GroundCache.warmUp(size, dpr, style.ground, _seed),
      );
    }
    if (_names.isEmpty) {
      _names.addAll([
        for (var i = 0; i < 4; i++)
          TextEditingController(text: Strings.defaultPlayerName(i + 1)),
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

  Player _playerAt(int i) {
    switch (_mode) {
      case PlayMode.ai:
        // Đấu máy: người 1 là bạn, các ghế còn lại là máy cùng độ khó.
        if (i == 0) return Player(id: 0, name: Strings.you);
        return Player(
          id: i,
          name: Strings.aiPlayerName(i),
          type: PlayerType.ai,
          aiLevel: _level,
        );
      case PlayMode.local:
        var name = _names[i].text.trim();
        if (name.isEmpty) name = Strings.defaultPlayerName(i + 1);
        return Player(id: i, name: name);
    }
  }

  void _start() {
    final players = [for (var i = 0; i < _players; i++) _playerAt(i)];
    ref
        .read(gameSessionProvider.notifier)
        .start(GameConfig(playerCount: _players, seed: _seed), players);
    context.pushReplacement(Routes.game);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final layout = ScreenLayout.of(context);
    final shapes = [
      Strings.boardRectangle,
      Strings.boardTriangle,
      Strings.boardSquare,
    ];
    final countAndMode = <Widget>[
      Text(Strings.choosePlayers, style: theme.textTheme.titleMedium),
      SizedBox(height: 8.r),
      Row(
        children: [
          for (final n in [2, 3, 4])
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.r),
                child: ChoiceCard(
                  key: Key('players$n'),
                  selected: _players == n,
                  onTap: () => setState(() => _players = n),
                  child: Column(
                    children: [
                      BoardShapeIcon(players: n),
                      SizedBox(height: 6.r),
                      Text(
                        Strings.playersCount(n),
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
      SizedBox(height: 16.r),
      Text(Strings.chooseMode, style: theme.textTheme.titleMedium),
      SizedBox(height: 8.r),
      SegmentedButton<PlayMode>(
        segments: [
          ButtonSegment(
            value: PlayMode.ai,
            label: Text(Strings.modeAi),
            icon: const FolkIcon(Icons.smart_toy_rounded),
          ),
          ButtonSegment(
            value: PlayMode.local,
            label: Text(Strings.modeLocal),
            icon: const FolkIcon(Icons.people_alt_rounded),
          ),
        ],
        selected: {_mode},
        onSelectionChanged: (s) => setState(() => _mode = s.first),
      ),
    ];
    final playersSection = <Widget>[
      if (_mode == PlayMode.ai) ...[
        Text(Strings.chooseLevel, style: theme.textTheme.titleMedium),
        SizedBox(height: 8.r),
        LevelPicker(
          level: _level,
          onChanged: (lv) => setState(() => _level = lv),
        ),
      ] else ...[
        Text(Strings.playerNames, style: theme.textTheme.titleMedium),
        SizedBox(height: 8.r),
        ..._nameTiles(layout),
      ],
    ];
    final start = FilledButton.icon(
      key: const Key('startGame'),
      icon: const FolkIcon(Icons.play_arrow_rounded),
      label: Text(Strings.startGame),
      onPressed: _start,
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(Strings.playNow),
        toolbarHeight: toolbarHeightFor(layout),
      ),
      extendBodyBehindAppBar: true,
      body: AppBackground(
        child: SafeArea(
          // Điện thoại ngang: trái là bàn + chế độ, phải là người chơi + nút
          // bắt đầu, vừa một màn hình. Dọc / màn rộng: một cột.
          child: AdaptivePanels(
            columnMaxWidth: 560.r,
            gap: 20.r,
            primary: countAndMode,
            secondary: [
              ...playersSection,
              SizedBox(height: 20.r),
              start,
            ],
          ),
        ),
      ),
    );
  }

  /// Ô tên người chơi: điện thoại ngang xếp 2 ô một hàng cho đỡ cao.
  List<Widget> _nameTiles(ScreenLayout layout) {
    if (layout != ScreenLayout.compactLandscape) {
      return [for (var i = 0; i < _players; i++) _nameTile(i)];
    }
    return [
      for (var i = 0; i < _players; i += 2)
        Row(
          children: [
            Expanded(child: _nameTile(i)),
            SizedBox(width: 8.r),
            Expanded(child: _nameTileOrEmpty(i + 1)),
          ],
        ),
    ];
  }

  Widget _nameTileOrEmpty(int i) {
    if (i < _players) return _nameTile(i);
    return const SizedBox();
  }

  Widget _nameTile(int i) => Card(
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.r, vertical: 8.r),
      child: Row(
        children: [
          PlayerAvatar(playerId: i),
          SizedBox(width: 12.r),
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
