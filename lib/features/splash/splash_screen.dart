import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app.dart';
import '../../app/router.dart';
import '../../app/widgets.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
        ..forward().whenComplete(() {
          if (mounted) context.go(Routes.home);
        });

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      body: AppBackground(
        child: Center(
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              final t = Curves.easeOutBack.transform(_c.value.clamp(0, 1));
              return Opacity(
                opacity: _c.value.clamp(0, 1),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Transform.scale(scale: 0.6 + 0.4 * t, child: LogoMark(size: 140, spin: _c.value * 2)),
                    const SizedBox(height: 20),
                    Text(l.appTitle,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
                    Text(l.appSubtitle, style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
