import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app.dart';
import '../../app/router.dart';
import '../../app/widgets.dart';
import '../game/data/save_repository.dart';
import '../game/game_session.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final hasSave = ref.watch(saveRepositoryProvider).hasSave;
    final theme = Theme.of(context);
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(child: LogoMark(size: 128)),
                    const SizedBox(height: 16),
                    Text(l.appTitle,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w900)),
                    Text(l.appSubtitle,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary)),
                    const SizedBox(height: 32),
                    if (hasSave) ...[
                      FilledButton.icon(
                        key: const Key('continue'),
                        icon: const Icon(Icons.play_circle_fill_rounded),
                        label: Text(l.continueGame),
                        onPressed: () {
                          if (ref.read(gameSessionProvider.notifier).resumeSaved()) {
                            context.push(Routes.game);
                          } else {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(SnackBar(content: Text(l.noSavedGame)));
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                    FilledButton.icon(
                      key: const Key('playNow'),
                      icon: const Icon(Icons.sports_esports_rounded),
                      label: Text(l.playNow),
                      style: hasSave
                          ? FilledButton.styleFrom(
                              backgroundColor: theme.colorScheme.secondary,
                              foregroundColor: Colors.black87)
                          : null,
                      onPressed: () => context.push(Routes.setup),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.menu_book_rounded),
                      label: Text(l.tutorial),
                      onPressed: () => context.push(Routes.tutorial),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.emoji_events_rounded),
                      label: Text(l.achievements),
                      onPressed: () => context.push(Routes.achievements),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.settings_rounded),
                      label: Text(l.settings),
                      onPressed: () => context.push(Routes.settings),
                    ),
                    const SizedBox(height: 24),
                    Text(l.rulesetNote,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
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
