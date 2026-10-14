import 'package:flutter/material.dart';

/// Màu người chơi: xanh lam, đỏ san hô, xanh lục, vàng hổ phách.
const playerColors = <Color>[
  Color(0xFF2F6FDE),
  Color(0xFFE5604D),
  Color(0xFF2E9E62),
  Color(0xFFE0A21B),
];

/// Biểu tượng hình dạng cho chế độ hỗ trợ màu: tròn, tam giác, vuông, thoi.
enum PlayerSymbol { circle, triangle, square, diamond }

PlayerSymbol symbolOf(int playerId) => PlayerSymbol.values[playerId % 4];

abstract final class AppColors {
  static const teal = Color(0xFF0E4D4A);
  static const tealDeep = Color(0xFF08302E);
  static const cream = Color(0xFFF6EBD6);
  static const creamDeep = Color(0xFFEBD9B8);
  static const wood = Color(0xFFC9893F);
  static const woodLight = Color(0xFFE2AE63);
  static const woodDark = Color(0xFF8A5523);
  static const groove = Color(0xFF6B3E17);
  static const gold = Color(0xFFD9A93B);
  static const ink = Color(0xFF2B1D10);
}

ThemeData buildTheme(Brightness b) {
  final dark = b == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.teal,
    brightness: b,
  ).copyWith(
    primary: dark ? const Color(0xFF7FD1C4) : AppColors.teal,
    secondary: AppColors.gold,
    surface: dark ? const Color(0xFF10201F) : AppColors.cream,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: dark ? AppColors.tealDeep : AppColors.cream,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      foregroundColor: dark ? AppColors.cream : AppColors.ink,
      centerTitle: true,
    ),
    cardTheme: CardThemeData(
      color: dark ? const Color(0xFF173533) : Colors.white.withValues(alpha: 0.75),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 52),
        textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
  );
}

/// Vẽ biểu tượng người chơi (dùng chung cho HUD và bàn Flame).
void paintPlayerSymbol(Canvas canvas, Offset c, double r, PlayerSymbol s, Paint paint) {
  switch (s) {
    case PlayerSymbol.circle:
      canvas.drawCircle(c, r, paint);
    case PlayerSymbol.square:
      canvas.drawRect(Rect.fromCenter(center: c, width: r * 1.7, height: r * 1.7), paint);
    case PlayerSymbol.triangle:
      canvas.drawPath(
        Path()
          ..moveTo(c.dx, c.dy - r * 1.1)
          ..lineTo(c.dx + r * 1.05, c.dy + r * 0.75)
          ..lineTo(c.dx - r * 1.05, c.dy + r * 0.75)
          ..close(),
        paint,
      );
    case PlayerSymbol.diamond:
      canvas.drawPath(
        Path()
          ..moveTo(c.dx, c.dy - r * 1.15)
          ..lineTo(c.dx + r * 1.0, c.dy)
          ..lineTo(c.dx, c.dy + r * 1.15)
          ..lineTo(c.dx - r * 1.0, c.dy)
          ..close(),
        paint,
      );
  }
}
