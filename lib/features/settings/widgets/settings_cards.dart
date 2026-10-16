import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/folk_art.dart';
import '../../../app/layout/screen_layout.dart';
import '../../../app/widgets.dart';
import '../../../l10n/l10n.dart';
import '../../../l10n/strings.dart';
import '../settings_controller.dart';
import 'style_tile.dart';

/// Âm thanh, rung.
class SoundCard extends ConsumerWidget {
  const SoundCard({super.key, this.dense = false});
  final bool dense;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final c = ref.read(settingsProvider.notifier);
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            key: const Key('soundSwitch'),
            dense: dense,
            secondary: const FolkIcon(Icons.volume_up_rounded),
            title: Text(Strings.settingsSound),
            value: s.sound,
            onChanged: (v) => c.update(s.copyWith(sound: v)),
          ),
          SwitchListTile(
            dense: dense,
            secondary: const FolkIcon(Icons.vibration_rounded),
            title: Text(Strings.settingsHaptics),
            value: s.haptics,
            onChanged: (v) => c.update(s.copyWith(haptics: v)),
          ),
        ],
      ),
    );
  }
}

/// Giảm chuyển động, chế độ mù màu.
class AccessibilityCard extends ConsumerWidget {
  const AccessibilityCard({super.key, this.dense = false});
  final bool dense;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final c = ref.read(settingsProvider.notifier);
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            key: const Key('reducedMotion'),
            dense: dense,
            secondary: const FolkIcon(Icons.motion_photos_off_rounded),
            title: Text(Strings.settingsReducedMotion),
            subtitle: Text(Strings.settingsReducedMotionDesc),
            value: s.reducedMotion,
            onChanged: (v) => c.update(s.copyWith(reducedMotion: v)),
          ),
          SwitchListTile(
            dense: dense,
            secondary: const FolkIcon(Icons.palette_rounded),
            title: Text(Strings.settingsColorBlind),
            subtitle: Text(Strings.settingsColorBlindDesc),
            value: s.colorBlind,
            onChanged: (v) => c.update(s.copyWith(colorBlind: v)),
          ),
        ],
      ),
    );
  }
}

/// Chọn mặt sân. [columns] khác null → chia đều thành lưới số cột đó
/// (điện thoại ngang), không thì ô cỡ mặc định xếp tràn dòng.
class BoardStyleCard extends ConsumerWidget {
  const BoardStyleCard({super.key, this.columns});
  final int? columns;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final c = ref.read(settingsProvider.notifier);
    final spacing = 10.r;
    Widget tiles(double? width) => Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: [
        StyleTile(
          key: const Key('style_random'),
          label: Strings.styleRandom,
          style: null,
          width: width,
          selected: s.boardStyle == FolkStyle.randomId,
          onTap: () => c.update(s.copyWith(boardStyle: FolkStyle.randomId)),
        ),
        for (final st in FolkStyle.all)
          StyleTile(
            key: Key('style_${st.id}'),
            label: Strings.styleName(st.id),
            style: st,
            width: width,
            selected: s.boardStyle == st.id,
            onTap: () => c.update(s.copyWith(boardStyle: st.id)),
          ),
      ],
    );
    final n = columns;
    Widget grid = tiles(null);
    if (n != null) {
      grid = LayoutBuilder(
        builder: (context, box) =>
            tiles((box.maxWidth - spacing * (n - 1)) / n - 0.5),
      );
    }
    return Card(
      child: Padding(
        padding: EdgeInsets.all(12.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              Strings.settingsBoardStyle,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            SizedBox(height: 8.r),
            grid,
          ],
        ),
      ),
    );
  }
}

/// Giao diện sáng/tối, ngôn ngữ. Điện thoại: nhãn cạnh nút chọn (ngang: hai
/// nhóm cùng một hàng), nút chọn tự thu nhỏ nếu thiếu chỗ. Màn rộng: nhãn
/// nằm trên nút chọn.
class ThemeLanguageCard extends ConsumerWidget {
  const ThemeLanguageCard({super.key, this.layout = ScreenLayout.wide});
  final ScreenLayout layout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final c = ref.read(settingsProvider.notifier);
    final label = Theme.of(context).textTheme.titleSmall;
    final theme = SegmentedButton<ThemeMode>(
      showSelectedIcon: !layout.isCompact,
      segments: [
        ButtonSegment(
          value: ThemeMode.system,
          label: Text(Strings.themeSystem),
        ),
        ButtonSegment(value: ThemeMode.light, label: Text(Strings.themeLight)),
        ButtonSegment(value: ThemeMode.dark, label: Text(Strings.themeDark)),
      ],
      selected: {s.themeMode},
      onSelectionChanged: (v) => c.update(s.copyWith(themeMode: v.first)),
    );
    final language = SegmentedButton<AppLanguage>(
      showSelectedIcon: !layout.isCompact,
      segments: [
        for (final lang in AppLanguage.values)
          ButtonSegment(value: lang, label: Text(lang.nativeName)),
      ],
      selected: {s.language},
      onSelectionChanged: (v) => c.update(s.copyWith(language: v.first)),
    );
    if (layout.isCompact) {
      Widget group(String text, Widget picker) => Row(
        children: [
          Text(text, style: label),
          SizedBox(width: 10.r),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: picker,
            ),
          ),
        ],
      );
      final themeGroup = group(Strings.settingsTheme, theme);
      final languageGroup = group(Strings.settingsLanguage, language);
      Widget groups = Column(
        children: [
          themeGroup,
          SizedBox(height: 8.r),
          languageGroup,
        ],
      );
      if (layout == ScreenLayout.compactLandscape) {
        groups = Row(
          children: [
            Expanded(child: themeGroup),
            SizedBox(width: 24.r),
            Expanded(child: languageGroup),
          ],
        );
      }
      return Card(
        child: Padding(padding: EdgeInsets.all(10.r), child: groups),
      );
    }
    return Card(
      child: Padding(
        padding: EdgeInsets.all(12.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(Strings.settingsTheme, style: label),
            SizedBox(height: 8.r),
            theme,
            SizedBox(height: 16.r),
            Text(Strings.settingsLanguage, style: label),
            SizedBox(height: 8.r),
            language,
          ],
        ),
      ),
    );
  }
}
