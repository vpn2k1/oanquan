import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/l10n.dart';

/// SharedPreferences được khởi tạo trong `main` rồi override provider này.
final sharedPrefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('override sharedPrefsProvider in main'),
);

/// Nhịp animation cố định ở mức "chậm" (không cho chỉnh) để người chơi
/// theo dõi được từng viên rải.
const kAnimSpeedFactor = 1.6;

class AppSettings {
  const AppSettings({
    this.sound = true,
    this.haptics = true,
    this.reducedMotion = false,
    this.colorBlind = false,
    this.themeMode = ThemeMode.dark,
    this.language = AppLanguage.vi,
    this.boardStyle = 'random',
  });

  final bool sound;
  final bool haptics;
  final bool reducedMotion;
  final bool colorBlind;
  final ThemeMode themeMode;
  final AppLanguage language;

  /// Mặt sân + nét vẽ: id `FolkStyle` hoặc `'random'` (ngẫu nhiên mỗi ván).
  final String boardStyle;

  AppSettings copyWith({
    bool? sound,
    bool? haptics,
    bool? reducedMotion,
    bool? colorBlind,
    ThemeMode? themeMode,
    AppLanguage? language,
    String? boardStyle,
  }) => AppSettings(
    sound: sound ?? this.sound,
    haptics: haptics ?? this.haptics,
    reducedMotion: reducedMotion ?? this.reducedMotion,
    colorBlind: colorBlind ?? this.colorBlind,
    themeMode: themeMode ?? this.themeMode,
    language: language ?? this.language,
    boardStyle: boardStyle ?? this.boardStyle,
  );
}

class SettingsController extends Notifier<AppSettings> {
  static const _prefix = 'settings.';

  SharedPreferences get _prefs => ref.read(sharedPrefsProvider);

  @override
  AppSettings build() {
    final p = _prefs;
    T pick<T extends Enum>(List<T> values, String key, T def) {
      final v = p.getString('$_prefix$key');
      return values.where((e) => e.name == v).firstOrNull ?? def;
    }

    return AppSettings(
      sound: p.getBool('${_prefix}sound') ?? true,
      haptics: p.getBool('${_prefix}haptics') ?? true,
      reducedMotion: p.getBool('${_prefix}reducedMotion') ?? false,
      colorBlind: p.getBool('${_prefix}colorBlind') ?? false,
      themeMode: pick(ThemeMode.values, 'themeMode', ThemeMode.dark),
      language: AppLanguage.byCode(p.getString('${_prefix}language')),
      boardStyle: p.getString('${_prefix}boardStyle') ?? 'random',
    );
  }

  void update(AppSettings s) {
    state = s;
    final p = _prefs;
    p.setBool('${_prefix}sound', s.sound);
    p.setBool('${_prefix}haptics', s.haptics);
    p.setBool('${_prefix}reducedMotion', s.reducedMotion);
    p.setBool('${_prefix}colorBlind', s.colorBlind);
    p.setString('${_prefix}themeMode', s.themeMode.name);
    p.setString('${_prefix}language', s.language.code);
    p.setString('${_prefix}boardStyle', s.boardStyle);
  }

  void toggleSound() => update(state.copyWith(sound: !state.sound));
}

final settingsProvider = NotifierProvider<SettingsController, AppSettings>(
  SettingsController.new,
);
