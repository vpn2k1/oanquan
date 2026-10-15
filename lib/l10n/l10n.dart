import '../core/game_models/player.dart';
import '../features/achievements/stats_repository.dart';
import 'app_localizations.dart';

/// Ngôn ngữ chọn trong Cài đặt.
enum AppLanguage {
  vi('vi', 'Tiếng Việt'),
  en('en', 'English');

  const AppLanguage(this.code, this.nativeName);

  /// Mã locale.
  final String code;

  /// Tên hiện trong Cài đặt, luôn viết bằng chính ngôn ngữ đó.
  final String nativeName;

  static AppLanguage byCode(String? code) =>
      values.firstWhere((e) => e.code == code, orElse: () => AppLanguage.vi);
}

/// Tên hiển thị của enum trong logic game (enum giữ trung lập, không chứa chữ).
/// Thêm giá trị enum mới: thêm câu chữ vào tool/gen_arb.py và nhánh ở đây.
extension L10nLabels on AppLocalizations {
  String level(AiLevel l) => switch (l) {
    AiLevel.easy => aiEasy,
    AiLevel.medium => aiMedium,
    AiLevel.hard => aiHard,
  };

  String levelDesc(AiLevel l) => switch (l) {
    AiLevel.easy => aiEasyDesc,
    AiLevel.medium => aiMediumDesc,
    AiLevel.hard => aiHardDesc,
  };

  String achievement(Achievement a) => switch (a) {
    Achievement.firstGame => achFirstGame,
    Achievement.beatAi => achBeatAi,
    Achievement.beatHard => achBeatHard,
    Achievement.quanHunter => achQuanHunter,
    Achievement.highScore => achHighScore,
    Achievement.allBoards => achAllBoards,
  };

  String achievementDesc(Achievement a) => switch (a) {
    Achievement.firstGame => achFirstGameDesc,
    Achievement.beatAi => achBeatAiDesc,
    Achievement.beatHard => achBeatHardDesc,
    Achievement.quanHunter => achQuanHunterDesc,
    Achievement.highScore => achHighScoreDesc,
    Achievement.allBoards => achAllBoardsDesc,
  };

  /// Theo `FolkStyle.id`.
  String styleName(String id) => switch (id) {
    'dirt_stick' => styleDirtStick,
    'tiles_chalk' => styleTilesChalk,
    'concrete_brick' => styleConcreteBrick,
    'concrete_charcoal' => styleConcreteCharcoal,
    _ => styleConcreteChalk,
  };
}
