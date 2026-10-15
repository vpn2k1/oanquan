import 'dart:math';

import 'package:flutter/material.dart';

import '../theme.dart';
import 'icon_pen.dart';

/// Nhóm biểu tượng điều khiển, âm thanh, rung và nhập/xuất.
/// Trả về true nếu đã vẽ [icon].
bool paintMediaIcon(IconPen p, IconData icon) {
  if (icon == Icons.play_arrow_rounded ||
      icon == Icons.play_circle_fill_rounded) {
    var playPaint = p.fill;
    if (icon == Icons.play_circle_fill_rounded) {
      p.dot(12, 12, 10, p.gold);
      playPaint = Paint()..color = AppColors.tealDeep;
    }
    p.poly(
      const [Offset(8, 5), Offset(19, 12), Offset(8, 19)],
      close: true,
      paint: playPaint,
    );
    return true;
  }
  if (icon == Icons.pause_rounded) {
    p.rounded(6, 4, 10, 20, 1.3, p.fill);
    p.rounded(14, 4, 18, 20, 1.3, p.fill);
    return true;
  }
  if (icon == Icons.fast_forward_rounded) {
    p.poly(const [Offset(3, 5), Offset(12, 12), Offset(3, 19)], close: true);
    p.poly(const [Offset(12, 5), Offset(21, 12), Offset(12, 19)], close: true);
    return true;
  }
  if (icon == Icons.replay_rounded || icon == Icons.undo_rounded) {
    final reverse = icon == Icons.undo_rounded;
    var arcStart = 2.65;
    if (reverse) arcStart = -0.4;
    p.canvas.drawArc(
      const Rect.fromLTRB(4, 4, 20, 20),
      arcStart,
      pi * 1.65,
      false,
      p.ink,
    );
    if (reverse) {
      p.poly(const [Offset(4, 8), Offset(4, 15), Offset(10, 14)]);
    } else {
      p.poly(const [Offset(20, 9), Offset(20, 16), Offset(14, 15)]);
    }
    p.dot(12, 12, 1.3, p.gold);
    return true;
  }
  if (icon == Icons.volume_up_rounded || icon == Icons.volume_off_rounded) {
    p.poly(const [
      Offset(3, 9),
      Offset(7, 9),
      Offset(12, 5),
      Offset(12, 19),
      Offset(7, 15),
      Offset(3, 15),
    ], close: true);
    if (icon == Icons.volume_up_rounded) {
      p.canvas.drawArc(
        const Rect.fromLTRB(11, 6, 20, 18),
        -pi / 2,
        pi,
        false,
        p.ink,
      );
      p.canvas.drawArc(
        const Rect.fromLTRB(10, 2, 24, 22),
        -pi / 2,
        pi,
        false,
        p.ink,
      );
    } else {
      p.line(16, 9, 21, 15);
      p.line(21, 9, 16, 15);
    }
    return true;
  }
  if (icon == Icons.vibration_rounded) {
    p.rounded(7, 3, 17, 21, 2);
    p.line(10, 18, 14, 18, p.gold);
    p.line(3, 8, 3, 16);
    p.line(21, 8, 21, 16);
    return true;
  }
  if (icon == Icons.motion_photos_off_rounded) {
    p.oval(5, 5, 19, 19);
    p.dot(12, 12, 3, p.gold);
    p.line(3, 21, 21, 3);
    return true;
  }
  if (icon == Icons.login_rounded || icon == Icons.save_alt_rounded) {
    if (icon == Icons.login_rounded) {
      p.poly(const [
        Offset(10, 3),
        Offset(20, 3),
        Offset(20, 21),
        Offset(10, 21),
      ]);
      p.line(3, 12, 15, 12);
      p.poly(const [Offset(11, 8), Offset(15, 12), Offset(11, 16)]);
    } else {
      p.line(12, 3, 12, 15);
      p.poly(const [Offset(8, 11), Offset(12, 15), Offset(16, 11)]);
      p.poly(const [
        Offset(4, 17),
        Offset(4, 21),
        Offset(20, 21),
        Offset(20, 17),
      ]);
    }
    return true;
  }
  return false;
}
