#!/usr/bin/env python3
"""Nguồn câu chữ duy nhất của app: key → (tiếng Việt, tiếng Anh).

Sinh ra:
  lib/l10n/app_vi.arb, lib/l10n/app_en.arb  (ARB chuẩn)
  lib/l10n/strings.dart                     (lớp Strings tĩnh)

Sau đó chạy `flutter gen-l10n` để sinh AppLocalizations.
    python3 tool/gen_arb.py && flutter gen-l10n
"""
import json
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, 'lib', 'l10n')

# Biến dùng {tên}; script tự khai báo placeholder trong ARB.
S = {
 'appTitle': ('Ô Quan Việt', 'O Quan Viet'),
 'appSubtitle': ('Đấu Trí Dân Gian', 'A Folk Strategy Duel'),
 'playNow': ('Chơi ngay', 'Play now'),
 'continueGame': ('Tiếp tục ván', 'Continue game'),
 'tutorial': ('Hướng dẫn', 'How to play'),
 'achievements': ('Thành tích', 'Achievements'),
 'settings': ('Cài đặt', 'Settings'),
 'back': ('Quay lại', 'Back'),
 'playersCount': ('{count} người', '{count} players'),
 'choosePlayers': ('Số người chơi', 'Players'),
 'boardRectangle': ('Bàn chữ nhật', 'Rectangle board'),
 'boardTriangle': ('Bàn tam giác', 'Triangle board'),
 'boardSquare': ('Bàn vuông', 'Square board'),
 'chooseMode': ('Chế độ', 'Mode'),
 'modeLocal': ('Chơi với bạn', 'With a friend'),
 'modeAi': ('Đấu máy', 'Vs computer'),
 'modeOnline': ('Online', 'Online'),
 'playersSetup': ('Người chơi', 'Players'),
 'human': ('Người', 'Human'),
 'ai': ('AI', 'AI'),
 'startGame': ('Bắt đầu', 'Start'),
 'defaultPlayerName': ('Người {n}', 'Player {n}'),
 'aiPlayerName': ('Máy {n}', 'Bot {n}'),
 'turnOf': ('Lượt: {name}', 'Turn: {name}'),
 'hintSelectCell': ('Chạm vào một ô sáng bên bạn để chọn', 'Tap one of your glowing pits'),
 'hintSelectDirection': ('Chọn hướng rải bằng mũi tên', 'Pick a sowing direction'),
 'aiThinking': ('{name} đang suy nghĩ…', '{name} is thinking…'),
 'animating': ('Đang rải quân…', 'Sowing…'),
 'undo': ('Đi lại', 'Undo'),
 'hint': ('Gợi ý', 'Hint'),
 'rules': ('Luật', 'Rules'),
 'pause': ('Tạm dừng', 'Pause'),
 'resume': ('Tiếp tục', 'Resume'),
 'saveAndExit': ('Lưu & thoát', 'Save & exit'),
 'restart': ('Chơi lại', 'Restart'),
 'home': ('Trang chủ', 'Home'),
 'soundOn': ('Bật âm thanh', 'Sound on'),
 'soundOff': ('Tắt âm thanh', 'Sound off'),
 'score': ('Điểm', 'Score'),
 'eliminated': ('Bị loại', 'Eliminated'),
 'danShort': ('dân', 'seeds'),
 'quanShort': ('quan', 'mandarins'),
 'gameOver': ('Kết thúc ván', 'Game over'),
 'winner': ('{name} thắng!', '{name} wins!'),
 'draw': ('Hòa — đồng hạng nhất', 'Draw — shared first place'),
 'rank': ('Hạng {n}', 'Rank {n}'),
 'endAllQuan': ('Tất cả quan đã bị ăn', 'All mandarins captured'),
 'endLastStanding': ('Chỉ còn một người trong cuộc', 'Only one player left'),
 'endMoveLimit': ('Đạt giới hạn số nước (luật chống bế tắc)', 'Move limit reached (anti-stall rule)'),
 'playAgain': ('Chơi lại', 'Play again'),
 'refillMsg': ('{name} hết dân — lấy 5 dân đã ăn rải lại mỗi ô 1 dân', '{name} ran out — puts 5 captured seeds back, one per pit'),
 'eliminateMsg': ('{name} hết dân và không vay được — bị loại', '{name} ran out and cannot borrow — eliminated'),
 'loopGuardMsg': ('Phát hiện vòng lặp — kết thúc lượt', 'Loop detected — turn ended'),
 'settingsSound': ('Âm thanh', 'Sound'),
 'settingsHaptics': ('Rung phản hồi', 'Haptic feedback'),
 'settingsReducedMotion': ('Giảm chuyển động', 'Reduce motion'),
 'settingsReducedMotionDesc': ('Bỏ hiệu ứng bay, cập nhật bàn tức thì', 'Skip flying effects, update the board instantly'),
 'settingsColorBlind': ('Hỗ trợ khó phân biệt màu', 'Color-blind assist'),
 'settingsColorBlindDesc': ('Thêm biểu tượng hình dạng cho mỗi người chơi', 'Add shape symbols for each player'),
 'settingsTheme': ('Giao diện', 'Theme'),
 'themeSystem': ('Theo hệ thống', 'System'),
 'themeLight': ('Sáng', 'Light'),
 'themeDark': ('Tối', 'Dark'),
 'settingsLanguage': ('Ngôn ngữ', 'Language'),
 'rulesetNote': ('Luật theo Ô ăn quan dân gian (2 người); bản 3–4 người mở rộng cùng luật trên bàn tam giác/vuông.', 'Rules follow traditional Ô ăn quan (2 players); the 3–4 player boards extend the same rules.'),
 'tutorialTitle': ('Cách chơi', 'How to play'),
 'tutStep1Title': ('Bàn và quân', 'Board and pieces'),
 'tutStep1': ('Mỗi người sở hữu 5 ô dân trên cạnh của mình, mỗi ô có 5 dân. Ô quan ở các góc là ô chung, mỗi ô có 1 quan (10 điểm).', 'Each player owns 5 pits on their side, each with 5 seeds. Mandarin pits at the corners are shared, each holding 1 mandarin (10 points).'),
 'tutStep2Title': ('Chọn ô và hướng', 'Pick a pit and direction'),
 'tutStep2': ('Đến lượt, chọn một ô dân của bạn còn dân, rồi chọn chiều kim đồng hồ hoặc ngược lại. Không được chọn ô quan.', 'On your turn pick one of your pits that has seeds, then sow clockwise or counter-clockwise. Mandarin pits cannot be picked.'),
 'tutStep3Title': ('Rải dân', 'Sowing'),
 'tutStep3': ('Nhấc hết dân trong ô, rải mỗi ô kế tiếp 1 dân (kể cả ô quan). Hết dân trên tay: nếu ô kế tiếp là ô dân còn dân thì bốc lên rải tiếp; gặp ô quan thì dừng.', 'Take all seeds and drop one in each following pit (mandarin pits included). When your hand is empty: if the next pit is a seed pit with seeds, pick them up and keep sowing; a mandarin pit stops you.'),
 'tutStep4Title': ('Ăn quân', 'Capturing'),
 'tutStep4': ('Nếu ô kế tiếp trống, bạn ăn toàn bộ dân ở ô ngay sau. Sau đó nếu lại có một ô trống rồi một ô có quân thì ăn chuỗi tiếp. Không ăn qua 2 ô trống liền.', 'If the next pit is empty, you capture everything in the pit right after it. If another empty pit is followed by a pit with pieces, keep capturing. Never across 2 empty pits.'),
 'tutStep5Title': ('Ăn quan', 'Capturing mandarins'),
 'tutStep5': ('Ô quan còn quan chỉ được ăn khi có từ 5 dân trở lên. Ít hơn là "quan non": không được ăn, bạn mất lượt.', 'A mandarin pit can only be captured when it holds at least 5 seeds. With fewer it is a "young mandarin": no capture, your turn ends.'),
 'tutStep6Title': ('Hết dân và kết thúc', 'Running out and ending'),
 'tutStep6': ('Đầu lượt nếu 5 ô của bạn đều trống: lấy 5 dân đã ăn rải lại mỗi ô 1 dân; không đủ thì vay đối thủ, trả khi tính điểm. Ván kết thúc khi cả hai ô quan hết sạch dân và quan; dân còn trên các ô bên nào thuộc về người bên đó. 1 quan = 10 dân, nhiều dân nhất thắng.', "If all 5 of your pits are empty at the start of your turn, put 5 captured seeds back, one per pit; if you lack them, borrow from opponents and repay at scoring. The game ends when both mandarin pits are completely empty; seeds left in each player's pits go to that player. 1 mandarin = 10 seeds; most seeds wins."),
 'tutKeyboard': ('Bàn phím: ←/→ chọn ô, Z = ngược chiều kim đồng hồ, X = theo chiều kim đồng hồ, Esc = hủy.', 'Keyboard: ←/→ select pit, Z = counter-clockwise, X = clockwise, Esc = cancel.'),
 'tutTryIt': ('Chơi thử với AI dễ', 'Try against easy AI'),
 'next': ('Tiếp', 'Next'),
 'previous': ('Trước', 'Previous'),
 'statsTitle': ('Thống kê', 'Statistics'),
 'statsPlayed': ('Ván đã chơi', 'Games played'),
 'statsWinsVsAi': ('Thắng AI', 'Wins vs AI'),
 'statsBestScore': ('Điểm cao nhất', 'Best score'),
 'statsQuanTotal': ('Tổng quan đã ăn', 'Mandarins captured'),
 'onlineTitle': ('Phòng online', 'Online rooms'),
 'onlineNotice': ('Chế độ online cần server xác thực (authoritative). Bản này mới có hợp đồng API và server giả lập chạy trong máy để kiểm thử — chưa kết nối mạng thật.', 'Online play needs an authoritative server. This build only ships the API contract and an in-process fake server for testing — no real network yet.'),
 'createRoom': ('Tạo phòng', 'Create room'),
 'joinRoom': ('Vào phòng', 'Join room'),
 'roomCode': ('Mã phòng', 'Room code'),
 'roomCreated': ('Đã tạo phòng {code} (giả lập cục bộ)', 'Room {code} created (local simulation)'),
 'roomJoined': ('Đã vào phòng {code} (giả lập cục bộ)', 'Joined room {code} (local simulation)'),
 'roomNotFound': ('Không tìm thấy phòng', 'Room not found'),
 'waitingPlayers': ('Đang chờ người chơi: {joined}/{total}', 'Waiting for players: {joined}/{total}'),
 'onlineUnavailable': ('Chưa có server thật — không thể bắt đầu ván online.', 'No real server yet — online games cannot start.'),
 'noSavedGame': ('Không có ván đã lưu', 'No saved game'),
 'confirmExit': ('Thoát ván? Ván sẽ được lưu để chơi tiếp.', 'Leave the game? It will be saved so you can continue.'),
 'cancel': ('Hủy', 'Cancel'),
 'ok': ('OK', 'OK'),
 'moveNumber': ('Nước {n}', 'Move {n}'),
 'currentRules': ('Luật chơi', 'Rules'),
 'markSrc': ('Ô được chọn', 'Chosen pit'),
 'markGap': ('Ô trống', 'Empty pit'),
 'markEat': ('Bị ăn', 'Captured'),
 'markPick': ('Rải lại 1 dân', 'Refilled with 1 seed'),
 'markStop': ('Dừng lượt', 'Turn ends'),
 'markDirection': ('Hai hướng rải', 'Two sowing directions'),
 'addSimulatedClient': ('+ Thêm client giả lập', '+ Add simulated client'),
 'borrowMsg': ('{name} hết dân, không đủ 5 dân — vay {count} dân để rải lại (trả khi tính điểm)', '{name} ran out and lacks seeds — borrows {count} to refill (repaid at scoring)'),
 'repayMsg': ('{name} trả {count} dân đã vay', '{name} repays {count} borrowed seeds'),
 'settingsBoardStyle': ('Mặt sân & nét vẽ', 'Ground & drawing'),
 'styleRandom': ('Ngẫu nhiên mỗi ván', 'Random each game'),
 'yourTurn': ('Tới lượt', 'Your turn'),
 'thinkingShort': ('Đang nghĩ…', 'Thinking…'),
 'eliminatedShort': ('Bị loại', 'Out'),
 'chooseLevel': ('Độ khó', 'Difficulty'),
 'playerNames': ('Tên người chơi', 'Player names'),
 'you': ('Bạn', 'You'),
 'shuffleGround': ('Đổi mặt sân', 'Change ground'),
 'guestName': ('Khách {n}', 'Guest {n}'),
    # Popup cập nhật phiên bản
    'updateTitle': ('Có bản cập nhật mới', 'Update available'),
    'updateSoftMsg': ('Ô Quan Việt có phiên bản mới với nhiều cải tiến. Cập nhật ngay nhé?', 'A new version of O Quan Viet is available. Update now?'),
    'updateRequiredMsg': ('Phiên bản này đã cũ, vui lòng cập nhật để tiếp tục chơi.', 'This version is no longer supported. Please update to keep playing.'),
    'updateVersionMsg': ('Phiên bản {version} đã có trên cửa hàng với nhiều cải tiến. Cập nhật ngay nhé?', 'Version {version} is now available in the store. Update now?'),
    'updateNow': ('Cập nhật', 'Update'),
    'updateLater': ('Để sau', 'Later'),
}

