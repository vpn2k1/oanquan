# Ô Quan Việt — Đấu Trí Dân Gian

Game Ô ăn quan 2–4 người viết bằng **Flutter + Dart + Flame**, chạy được trên Android, iOS và Web.
Bàn 2 người hình chữ nhật, 3 người hình tam giác đều, 4 người hình vuông. Cả ba dùng chung một
engine theo **vòng ô có thứ tự**.

> Bộ luật `multi_v1` là **biến thể do dự án định nghĩa** cho 2–4 người, không phải luật dân gian
> thống nhất. Muốn đổi luật thì phải cập nhật test và spec trước.

## Chạy

```bash
flutter pub get
flutter test
flutter run -d chrome
```

- Android: `flutter run -d <android-device>` hoặc `flutter build apk --debug`
- iOS (cần Xcode): `flutter run -d <ios-simulator>`
- Web release: `flutter build web -o build/web`. Máy dev này có `build-dir` toàn cục, nên cần truyền `-o`.
- Kiểm tra tĩnh: `flutter analyze`

Nếu sửa file `lib/l10n/*.arb` thì chạy `flutter gen-l10n`. Lệnh `flutter run` và `flutter build` cũng tự sinh lại.

## Kiến trúc

```
lib/
  main.dart                 ProviderScope + SharedPreferences
  app/                      theme, router (go_router), widget dùng chung
  core/                     ← Dart thuần, KHÔNG import Flutter/Flame
    game_models/            Cell, Player, GameConfig/RulesetConfig, Move, GameState, GameEvent
    engine/                 RulesEngine (getLegalMoves/applyMove), BoardTopology, Scoring, Replay
    ai/                     Minimax + alpha-beta (2p), Max-N (3/4p), Evaluation
    persistence/            GameSerializer (JSON, schemaVersion)
  features/
    splash/ home/ mode_selection/ tutorial/ result/ settings/ achievements/
    game/
      game_session.dart     Riverpod Notifier: nước đi, animation batch, AI (compute), undo, gợi ý, tự lưu
      data/                 SaveRepository (shared_preferences — có hỗ trợ web)
      audio/                SoundService: WAV tổng hợp bằng code, lỗi audio không làm crash game
      flame/                OQuanGame, BoardGeometry, components, PiecesPainter (quân vẽ bằng Canvas)
      ui/                   GameScreen (bàn toàn màn hình + HUD nổi), hud.dart (PlayerChip, StoneIcon, GemIcon)
    multiplayer/            protocol, MatchServer (authoritative), repository, lobby UI
  l10n/                     ARB tiếng Việt (mặc định) và tiếng Anh
test/  engine/ ai/ persistence/ game/ multiplayer/ widgets/
```

- **State:** `flutter_riverpod` 3 (Notifier). **Routing:** `go_router`.
- **Màn hình ngang mặc định:** khóa landscape trên Android (`sensorLandscape`), iOS (`UISupportedInterfaceOrientations`) và trong `main.dart`. Home, Setup, Kết quả, Hướng dẫn có bố cục 2 cột khi ngang.
- **Bàn chơi toàn màn hình:** HUD nổi ở các góc. Thẻ người chơi nằm ở góc gần cạnh của người đó. Dân và quan đã ăn hiển thị bằng hình viên sỏi và viên ngọc kèm số, không dùng chữ. Giao diện mặc định là theme sáng, tông tươi.
- Trạng thái logic và trạng thái hiển thị được tách riêng. Engine tính ra trạng thái cuối cùng cùng
  danh sách event. Flame phát lại các event đó thành animation (bốc, rải từng viên theo đường cong,
  ăn dân, ăn quan, nạp dân). Input bị khóa trong lúc animation chạy. Chạm vào bàn để tua nhanh,
  hoặc bấm nút "Bỏ qua".
- AI chạy qua `compute` (isolate trên mobile/desktop) và có giới hạn thời gian (Easy 60 ms,
  Medium 200 ms, Hard 450 ms). Nếu lỗi thì AI trả về một nước hợp lệ.
- Lưu ván gồm trạng thái ban đầu và trạng thái hiện tại. Undo phát lại ván từ đầu với danh sách
  nước đi bỏ đi các nước sau lần đi gần nhất của người thật.

### Vòng ô

`N` người, `K = 5`. Vòng gồm `N*(K+1)` ô: `Q0, P0C0..P0C4, Q1, P1C0..`. Chỉ số tăng theo chiều kim
đồng hồ trên màn hình. Người 0 luôn ngồi ở cạnh dưới. `Qp` là ô góc nằm ngay trước đoạn ô dân của
người `p`.

## Luật `multi_v1` (tóm tắt) và các giả định

Toàn bộ luật nằm trong spec. Engine cài đặt đúng mục 4.1–4.3 của spec. Ba điểm sau spec chưa nói rõ,
nên dự án tự đặt giả định:

