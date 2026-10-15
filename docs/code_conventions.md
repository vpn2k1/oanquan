# Quy ước code

1. Không dùng toán tử 3 ngôi
2. Mỗi file dưới 300 dòng code, chia nhỏ widget

## 1. Không dùng toán tử 3 ngôi

Không viết `điều kiện ? a : b`. Áp dụng cho `lib/` và `test/`, bỏ qua code
sinh tự động (`app_localizations*.dart`, `l10n/strings.dart`).

Cách viết thay thế:

```dart
// Giá trị → hàm nhỏ, if + return
color: _labelColor(selected),

Color _labelColor(bool selected) {
  if (selected) return FolkColors.ink;
  return FolkColors.muted;
}

// Lồng nhau → chuỗi return sớm
Outcome _outcomeFor(bool aDead, bool bDead) {
  if (aDead && bDead) return Outcome.draw;
  if (aDead) return Outcome.bWins;
  if (bDead) return Outcome.aWins;
  return Outcome.ongoing;
}

// Callback có thể null → gán bằng if trước return
VoidCallback? onSkip;
if (allSeen) onSkip = widget.onSkip;

// Chọn widget → hàm trả Widget, hoặc if trong list
children: [if (wide) const SidePanel() else const BottomPanel()],

// Câu lệnh → if/else
if (i == 0) {
  path.moveTo(x, y);
} else {
  path.lineTo(x, y);
}
```

Được phép: `??`, `?.`, `if` trong collection literal, `if/else`.
Không được né rule: `switch` trên bool, map `{true: a, false: b}[x]`, hay cách
che giấu khác.

Lưu ý khi chuyển đổi:

- Giữ nguyên hành vi: toán tử 3 ngôi chỉ tính nhánh được chọn. Nhánh có tác
  dụng phụ, tốn chi phí hoặc dùng `x!` chỉ an toàn ở một nhánh → viết `if` trực
  tiếp, không truyền cả hai giá trị vào hàm.
- Code vẽ chạy mỗi frame: hàm nhỏ, rẻ, không tạo thêm object.
- Giá trị đổi thành lời gọi hàm thì bỏ `const` bao quanh.
- Nhiều chỗ cùng một phép chọn: dùng chung một hàm.

Kiểm tra (`?` của toán tử 3 ngôi luôn có khoảng trắng hai bên sau `dart format`):

```bash
dart format lib test && flutter test test/no_ternary_test.dart
```

## 2. Mỗi file dưới 300 dòng code

Dòng trống và dòng comment `//` không tính. Bỏ qua file sinh tự động.

Cách chia nhỏ:

1. Mỗi widget lớn một file, tên file `snake_case` theo tên widget.
2. Màn hình là thư mục: `xxx_screen.dart` chỉ ghép bố cục, các phần nằm trong
   `widgets/`.
3. Hàm `_buildXxx()` dài → `StatelessWidget` trong file riêng.
4. Widget dùng ở nhiều màn hình đặt trong `lib/app/` (hoặc `lib/widgets/`), mỗi
   widget một file.
5. Class private tách ra file riêng thì đổi thành public.
6. Logic không phải giao diện tách khỏi widget.
7. Nhiều file con có thể gom bằng file `export`.

Khi tách: truyền dữ liệu/callback qua tham số; giữ nguyên hành vi, `Strings.xxx`,
`.r`/`.sp`; widget 5–10 dòng chỉ dùng một chỗ thì để lại file cha.

Kiểm tra:

```bash
flutter test test/file_size_test.dart
```

File cũ vượt chuẩn nằm trong `legacyCeilings` với trần = số dòng lúc thêm rule.
Trần chỉ được hạ, không tăng, không thêm file mới. Khi file giảm, test thứ hai
báo phải hạ trần hoặc xóa khỏi danh sách.

Đếm tay: `grep -vE '^\s*($|//)' lib/path/to/file.dart | wc -l`
