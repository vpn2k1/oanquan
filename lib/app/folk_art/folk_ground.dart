import 'dart:math';

import 'package:flutter/painting.dart';

import 'folk_style.dart';
import 'ground_concrete.dart';
import 'ground_dirt.dart';
import 'ground_tiles.dart';

abstract final class FolkGround {
  static Color baseColor(GroundKind k) => switch (k) {
    GroundKind.dirt => const Color(0xFFC49A6C),
    GroundKind.concrete => const Color(0xFFBAB7AF),
    GroundKind.tiles => const Color(0xFFB5583D),
    GroundKind.darkDirt => const Color(0xFF4A3727),
  };

  static void paint(Canvas c, Size size, GroundKind kind, int seed) {
    final rnd = Random(seed);
    switch (kind) {
      case GroundKind.dirt:
        paintDirt(c, size, rnd);
      case GroundKind.concrete:
        paintConcrete(c, size, rnd);
      case GroundKind.tiles:
        paintTiles(c, size, rnd);
      case GroundKind.darkDirt:
        paintDirt(c, size, rnd, dark: true);
    }
  }
}
