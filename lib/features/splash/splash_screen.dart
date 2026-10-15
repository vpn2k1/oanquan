import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 1400),
        )
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
    return Scaffold(
      backgroundColor: const Color(0xFFB55D2D),
      body: FadeTransition(
        opacity: _c,
        child: SizedBox.expand(
          child: Image.asset('assets/splash.png', fit: BoxFit.contain),
        ),
      ),
    );
  }
}
