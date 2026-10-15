import 'dart:math';

import 'package:flutter/painting.dart';

import 'ground_colors.dart';

Offset groundPoint(Random r, Size s) =>
    Offset(r.nextDouble() * s.width, r.nextDouble() * s.height);

void paintBlotches(
  Canvas c,
  Size s,
  Random r,
  int n,
  Color dark,
  Color light,
  double minR,
  double maxR,
  double maxAlpha,
) {
  final p = Paint();
  for (var i = 0; i < n; i++) {
    final rad = minR + r.nextDouble() * (maxR - minR);
    p
      ..color = randomOf(
        r,
        dark,
        light,
      ).withValues(alpha: 0.03 + r.nextDouble() * maxAlpha)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, rad * 0.5);
    c.drawCircle(groundPoint(r, s), rad, p);
  }
}

void paintGrit(
  Canvas c,
  Size s,
  Random r,
  double density,
  Color dark,
  Color light,
  double minR,
  double maxR,
  double minA,
  double maxA,
) {
  final n = (s.width * s.height / density).round();
  final p = Paint();
  for (var i = 0; i < n; i++) {
    p.color = randomOf(
      r,
      dark,
      light,
    ).withValues(alpha: minA + r.nextDouble() * (maxA - minA));
    c.drawCircle(groundPoint(r, s), minR + r.nextDouble() * (maxR - minR), p);
  }
}
