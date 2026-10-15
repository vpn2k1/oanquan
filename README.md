# Ô Quan Việt — Đấu Trí Dân Gian

Game Ô ăn quan 2–4 người viết bằng **Flutter + Dart + Flame**, chạy được trên Android, iOS và Web.
Bàn 2 người hình chữ nhật, 3 người hình tam giác đều, 4 người hình vuông. Cả ba dùng chung một
engine theo **vòng ô có thứ tự**.

> Luật theo **Ô ăn quan dân gian** ([Wikipedia](https://vi.wikipedia.org/wiki/%C3%94_%C4%83n_quan)) cho
> 2 người; bàn 3–4 người áp dụng cùng luật trên vòng ô dài hơn. Preset vẫn có id `multi_v1`.

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
- **Giao diện tham khảo Recess (rachoi.app):** tông tối ấm mặc định (nền `#1B1410` lưới chấm, thẻ `#2D2621` viền kem 20%, chữ `#FFF3E2`, nhấn cam `#FF8F3A`), có bản sáng tương ứng; token trong `Rc`/`RcTokens` (`lib/app/theme.dart`). Bàn đặt trong khay bo góc; quân là sỏi tự nhiên, quan là đá nâu lớn; số đếm chữ kem nhỏ ở góc ô. Quân ăn được bay vào **đống quân trên khay** (bàn 2 người: ngoài mép bàn phía người ăn; bàn 3–4 người: phần trống trong lòng bàn sát cạnh mình), quan nằm đầu hàng, số điểm ở cuối hàng. Nhịp rải nhanh hơn (Vừa ≈ 0,12 s/viên); nút **Chậm/Vừa/Nhanh** trên HUD. Màn chơi: ngang → bảng phải (nút, thẻ người chơi, Gợi ý/Đi lại); dọc → đối thủ trên, mình dưới.
- **Mặt sân dân dã, bàn kẻ tay** (`lib/app/folk_art.dart`, vẽ thủ tục bằng Canvas, không dùng ảnh): 3 mặt sân (đất, xi măng, sân gạch bát) × nét vẽ (que vạch đất, phấn, gạch non, than củi) → 5 kiểu. Mặc định **ngẫu nhiên mỗi ván** theo seed ván; chọn cố định trong Cài đặt → "Mặt sân & nét vẽ". Nét run tay bằng nhiễu mượt, đứt phấn, bụi/vụn đất; mặt sân + bàn được raster hóa một lần thành ảnh nên không tốn chi phí mỗi frame.
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

## Luật (theo luật dân gian)

1. Mỗi người 5 ô dân × 5 dân; mỗi ô quan có 1 quan (= 10 dân). Không được bốc từ ô quan.
2. Rải mỗi ô 1 dân (kể cả ô quan) theo chiều tự chọn. Hết dân trên tay:
   - ô kế tiếp là ô dân còn dân → bốc rải tiếp;
   - ô kế tiếp là ô quan còn quân → **mất lượt**;
   - ô kế tiếp trống rồi một ô có quân → **ăn** ô đó, rồi ăn chuỗi nếu lại "trống – có quân";
   - 2 ô trống liền → mất lượt.
3. **Quan non:** ô quan còn quan nhưng có ít hơn 5 dân thì **không được ăn** (kể cả dân trong ô); gặp quan non là mất lượt.
   Ô quan đã bị ăn mất quan: còn dân thì ăn như ô thường, hết dân thì là ô trống.
4. **Hết dân:** đầu lượt, nếu 5 ô của mình đều trống thì lấy 5 dân đã ăn rải lại mỗi ô 1 dân. Không đủ
   thì **vay** người chơi khác (ưu tiên người nhiều điểm nhất) và **trả khi tính điểm**.
5. **Kết thúc:** khi **cả hai ô quan hết sạch quan và dân**. Dân còn trên các ô bên nào thì thuộc về người
   bên đó. Sau đó trả nợ. Nhiều dân nhất (1 quan = 10 dân) thắng; bằng điểm thì đồng hạng.

Các điểm dự án tự bổ sung, vì luật dân gian không quy định:

| # | Quy định | Lý do |
|---|---|---|
| B1 | Không vay đủ (người khác cũng không có điểm) → bị loại; còn ≤ 1 người thì kết thúc ván. | Luật 2 người không nói tới trường hợp này. Mô phỏng 600 ván cho thấy hầu như không xảy ra. |
| B2 | Chống bế tắc: ván dừng sau `maxMovesPerPlayer × N` nước (mặc định 60 mỗi người), vẫn thu dân và trả nợ như bình thường. | Mô phỏng: 2 người luôn kết thúc tự nhiên; 3–4 người khoảng 2–8% ván ngẫu nhiên chạm giới hạn. |
| B3 | Dân nằm trong ô quan khi ván dừng theo B1/B2 không thuộc về ai. | Ô quan là ô chung. |
| B4 | Chốt chống lặp trong một lượt (`RuleLoopGuard`). | An toàn kỹ thuật. |

## Test (84 test)

| Nhóm | Nội dung |
|---|---|
| `test/engine` | Fixture (2p/3p/4p initial, invalidMove, captureOne, ăn quan 5 dân, quan non 4 dân, rải lại, vay/trả nợ, thu dân cuối ván, ô quan còn dân chưa kết thúc, loại khi không vay được), wrap modulo hai chiều, ăn chuỗi, không ăn qua 2 ô trống, game over, hòa, loop guard. Thêm 180 ván ngẫu nhiên có seed để kiểm tra bảo toàn dân/quan và replay. |
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
