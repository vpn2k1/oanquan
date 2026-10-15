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

/// Bảng màu kiểu "Recess": tối ấm (nâu đen, thẻ nâu, viền kem, nhấn cam)
/// và bản sáng tương ứng (nền kem, thẻ trắng, chữ nâu, nhấn cam).
abstract final class Rc {
  static const bg = Color(0xFF1B1410);
  static const surface = Color(0xFF2D2621);
  static const surfaceHigh = Color(0xFF3A3029);
  static const text = Color(0xFFFFF3E2);
  static const muted = Color(0xFFD0BDAA);
  static const line = Color(0x33FFF3E2);
  static const accent = Color(0xFFFF8F3A);
  static const onAccent = Color(0xFF12100C);
  static const accentSoft = Color(0x33FF8F3A);

  static const bgLight = Color(0xFFFFF3E2);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const surfaceHighLight = Color(0xFFF6E7D2);
  static const textLight = Color(0xFF2D2621);
  static const mutedLight = Color(0xFF7A6656);
  static const lineLight = Color(0x262D2621);
}

/// Token theo độ sáng hiện tại.
class RcTokens {
  const RcTokens(this.dark);
  factory RcTokens.of(BuildContext context) =>
      RcTokens(Theme.of(context).brightness == Brightness.dark);
  final bool dark;
  Color get bg => dark ? Rc.bg : Rc.bgLight;
  Color get surface => dark ? Rc.surface : Rc.surfaceLight;
  Color get surfaceHigh => dark ? Rc.surfaceHigh : Rc.surfaceHighLight;
  Color get text => dark ? Rc.text : Rc.textLight;
  Color get muted => dark ? Rc.muted : Rc.mutedLight;
  Color get line => dark ? Rc.line : Rc.lineLight;
}

ThemeData buildTheme(Brightness b) {
  final t = RcTokens(b == Brightness.dark);
  final scheme = ColorScheme.fromSeed(seedColor: Rc.accent, brightness: b).copyWith(
    primary: Rc.accent,
    onPrimary: Rc.onAccent,
    secondary: Rc.accent,
    onSecondary: Rc.onAccent,
    surface: t.surface,
    onSurface: t.text,
    onSurfaceVariant: t.muted,
    outline: t.line,
    outlineVariant: t.line,
    surfaceContainerHighest: t.surfaceHigh,
    secondaryContainer: Rc.accentSoft,
    onSecondaryContainer: t.text,
  );
  final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(16));
  final border = BorderSide(color: t.line, width: 2);
  const label = TextStyle(fontSize: 16, fontWeight: FontWeight.w800);
  final base = ThemeData(useMaterial3: true, colorScheme: scheme, brightness: b);
  return base.copyWith(
    scaffoldBackgroundColor: t.bg,
    textTheme: base.textTheme
        .apply(bodyColor: t.text, displayColor: t.text)
        .copyWith(
          titleMedium: base.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: t.text),
          titleSmall: base.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, color: t.muted),
        ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      foregroundColor: t.text,
      centerTitle: true,
      titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: t.text),
    ),
    cardTheme: CardThemeData(
      color: t.surface,
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: border),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 52),
        backgroundColor: Rc.accent,
        foregroundColor: Rc.onAccent,
        textStyle: label.copyWith(fontSize: 17),
        shape: shape,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        backgroundColor: t.surface,
        foregroundColor: t.text,
        side: border,
        textStyle: label,
        shape: shape,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: Rc.accent, textStyle: label),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        backgroundColor: t.surface,
        foregroundColor: t.text,
        selectedBackgroundColor: Rc.accentSoft,
        selectedForegroundColor: t.text,
        side: border,
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? Rc.onAccent : t.muted,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? Rc.accent : t.surfaceHigh,
      ),
      trackOutlineColor: WidgetStatePropertyAll(t.line),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: t.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: border),
    ),
    bottomSheetTheme: BottomSheetThemeData(backgroundColor: t.surface),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: t.surfaceHigh,
      contentTextStyle: TextStyle(color: t.text, fontWeight: FontWeight.w600),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: border),
    ),
    inputDecorationTheme: InputDecorationTheme(
      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: t.line, width: 2)),
      focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Rc.accent, width: 2)),
    ),
    dividerTheme: DividerThemeData(color: t.line),
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