# Mức AI (enum AiLevel): key `ai` + Tên → (vi, en, mô tả vi, mô tả en).
LEVELS = {
 'easy': ('Dễ', 'Easy', 'Máy hay đi ngẫu nhiên', 'Often plays randomly'),
 'medium': ('Vừa', 'Medium', 'Tính trước vài nước', 'Looks a few moves ahead'),
 'hard': ('Khó', 'Hard', 'Tính sâu, khó thắng', 'Searches deep, tough to beat'),
}

# Thành tích (enum Achievement): key `ach` + Tên (+ `Desc`).
ACHIEVEMENTS = {
 'firstGame': ('Ván đầu tiên', 'First game', 'Hoàn thành một ván bất kỳ', 'Finish any game'),
 'beatAi': ('Khắc chế cỗ máy', 'Machine tamer', 'Thắng một ván có AI', 'Win a game with an AI'),
 'beatHard': ('Cao thủ', 'Grandmaster', 'Thắng AI mức Khó', 'Beat a Hard AI'),
 'quanHunter': ('Thợ săn quan', 'Mandarin hunter', 'Ăn 2 quan trong một ván', 'Capture 2 mandarins in one game'),
 'highScore': ('Đại phú', 'Tycoon', 'Đạt từ 40 điểm trong một ván', 'Score 40+ in one game'),
 'allBoards': ('Du ngoạn ba bàn', 'Board explorer', 'Chơi đủ bàn 2, 3 và 4 người', 'Play on the 2, 3 and 4 player boards'),
}

