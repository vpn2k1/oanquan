# Ô Quan Việt — quy ước dự án

Chi tiết và ví dụ: [docs/code_conventions.md](docs/code_conventions.md),
đa ngôn ngữ: [docs/l10n.md](docs/l10n.md).

- **Không dùng toán tử 3 ngôi** (`a ? b : c`) trong `lib/` và `test/`: dùng
  `if` + `return` trong hàm nhỏ, `if` trong collection, hoặc `if/else`.
  Cấm né rule bằng `switch` trên bool hay map `{true: …}`.
  Kiểm tra: `dart format lib test && flutter test test/no_ternary_test.dart`.
- **Mỗi file dưới 300 dòng code** (không tính dòng trống/comment `//`).
  Widget lớn tách thành file riêng; màn hình là thư mục với `widgets/`.
  File cũ vượt chuẩn nằm trong `legacyCeilings` ở `test/file_size_test.dart`:
  chỉ được hạ trần/xóa, không tăng, không thêm file mới.
  Kiểm tra: `flutter test test/file_size_test.dart`.
- **Câu chữ UI**: chỉ sửa `tool/gen_arb.py`, rồi
  `python3 tool/gen_arb.py && flutter gen-l10n`. Dùng `Strings.xxx`;
  không sửa tay file sinh trong `lib/l10n/`.
