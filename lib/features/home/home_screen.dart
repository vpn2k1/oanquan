import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/folk_art.dart';
import '../../app/router.dart';
import '../../app/theme.dart';
import '../../app/widgets.dart';
import '../game/data/save_repository.dart';
import '../game/game_session.dart';
import '../settings/settings_controller.dart';
import '../../l10n/strings.dart';

/// Vẽ sẵn mặt sân của ván đã lưu để "Tiếp tục ván" vào là có ngay.
void _warmSavedGround(BuildContext context, WidgetRef ref) {
  final size = MediaQuery.sizeOf(context);
  final dpr = MediaQuery.devicePixelRatioOf(context);
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final save = ref.read(saveRepositoryProvider).load();
    if (save == null) return;
    final seed = save.current.config.seed;
    final style = FolkStyle.resolve(
      ref.read(settingsProvider).boardStyle,
      seed,
    );
    GroundCache.warmUp(size, dpr, style.ground, seed);
  });
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasSave = ref.watch(saveRepositoryProvider).hasSave;
    if (hasSave) _warmSavedGround(context, ref);
    final theme = Theme.of(context);
    ButtonStyle? playNowStyle;
    if (hasSave) {
      playNowStyle = FilledButton.styleFrom(
        backgroundColor: theme.colorScheme.secondary,
        foregroundColor: Colors.black87,
      );
    }
    final brand = <Widget>[Center(child: LogoMark(size: 128.r))];
    final buttons = <Widget>[
      if (hasSave) ...[
        FilledButton.icon(
          key: const Key('continue'),
          icon: const FolkIcon(Icons.play_circle_fill_rounded),
          label: Text(Strings.continueGame),
          onPressed: () {
            if (ref.read(gameSessionProvider.notifier).resumeSaved()) {
              context.push(Routes.game);
            } else {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(Strings.noSavedGame)));
            }
          },
        ),
        SizedBox(height: 12.r),
      ],
      FilledButton.icon(
        key: const Key('playNow'),
        icon: const FolkIcon(Icons.sports_esports_rounded),
        label: Text(Strings.playNow),
        style: playNowStyle,
        onPressed: () => context.push(Routes.setup),
      ),
      SizedBox(height: 18.r),
      // Hàng biểu tượng phụ: Hướng dẫn · Thành tích · Cài đặt (chia đều bề ngang).
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (key, icon, route) in [
            ('tutorial', Icons.menu_book_rounded, Routes.tutorial),
            ('achievements', Icons.emoji_events_rounded, Routes.achievements),
            ('settings', Icons.settings_rounded, Routes.settings),
          ])
            Expanded(
              child: _IconTile(
                key: Key(key),
                icon: icon,
                onTap: () => context.push(route),
              ),
            ),
        ],
      ),
    ];
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          // Ngang hay dọc đều xếp một cột: logo trên, các nút bên dưới.
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24.r, vertical: 16.r),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 420.r),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ...brand,
                    SizedBox(height: 24.r),
                    ...buttons,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Nút biểu tượng vuông viền phấn, nhãn nhỏ bên dưới (hàng phụ ở trang chủ).
class _IconTile extends StatelessWidget {
  const _IconTile({super.key, required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = RcTokens.of(context);
    return Semantics(
      button: true,
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: t.surface,
            shape: ChalkBorder(
              radius: 18.r,
              color: t.text.withValues(alpha: 0.85),
            ),
            child: InkWell(
              customBorder: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(18.r)),
              ),
              onTap: onTap,
              child: SizedBox.square(
                dimension: 60.r,
                child: Center(
                  child: FolkIcon(icon, size: 28.r, color: t.text),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
