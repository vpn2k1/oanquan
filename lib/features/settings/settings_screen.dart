import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app.dart';
import '../../app/widgets.dart';
import '../../app/folk_art.dart';
import '../../l10n/app_localizations.dart';
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
                          l.settingsBoardStyle,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _StyleTile(
                              key: const Key('style_random'),
                              label: l.styleRandom,
                              style: null,
                              selected: s.boardStyle == FolkStyle.randomId,
                              onTap: () => c.update(
                                s.copyWith(boardStyle: FolkStyle.randomId),
                              ),
                            ),
                            for (final st in FolkStyle.all)
                              _StyleTile(
                                key: Key('style_${st.id}'),
                                label: _styleName(l, st),
                                style: st,
                                selected: s.boardStyle == st.id,
                                onTap: () =>
                                    c.update(s.copyWith(boardStyle: st.id)),
                              ),
                          ],
                        ),
                      ],
                    ),
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

String _styleName(AppLocalizations l, FolkStyle st) => switch (st.id) {
      'dirt_stick' => l.style_dirt_stick,
      'tiles_chalk' => l.style_tiles_chalk,
      'concrete_brick' => l.style_concrete_brick,
      'concrete_charcoal' => l.style_concrete_charcoal,
      _ => l.style_concrete_chalk,
    };

/// Ô xem trước: mặt sân + một hàng ô kẻ bằng dụng cụ tương ứng.
class _StyleTile extends StatelessWidget {
  const _StyleTile({
    super.key,
    required this.label,
    required this.style,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final FolkStyle? style;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 132,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? scheme.primary : scheme.outlineVariant,
              width: selected ? 3 : 1,
            ),
          ),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  height: 64,
                  width: double.infinity,
                  child: CustomPaint(painter: _PreviewPainter(style)),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewPainter extends CustomPainter {
  _PreviewPainter(this.style);
  final FolkStyle? style;

  @override
  void paint(Canvas canvas, Size size) {
    final st = style;
    if (st == null) {
      // "Ngẫu nhiên": ghép bốn mảnh mặt sân.
      final kinds = [GroundKind.dirt, GroundKind.concrete, GroundKind.tiles, GroundKind.concrete];
      for (var i = 0; i < 4; i++) {
        final r = Rect.fromLTWH(i * size.width / 4, 0, size.width / 4, size.height);
        canvas.save();
        canvas.clipRect(r);
        FolkGround.paint(canvas, size, kinds[i], 3 + i);
        canvas.restore();
      }
      final tp = TextPainter(
        text: const TextSpan(
          text: '?',
          style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Color(0xFFF7F4EC)),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, size.center(Offset(-tp.width / 2, -tp.height / 2)));
      return;
    }
    FolkGround.paint(canvas, size, st.ground, 11);
    final cell = size.height * 0.46;
    final top = (size.height - cell) / 2;
    final quan = Path()
      ..addArc(Rect.fromLTWH(8, top, cell, cell), pi / 2, pi)
      ..lineTo(8 + cell / 2, top + cell);
    final quanR = Path()
      ..addArc(Rect.fromLTWH(size.width - 8 - cell, top, cell, cell), -pi / 2, pi);
    FolkPen.stroke(canvas, quan, st.pen, width: 2.6, seed: 1);
    FolkPen.stroke(canvas, quanR, st.pen, width: 2.6, seed: 2);
    final left = 8 + cell / 2;
    final w = (size.width - 16 - cell) / 3;
    for (var i = 0; i < 3; i++) {
      FolkPen.stroke(
        canvas,
        Path()..addRect(Rect.fromLTWH(left + i * w, top, w, cell)),
        st.pen,
        width: 2.4,
        seed: 10 + i,
      );
    }
  }

  @override
  bool shouldRepaint(_PreviewPainter old) => old.style != style;
}
