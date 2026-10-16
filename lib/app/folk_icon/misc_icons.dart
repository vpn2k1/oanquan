import 'dart:math';

import 'package:flutter/material.dart';

import 'icon_pen.dart';

/// Nhóm biểu tượng trạng thái và vật dụng.
/// Trả về true nếu đã vẽ [icon].
bool paintMiscIcon(IconPen p, IconData icon) {
  if (icon == Icons.diamond_rounded) {
    p.poly(const [
      Offset(6, 5),
      Offset(18, 5),
      Offset(22, 10),
      Offset(12, 21),
      Offset(2, 10),
    ], close: true);
    p.poly(const [Offset(2, 10), Offset(22, 10)]);
    p.poly(const [
      Offset(6, 5),
      Offset(9, 10),
      Offset(12, 21),
      Offset(15, 10),
      Offset(18, 5),
    ]);
    return true;
  }
  if (icon == Icons.savings_rounded) {
    p.rounded(3, 8, 21, 19, 5);
    p.line(8, 8, 9, 5);
    p.line(15, 8, 14, 5);
    p.line(8, 19, 8, 21);
    p.line(17, 19, 17, 21);
    p.dot(16.5, 12, 1.2, p.gold);
    p.line(10, 10, 14, 10);
    p.dot(12, 4, 2, p.gold);
    return true;
  }
  if (icon == Icons.category_rounded) {
    p.rounded(3, 3, 10, 10, 1.5, p.gold);
    p.rounded(14, 3, 21, 10, 1.5);
    p.rounded(3, 14, 10, 21, 1.5);
    p.poly(const [
      Offset(17.5, 13),
      Offset(22, 21),
      Offset(13, 21),
    ], close: true);
    return true;
  }
  if (icon == Icons.check_circle_rounded || icon == Icons.block_rounded) {
    p.oval(2, 2, 22, 22);
    if (icon == Icons.check_circle_rounded) {
      p.poly(const [
        Offset(6, 12),
        Offset(10, 16),
        Offset(18, 8),
      ], paint: p.ink);
    } else {
      p.line(5, 19, 19, 5);
    }
    return true;
  }
  if (icon == Icons.lock_rounded) {
    p.rounded(4, 10, 20, 21, 2);
    p.canvas.drawArc(const Rect.fromLTRB(7, 2, 17, 15), pi, pi, false, p.ink);
    p.dot(12, 15, 1.5, p.gold);
    return true;
  }
  if (icon == Icons.info_outline_rounded) {
    p.oval(2, 2, 22, 22);
    p.dot(12, 7, 1.3, p.gold);
    p.line(12, 11, 12, 17);
    return true;
  }
  if (icon == Icons.lightbulb_rounded) {
    final bulb = Path()
      ..moveTo(8, 17)
      ..quadraticBezierTo(7, 14, 5, 12)
      ..arcToPoint(const Offset(19, 12), radius: const Radius.circular(7))
      ..quadraticBezierTo(17, 14, 16, 17)
      ..close();
    p.canvas.drawPath(bulb, p.ink);
    p.line(9, 19, 15, 19);
    p.line(10, 22, 14, 22);
    p.dot(12, 10, 2, p.gold);
    return true;
  }
  if (icon == Icons.palette_rounded) {
    final shape = Path()
      ..moveTo(12, 3)
      ..arcToPoint(const Offset(21, 12), radius: const Radius.circular(9))
      ..quadraticBezierTo(21, 16, 17, 16)
      ..lineTo(15, 15)
      ..quadraticBezierTo(12, 14, 12, 18)
      ..quadraticBezierTo(12, 22, 8, 21)
      ..arcToPoint(const Offset(12, 3), radius: const Radius.circular(9));
    p.canvas.drawPath(shape, p.ink);
    p.dot(8, 8, 1.3, p.gold);
    p.dot(15, 7, 1.3, p.gold);
    p.dot(7, 15, 1.3, p.gold);
    return true;
  }
  if (icon == Icons.close_rounded) {
    p.line(6, 6, 18, 18);
    p.line(18, 6, 6, 18);
    return true;
  }
  if (icon == Icons.swap_horiz_rounded) {
    // Hai mũi tên ngược chiều: hai hướng rải.
    p.poly(const [Offset(3, 9), Offset(20, 9)]);
    p.poly(const [Offset(16, 5), Offset(20, 9), Offset(16, 13)]);
    p.poly(const [Offset(21, 16), Offset(4, 16)]);
    p.poly(const [Offset(8, 12), Offset(4, 16), Offset(8, 20)]);
    return true;
  }
  if (icon == Icons.cloud_off_rounded) {
    final cloud = Path()
      ..moveTo(5, 18)
      ..quadraticBezierTo(1, 16, 3, 12)
      ..quadraticBezierTo(4, 9, 7, 9)
      ..quadraticBezierTo(9, 3, 15, 5)
      ..quadraticBezierTo(19, 6, 19, 10)
      ..quadraticBezierTo(23, 12, 21, 16)
      ..quadraticBezierTo(20, 18, 17, 18);
    p.canvas.drawPath(cloud, p.ink);
    p.line(3, 3, 21, 21);
    return true;
  }
  return false;
}
