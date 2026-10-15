import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app.dart';
import '../../app/folk_art.dart';
import '../../app/router.dart';
import '../../app/theme.dart';
import '../../app/widgets.dart';
import '../game/data/save_repository.dart';
import '../game/game_session.dart';
import '../settings/settings_controller.dart';

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
    final l = context.l10n;
    final hasSave = ref.watch(saveRepositoryProvider).hasSave;
    if (hasSave) _warmSavedGround(context, ref);
    final theme = Theme.of(context);
    final brand = <Widget>[
      const Center(child: LogoMark(size: 128)),
      const SizedBox(height: 16),
      Text(
        l.appTitle,
        textAlign: TextAlign.center,
        style: theme.textTheme.headlineLarge?.copyWith(
          fontWeight: FontWeight.w900,
          color: theme.colorScheme.onSurface,
        ),
      ),
      Text(
        l.appSubtitle,
        textAlign: TextAlign.center,
        style: theme.textTheme.titleMedium?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    ];
    final buttons = <Widget>[
      if (hasSave) ...[
        FilledButton.icon(
          key: const Key('continue'),
          icon: const FolkIcon(Icons.play_circle_fill_rounded),
          label: Text(l.continueGame),
          onPressed: () {
            if (ref.read(gameSessionProvider.notifier).resumeSaved()) {
              context.push(Routes.game);
            } else {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(l.noSavedGame)));
            }
          },
        ),
        const SizedBox(height: 12),
      ],
      FilledButton.icon(
        key: const Key('playNow'),
        icon: const FolkIcon(Icons.sports_esports_rounded),
        label: Text(l.playNow),
        style: hasSave
            ? FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.secondary,
                foregroundColor: Colors.black87,
              )
            : null,
        onPressed: () => context.push(Routes.setup),
      ),
      const SizedBox(height: 18),
      // Hàng biểu tượng phụ: Hướng dẫn · Thành tích · Cài đặt (chia đều bề ngang).
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (key, icon, label, route) in [
            ('tutorial', Icons.menu_book_rounded, l.tutorial, Routes.tutorial),
            (
              'achievements',
              Icons.emoji_events_rounded,
              l.achievements,
              Routes.achievements,
            ),
            ('settings', Icons.settings_rounded, l.settings, Routes.settings),
          ])
            Expanded(
              child: _IconTile(
                key: Key(key),
                icon: icon,
                label: label,
                onTap: () => context.push(route),
              ),
            ),
        ],
      ),
    ];
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, c) {
              final landscape = c.maxWidth > c.maxHeight && c.maxWidth > 560;
              if (landscape) {
                // Màn hình ngang: thương hiệu bên trái, nút bên phải.
                return Row(
                  children: [
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [...brand],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 380),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: buttons,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }
              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ...brand,
                        const SizedBox(height: 32),
                        ...buttons,
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Nút biểu tượng vuông viền phấn, nhãn nhỏ bên dưới (hàng phụ ở trang chủ).
class _IconTile extends StatelessWidget {
  const _IconTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = RcTokens.of(context);
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: t.surface,
            shape: ChalkBorder(
              radius: 18,
              color: t.text.withValues(alpha: 0.85),
            ),
            child: InkWell(
              customBorder: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(18)),
              ),
              onTap: onTap,
              child: SizedBox.square(
                dimension: 60,
                child: Center(child: FolkIcon(icon, size: 28, color: t.text)),
              ),
            ),
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: onTap,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: t.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
