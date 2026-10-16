import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/achievements/achievements_screen.dart';
import '../features/game/ui/game_screen.dart';
import '../features/home/home_screen.dart';
import '../features/mode_selection/setup_screen.dart';
import '../features/multiplayer/online_lobby_screen.dart';
import 'features.dart';
import 'update/update_gate.dart';
import '../features/result/result_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/tutorial/tutorial_screen.dart';

abstract final class Routes {
  static const home = '/home';
  static const setup = '/setup';
  static const game = '/game';
  static const result = '/result';
  static const tutorial = '/tutorial';
  static const settings = '/settings';
  static const achievements = '/achievements';
  static const online = '/online';
}

final routerProvider = Provider<GoRouter>(
  (ref) => GoRouter(
    initialLocation: Routes.home,
    routes: [
      GoRoute(path: '/', redirect: (_, _) => Routes.home),
      GoRoute(
        path: Routes.home,
        builder: (_, _) => const UpdateGate(child: HomeScreen()),
      ),
      GoRoute(path: Routes.setup, builder: (_, _) => const SetupScreen()),
      GoRoute(path: Routes.game, builder: (_, _) => const GameScreen()),
      GoRoute(path: Routes.result, builder: (_, _) => const ResultScreen()),
      GoRoute(path: Routes.tutorial, builder: (_, _) => const TutorialScreen()),
      GoRoute(path: Routes.settings, builder: (_, _) => const SettingsScreen()),
      GoRoute(
        path: Routes.achievements,
        builder: (_, _) => const AchievementsScreen(),
      ),
      // Online tạm ẩn: bật lại bằng `kOnlineEnabled` trong lib/app/features.dart.
      if (kOnlineEnabled)
        GoRoute(
          path: Routes.online,
          builder: (_, _) => const OnlineLobbyScreen(),
        ),
    ],
  ),
);