# Mặt sân + nét vẽ (FolkStyle.id): key `style` + Tên.
STYLES = {
 'dirt_stick': ('Sân đất · que vạch', 'Dirt · stick'),
 'concrete_chalk': ('Xi măng · phấn trắng', 'Concrete · white chalk'),
 'tiles_chalk': ('Sân gạch bát · phấn', 'Brick tiles · chalk'),
 'concrete_brick': ('Xi măng · gạch non', 'Concrete · brick shard'),
 'concrete_charcoal': ('Xi măng · than củi', 'Concrete · charcoal'),
}

# Hàm tên hiển thị trong `L10nLabels` (lib/l10n/l10n.dart), bọc lại vào Strings.
HELPERS = [
 ('String level(AiLevel l)', 'level(l)'),
 ('String levelDesc(AiLevel l)', 'levelDesc(l)'),
 ('String achievement(Achievement a)', 'achievement(a)'),
 ('String achievementDesc(Achievement a)', 'achievementDesc(a)'),
 ('String styleName(String id)', 'styleName(id)'),
]

HELPER_IMPORTS = [
 '../core/game_models/player.dart',
 '../features/achievements/stats_repository.dart',
]


def cap(s):
    return s[0].upper() + s[1:]


def camel(s):
    head, *rest = s.split('_')
    return head + ''.join(cap(p) for p in rest)


