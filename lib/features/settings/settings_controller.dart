import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences được khởi tạo trong `main` rồi override provider này.
final sharedPrefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('override sharedPrefsProvider in main'),
);

enum AnimSpeed { slow, normal, fast }

extension AnimSpeedX on AnimSpeed {
  /// Hệ số nhân thời lượng animation.
  double get factor => switch (this) {
        AnimSpeed.slow => 1.7,
        AnimSpeed.normal => 1.0,
        AnimSpeed.fast => 0.45,
      };
}

class AppSettings {
  const AppSettings({
    this.sound = true,
    this.haptics = true,
    this.speed = AnimSpeed.normal,
    this.reducedMotion = false,
    this.colorBlind = false,
    this.themeMode = ThemeMode.dark,
    this.localeCode = 'vi',
    this.boardStyle = 'random',
  });

  final bool sound;
  final bool haptics;
  final AnimSpeed speed;
  final bool reducedMotion;
  final bool colorBlind;
  final ThemeMode themeMode;
  final String localeCode;

  /// Mặt sân + nét vẽ: id `FolkStyle` hoặc `'random'` (ngẫu nhiên mỗi ván).
  final String boardStyle;

  AppSettings copyWith({
    bool? sound,
    bool? haptics,
    AnimSpeed? speed,
    bool? reducedMotion,
    bool? colorBlind,
    ThemeMode? themeMode,
    String? localeCode,
    String? boardStyle,
  }) =>
      AppSettings(
        sound: sound ?? this.sound,
        haptics: haptics ?? this.haptics,
        speed: speed ?? this.speed,
        reducedMotion: reducedMotion ?? this.reducedMotion,
        colorBlind: colorBlind ?? this.colorBlind,
        themeMode: themeMode ?? this.themeMode,
        localeCode: localeCode ?? this.localeCode,
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
      speed: pick(AnimSpeed.values, 'speed', AnimSpeed.normal),
      reducedMotion: p.getBool('${_prefix}reducedMotion') ?? false,
      colorBlind: p.getBool('${_prefix}colorBlind') ?? false,
      themeMode: pick(ThemeMode.values, 'themeMode', ThemeMode.dark),
      localeCode: p.getString('${_prefix}locale') ?? 'vi',
      boardStyle: p.getString('${_prefix}boardStyle') ?? 'random',
    );
  }

  void update(AppSettings s) {
    state = s;
    final p = _prefs;
    p.setBool('${_prefix}sound', s.sound);
    p.setBool('${_prefix}haptics', s.haptics);
    p.setString('${_prefix}speed', s.speed.name);
    p.setBool('${_prefix}reducedMotion', s.reducedMotion);
    p.setBool('${_prefix}colorBlind', s.colorBlind);
    p.setString('${_prefix}themeMode', s.themeMode.name);
    p.setString('${_prefix}locale', s.localeCode);
    p.setString('${_prefix}boardStyle', s.boardStyle);
  }

  void toggleSound() => update(state.copyWith(sound: !state.sound));
}

final settingsProvider =
    NotifierProvider<SettingsController, AppSettings>(SettingsController.new);
