import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../features/settings/settings_controller.dart';
import '../l10n/app_localizations.dart';
import '../l10n/strings.dart';
import '../l10n/strings_scope.dart';
import 'router.dart';
import 'theme.dart';

class OQuanApp extends ConsumerWidget {
  const OQuanApp({super.key});

  /// Khung thiết kế (dọc). Màn hình ngang dùng khung xoay ngang tương ứng.
  static const designSize = Size(390, 844);

  /// Tablet không bị to quá, máy nhỏ không bị chữ quá bé.
  static const minScale = 0.85;
  static const maxScale = 1.3;

  /// designSize sao cho tỉ lệ `.r`/`.sp` = tỉ lệ thật, kẹp trong [min, max].
  /// Game chơi màn ngang là chính → khi ngang, so với khung 844×390.
  static Size clampedDesignSize(Size screen) {
    var base = designSize;
    if (screen.width > screen.height) base = designSize.flipped;
    final scale = math.min(
      screen.width / base.width,
      screen.height / base.height,
    );
    if (!scale.isFinite || scale <= 0) return base;
    return base * (scale / scale.clamp(minScale, maxScale));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final router = ref.watch(routerProvider);
    return LayoutBuilder(
      builder: (context, screen) => ScreenUtilInit(
        designSize: clampedDesignSize(screen.biggest),
        minTextAdapt: true,
        builder: (context, _) => MaterialApp.router(
          onGenerateTitle: (_) => Strings.appTitle,
          debugShowCheckedModeBanner: false,
          theme: buildTheme(Brightness.light),
          darkTheme: buildTheme(Brightness.dark),
          themeMode: settings.themeMode,
          locale: Locale(settings.language.code),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          routerConfig: router,
          builder: (context, child) => StringsScope(child: child!),
        ),
      ),
    );
  }
}
