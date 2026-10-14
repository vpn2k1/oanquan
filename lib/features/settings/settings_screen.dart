import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app.dart';
import '../../app/widgets.dart';
import 'settings_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final s = ref.watch(settingsProvider);
    final c = ref.read(settingsProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: Text(l.settings)),
      body: AppBackground(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Column(
                    children: [
                      SwitchListTile(
                        key: const Key('soundSwitch'),
                        secondary: const FolkIcon(Icons.volume_up_rounded),
                        title: Text(l.settingsSound),
                        value: s.sound,
                        onChanged: (v) => c.update(s.copyWith(sound: v)),
                      ),
                      SwitchListTile(
                        secondary: const FolkIcon(Icons.vibration_rounded),
                        title: Text(l.settingsHaptics),
                        value: s.haptics,
                        onChanged: (v) => c.update(s.copyWith(haptics: v)),
                      ),
                    ],
                  ),
                ),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.settingsAnimSpeed,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        SegmentedButton<AnimSpeed>(
                          segments: [
                            ButtonSegment(
                              value: AnimSpeed.slow,
                              label: Text(l.speedSlow),
                            ),
                            ButtonSegment(
                              value: AnimSpeed.normal,
                              label: Text(l.speedNormal),
                            ),
                            ButtonSegment(
                              value: AnimSpeed.fast,
                              label: Text(l.speedFast),
                            ),
                          ],
                          selected: {s.speed},
                          onSelectionChanged: (v) =>
                              c.update(s.copyWith(speed: v.first)),
                        ),
                      ],
                    ),
                  ),
                ),
                Card(
                  child: Column(
                    children: [
                      SwitchListTile(
                        key: const Key('reducedMotion'),
                        secondary: const FolkIcon(
                          Icons.motion_photos_off_rounded,
                        ),
                        title: Text(l.settingsReducedMotion),
                        subtitle: Text(l.settingsReducedMotionDesc),
                        value: s.reducedMotion,
                        onChanged: (v) =>
                            c.update(s.copyWith(reducedMotion: v)),
                      ),
                      SwitchListTile(
                        secondary: const FolkIcon(Icons.palette_rounded),
                        title: Text(l.settingsColorBlind),
                        subtitle: Text(l.settingsColorBlindDesc),
                        value: s.colorBlind,
                        onChanged: (v) => c.update(s.copyWith(colorBlind: v)),
                      ),
                    ],
                  ),
                ),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.settingsTheme,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        SegmentedButton<ThemeMode>(
                          segments: [
                            ButtonSegment(
                              value: ThemeMode.system,
                              label: Text(l.themeSystem),
                            ),
                            ButtonSegment(
                              value: ThemeMode.light,
                              label: Text(l.themeLight),
                            ),
                            ButtonSegment(
                              value: ThemeMode.dark,
                              label: Text(l.themeDark),
                            ),
                          ],
                          selected: {s.themeMode},
                          onSelectionChanged: (v) =>
                              c.update(s.copyWith(themeMode: v.first)),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l.settingsLanguage,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(
                              value: 'vi',
                              label: Text('Tiếng Việt'),
                            ),
                            ButtonSegment(value: 'en', label: Text('English')),
                          ],
                          selected: {s.localeCode},
                          onSelectionChanged: (v) =>
                              c.update(s.copyWith(localeCode: v.first)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