for k, (vi, en, dvi, den) in LEVELS.items():
    S['ai' + cap(k)] = (vi, en)
    S['ai' + cap(k) + 'Desc'] = (dvi, den)
for k, (vi, en, dvi, den) in ACHIEVEMENTS.items():
    S['ach' + cap(k)] = (vi, en)
    S['ach' + cap(k) + 'Desc'] = (dvi, den)
for k, v in STYLES.items():
    S['style' + cap(camel(k))] = v

PH = re.compile(r'\{(\w+)\}')


def params(text):
    seen = []
    for p in PH.findall(text):
        if p not in seen:
            seen.append(p)
    return seen


def write_arbs():
    for lang, i in (('vi', 0), ('en', 1)):
        arb = {'@@locale': lang}
        for key, vals in S.items():
            arb[key] = vals[i]
            ps = params(vals[0])
            if lang == 'vi' and ps:
                arb['@' + key] = {'placeholders': {p: {} for p in ps}}
            missing = set(ps) ^ set(params(vals[i]))
            if missing:
                raise SystemExit(f'{key}: placeholder lệch giữa vi/{lang}: {missing}')
        with open(os.path.join(OUT, f'app_{lang}.arb'), 'w', encoding='utf-8') as f:
            json.dump(arb, f, ensure_ascii=False, indent=2)
            f.write('\n')


