// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'O Quan Viet';

  @override
  String get appSubtitle => 'A Folk Strategy Duel';

  @override
  String get playNow => 'Play now';

  @override
  String get continueGame => 'Continue game';

  @override
  String get tutorial => 'How to play';

  @override
  String get achievements => 'Achievements';

  @override
  String get settings => 'Settings';

  @override
  String get back => 'Back';

  @override
  String playersCount(int count) {
    return '$count players';
  }

  @override
  String get choosePlayers => 'Players';

  @override
  String get boardRectangle => 'Rectangle board';

  @override
  String get boardTriangle => 'Triangle board';

  @override
  String get boardSquare => 'Square board';

  @override
  String get chooseMode => 'Mode';

  @override
  String get modeLocal => 'Same device';

  @override
  String get modeAi => 'Vs AI';

  @override
  String get modeOnline => 'Online';

  @override
  String get playersSetup => 'Players';

  @override
  String get human => 'Human';

  @override
  String get ai => 'AI';

  @override
  String get aiEasy => 'Easy';

  @override
  String get aiMedium => 'Medium';

  @override
  String get aiHard => 'Hard';

  @override
  String get startGame => 'Start';

  @override
  String defaultPlayerName(int n) {
    return 'Player $n';
  }

  @override
  String aiPlayerName(int n) {
    return 'Bot $n';
  }

  @override
  String turnOf(String name) {
    return 'Turn: $name';
  }

  @override
  String get hintSelectCell => 'Tap one of your glowing pits';

  @override
  String get hintSelectDirection => 'Pick a sowing direction';

  @override
  String aiThinking(String name) {
    return '$name is thinking…';
  }

  @override
  String get animating => 'Sowing… (tap to fast-forward)';

  @override
  String get skip => 'Skip';

  @override
  String get undo => 'Undo';

  @override
  String get hint => 'Hint';

  @override
  String get rules => 'Rules';

  @override
  String get pause => 'Pause';

  @override
  String get resume => 'Resume';

  @override
  String get saveAndExit => 'Save & exit';

  @override
  String get restart => 'Restart';

  @override
  String get home => 'Home';

  @override
  String get soundOn => 'Sound on';

  @override
  String get soundOff => 'Sound off';

  @override
  String get score => 'Score';

  @override
  String get eliminated => 'Eliminated';

  @override
  String get danShort => 'seeds';

  @override
  String get quanShort => 'mandarins';

  @override
  String get gameOver => 'Game over';

  @override
  String winner(String name) {
    return '$name wins!';
  }

  @override
  String get draw => 'Draw — shared first place';

  @override
  String rank(int n) {
    return 'Rank $n';
  }

  @override
  String get endAllQuan => 'All mandarins captured';

  @override
  String get endLastStanding => 'Only one player left';

  @override
  String get endMoveLimit => 'Move limit reached (anti-stall rule)';

  @override
  String get playAgain => 'Play again';

  @override
  String refillMsg(String name) {
    return '$name ran out — puts 5 captured seeds back, one per pit';
  }

  @override
  String eliminateMsg(String name) {
    return '$name ran out and cannot borrow — eliminated';
  }

  @override
  String get loopGuardMsg => 'Loop detected — turn ended';

  @override
  String get settingsSound => 'Sound';

  @override
  String get settingsHaptics => 'Haptic feedback';

  @override
  String get settingsAnimSpeed => 'Animation speed';

  @override
  String get speedSlow => 'Slow';

  @override
  String get speedNormal => 'Normal';

  @override
  String get speedFast => 'Fast';

  @override
  String get settingsReducedMotion => 'Reduce motion';

  @override
  String get settingsReducedMotionDesc =>
      'Skip flying effects, update the board instantly';

  @override
  String get settingsColorBlind => 'Color-blind assist';

  @override
  String get settingsColorBlindDesc => 'Add shape symbols for each player';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get rulesetNote =>
      'Rules follow traditional Ô ăn quan (2 players); the 3–4 player boards extend the same rules.';

  @override
  String get tutorialTitle => 'How to play';

  @override
  String get tutStep1Title => 'Board and pieces';

  @override
  String get tutStep1 =>
      'Each player owns 5 pits on their side, each with 5 seeds. Mandarin pits at the corners are shared, each holding 1 mandarin (10 points).';

  @override
  String get tutStep2Title => 'Pick a pit and direction';

  @override
  String get tutStep2 =>
      'On your turn pick one of your pits that has seeds, then sow clockwise or counter-clockwise. Mandarin pits cannot be picked.';

  @override
  String get tutStep3Title => 'Sowing';

  @override
  String get tutStep3 =>
      'Take all seeds and drop one in each following pit (mandarin pits included). When your hand is empty: if the next pit is a seed pit with seeds, pick them up and keep sowing; a mandarin pit stops you.';

  @override
  String get tutStep4Title => 'Capturing';

  @override
  String get tutStep4 =>
      'If the next pit is empty, you capture everything in the pit right after it. If another empty pit is followed by a pit with pieces, keep capturing. Never across 2 empty pits.';

  @override
  String get tutStep5Title => 'Capturing mandarins';

  @override
  String get tutStep5 =>
      'A mandarin pit can only be captured when it holds at least 5 seeds. With fewer it is a \"young mandarin\": no capture, your turn ends.';

  @override
  String get tutStep6Title => 'Running out and ending';

  @override
  String get tutStep6 =>
      'If all 5 of your pits are empty at the start of your turn, put 5 captured seeds back, one per pit; if you lack them, borrow from opponents and repay at scoring. The game ends when both mandarin pits are completely empty; seeds left in each player\'s pits go to that player. 1 mandarin = 10 seeds; most seeds wins.';

  @override
  String get tutKeyboard =>
      'Keyboard: ←/→ select pit, Z = counter-clockwise, X = clockwise, Esc = cancel.';

  @override
  String get tutTryIt => 'Try against easy AI';

  @override
  String get next => 'Next';

  @override
  String get previous => 'Previous';

  @override
  String get statsTitle => 'Statistics';

  @override
  String get statsPlayed => 'Games played';

  @override
  String get statsWinsVsAi => 'Wins vs AI';

  @override
  String get statsBestScore => 'Best score';

  @override
  String get statsQuanTotal => 'Mandarins captured';

  @override
  String get achFirstGame => 'First game';

  @override
  String get achFirstGameDesc => 'Finish any game';

  @override
  String get achBeatAi => 'Machine tamer';

  @override
  String get achBeatAiDesc => 'Win a game with an AI';

  @override
  String get achBeatHard => 'Grandmaster';

  @override
  String get achBeatHardDesc => 'Beat a Hard AI';

  @override
  String get achQuanHunter => 'Mandarin hunter';

  @override
  String get achQuanHunterDesc => 'Capture 2 mandarins in one game';

  @override
  String get achHighScore => 'Tycoon';

  @override
  String get achHighScoreDesc => 'Score 40+ in one game';

  @override
  String get achAllBoards => 'Board explorer';

  @override
  String get achAllBoardsDesc => 'Play on the 2, 3 and 4 player boards';

  @override
  String get onlineTitle => 'Online rooms';

  @override
  String get onlineNotice =>
      'Online play needs an authoritative server. This build only ships the API contract and an in-process fake server for testing — no real network yet.';

  @override
  String get createRoom => 'Create room';

  @override
  String get joinRoom => 'Join room';

  @override
  String get roomCode => 'Room code';

  @override
  String roomCreated(String code) {
    return 'Room $code created (local simulation)';
  }

  @override
  String roomJoined(String code) {
    return 'Joined room $code (local simulation)';
  }

  @override
  String get roomNotFound => 'Room not found';

  @override
  String waitingPlayers(int joined, int total) {
    return 'Waiting for players: $joined/$total';
  }

  @override
  String get onlineUnavailable =>
      'No real server yet — online games cannot start.';

  @override
  String get noSavedGame => 'No saved game';

  @override
  String get confirmExit =>
      'Leave the game? It will be saved so you can continue.';

  @override
  String get cancel => 'Cancel';

  @override
  String get ok => 'OK';

  @override
  String moveNumber(int n) {
    return 'Move $n';
  }

  @override
  String get currentRules => 'Current rules (multi_v1)';

  @override
  String get rulesSummary =>
      '• Pick your own pit and a direction, drop 1 seed per pit.\n• Next pit has seeds → pick up and continue; mandarin pit → turn ends.\n• Empty pit then a pit with pieces → capture, chains allowed; 2 empty pits → turn ends.\n• A young mandarin (< 5 seeds in its pit) cannot be captured.\n• Out of seeds: put 5 captured seeds back; borrow if short, repay at scoring.\n• Mandarin pits emptied → game over; seeds left go to each pit\'s owner. 1 mandarin = 10 seeds.';

  @override
  String get addSimulatedClient => '+ Add simulated client';

  @override
  String borrowMsg(String name, int count) {
    return '$name ran out and lacks seeds — borrows $count to refill (repaid at scoring)';
  }

  @override
  String repayMsg(String name, int count) {
    return '$name repays $count borrowed seeds';
  }

  @override
  String get settingsBoardStyle => 'Ground & drawing';

  @override
  String get styleRandom => 'Random each game';

  @override
  String get style_dirt_stick => 'Dirt · stick';

  @override
  String get style_concrete_chalk => 'Concrete · white chalk';

  @override
  String get style_tiles_chalk => 'Brick tiles · chalk';

  @override
  String get style_concrete_brick => 'Concrete · brick shard';

  @override
  String get style_concrete_charcoal => 'Concrete · charcoal';

  @override
  String get yourTurn => 'Your turn';

  @override
  String get thinkingShort => 'Thinking…';

  @override
  String get eliminatedShort => 'Out';
}
