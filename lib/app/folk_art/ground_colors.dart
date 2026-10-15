import 'dart:math';

import 'package:flutter/painting.dart';

/// `+v` hoặc `-v` ngẫu nhiên (một lần gọi `nextBool`).
double signedOf(Random r, double v) {
  if (r.nextBool()) return v;
  return -v;
}

/// Chọn ngẫu nhiên một trong hai màu (một lần gọi `nextBool`).
Color randomOf(Random r, Color a, Color b) {
  if (r.nextBool()) return a;
  return b;
}

/// Vết rỗ mặt gạch: 60% sẫm, 40% sáng (một lần gọi `nextDouble`).
Color pitColor(Random r) {
  if (r.nextDouble() < 0.6) return const Color(0xFF6E2A18);
  return const Color(0xFFE4A07C);
}

List<Color> clayColors(bool dark) {
  if (dark) {
    return const [Color(0xFF5E4631), Color(0xFF4A3727), Color(0xFF33251A)];
  }
  return const [Color(0xFFD3AE80), Color(0xFFC49A6C), Color(0xFFA97E52)];
}

Color blotchDark(bool dark) {
  if (dark) return const Color(0xFF1E140C);
  return const Color(0xFF7E5834);
}

Color blotchLight(bool dark) {
  if (dark) return const Color(0xFF8A6A48);
  return const Color(0xFFE6C9A0);
}

Color sweepColor(bool dark) {
  if (dark) return const Color(0xFF7A5C3E);
  return const Color(0xFF8E683F);
}

Color gritDark(bool dark) {
  if (dark) return const Color(0xFF1A110A);
  return const Color(0xFF6E4C2C);
}

Color gritLight(bool dark) {
  if (dark) return const Color(0xFFA88660);
  return const Color(0xFFEAD3AE);
}

Color pebbleLo(bool dark) {
  if (dark) return const Color(0xFF6E665C);
  return const Color(0xFF8F8478);
}

Color pebbleHi(bool dark) {
  if (dark) return const Color(0xFFB8AC98);
  return const Color(0xFFCDBEA8);
}
