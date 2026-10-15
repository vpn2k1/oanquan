import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'folk_art.dart';

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
  Color get bg {
    if (dark) return Rc.bg;
    return Rc.bgLight;
  }

  Color get surface {
    if (dark) return Rc.surface;
    return Rc.surfaceLight;
  }

  Color get surfaceHigh {
    if (dark) return Rc.surfaceHigh;
    return Rc.surfaceHighLight;
  }

  Color get text {
    if (dark) return Rc.text;
    return Rc.textLight;
  }

  Color get muted {
    if (dark) return Rc.muted;
    return Rc.mutedLight;
  }

  Color get line {
    if (dark) return Rc.line;
    return Rc.lineLight;
  }
}

/// Màu nét phấn viền nút: kem trên nền tối, nâu sẫm trên nền sáng.
Color _chalkColor(bool dark) {
  if (dark) return const Color(0xE6FFF3E2);
  return const Color(0xCC2D2621);
}

Color _switchThumb(Set<WidgetState> s, RcTokens t) {
  if (s.contains(WidgetState.selected)) return Rc.onAccent;
  return t.muted;
}

Color _switchTrack(Set<WidgetState> s, RcTokens t) {
  if (s.contains(WidgetState.selected)) return Rc.accent;
  return t.surfaceHigh;
}

ThemeData buildTheme(Brightness b) {
  final t = RcTokens(b == Brightness.dark);
  final scheme = ColorScheme.fromSeed(seedColor: Rc.accent, brightness: b)
      .copyWith(
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
  // Nút viền nét phấn (kem trên nền tối, nâu sẫm trên nền sáng).
  // Theme dựng bên trong ScreenUtilInit → dùng được .r/.sp.
  final chalk = ChalkBorder(radius: 16.r, color: _chalkColor(t.dark));
  final chalkOnAccent = ChalkBorder(
    radius: 16.r,
    color: const Color(0xF2FFF3E2),
    width: 2.4,
  );
  final label = TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w800);
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    brightness: b,
  );
  // Ghép bộ cỡ chữ chuẩn (englishLike2021) rồi nhân tỉ lệ .sp cho toàn app.
  final text = Typography.englishLike2021
      .merge(base.textTheme)
      .apply(bodyColor: t.text, displayColor: t.text, fontSizeFactor: 1.sp);
  return base.copyWith(
    scaffoldBackgroundColor: t.bg,
    textTheme: text.copyWith(
      titleMedium: text.titleMedium?.copyWith(
        fontWeight: FontWeight.w800,
        color: t.text,
      ),
      titleSmall: text.titleSmall?.copyWith(
        fontWeight: FontWeight.w800,
        color: t.muted,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      foregroundColor: t.text,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 20.sp,
        fontWeight: FontWeight.w900,
        color: t.text,
      ),
    ),
    cardTheme: CardThemeData(
      color: t.surface,
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: chalk.copyWith(radius: 18.r),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: Size(48.r, 52.r),
        backgroundColor: Rc.accent,
        foregroundColor: Rc.onAccent,
        textStyle: label.copyWith(fontSize: 17.sp),
        shape: chalkOnAccent,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: Size(48.r, 48.r),
        backgroundColor: t.surface,
        foregroundColor: t.text,
        side: BorderSide.none,
        textStyle: label,
        shape: chalk,
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
        side: BorderSide(color: t.line, width: 1.5),
        shape: chalk,
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) => _switchThumb(s, t)),
      trackColor: WidgetStateProperty.resolveWith((s) => _switchTrack(s, t)),
      trackOutlineColor: WidgetStatePropertyAll(t.line),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: t.surface,
      shape: chalk.copyWith(radius: 20.r),
    ),
    bottomSheetTheme: BottomSheetThemeData(backgroundColor: t.surface),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: t.surfaceHigh,
      contentTextStyle: TextStyle(color: t.text, fontWeight: FontWeight.w600),
      behavior: SnackBarBehavior.floating,
      shape: chalk.copyWith(radius: 14.r),
    ),
    inputDecorationTheme: InputDecorationTheme(
      enabledBorder: ChalkUnderlineInputBorder(
        color: t.text.withValues(alpha: 0.6),
      ),
      focusedBorder: const ChalkUnderlineInputBorder(
        color: Rc.accent,
        width: 2.6,
      ),
    ),
    dividerTheme: DividerThemeData(color: t.line),
  );
}

/// Vẽ biểu tượng người chơi (dùng chung cho HUD và bàn Flame).
void paintPlayerSymbol(
  Canvas canvas,
  Offset c,
  double r,
  PlayerSymbol s,
  Paint paint,
) {
  switch (s) {
    case PlayerSymbol.circle:
      canvas.drawCircle(c, r, paint);
    case PlayerSymbol.square:
      canvas.drawRect(
        Rect.fromCenter(center: c, width: r * 1.7, height: r * 1.7),
        paint,
      );
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
