import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In vi, this message translates to:
  /// **'Ô Quan Việt'**
  String get appTitle;

  /// No description provided for @appSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Đấu Trí Dân Gian'**
  String get appSubtitle;

  /// No description provided for @playNow.
  ///
  /// In vi, this message translates to:
  /// **'Chơi ngay'**
  String get playNow;

  /// No description provided for @continueGame.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục ván'**
  String get continueGame;

  /// No description provided for @tutorial.
  ///
  /// In vi, this message translates to:
  /// **'Hướng dẫn'**
  String get tutorial;

  /// No description provided for @achievements.
  ///
  /// In vi, this message translates to:
  /// **'Thành tích'**
  String get achievements;

  /// No description provided for @settings.
  ///
  /// In vi, this message translates to:
  /// **'Cài đặt'**
  String get settings;

  /// No description provided for @back.
  ///
  /// In vi, this message translates to:
  /// **'Quay lại'**
  String get back;

  /// No description provided for @playersCount.
  ///
  /// In vi, this message translates to:
  /// **'{count} người'**
  String playersCount(int count);

  /// No description provided for @choosePlayers.
  ///
  /// In vi, this message translates to:
  /// **'Số người chơi'**
  String get choosePlayers;

  /// No description provided for @boardRectangle.
  ///
  /// In vi, this message translates to:
  /// **'Bàn chữ nhật'**
  String get boardRectangle;

  /// No description provided for @boardTriangle.
  ///
  /// In vi, this message translates to:
  /// **'Bàn tam giác'**
  String get boardTriangle;

  /// No description provided for @boardSquare.
  ///
  /// In vi, this message translates to:
  /// **'Bàn vuông'**
  String get boardSquare;

  /// No description provided for @chooseMode.
  ///
  /// In vi, this message translates to:
  /// **'Chế độ'**
  String get chooseMode;

  /// No description provided for @modeLocal.
  ///
  /// In vi, this message translates to:
  /// **'Chơi với bạn'**
  String get modeLocal;

  /// No description provided for @modeAi.
  ///
  /// In vi, this message translates to:
  /// **'Đấu máy'**
  String get modeAi;

  /// No description provided for @modeOnline.
  ///
  /// In vi, this message translates to:
  /// **'Online'**
  String get modeOnline;

  /// No description provided for @playersSetup.
  ///
  /// In vi, this message translates to:
  /// **'Người chơi'**
  String get playersSetup;

  /// No description provided for @human.
  ///
  /// In vi, this message translates to:
  /// **'Người'**
  String get human;

  /// No description provided for @ai.
  ///
  /// In vi, this message translates to:
  /// **'AI'**
  String get ai;

  /// No description provided for @aiEasy.
  ///
  /// In vi, this message translates to:
  /// **'Dễ'**
  String get aiEasy;

  /// No description provided for @aiMedium.
  ///
  /// In vi, this message translates to:
  /// **'Vừa'**
  String get aiMedium;

  /// No description provided for @aiHard.
  ///
  /// In vi, this message translates to:
  /// **'Khó'**
  String get aiHard;

  /// No description provided for @startGame.
  ///
  /// In vi, this message translates to:
  /// **'Bắt đầu'**
  String get startGame;

  /// No description provided for @defaultPlayerName.
  ///
  /// In vi, this message translates to:
  /// **'Người {n}'**
  String defaultPlayerName(int n);

  /// No description provided for @aiPlayerName.
  ///
  /// In vi, this message translates to:
  /// **'Máy {n}'**
  String aiPlayerName(int n);

  /// No description provided for @turnOf.
  ///
  /// In vi, this message translates to:
  /// **'Lượt: {name}'**
  String turnOf(String name);

  /// No description provided for @hintSelectCell.
  ///
  /// In vi, this message translates to:
  /// **'Chạm vào một ô sáng bên bạn để chọn'**
  String get hintSelectCell;

  /// No description provided for @hintSelectDirection.
  ///
  /// In vi, this message translates to:
  /// **'Chọn hướng rải bằng mũi tên'**
  String get hintSelectDirection;

  /// No description provided for @aiThinking.
  ///
  /// In vi, this message translates to:
  /// **'{name} đang suy nghĩ…'**
  String aiThinking(String name);

  /// No description provided for @animating.
  ///
  /// In vi, this message translates to:
  /// **'Đang rải quân… (chạm để tua nhanh)'**
  String get animating;

  /// No description provided for @skip.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ qua'**
  String get skip;

  /// No description provided for @undo.
  ///
  /// In vi, this message translates to:
  /// **'Đi lại'**
  String get undo;

  /// No description provided for @hint.
  ///
  /// In vi, this message translates to:
  /// **'Gợi ý'**
  String get hint;

  /// No description provided for @rules.
  ///
  /// In vi, this message translates to:
  /// **'Luật'**
  String get rules;

  /// No description provided for @pause.
  ///
  /// In vi, this message translates to:
  /// **'Tạm dừng'**
  String get pause;

  /// No description provided for @resume.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục'**
  String get resume;

  /// No description provided for @saveAndExit.
  ///
  /// In vi, this message translates to:
  /// **'Lưu & thoát'**
  String get saveAndExit;

  /// No description provided for @restart.
  ///
  /// In vi, this message translates to:
  /// **'Chơi lại'**
  String get restart;

  /// No description provided for @home.
  ///
  /// In vi, this message translates to:
  /// **'Trang chủ'**
  String get home;

  /// No description provided for @soundOn.
  ///
  /// In vi, this message translates to:
  /// **'Bật âm thanh'**
  String get soundOn;

  /// No description provided for @soundOff.
  ///
  /// In vi, this message translates to:
  /// **'Tắt âm thanh'**
  String get soundOff;

  /// No description provided for @score.
  ///
  /// In vi, this message translates to:
  /// **'Điểm'**
  String get score;

  /// No description provided for @eliminated.
  ///
  /// In vi, this message translates to:
  /// **'Bị loại'**
  String get eliminated;

  /// No description provided for @danShort.
  ///
  /// In vi, this message translates to:
  /// **'dân'**
  String get danShort;

  /// No description provided for @quanShort.
  ///
  /// In vi, this message translates to:
  /// **'quan'**
  String get quanShort;

  /// No description provided for @gameOver.
  ///
  /// In vi, this message translates to:
  /// **'Kết thúc ván'**
  String get gameOver;

  /// No description provided for @winner.
  ///
  /// In vi, this message translates to:
  /// **'{name} thắng!'**
  String winner(String name);

  /// No description provided for @draw.
  ///
  /// In vi, this message translates to:
  /// **'Hòa — đồng hạng nhất'**
  String get draw;

  /// No description provided for @rank.
  ///
  /// In vi, this message translates to:
  /// **'Hạng {n}'**
  String rank(int n);

  /// No description provided for @endAllQuan.
  ///
  /// In vi, this message translates to:
  /// **'Tất cả quan đã bị ăn'**
  String get endAllQuan;

  /// No description provided for @endLastStanding.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ còn một người trong cuộc'**
  String get endLastStanding;

  /// No description provided for @endMoveLimit.
  ///
  /// In vi, this message translates to:
  /// **'Đạt giới hạn số nước (luật chống bế tắc)'**
  String get endMoveLimit;

  /// No description provided for @playAgain.
  ///
  /// In vi, this message translates to:
  /// **'Chơi lại'**
  String get playAgain;

  /// No description provided for @refillMsg.
  ///
  /// In vi, this message translates to:
  /// **'{name} hết dân — lấy 5 dân đã ăn rải lại mỗi ô 1 dân'**
  String refillMsg(String name);

  /// No description provided for @eliminateMsg.
  ///
  /// In vi, this message translates to:
  /// **'{name} hết dân và không vay được — bị loại'**
  String eliminateMsg(String name);

  /// No description provided for @loopGuardMsg.
  ///
  /// In vi, this message translates to:
  /// **'Phát hiện vòng lặp — kết thúc lượt'**
  String get loopGuardMsg;

  /// No description provided for @settingsSound.
  ///
  /// In vi, this message translates to:
  /// **'Âm thanh'**
  String get settingsSound;

  /// No description provided for @settingsHaptics.
  ///
  /// In vi, this message translates to:
  /// **'Rung phản hồi'**
  String get settingsHaptics;

  /// No description provided for @settingsReducedMotion.
  ///
  /// In vi, this message translates to:
  /// **'Giảm chuyển động'**
  String get settingsReducedMotion;

  /// No description provided for @settingsReducedMotionDesc.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ hiệu ứng bay, cập nhật bàn tức thì'**
  String get settingsReducedMotionDesc;

  /// No description provided for @settingsColorBlind.
  ///
  /// In vi, this message translates to:
  /// **'Hỗ trợ khó phân biệt màu'**
  String get settingsColorBlind;

  /// No description provided for @settingsColorBlindDesc.
  ///
  /// In vi, this message translates to:
  /// **'Thêm biểu tượng hình dạng cho mỗi người chơi'**
  String get settingsColorBlindDesc;

  /// No description provided for @settingsTheme.
  ///
  /// In vi, this message translates to:
  /// **'Giao diện'**
  String get settingsTheme;

  /// No description provided for @themeSystem.
  ///
  /// In vi, this message translates to:
  /// **'Theo hệ thống'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In vi, this message translates to:
  /// **'Sáng'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In vi, this message translates to:
  /// **'Tối'**
  String get themeDark;

  /// No description provided for @settingsLanguage.
  ///
  /// In vi, this message translates to:
  /// **'Ngôn ngữ'**
  String get settingsLanguage;

  /// No description provided for @rulesetNote.
  ///
  /// In vi, this message translates to:
  /// **'Luật theo Ô ăn quan dân gian (2 người); bản 3–4 người mở rộng cùng luật trên bàn tam giác/vuông.'**
  String get rulesetNote;

  /// No description provided for @tutorialTitle.
  ///
  /// In vi, this message translates to:
  /// **'Cách chơi'**
  String get tutorialTitle;

  /// No description provided for @tutStep1Title.
  ///
  /// In vi, this message translates to:
  /// **'Bàn và quân'**
  String get tutStep1Title;

  /// No description provided for @tutStep1.
  ///
  /// In vi, this message translates to:
  /// **'Mỗi người sở hữu 5 ô dân trên cạnh của mình, mỗi ô có 5 dân. Ô quan ở các góc là ô chung, mỗi ô có 1 quan (10 điểm).'**
  String get tutStep1;

  /// No description provided for @tutStep2Title.
  ///
  /// In vi, this message translates to:
  /// **'Chọn ô và hướng'**
  String get tutStep2Title;

  /// No description provided for @tutStep2.
  ///
  /// In vi, this message translates to:
  /// **'Đến lượt, chọn một ô dân của bạn còn dân, rồi chọn chiều kim đồng hồ hoặc ngược lại. Không được chọn ô quan.'**
  String get tutStep2;

  /// No description provided for @tutStep3Title.
  ///
  /// In vi, this message translates to:
  /// **'Rải dân'**
  String get tutStep3Title;

  /// No description provided for @tutStep3.
  ///
  /// In vi, this message translates to:
  /// **'Nhấc hết dân trong ô, rải mỗi ô kế tiếp 1 dân (kể cả ô quan). Hết dân trên tay: nếu ô kế tiếp là ô dân còn dân thì bốc lên rải tiếp; gặp ô quan thì dừng.'**
  String get tutStep3;

  /// No description provided for @tutStep4Title.
  ///
  /// In vi, this message translates to:
  /// **'Ăn quân'**
  String get tutStep4Title;

  /// No description provided for @tutStep4.
  ///
  /// In vi, this message translates to:
  /// **'Nếu ô kế tiếp trống, bạn ăn toàn bộ dân ở ô ngay sau. Sau đó nếu lại có một ô trống rồi một ô có quân thì ăn chuỗi tiếp. Không ăn qua 2 ô trống liền.'**
  String get tutStep4;

  /// No description provided for @tutStep5Title.
  ///
  /// In vi, this message translates to:
  /// **'Ăn quan'**
  String get tutStep5Title;

  /// No description provided for @tutStep5.
  ///
  /// In vi, this message translates to:
  /// **'Ô quan còn quan chỉ được ăn khi có từ 5 dân trở lên. Ít hơn là \"quan non\": không được ăn, bạn mất lượt.'**
  String get tutStep5;

  /// No description provided for @tutStep6Title.
  ///
  /// In vi, this message translates to:
  /// **'Hết dân và kết thúc'**
  String get tutStep6Title;

  /// No description provided for @tutStep6.
  ///
  /// In vi, this message translates to:
  /// **'Đầu lượt nếu 5 ô của bạn đều trống: lấy 5 dân đã ăn rải lại mỗi ô 1 dân; không đủ thì vay đối thủ, trả khi tính điểm. Ván kết thúc khi cả hai ô quan hết sạch dân và quan; dân còn trên các ô bên nào thuộc về người bên đó. 1 quan = 10 dân, nhiều dân nhất thắng.'**
  String get tutStep6;

  /// No description provided for @tutKeyboard.
  ///
  /// In vi, this message translates to:
  /// **'Bàn phím: ←/→ chọn ô, Z = ngược chiều kim đồng hồ, X = theo chiều kim đồng hồ, Esc = hủy.'**
  String get tutKeyboard;

  /// No description provided for @tutTryIt.
  ///
  /// In vi, this message translates to:
  /// **'Chơi thử với AI dễ'**
  String get tutTryIt;

  /// No description provided for @next.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp'**
  String get next;

  /// No description provided for @previous.
  ///
  /// In vi, this message translates to:
  /// **'Trước'**
  String get previous;

  /// No description provided for @statsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Thống kê'**
  String get statsTitle;

  /// No description provided for @statsPlayed.
  ///
  /// In vi, this message translates to:
  /// **'Ván đã chơi'**
  String get statsPlayed;

  /// No description provided for @statsWinsVsAi.
  ///
  /// In vi, this message translates to:
  /// **'Thắng AI'**
  String get statsWinsVsAi;

  /// No description provided for @statsBestScore.
  ///
  /// In vi, this message translates to:
  /// **'Điểm cao nhất'**
  String get statsBestScore;

  /// No description provided for @statsQuanTotal.
  ///
  /// In vi, this message translates to:
  /// **'Tổng quan đã ăn'**
  String get statsQuanTotal;

  /// No description provided for @achFirstGame.
  ///
  /// In vi, this message translates to:
  /// **'Ván đầu tiên'**
  String get achFirstGame;

  /// No description provided for @achFirstGameDesc.
  ///
  /// In vi, this message translates to:
  /// **'Hoàn thành một ván bất kỳ'**
  String get achFirstGameDesc;

  /// No description provided for @achBeatAi.
  ///
  /// In vi, this message translates to:
  /// **'Khắc chế cỗ máy'**
  String get achBeatAi;

  /// No description provided for @achBeatAiDesc.
  ///
  /// In vi, this message translates to:
  /// **'Thắng một ván có AI'**
  String get achBeatAiDesc;

  /// No description provided for @achBeatHard.
  ///
  /// In vi, this message translates to:
  /// **'Cao thủ'**
  String get achBeatHard;

  /// No description provided for @achBeatHardDesc.
  ///
  /// In vi, this message translates to:
  /// **'Thắng AI mức Khó'**
  String get achBeatHardDesc;

  /// No description provided for @achQuanHunter.
  ///
  /// In vi, this message translates to:
  /// **'Thợ săn quan'**
  String get achQuanHunter;

  /// No description provided for @achQuanHunterDesc.
  ///
  /// In vi, this message translates to:
  /// **'Ăn 2 quan trong một ván'**
  String get achQuanHunterDesc;

  /// No description provided for @achHighScore.
  ///
  /// In vi, this message translates to:
  /// **'Đại phú'**
  String get achHighScore;

  /// No description provided for @achHighScoreDesc.
  ///
  /// In vi, this message translates to:
  /// **'Đạt từ 40 điểm trong một ván'**
  String get achHighScoreDesc;

  /// No description provided for @achAllBoards.
  ///
  /// In vi, this message translates to:
  /// **'Du ngoạn ba bàn'**
  String get achAllBoards;

  /// No description provided for @achAllBoardsDesc.
  ///
  /// In vi, this message translates to:
  /// **'Chơi đủ bàn 2, 3 và 4 người'**
  String get achAllBoardsDesc;

  /// No description provided for @onlineTitle.
  ///
  /// In vi, this message translates to:
  /// **'Phòng online'**
  String get onlineTitle;

  /// No description provided for @onlineNotice.
  ///
  /// In vi, this message translates to:
  /// **'Chế độ online cần server xác thực (authoritative). Bản này mới có hợp đồng API và server giả lập chạy trong máy để kiểm thử — chưa kết nối mạng thật.'**
  String get onlineNotice;

  /// No description provided for @createRoom.
  ///
  /// In vi, this message translates to:
  /// **'Tạo phòng'**
  String get createRoom;

  /// No description provided for @joinRoom.
  ///
  /// In vi, this message translates to:
  /// **'Vào phòng'**
  String get joinRoom;

  /// No description provided for @roomCode.
  ///
  /// In vi, this message translates to:
  /// **'Mã phòng'**
  String get roomCode;

  /// No description provided for @roomCreated.
  ///
  /// In vi, this message translates to:
  /// **'Đã tạo phòng {code} (giả lập cục bộ)'**
  String roomCreated(String code);

  /// No description provided for @roomJoined.
  ///
  /// In vi, this message translates to:
  /// **'Đã vào phòng {code} (giả lập cục bộ)'**
  String roomJoined(String code);

  /// No description provided for @roomNotFound.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy phòng'**
  String get roomNotFound;

  /// No description provided for @waitingPlayers.
  ///
  /// In vi, this message translates to:
  /// **'Đang chờ người chơi: {joined}/{total}'**
  String waitingPlayers(int joined, int total);

  /// No description provided for @onlineUnavailable.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có server thật — không thể bắt đầu ván online.'**
  String get onlineUnavailable;

  /// No description provided for @noSavedGame.
  ///
  /// In vi, this message translates to:
  /// **'Không có ván đã lưu'**
  String get noSavedGame;

  /// No description provided for @confirmExit.
  ///
  /// In vi, this message translates to:
  /// **'Thoát ván? Ván sẽ được lưu để chơi tiếp.'**
  String get confirmExit;

  /// No description provided for @cancel.
  ///
  /// In vi, this message translates to:
  /// **'Hủy'**
  String get cancel;

  /// No description provided for @ok.
  ///
  /// In vi, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @moveNumber.
  ///
  /// In vi, this message translates to:
  /// **'Nước {n}'**
  String moveNumber(int n);

  /// No description provided for @currentRules.
  ///
  /// In vi, this message translates to:
  /// **'Luật hiện hành (multi_v1)'**
  String get currentRules;

  /// No description provided for @rulesSummary.
  ///
  /// In vi, this message translates to:
  /// **'• Chọn ô dân của mình, chọn hướng, rải 1 dân/ô.\n• Ô kế tiếp có dân → bốc rải tiếp; gặp ô quan → mất lượt.\n• Một ô trống rồi ô có quân → ăn, có thể ăn chuỗi; 2 ô trống liền → mất lượt.\n• Quan non (ô quan < 5 dân) không được ăn.\n• Hết dân: lấy 5 dân đã ăn rải lại; thiếu thì vay, trả khi tính điểm.\n• Hết quan và dân ở các ô quan → kết thúc; dân bên nào về bên đó. 1 quan = 10 dân.'**
  String get rulesSummary;

  /// No description provided for @addSimulatedClient.
  ///
  /// In vi, this message translates to:
  /// **'+ Thêm client giả lập'**
  String get addSimulatedClient;

  /// No description provided for @borrowMsg.
  ///
  /// In vi, this message translates to:
  /// **'{name} hết dân, không đủ 5 dân — vay {count} dân để rải lại (trả khi tính điểm)'**
  String borrowMsg(String name, int count);

  /// No description provided for @repayMsg.
  ///
  /// In vi, this message translates to:
  /// **'{name} trả {count} dân đã vay'**
  String repayMsg(String name, int count);

  /// No description provided for @settingsBoardStyle.
  ///
  /// In vi, this message translates to:
  /// **'Mặt sân & nét vẽ'**
  String get settingsBoardStyle;

  /// No description provided for @styleRandom.
  ///
  /// In vi, this message translates to:
  /// **'Ngẫu nhiên mỗi ván'**
  String get styleRandom;

  /// No description provided for @style_dirt_stick.
  ///
  /// In vi, this message translates to:
  /// **'Sân đất · que vạch'**
  String get style_dirt_stick;

  /// No description provided for @style_concrete_chalk.
  ///
  /// In vi, this message translates to:
  /// **'Xi măng · phấn trắng'**
  String get style_concrete_chalk;

  /// No description provided for @style_tiles_chalk.
  ///
  /// In vi, this message translates to:
  /// **'Sân gạch bát · phấn'**
  String get style_tiles_chalk;

  /// No description provided for @style_concrete_brick.
  ///
  /// In vi, this message translates to:
  /// **'Xi măng · gạch non'**
  String get style_concrete_brick;

  /// No description provided for @style_concrete_charcoal.
  ///
  /// In vi, this message translates to:
  /// **'Xi măng · than củi'**
  String get style_concrete_charcoal;

  /// No description provided for @yourTurn.
  ///
  /// In vi, this message translates to:
  /// **'Tới lượt'**
  String get yourTurn;

  /// No description provided for @thinkingShort.
  ///
  /// In vi, this message translates to:
  /// **'Đang nghĩ…'**
  String get thinkingShort;

  /// No description provided for @eliminatedShort.
  ///
  /// In vi, this message translates to:
  /// **'Bị loại'**
  String get eliminatedShort;

  /// No description provided for @chooseLevel.
  ///
  /// In vi, this message translates to:
  /// **'Độ khó'**
  String get chooseLevel;

  /// No description provided for @playerNames.
  ///
  /// In vi, this message translates to:
  /// **'Tên người chơi'**
  String get playerNames;

  /// No description provided for @you.
  ///
  /// In vi, this message translates to:
  /// **'Bạn'**
  String get you;

  /// No description provided for @aiEasyDesc.
  ///
  /// In vi, this message translates to:
  /// **'Máy hay đi ngẫu nhiên'**
  String get aiEasyDesc;

  /// No description provided for @aiMediumDesc.
  ///
  /// In vi, this message translates to:
  /// **'Tính trước vài nước'**
  String get aiMediumDesc;

  /// No description provided for @aiHardDesc.
  ///
  /// In vi, this message translates to:
  /// **'Tính sâu, khó thắng'**
  String get aiHardDesc;

  /// No description provided for @shuffleGround.
  ///
  /// In vi, this message translates to:
  /// **'Đổi mặt sân'**
  String get shuffleGround;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
