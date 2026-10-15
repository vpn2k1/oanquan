// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appTitle => 'Ô Quan Việt';

  @override
  String get appSubtitle => 'Đấu Trí Dân Gian';

  @override
  String get playNow => 'Chơi ngay';

  @override
  String get continueGame => 'Tiếp tục ván';

  @override
  String get tutorial => 'Hướng dẫn';

  @override
  String get achievements => 'Thành tích';

  @override
  String get settings => 'Cài đặt';

  @override
  String get back => 'Quay lại';

  @override
  String playersCount(int count) {
    return '$count người';
  }

  @override
  String get choosePlayers => 'Số người chơi';

  @override
  String get boardRectangle => 'Bàn chữ nhật';

  @override
  String get boardTriangle => 'Bàn tam giác';

  @override
  String get boardSquare => 'Bàn vuông';

  @override
  String get chooseMode => 'Chế độ';

  @override
  String get modeLocal => 'Cùng máy';

  @override
  String get modeAi => 'Đấu AI';

  @override
  String get modeOnline => 'Online';

  @override
  String get playersSetup => 'Người chơi';

  @override
  String get human => 'Người';

  @override
  String get ai => 'AI';

  @override
  String get aiEasy => 'Dễ';

  @override
  String get aiMedium => 'Vừa';

  @override
  String get aiHard => 'Khó';

  @override
  String get startGame => 'Bắt đầu';

  @override
  String defaultPlayerName(int n) {
    return 'Người $n';
  }

  @override
  String aiPlayerName(int n) {
    return 'Máy $n';
  }

  @override
  String turnOf(String name) {
    return 'Lượt: $name';
  }

  @override
  String get hintSelectCell => 'Chạm vào một ô sáng bên bạn để chọn';

  @override
  String get hintSelectDirection => 'Chọn hướng rải bằng mũi tên';

  @override
  String aiThinking(String name) {
    return '$name đang suy nghĩ…';
  }

  @override
  String get animating => 'Đang rải quân… (chạm để tua nhanh)';

  @override
  String get skip => 'Bỏ qua';

  @override
  String get undo => 'Đi lại';

  @override
  String get hint => 'Gợi ý';

  @override
  String get rules => 'Luật';

  @override
  String get pause => 'Tạm dừng';

  @override
  String get resume => 'Tiếp tục';

  @override
  String get saveAndExit => 'Lưu & thoát';

  @override
  String get restart => 'Chơi lại';

  @override
  String get home => 'Trang chủ';

  @override
  String get soundOn => 'Bật âm thanh';

  @override
  String get soundOff => 'Tắt âm thanh';

  @override
  String get score => 'Điểm';

  @override
  String get eliminated => 'Bị loại';

  @override
  String get danShort => 'dân';

  @override
  String get quanShort => 'quan';

  @override
  String get gameOver => 'Kết thúc ván';

  @override
  String winner(String name) {
    return '$name thắng!';
  }

  @override
  String get draw => 'Hòa — đồng hạng nhất';

  @override
  String rank(int n) {
    return 'Hạng $n';
  }

  @override
  String get endAllQuan => 'Tất cả quan đã bị ăn';

  @override
  String get endLastStanding => 'Chỉ còn một người trong cuộc';

  @override
  String get endMoveLimit => 'Đạt giới hạn số nước (luật chống bế tắc)';

  @override
  String get playAgain => 'Chơi lại';

  @override
  String refillMsg(String name) {
    return '$name hết dân — lấy 5 dân đã ăn rải lại mỗi ô 1 dân';
  }

  @override
  String eliminateMsg(String name) {
    return '$name hết dân và không vay được — bị loại';
  }

  @override
  String get loopGuardMsg => 'Phát hiện vòng lặp — kết thúc lượt';

  @override
  String get settingsSound => 'Âm thanh';

  @override
  String get settingsHaptics => 'Rung phản hồi';

  @override
  String get settingsAnimSpeed => 'Tốc độ animation';

  @override
  String get speedSlow => 'Chậm';

  @override
  String get speedNormal => 'Vừa';

  @override
  String get speedFast => 'Nhanh';

  @override
  String get settingsReducedMotion => 'Giảm chuyển động';

  @override
  String get settingsReducedMotionDesc =>
      'Bỏ hiệu ứng bay, cập nhật bàn tức thì';

  @override
  String get settingsColorBlind => 'Hỗ trợ khó phân biệt màu';

  @override
  String get settingsColorBlindDesc =>
      'Thêm biểu tượng hình dạng cho mỗi người chơi';

  @override
  String get settingsTheme => 'Giao diện';

  @override
  String get themeSystem => 'Theo hệ thống';

  @override
  String get themeLight => 'Sáng';

  @override
  String get themeDark => 'Tối';

  @override
  String get settingsLanguage => 'Ngôn ngữ';

  @override
  String get rulesetNote =>
      'Luật theo Ô ăn quan dân gian (2 người); bản 3–4 người mở rộng cùng luật trên bàn tam giác/vuông.';

  @override
  String get tutorialTitle => 'Cách chơi';

  @override
  String get tutStep1Title => 'Bàn và quân';

  @override
  String get tutStep1 =>
      'Mỗi người sở hữu 5 ô dân trên cạnh của mình, mỗi ô có 5 dân. Ô quan ở các góc là ô chung, mỗi ô có 1 quan (10 điểm).';

  @override
  String get tutStep2Title => 'Chọn ô và hướng';

  @override
  String get tutStep2 =>
      'Đến lượt, chọn một ô dân của bạn còn dân, rồi chọn chiều kim đồng hồ hoặc ngược lại. Không được chọn ô quan.';

  @override
  String get tutStep3Title => 'Rải dân';

  @override
  String get tutStep3 =>
      'Nhấc hết dân trong ô, rải mỗi ô kế tiếp 1 dân (kể cả ô quan). Hết dân trên tay: nếu ô kế tiếp là ô dân còn dân thì bốc lên rải tiếp; gặp ô quan thì dừng.';

  @override
  String get tutStep4Title => 'Ăn quân';

  @override
  String get tutStep4 =>
      'Nếu ô kế tiếp trống, bạn ăn toàn bộ dân ở ô ngay sau. Sau đó nếu lại có một ô trống rồi một ô có quân thì ăn chuỗi tiếp. Không ăn qua 2 ô trống liền.';

  @override
  String get tutStep5Title => 'Ăn quan';

  @override
  String get tutStep5 =>
      'Ô quan còn quan chỉ được ăn khi có từ 5 dân trở lên. Ít hơn là \"quan non\": không được ăn, bạn mất lượt.';

  @override
  String get tutStep6Title => 'Hết dân và kết thúc';

  @override
  String get tutStep6 =>
      'Đầu lượt nếu 5 ô của bạn đều trống: lấy 5 dân đã ăn rải lại mỗi ô 1 dân; không đủ thì vay đối thủ, trả khi tính điểm. Ván kết thúc khi cả hai ô quan hết sạch dân và quan; dân còn trên các ô bên nào thuộc về người bên đó. 1 quan = 10 dân, nhiều dân nhất thắng.';

  @override
  String get tutKeyboard =>
      'Bàn phím: ←/→ chọn ô, Z = ngược chiều kim đồng hồ, X = theo chiều kim đồng hồ, Esc = hủy.';

  @override
  String get tutTryIt => 'Chơi thử với AI dễ';

  @override
  String get next => 'Tiếp';

  @override
  String get previous => 'Trước';

  @override
  String get statsTitle => 'Thống kê';

  @override
  String get statsPlayed => 'Ván đã chơi';

  @override
  String get statsWinsVsAi => 'Thắng AI';

  @override
  String get statsBestScore => 'Điểm cao nhất';

  @override
  String get statsQuanTotal => 'Tổng quan đã ăn';

  @override
  String get achFirstGame => 'Ván đầu tiên';

  @override
  String get achFirstGameDesc => 'Hoàn thành một ván bất kỳ';

  @override
  String get achBeatAi => 'Khắc chế cỗ máy';

  @override
  String get achBeatAiDesc => 'Thắng một ván có AI';

  @override
  String get achBeatHard => 'Cao thủ';

  @override
  String get achBeatHardDesc => 'Thắng AI mức Khó';

  @override
  String get achQuanHunter => 'Thợ săn quan';

  @override
  String get achQuanHunterDesc => 'Ăn 2 quan trong một ván';

  @override
  String get achHighScore => 'Đại phú';

  @override
  String get achHighScoreDesc => 'Đạt từ 40 điểm trong một ván';

  @override
  String get achAllBoards => 'Du ngoạn ba bàn';

  @override
  String get achAllBoardsDesc => 'Chơi đủ bàn 2, 3 và 4 người';

  @override
  String get onlineTitle => 'Phòng online';

  @override
  String get onlineNotice =>
      'Chế độ online cần server xác thực (authoritative). Bản này mới có hợp đồng API và server giả lập chạy trong máy để kiểm thử — chưa kết nối mạng thật.';

  @override
  String get createRoom => 'Tạo phòng';

  @override
  String get joinRoom => 'Vào phòng';

  @override
  String get roomCode => 'Mã phòng';

  @override
  String roomCreated(String code) {
    return 'Đã tạo phòng $code (giả lập cục bộ)';
  }

  @override
  String roomJoined(String code) {
    return 'Đã vào phòng $code (giả lập cục bộ)';
  }

  @override
  String get roomNotFound => 'Không tìm thấy phòng';

  @override
  String waitingPlayers(int joined, int total) {
    return 'Đang chờ người chơi: $joined/$total';
  }

  @override
  String get onlineUnavailable =>
      'Chưa có server thật — không thể bắt đầu ván online.';

  @override
  String get noSavedGame => 'Không có ván đã lưu';

  @override
  String get confirmExit => 'Thoát ván? Ván sẽ được lưu để chơi tiếp.';

  @override
  String get cancel => 'Hủy';

  @override
  String get ok => 'OK';

  @override
  String moveNumber(int n) {
    return 'Nước $n';
  }

  @override
  String get currentRules => 'Luật hiện hành (multi_v1)';

  @override
  String get rulesSummary =>
      '• Chọn ô dân của mình, chọn hướng, rải 1 dân/ô.\n• Ô kế tiếp có dân → bốc rải tiếp; gặp ô quan → mất lượt.\n• Một ô trống rồi ô có quân → ăn, có thể ăn chuỗi; 2 ô trống liền → mất lượt.\n• Quan non (ô quan < 5 dân) không được ăn.\n• Hết dân: lấy 5 dân đã ăn rải lại; thiếu thì vay, trả khi tính điểm.\n• Hết quan và dân ở các ô quan → kết thúc; dân bên nào về bên đó. 1 quan = 10 dân.';

  @override
  String get addSimulatedClient => '+ Thêm client giả lập';

  @override
  String borrowMsg(String name, int count) {
    return '$name hết dân, không đủ 5 dân — vay $count dân để rải lại (trả khi tính điểm)';
  }

  @override
  String repayMsg(String name, int count) {
    return '$name trả $count dân đã vay';
  }

  @override
  String get settingsBoardStyle => 'Mặt sân & nét vẽ';

  @override
  String get styleRandom => 'Ngẫu nhiên mỗi ván';

  @override
  String get style_dirt_stick => 'Sân đất · que vạch';

  @override
  String get style_concrete_chalk => 'Xi măng · phấn trắng';

  @override
  String get style_tiles_chalk => 'Sân gạch bát · phấn';

  @override
  String get style_concrete_brick => 'Xi măng · gạch non';

  @override
  String get style_concrete_charcoal => 'Xi măng · than củi';

  @override
  String get yourTurn => 'Tới lượt';

  @override
  String get thinkingShort => 'Đang nghĩ…';

  @override
  String get eliminatedShort => 'Bị loại';
}
