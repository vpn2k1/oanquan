import 'package:flutter/material.dart';

/// Màu người chơi: xanh lam, đỏ san hô, xanh lục, vàng hổ phách.
const playerColors = <Color>[
  Color(0xFF2B7BFF),
  Color(0xFFFF5A5F),
  Color(0xFF1FBF68),
  Color(0xFFFFB020),
];

/// Biểu tượng hình dạng cho chế độ hỗ trợ màu: tròn, tam giác, vuông, thoi.
enum PlayerSymbol { circle, triangle, square, diamond }

PlayerSymbol symbolOf(int playerId) => PlayerSymbol.values[playerId % 4];

abstract final class AppColors {
  // Tông sáng, tươi: ngọc lam + kem + gỗ mật ong sáng.
  static const teal = Color(0xFF0B8F84);
  static const turquoise = Color(0xFF19C3B1);
  static const tealDeep = Color(0xFF0B4F4A);
  static const tealMid = Color(0xFF137A72);
  static const cream = Color(0xFFFFF6E0);
  static const creamDeep = Color(0xFFFFE9B8);
  static const mint = Color(0xFFC4F1E6);
  static const wood = Color(0xFFF0A955);
  static const woodLight = Color(0xFFFFD08A);
  static const woodDark = Color(0xFFC27A32);
  static const well = Color(0xFFA9692F);
  static const wellLight = Color(0xFFC88442);
  static const groove = Color(0xFF9A5A22);
  static const gold = Color(0xFFFFC233);
  static const ink = Color(0xFF2B1D10);
}

ThemeData buildTheme(Brightness b) {
  final dark = b == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.teal,
    brightness: b,
  ).copyWith(
    primary: dark ? const Color(0xFF6FE6D6) : AppColors.teal,
    secondary: AppColors.gold,
    surface: dark ? const Color(0xFF12403C) : AppColors.cream,
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
      color: dark ? const Color(0xFF1A5A54) : Colors.white.withValues(alpha: 0.85),
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
