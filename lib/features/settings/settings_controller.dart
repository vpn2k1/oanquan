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
        AnimSpeed.slow => 1.5,
        AnimSpeed.normal => 1.0,
        AnimSpeed.fast => 0.55,
      };
}

class AppSettings {
  const AppSettings({
    this.sound = true,
    this.haptics = true,
    this.speed = AnimSpeed.normal,
    this.reducedMotion = false,
    this.colorBlind = false,
    this.themeMode = ThemeMode.system,
    this.localeCode = 'vi',
  });

  final bool sound;
  final bool haptics;
  final AnimSpeed speed;
  final bool reducedMotion;
  final bool colorBlind;
  final ThemeMode themeMode;
  final String localeCode;

  AppSettings copyWith({
    bool? sound,
    bool? haptics,
    AnimSpeed? speed,
    bool? reducedMotion,
    bool? colorBlind,
    ThemeMode? themeMode,
    String? localeCode,
  }) =>
      AppSettings(
        sound: sound ?? this.sound,
        haptics: haptics ?? this.haptics,
        speed: speed ?? this.speed,
        reducedMotion: reducedMotion ?? this.reducedMotion,
        colorBlind: colorBlind ?? this.colorBlind,
        themeMode: themeMode ?? this.themeMode,
        localeCode: localeCode ?? this.localeCode,
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
      themeMode: pick(ThemeMode.values, 'themeMode', ThemeMode.system),
      localeCode: p.getString('${_prefix}locale') ?? 'vi',
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
  }

  void toggleSound() => update(state.copyWith(sound: !state.sound));
}

final settingsProvider =
    NotifierProvider<SettingsController, AppSettings>(SettingsController.new);
