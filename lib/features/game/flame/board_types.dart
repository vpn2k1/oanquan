import 'dart:async';

import '../../../app/folk_art.dart';
import '../../../core/game_models/game_event.dart';
import '../../../core/game_models/move.dart';
import '../audio/sound_service.dart';

class BoardVisuals {
  const BoardVisuals({
    this.reducedMotion = false,
    this.speedFactor = 1.0,
    this.colorBlind = false,
    this.styleSetting = FolkStyle.randomId,
  });
  final bool reducedMotion;
  final double speedFactor;
  final bool colorBlind;

  /// Id [FolkStyle] hoặc [FolkStyle.randomId].
  final String styleSetting;
}

class BoardCallbacks {
  const BoardCallbacks({
    required this.onMove,
    required this.onAnimationDone,
    required this.onNotice,
    required this.onSound,
  });
  final void Function(Move move) onMove;
  final void Function(int batchId) onAnimationDone;
  final void Function(GameEvent e) onNotice;
  final void Function(Sfx sfx) onSound;
}

class GameTimer {
  GameTimer(this.left);
  double left;
  final c = Completer<void>();
}