def write_strings():
    lines = [
        '// GENERATED by tool/gen_arb.py — không sửa tay.',
        '',
        "import 'package:flutter/widgets.dart';",
        '',
    ]
    lines += [f"import '{p}';" for p in HELPER_IMPORTS]
    lines += [
        "import 'app_localizations.dart';",
        "import 'l10n.dart';",
        '',
        '/// Truy cập câu chữ không cần BuildContext. `StringsScope` gọi [use]',
        '/// mỗi khi locale đổi.',
        'abstract final class Strings {',
        "  static AppLocalizations _l = lookupAppLocalizations(const Locale('vi'));",
        '  static void use(AppLocalizations l) => _l = l;',
        '  static AppLocalizations get current => _l;',
        '',
    ]
    for key, (vi, _) in S.items():
        ps = params(vi)
        if ps:
            sig = ', '.join(f'Object {p}' for p in ps)
            lines.append(f'  static String {key}({sig}) => _l.{key}({", ".join(ps)});')
        else:
            lines.append(f'  static String get {key} => _l.{key};')
    lines.append('')
    for sig, call in HELPERS:
        lines.append(f'  static {sig} => _l.{call};')
    lines.append('}')
    with open(os.path.join(OUT, 'strings.dart'), 'w', encoding='utf-8') as f:
        f.write('\n'.join(lines) + '\n')


if __name__ == '__main__':
    write_arbs()
    write_strings()
    print(f'{len(S)} keys → app_vi.arb, app_en.arb, strings.dart')
