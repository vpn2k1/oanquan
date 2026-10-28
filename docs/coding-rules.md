# Quy ước code: giải thích và cách mang sang dự án khác

Nội dung quy tắc nằm trong thư mục `rules/` và được `CLAUDE.md` import để luôn áp dụng khi viết code:

| Rule | File | Kiểm tra tự động |
|---|---|---|
| Không dùng toán tử 3 ngôi | `rules/no-ternary.md` | `test/no_ternary_test.dart` |
| Mỗi file dưới 300 dòng code | `rules/file-size.md` | `test/file_size_test.dart` |
| Chuỗi giao diện qua `Strings` | `rules/localization.md` | Không |
| Kích thước `.r` / `.sp` | `rules/responsive-ui.md` | Không |
| Format, analyze, test sau khi sửa | `rules/workflow.md` | Không |

File này chỉ giải thích lý do và cách dùng lại.

## Vì sao tách `rules/` và `docs/`

- `rules/` ngắn, viết dạng mệnh lệnh, được nạp vào mọi phiên làm việc qua `@rules/...` trong `CLAUDE.md`. Thêm chữ vào đây tốn ngữ cảnh mỗi lần, nên chỉ ghi điều bắt buộc.
- `docs/` dài, viết cho người đọc (cài đặt, phát hành, lý do). Không được import.

Khi thêm quy tắc mới: viết vào `rules/<tên>.md` và thêm một dòng `@rules/<tên>.md` trong `CLAUDE.md`.

## Vì sao có các rule này

- **Không toán tử 3 ngôi:** mỗi nhánh một dòng, dễ đọc và đặt breakpoint; tránh lồng nhau khó hiểu; tên hàm tự giải thích ý định.
- **Dưới 300 dòng:** file ngắn dễ tìm, dễ sửa, ít xung đột khi nhiều người cùng làm; widget nhỏ dễ test và dùng lại.

## Cách kiểm tra tự động hoạt động

- `no_ternary_test.dart` quét `lib/` và `test/`, bỏ qua comment và nội dung chuỗi (vẫn kiểm tra code trong `${...}`). Nó dựa vào định dạng của `dart format`: dấu `?` của toán tử 3 ngôi luôn có khoảng trắng hai bên, còn `?.`, `??`, `?[`, `...?` và kiểu nullable thì không. Vì vậy cần `dart format` trước khi test.
- `file_size_test.dart` đếm dòng không trống, không bắt đầu bằng `//`. Danh sách `legacyCeilings` dùng khi áp dụng rule cho dự án đã có file lớn: ghi mức trần bằng số dòng hiện tại, chỉ được giảm. Test thứ hai nhắc hạ mức trần khi file nhỏ đi, để danh sách thu dần về rỗng.

## Mang sang dự án khác

1. Chép thư mục `rules/` và hai file test.
2. Sửa trong test: danh sách thư mục cần quét, mẫu tên file sinh tự động cần bỏ qua.
3. Thêm các dòng `@rules/...` vào `CLAUDE.md` của dự án mới. Bỏ các rule không áp dụng (ví dụ `localization.md`, `responsive-ui.md` gắn với cấu trúc của dự án này).
4. Chạy test để lấy danh sách chỗ vi phạm. Với rule 300 dòng, đưa các file đang vượt vào `legacyCeilings` rồi chia nhỏ dần.
