import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:o_quan_viet/core/engine/rules_engine.dart';
import 'package:o_quan_viet/core/game_models/game_config.dart';
import 'package:o_quan_viet/core/game_models/player.dart';
import 'package:o_quan_viet/features/achievements/stats_repository.dart';
import 'package:o_quan_viet/features/game/data/save_repository.dart';
import 'package:o_quan_viet/features/game/game_session.dart';
import 'package:o_quan_viet/features/settings/settings_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> makeContainer() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final c = ProviderContainer(
    overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
  );
  addTearDown(c.dispose);
  return c;
}

List<Player> humans(int n) => [
  for (var i = 0; i < n; i++) Player(id: i, name: 'P$i'),
];

void main() {
  const engine = RulesEngine();

  test('nước đi → lô animation → xong thì HUD cập nhật và tự lưu', () async {
    final c = await makeContainer();
    final ctl = c.read(gameSessionProvider.notifier);
    ctl.start(GameConfig.preset(3), humans(3));
    var s = c.read(gameSessionProvider)!;
    expect(c.read(saveRepositoryProvider).hasSave, isTrue);
    final m = engine.getLegalMoves(s.current).first;
    expect(ctl.submitMove(m), isNull);
    s = c.read(gameSessionProvider)!;
    expect(s.pending, isNotNull);
    expect(s.busy, isTrue);
    expect(s.shown.moveNumber, 0, reason: 'HUD chưa đổi khi đang animate');
    expect(
      ctl.submitMove(engine.getLegalMoves(s.current).first),
      isNotNull,
      reason: 'khóa input khi animate',
    );
    ctl.animationDone(s.pending!.id);
    s = c.read(gameSessionProvider)!;
    expect(s.pending, isNull);
    expect(s.shown.moveNumber, 1);
    final saved = c.read(saveRepositoryProvider).load()!;
    expect(saved.current.boardKey, s.current.boardKey);
  });

  test(
    'undo offline quay về trước nước người cuối; khôi phục ván đã lưu',
    () async {
      final c = await makeContainer();
      final ctl = c.read(gameSessionProvider.notifier);
      ctl.start(GameConfig.preset(2), humans(2));
      final before = c.read(gameSessionProvider)!.current.boardKey;
      for (var i = 0; i < 2; i++) {
        final s = c.read(gameSessionProvider)!;
        ctl.submitMove(engine.getLegalMoves(s.current).first);
        ctl.animationDone(c.read(gameSessionProvider)!.pending!.id);
      }
      expect(c.read(gameSessionProvider)!.current.moveNumber, 2);
      ctl.undo();
      expect(c.read(gameSessionProvider)!.current.moveNumber, 1);
      ctl.undo();
      expect(c.read(gameSessionProvider)!.current.boardKey, before);
      expect(c.read(gameSessionProvider)!.canUndo, isFalse);

      ctl.submitMove(
        engine.getLegalMoves(c.read(gameSessionProvider)!.current).last,
      );
      ctl.animationDone(c.read(gameSessionProvider)!.pending!.id);
      final key = c.read(gameSessionProvider)!.current.boardKey;
      ctl.abandon();
      expect(c.read(gameSessionProvider), isNull);
      expect(ctl.resumeSaved(), isTrue);
      expect(c.read(gameSessionProvider)!.current.boardKey, key);
      expect(c.read(gameSessionProvider)!.initial.moveNumber, 0);
    },
  );

  test(
    'AI tự đi sau người; undo bỏ qua nước AI; kết thúc ván ghi thống kê',
    () async {
      final c = await makeContainer();
      final ctl = c.read(gameSessionProvider.notifier)..aiDelay = Duration.zero;
      ctl.start(GameConfig.preset(2), [
        const Player(id: 0, name: 'Người'),
        const Player(
          id: 1,
          name: 'Máy',
          type: PlayerType.ai,
          aiLevel: AiLevel.easy,
        ),
      ]);
      var guard = 0;
      while (!c.read(gameSessionProvider)!.current.isOver && guard++ < 400) {
        final s = c.read(gameSessionProvider)!;
        if (s.pending != null) {
          ctl.animationDone(s.pending!.id);
          continue;
        }
        if (s.aiThinking) {
          await Future<void>.delayed(const Duration(milliseconds: 5));
          continue;
        }
        if (s.humanTurn) {
          ctl.submitMove(engine.getLegalMoves(s.current).first);
          continue;
        }
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
      final s = c.read(gameSessionProvider)!;
      expect(s.current.isOver, isTrue);
      if (s.pending != null) ctl.animationDone(s.pending!.id);
      expect(c.read(statsProvider).played, 1);
      expect(
        c.read(gameSessionProvider)!.canUndo,
        isFalse,
        reason: 'ván xong không undo được',
      );
      ctl.undo();
      expect(c.read(gameSessionProvider)!.current.isOver, isTrue);
      expect(
        c.read(saveRepositoryProvider).hasSave,
        isFalse,
        reason: 'ván xong thì xóa bản lưu',
      );
      expect(s.current.history.where((m) => m.playerId == 1), isNotEmpty);
    },
  );
}
