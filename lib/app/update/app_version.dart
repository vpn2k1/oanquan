/// Phiên bản dạng `1.2.0+5` (tên + build), so sánh từng phần.
class AppVersion implements Comparable<AppVersion> {
  final List<int> parts;

  const AppVersion(this.parts);

  /// Đọc `1.2.0+5`. Thiếu phần coi là 0; sai định dạng trả null.
  static AppVersion? tryParse(String raw) {
    final pieces = raw.trim().split('+');
    if (pieces.isEmpty || pieces.length > 2) return null;
    final name = pieces[0].split('.');
    final numbers = [...name, ...pieces.skip(1)].map(int.tryParse).toList();
    if (numbers.any((n) => n == null)) return null;
    return AppVersion(numbers.cast<int>());
  }

  @override
  int compareTo(AppVersion other) {
    final n = _max(parts.length, other.parts.length);
    for (var i = 0; i < n; i++) {
      final a = _partAt(parts, i);
      final b = _partAt(other.parts, i);
      if (a != b) return a.compareTo(b);
    }
    return 0;
  }

  static int _max(int a, int b) {
    if (a > b) return a;
    return b;
  }

  static int _partAt(List<int> list, int i) {
    if (i < list.length) return list[i];
    return 0;
  }

  @override
  String toString() => parts.join('.');
}