| # | Giả định | Lý do |
|---|---|---|
| A1 | Ô quan **đã mất token và còn 0 dân** được coi là **ô trống**, nên có thể làm khe để ăn qua. Ô quan còn dân hoặc còn token thì làm dừng pha rải. | Spec định nghĩa "ô trống" = `danCount == 0 && !hasQuan`. Định nghĩa này chỉ có nghĩa khi ô quan cũng có thể trống. |
| A2 | Nạp dân trừ vào **điểm tổng** (`score ≥ refillCost`). Thống kê dân và quan được hiển thị riêng. | Spec mục 4.2: "Dùng điểm tổng cho MVP". |
| A3 | **Luật chống bế tắc:** ván tự kết thúc khi tổng số nước đạt `maxMovesPerPlayer × N` (mặc định 60 nước mỗi người). Có thể chỉnh trong `RulesetConfig`; đặt 0 để tắt. | Khi mô phỏng ngẫu nhiên, khoảng 1% ván 4 người lặp vô hạn: người chơi nạp dân, rồi bị ăn lại, nhưng không ai ăn được quan cuối cùng. |

Các điểm khác:
- Loop guard: trước mỗi lần bốc, engine băm `{cells, cursor, phase, direction}`. Nếu một trạng thái
  lặp lại, hoặc số bước vượt chốt an toàn, engine phát `RuleLoopGuard` và kết thúc lượt.
- Ván kết thúc khi hết token quan, khi chỉ còn ≤ 1 người active, hoặc theo A3. Dân còn trên bàn
  không được cộng điểm. Đồng điểm thì đồng hạng.
- `rulesetConfig` cho phép chỉnh `initialDan`, `quanValue`, `quanCaptureThreshold`, `refillCost`.
  `RulesetConfig.isPreset` cho biết ván có dùng preset hay không. Chế độ xếp hạng chưa có.

## Test (78 test)

| Nhóm | Nội dung |
|---|---|
| `test/engine` | Fixture trong spec (2p/3p/4p initial, invalidMove, captureOne, captureQuanThreshold 4 so với 5, refill, skipEliminated), wrap modulo hai chiều, ăn chuỗi, không ăn qua 2 ô trống, game over, hòa, loop guard. Thêm 180 ván ngẫu nhiên có seed để kiểm tra bảo toàn dân/quan và replay. |
| `test/ai` | Bot luôn đi nước hợp lệ ở 2/3/4 người với mọi mức. Kiểm tra time budget, tính tất định theo seed, Medium thắng bot ngẫu nhiên ≥ 70%. |
| `test/persistence` | Round-trip JSON cho state, save, event. Từ chối `schemaVersion` lạ. Giới hạn số nước. |
| `test/game` | Controller: khóa input khi animation, tự lưu, undo, khôi phục, AI tự đi, ghi thống kê. |
| `test/multiplayer` | Server authoritative: sai ghế, sai lượt, revision cũ, idempotency theo `actionId`, reconnect cần token, chơi hết ván qua server. |
| `test/widgets` | Geometry ở viewport mobile, tablet và desktop: không đè ô, đúng chiều kim đồng hồ, Q nằm ở góc, vùng chạm ≥ 44 px. Luồng app Home → Setup → Game → một nước đi cho 2/3/4 người trên 3 kích thước màn hình. Tutorial, cài đặt, đổi ngôn ngữ, thành tích. |

## Online (Milestone D — mới là hợp đồng API, **chưa có mạng thật**)

- `protocol.dart` định nghĩa `CreateRoom`, `JoinRoom`, `SubmitMove`, `PlayerReconnect`,
  `StateSnapshot`, `MoveAccepted`, `MoveRejected`, `GameEnded`. Các message có `matchId`,
  `revision`, `playerId`, `actionId`.
- `MatchServer` là server có thẩm quyền, viết bằng Dart thuần. Nó kiểm tra nước đi bằng engine,
  tăng revision, xử lý idempotent theo `actionId` và cấp session token cho mỗi ghế. Client không tự
  tính điểm.
- `LocalFakeMultiplayerRepository` gửi message qua JSON tới một `MatchServer` chạy cùng tiến trình.
  Lobby UI dùng nó để tạo phòng, vào phòng và thêm client giả lập.
- **Chưa làm:** server WebSocket thật (có thể bọc `MatchServer` bằng `shelf_web_socket`), tài khoản
  (Supabase Auth), lưu thống kê online, xếp trận, bảng xếp hạng, chơi online thực sự trên GameScreen.

## Đã biết / TODO

- Âm thanh là WAV tổng hợp, phát qua `audioplayers`. Nếu nền tảng không phát được thì game im lặng
  và không báo lỗi. Trên web, trình duyệt chỉ cho phát sau lần chạm đầu tiên.
- Trên web, `compute` chạy AI ngay trên main thread. Mức Hard có thể chặn UI tới khoảng 450 ms.
- Bàn tam giác trên điện thoại dọc 360 px có ô khoảng 35 px. Vùng chạm vẫn ≥ 44 px, nhưng chưa có
  zoom/pan.
- Chế độ 2v2 mới có `Scoring.teamScores`. Chưa có UI và chưa có test riêng cho điều kiện kết thúc.
- Chưa có `integration_test/` chạy trên thiết bị thật. Mới có widget test và kiểm tra thủ công trên
  bản build web.
