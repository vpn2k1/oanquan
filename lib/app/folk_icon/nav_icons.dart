import 'dart:math';

import 'package:flutter/material.dart';

import '../theme.dart';
import 'icon_pen.dart';

/// Nhóm biểu tượng điều hướng, trò chơi và người chơi.
/// Trả về true nếu đã vẽ [icon].
bool paintNavIcon(IconPen p, IconData icon) {
  if (icon == Icons.home_rounded || icon == Icons.add_home_rounded) {
    p.poly(const [Offset(3, 11), Offset(12, 3), Offset(21, 11)]);
    p.poly(const [
      Offset(5, 10),
      Offset(5, 21),
      Offset(19, 21),
      Offset(19, 10),
    ]);
    p.rounded(10, 14, 14, 21, 1, p.gold);
    if (icon == Icons.add_home_rounded) {
      p.dot(19, 5, 4, p.gold);
      p.line(17, 5, 21, 5);
      p.line(19, 3, 19, 7);
    }
    return true;
  }
  if (icon == Icons.menu_book_rounded || icon == Icons.rule_rounded) {
    p.poly(const [
      Offset(12, 6),
      Offset(8, 4),
      Offset(3, 5),
      Offset(3, 19),
      Offset(8, 18),
      Offset(12, 20),
      Offset(16, 18),
      Offset(21, 19),
      Offset(21, 5),
      Offset(16, 4),
      Offset(12, 6),
    ]);
    p.line(12, 6, 12, 20);
    p.line(5.5, 9, 9.5, 9, p.gold);
    p.line(14.5, 9, 18.5, 9, p.gold);
    if (icon == Icons.rule_rounded) {
      p.line(5.5, 12, 9.5, 12);
      p.line(14.5, 12, 18.5, 12);
    }
    return true;
  }
  if (icon == Icons.emoji_events_rounded ||
      icon == Icons.workspace_premium_rounded) {
    if (icon == Icons.emoji_events_rounded) {
      p.rounded(6, 4, 18, 14, 3);
      p.canvas.drawArc(
        const Rect.fromLTRB(2, 5, 8, 12),
        pi / 2,
        pi,
        false,
        p.ink,
      );
      p.canvas.drawArc(
        const Rect.fromLTRB(16, 5, 22, 12),
        -pi / 2,
        pi,
        false,
        p.ink,
      );
      p.line(12, 14, 12, 20);
      p.line(7, 21, 17, 21);
      p.dot(12, 9, 2, p.gold);
    } else {
      p.poly(const [
        Offset(6, 3),
        Offset(10, 3),
        Offset(12, 9),
        Offset(14, 3),
        Offset(18, 3),
        Offset(15, 12),
      ]);
      p.dot(12, 16, 6, p.gold);
      p.poly(
        const [
          Offset(12, 12),
          Offset(13.2, 15),
          Offset(16, 15),
          Offset(13.8, 17),
          Offset(14.7, 20),
          Offset(12, 18.3),
          Offset(9.3, 20),
          Offset(10.2, 17),
          Offset(8, 15),
          Offset(10.8, 15),
        ],
        close: true,
        paint: p.fill,
      );
    }
    return true;
  }
  if (icon == Icons.settings_rounded) {
    for (var i = 0; i < 8; i++) {
      final a = i * pi / 4;
      p.line(
        12 + cos(a) * 7,
        12 + sin(a) * 7,
        12 + cos(a) * 10,
        12 + sin(a) * 10,
      );
    }
    p.dot(12, 12, 6, p.gold);
    p.oval(9, 9, 15, 15, Paint()..color = AppColors.tealDeep);
    return true;
  }
  if (icon == Icons.smart_toy_rounded) {
    p.rounded(3, 7, 21, 20, 4);
    p.line(12, 7, 12, 4);
    p.dot(12, 3, 1.7, p.gold);
    p.dot(8, 12, 1.2, p.fill);
    p.dot(16, 12, 1.2, p.fill);
    p.canvas.drawArc(
      const Rect.fromLTRB(8, 12, 16, 18),
      0.15,
      pi - 0.3,
      false,
      p.ink,
    );
    p.line(3, 13, 1.5, 13);
    p.line(21, 13, 22.5, 13);
    return true;
  }
  if (icon == Icons.sports_esports_rounded) {
    final pad = Path()
      ..moveTo(6, 8)
      ..quadraticBezierTo(12, 6, 18, 8)
      ..quadraticBezierTo(21, 10, 22, 17)
      ..quadraticBezierTo(21, 20, 18, 19)
      ..lineTo(15, 16)
      ..lineTo(9, 16)
      ..lineTo(6, 19)
      ..quadraticBezierTo(3, 20, 2, 17)
      ..quadraticBezierTo(3, 10, 6, 8)
      ..close();
    p.canvas.drawPath(pad, p.ink);
    p.line(6, 12, 10, 12);
    p.line(8, 10, 8, 14);
    p.dot(16, 11, 1.3, p.gold);
    p.dot(19, 13, 1.3, p.gold);
    return true;
  }
  if (icon == Icons.people_alt_rounded ||
      icon == Icons.person_add_alt_rounded ||
      icon == Icons.person_pin_rounded) {
    p.oval(8, 3, 16, 11);
    p.canvas.drawArc(const Rect.fromLTRB(4, 12, 20, 25), pi, pi, false, p.ink);
    if (icon == Icons.people_alt_rounded) {
      p.oval(2, 7, 7, 12);
      p.oval(17, 7, 22, 12);
      p.line(2, 18, 5, 15);
      p.line(22, 18, 19, 15);
    } else if (icon == Icons.person_add_alt_rounded) {
      p.line(18, 5, 23, 5, p.gold);
      p.line(20.5, 2.5, 20.5, 7.5, p.gold);
    } else if (icon == Icons.person_pin_rounded) {
      p.dot(19, 6, 3.2, p.gold);
      p.dot(19, 6, 1, p.fill);
    }
    return true;
  }
  if (icon == Icons.public_rounded) {
    p.oval(2, 2, 22, 22);
    p.oval(7, 2, 17, 22);
    p.line(3, 12, 21, 12);
    p.line(6, 6, 18, 6, p.gold);
    p.line(6, 18, 18, 18, p.gold);
    return true;
  }
  if (icon == Icons.flag_rounded) {
    p.line(5, 3, 5, 22);
    p.poly(
      const [Offset(5, 4), Offset(19, 5), Offset(16, 12), Offset(5, 12)],
      close: true,
      paint: p.gold,
    );
    p.line(5, 12, 5, 4);
    return true;
  }
  return false;
}
