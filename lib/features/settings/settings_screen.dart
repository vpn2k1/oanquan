import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/widgets.dart';
import '../../app/folk_art.dart';
import 'settings_controller.dart';
import '../../l10n/l10n.dart';
import '../../l10n/strings.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final c = ref.read(settingsProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: Text(Strings.settings)),
      body: AppBackground(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 560.r),
            child: ListView(
              padding: EdgeInsets.all(16.r),
              children: [
                Card(
                  child: Column(
                    children: [
                      SwitchListTile(
                        key: const Key('soundSwitch'),
                        secondary: const FolkIcon(Icons.volume_up_rounded),
                        title: Text(Strings.settingsSound),
                        value: s.sound,
                        onChanged: (v) => c.update(s.copyWith(sound: v)),
                      ),
                      SwitchListTile(
                        secondary: const FolkIcon(Icons.vibration_rounded),
                        title: Text(Strings.settingsHaptics),
                        value: s.haptics,
                        onChanged: (v) => c.update(s.copyWith(haptics: v)),
                      ),
                    ],
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
                        title: Text(Strings.settingsReducedMotion),
                        subtitle: Text(Strings.settingsReducedMotionDesc),
                        value: s.reducedMotion,
                        onChanged: (v) =>
                            c.update(s.copyWith(reducedMotion: v)),
                      ),
                      SwitchListTile(
                        secondary: const FolkIcon(Icons.palette_rounded),
                        title: Text(Strings.settingsColorBlind),
                        subtitle: Text(Strings.settingsColorBlindDesc),
                        value: s.colorBlind,
                        onChanged: (v) => c.update(s.copyWith(colorBlind: v)),
                      ),
                    ],
                  ),
                ),
                Card(
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
                        Wrap(
                          spacing: 10.r,
                          runSpacing: 10.r,
                          children: [
                            _StyleTile(
                              key: const Key('style_random'),
                              label: Strings.styleRandom,
                              style: null,
                              selected: s.boardStyle == FolkStyle.randomId,
                              onTap: () => c.update(
                                s.copyWith(boardStyle: FolkStyle.randomId),
                              ),
                            ),
                            for (final st in FolkStyle.all)
                              _StyleTile(
                                key: Key('style_${st.id}'),
                                label: Strings.styleName(st.id),
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
                    padding: EdgeInsets.all(12.r),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          Strings.settingsTheme,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        SizedBox(height: 8.r),
                        SegmentedButton<ThemeMode>(
                          segments: [
                            ButtonSegment(
                              value: ThemeMode.system,
                              label: Text(Strings.themeSystem),
                            ),
                            ButtonSegment(
                              value: ThemeMode.light,
                              label: Text(Strings.themeLight),
                            ),
                            ButtonSegment(
                              value: ThemeMode.dark,
                              label: Text(Strings.themeDark),
                            ),
                          ],
                          selected: {s.themeMode},
                          onSelectionChanged: (v) =>
                              c.update(s.copyWith(themeMode: v.first)),
                        ),
                        SizedBox(height: 16.r),
                        Text(
                          Strings.settingsLanguage,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        SizedBox(height: 8.r),
                        SegmentedButton<AppLanguage>(
                          segments: [
                            for (final lang in AppLanguage.values)
                              ButtonSegment(
                                value: lang,
                                label: Text(lang.nativeName),
                              ),
                          ],
                          selected: {s.language},
                          onSelectionChanged: (v) =>
                              c.update(s.copyWith(language: v.first)),
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
    var borderColor = scheme.onSurface.withValues(alpha: 0.45);
    var borderWidth = 1.8;
    if (selected) {
      borderColor = scheme.primary;
      borderWidth = 2.8;
    }
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14.r),
        child: Container(
          width: 132.r,
          padding: EdgeInsets.all(4.r),
          decoration: ShapeDecoration(
            shape: ChalkBorder(
              radius: 14.r,
              color: borderColor,
              width: borderWidth,
            ),
          ),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10.r),
                child: SizedBox(
                  height: 64.r,
                  width: double.infinity,
                  child: CustomPaint(painter: _PreviewPainter(style)),
                ),
              ),
              SizedBox(height: 4.r),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
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
      final kinds = [
        GroundKind.dirt,
        GroundKind.concrete,
        GroundKind.tiles,
        GroundKind.concrete,
      ];
      for (var i = 0; i < 4; i++) {
        final r = Rect.fromLTWH(
          i * size.width / 4,
          0,
          size.width / 4,
          size.height,
        );
        canvas.save();
        canvas.clipRect(r);
        FolkGround.paint(canvas, size, kinds[i], 3 + i);
        canvas.restore();
      }
      final tp = TextPainter(
        text: TextSpan(
          text: '?',
          style: TextStyle(
            fontSize: 34.sp,
            fontWeight: FontWeight.w900,
            color: Color(0xFFF7F4EC),
          ),
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
      ..addArc(
        Rect.fromLTWH(size.width - 8 - cell, top, cell, cell),
        -pi / 2,
        pi,
      );
    FolkPen.stroke(canvas, quan, st.pen, width: 2.6.r, seed: 1);
    FolkPen.stroke(canvas, quanR, st.pen, width: 2.6.r, seed: 2);
    final left = 8 + cell / 2;
    final w = (size.width - 16 - cell) / 3;
    for (var i = 0; i < 3; i++) {
      FolkPen.stroke(
        canvas,
        Path()..addRect(Rect.fromLTWH(left + i * w, top, w, cell)),
        st.pen,
        width: 2.4.r,
        seed: 10 + i,
      );
    }
  }

  @override
  bool shouldRepaint(_PreviewPainter old) => old.style != style;
}
