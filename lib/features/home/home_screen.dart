import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app.dart';
import '../../app/folk_art.dart';
import '../../app/router.dart';
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
    final style = FolkStyle.resolve(ref.read(settingsProvider).boardStyle, seed);
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
      const SizedBox(height: 12),
      OutlinedButton.icon(
        icon: const FolkIcon(Icons.menu_book_rounded),
        label: Text(l.tutorial),
        onPressed: () => context.push(Routes.tutorial),
      ),
      const SizedBox(height: 12),
      OutlinedButton.icon(
        icon: const FolkIcon(Icons.emoji_events_rounded),
        label: Text(l.achievements),
        onPressed: () => context.push(Routes.achievements),
      ),
      const SizedBox(height: 12),
      OutlinedButton.icon(
        icon: const FolkIcon(Icons.settings_rounded),
        label: Text(l.settings),
        onPressed: () => context.push(Routes.settings),
      ),
    ];
    final note = <Widget>[
      DecoratedBox(
        decoration: ShapeDecoration(
          color: theme.colorScheme.surface,
          shape: ChalkBorder(radius: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Text(
            l.rulesetNote,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
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
                            children: [
                              ...brand,
                              const SizedBox(height: 12),
                              ...note,
                            ],
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
                        const SizedBox(height: 24),
                        ...note,
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
