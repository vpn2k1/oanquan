# Tech stack và thư viện

Tài liệu này liệt kê stack nền của dự án Ô Quan Việt: thư viện nào dùng cho việc gì, lệnh cài đặt, và các lưu ý khi thêm thư viện mới.

Phiên bản ràng buộc nằm trong [pubspec.yaml](../pubspec.yaml). Khi cài mới, dùng `flutter pub add` để lấy bản tương thích với SDK (`^3.12.2`).

## 1. Nền tảng

| Hạng mục | Công nghệ |
| --- | --- |
| Framework | Flutter (Dart `^3.12.2`) |
| Game engine | Flame (`flame`) |
| Nền tảng đích | Android, iOS (thư mục `web/` có sẵn nhưng chưa phải mục tiêu chính) |

## 2. Thư viện đang dùng

### 2.1 Giao diện và bố cục

| Thư viện | Vai trò |
| --- | --- |
| `flutter_screenutil` | Co giãn kích thước theo màn hình (`.w`, `.h`, `.sp`) |
| `flutter_localizations` | Bộ bản địa hóa của Flutter |
| `intl` | Định dạng số, ngày, và nền tảng cho `gen-l10n` |

Câu chữ UI không viết tay trong widget. Xem [docs/l10n.md](l10n.md).

### 2.2 Điều hướng

| Thư viện | Vai trò |
| --- | --- |
| `go_router` | Định tuyến khai báo, deep link, redirect |

### 2.3 Quản lý state

| Thư viện | Vai trò |
| --- | --- |
| `flutter_riverpod` | State management và dependency injection (`Provider`, `Notifier`, `AsyncNotifier`) |

Quy ước: state màn hình dùng `Notifier`/`AsyncNotifier`, logic thuần nằm trong `lib/core/`, widget chỉ `watch` và gọi hành động.

### 2.4 Lưu trữ cục bộ

| Thư viện | Vai trò |
| --- | --- |
| `shared_preferences` | Lưu cài đặt nhỏ (ngôn ngữ, âm thanh, thành tích) |

Cần dữ liệu có cấu trúc hoặc khối lượng lớn: thêm `drift` hoặc `hive_ce` (xem mục 4).

### 2.5 Firebase và cấu hình từ xa

| Thư viện | Vai trò |
| --- | --- |
| `firebase_core` | Khởi tạo Firebase, bắt buộc cho các dịch vụ Firebase khác |
| `firebase_remote_config` | Đọc cấu hình từ xa (bật/tắt tính năng, tham số) |

### 2.6 Quảng cáo và cập nhật ứng dụng

| Thư viện | Vai trò |
| --- | --- |
| `google_mobile_ads` | Quảng cáo AdMob (code nằm trong `lib/app/ads/`) |
| `in_app_update` | Cập nhật trong ứng dụng trên Android |
| `package_info_plus` | Đọc tên và phiên bản ứng dụng |
| `url_launcher` | Mở liên kết, store, mail |

### 2.7 Game và âm thanh

| Thư viện | Vai trò |
| --- | --- |
| `flame` | Vòng lặp game, render board |
| `audioplayers` | Phát hiệu ứng và nhạc nền |

### 2.8 Công cụ phát triển

| Thư viện | Vai trò |
| --- | --- |
| `flutter_lints` | Bộ lint chuẩn (đã kích hoạt qua `analysis_options.yaml`) |
| `flutter_native_splash` | Sinh màn hình chờ native |
| `flutter_launcher_icons` | Sinh icon ứng dụng |

## 3. Lệnh cài đặt trên máy mới

Lấy các gói đã khai báo trong `pubspec.yaml`:

```bash
flutter pub get
```

Sinh mã (l10n, và các file build_runner nếu có):

```bash
flutter gen-l10n
```

Sinh icon và splash sau khi đổi asset:

```bash
dart run flutter_launcher_icons && dart run flutter_native_splash:create
```

## 4. Thư viện nên cân nhắc thêm

Các thư viện này chưa có trong dự án. Chỉ thêm khi có nhu cầu tương ứng, không thêm trước.

| Nhu cầu | Thư viện gợi ý | Ghi chú |
| --- | --- | --- |
| Model bất biến, `copyWith`, so sánh giá trị | `freezed`, `freezed_annotation`, `json_serializable`, `json_annotation` | Cần `build_runner` (dev) |
| Lưu dữ liệu có cấu trúc, truy vấn | `drift` hoặc `hive_ce` | Thay cho `shared_preferences` khi dữ liệu lớn |
| Gọi HTTP | `dio` hoặc `http` | `dio` khi cần interceptor, retry |
| Kiểm tra mạng | `connectivity_plus` | Hiển thị trạng thái offline |
| Ghi log | `logger` | Thay cho `print` |
| Biến môi trường | `flutter_dotenv` | Không đưa khóa bí mật vào repo |
| Test mock | `mocktail` (dev) | Mock cho Riverpod, repository |
| Crash report | `firebase_crashlytics` | Đi cùng `firebase_core` |
| Phân tích | `firebase_analytics` | Chỉ thêm khi có kế hoạch đo lường rõ ràng |

Lệnh thêm nhóm dev dùng cho test và code gen:

```bash
flutter pub add dev:mocktail dev:build_runner
```

## 5. Lưu ý khi thêm hoặc đổi thư viện

1. **Dùng `flutter pub add`**, không sửa `pubspec.yaml` bằng tay, để pub tự cập nhật `pubspec.lock`.
2. **Gói chỉ dùng khi build** (launcher icons, splash, build_runner, test) đặt trong `dev_dependencies`.
3. **Commit cả `pubspec.lock`** để mọi máy dùng cùng phiên bản.
4. **Kiểm tra trước khi merge**:

   ```bash
   flutter analyze
   ```

5. **Đọc changelog** khi nâng major, đặc biệt với Firebase, `google_mobile_ads`, `flame` và `flutter_riverpod`.
6. **Quy ước của dự án** (xem [CLAUDE.md](../CLAUDE.md) và [docs/code_conventions.md](code_conventions.md)):
   - Không dùng toán tử 3 ngôi trong `lib/` và `test/`.
   - Mỗi file dưới 300 dòng code.
   - Câu chữ UI đi qua `tool/gen_arb.py`.

## 6. Điểm cần rà soát trong pubspec hiện tại

- `flutter_launcher_icons` và `flutter_native_splash` đang nằm trong `dependencies`. Nên chuyển sang `dev_dependencies` vì chỉ dùng lúc build.
- `shorebird.yaml` đã có và `shorebird_code_push` đã được khai báo trong `dependencies` để cập nhật code OTA.
- Chạy `flutter pub outdated` định kỳ để biết gói nào đã lỗi thời.
