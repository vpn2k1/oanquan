import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../app/layout/fit_to_screen.dart';
import '../../app/layout/screen_layout.dart';
import '../../app/widgets.dart';
import '../../l10n/strings.dart';
import 'widgets/settings_cards.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final layout = ScreenLayout.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(Strings.settings),
        toolbarHeight: toolbarHeightFor(layout),
      ),
      body: AppBackground(child: SafeArea(top: false, child: _body(layout))),
    );
  }

  Widget _body(ScreenLayout layout) {
    final pad = EdgeInsets.all(16.r);
    // Điện thoại ngang: công tắc | mặt sân, dưới cùng là giao diện + ngôn ngữ
    // trên một hàng — vừa một màn hình.
    if (layout == ScreenLayout.compactLandscape) {
      return Padding(
        padding: pad,
        child: FitToScreen(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    child: Column(
                      children: [
                        SoundCard(dense: true),
                        AccessibilityCard(dense: true),
                      ],
                    ),
                  ),
                  SizedBox(width: 12.r),
                  const Expanded(child: BoardStyleCard(columns: 3)),
                ],
              ),
              const ThemeLanguageCard(layout: ScreenLayout.compactLandscape),
            ],
          ),
        ),
      );
    }
    final compact = layout.isCompact;
    int? styleColumns;
    if (compact) styleColumns = 3;
    final cards = [
      SoundCard(dense: compact),
      AccessibilityCard(dense: compact),
      BoardStyleCard(columns: styleColumns),
      ThemeLanguageCard(layout: layout),
    ];
    // Điện thoại dọc: một cột vừa màn hình. Màn rộng (web): một cột, cuộn.
    Widget content = ListView(padding: pad, shrinkWrap: true, children: cards);
    if (compact) {
      content = Padding(
        padding: pad,
        child: FitToScreen(
          child: Column(mainAxisSize: MainAxisSize.min, children: cards),
        ),
      );
    }
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 560.r),
        child: content,
      ),
    );
  }
}
