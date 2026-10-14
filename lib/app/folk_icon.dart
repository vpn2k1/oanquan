import 'dart:math';

import 'package:flutter/material.dart';

import 'theme.dart';

/// Bộ biểu tượng nét tròn lấy cảm hứng từ quân gốm và nét khắc trên bàn gỗ.
class FolkIcon extends StatelessWidget {
  const FolkIcon(
    this.icon, {
    super.key,
    this.size,
    this.color,
    this.semanticLabel,
  });

  final IconData icon;
  final double? size;
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    final dimension = size ?? theme.size ?? 24;
    final paintColor = color ?? theme.color ?? AppColors.tealDeep;
    final image = SizedBox.square(
      dimension: dimension,
      child: CustomPaint(painter: _FolkIconPainter(icon, paintColor)),
    );
    return semanticLabel == null
        ? image
        : Semantics(label: semanticLabel, child: image);
  }
}

class _FolkIconPainter extends CustomPainter {
  const _FolkIconPainter(this.icon, this.color);

  final IconData icon;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24, size.height / 24);
    final ink = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.1
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()..color = color;
    final gold = Paint()..color = Color.lerp(color, AppColors.gold, 0.65)!;

    void line(double x1, double y1, double x2, double y2, [Paint? paint]) =>
        canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint ?? ink);
    void dot(double x, double y, double radius, [Paint? paint]) =>
        canvas.drawCircle(Offset(x, y), radius, paint ?? fill);
    void oval(
      double left,
      double top,
      double right,
      double bottom, [
      Paint? paint,
    ]) =>
        canvas.drawOval(Rect.fromLTRB(left, top, right, bottom), paint ?? ink);
    void poly(List<Offset> points, {bool close = false, Paint? paint}) {
      final path = Path()..addPolygon(points, close);
      canvas.drawPath(path, paint ?? ink);
    }

    void rounded(
      double left,
      double top,
      double right,
      double bottom,
      double radius, [
      Paint? paint,
    ]) => canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(left, top, right, bottom),
        Radius.circular(radius),
      ),
      paint ?? ink,
    );

    if (icon == Icons.play_arrow_rounded ||
        icon == Icons.play_circle_fill_rounded) {
      if (icon == Icons.play_circle_fill_rounded) dot(12, 12, 10, gold);
      poly(
        const [Offset(8, 5), Offset(19, 12), Offset(8, 19)],
        close: true,
        paint: icon == Icons.play_circle_fill_rounded
            ? (Paint()..color = AppColors.tealDeep)
            : fill,
      );
    } else if (icon == Icons.pause_rounded) {
      rounded(6, 4, 10, 20, 1.3, fill);
      rounded(14, 4, 18, 20, 1.3, fill);
    } else if (icon == Icons.fast_forward_rounded) {
      poly(const [Offset(3, 5), Offset(12, 12), Offset(3, 19)], close: true);
      poly(const [Offset(12, 5), Offset(21, 12), Offset(12, 19)], close: true);
    } else if (icon == Icons.replay_rounded || icon == Icons.undo_rounded) {
      final reverse = icon == Icons.undo_rounded;
      canvas.drawArc(
        const Rect.fromLTRB(4, 4, 20, 20),
        reverse ? -0.4 : 2.65,
        pi * 1.65,
        false,
        ink,
      );
      if (reverse) {
        poly(const [Offset(4, 8), Offset(4, 15), Offset(10, 14)]);
      } else {
        poly(const [Offset(20, 9), Offset(20, 16), Offset(14, 15)]);
      }
      dot(12, 12, 1.3, gold);
    } else if (icon == Icons.home_rounded || icon == Icons.add_home_rounded) {
      poly(const [Offset(3, 11), Offset(12, 3), Offset(21, 11)]);
      poly(const [
        Offset(5, 10),
        Offset(5, 21),
        Offset(19, 21),
        Offset(19, 10),
      ]);
      rounded(10, 14, 14, 21, 1, gold);
      if (icon == Icons.add_home_rounded) {
        dot(19, 5, 4, gold);
        line(17, 5, 21, 5);
        line(19, 3, 19, 7);
      }
    } else if (icon == Icons.menu_book_rounded || icon == Icons.rule_rounded) {
      poly(const [
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
      line(12, 6, 12, 20);
      line(5.5, 9, 9.5, 9, gold);
      line(14.5, 9, 18.5, 9, gold);
      if (icon == Icons.rule_rounded) {
        line(5.5, 12, 9.5, 12);
        line(14.5, 12, 18.5, 12);
      }
    } else if (icon == Icons.emoji_events_rounded ||
        icon == Icons.workspace_premium_rounded) {
      if (icon == Icons.emoji_events_rounded) {
        rounded(6, 4, 18, 14, 3);
        canvas.drawArc(
          const Rect.fromLTRB(2, 5, 8, 12),
          pi / 2,
          pi,
          false,
          ink,
        );
        canvas.drawArc(
          const Rect.fromLTRB(16, 5, 22, 12),
          -pi / 2,
          pi,
          false,
          ink,
        );
        line(12, 14, 12, 20);
        line(7, 21, 17, 21);
        dot(12, 9, 2, gold);
      } else {
        poly(const [
          Offset(6, 3),
          Offset(10, 3),
          Offset(12, 9),
          Offset(14, 3),
          Offset(18, 3),
          Offset(15, 12),
        ]);
        dot(12, 16, 6, gold);
        poly(
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
          paint: fill,
        );
      }
    } else if (icon == Icons.settings_rounded) {
      for (var i = 0; i < 8; i++) {
        final a = i * pi / 4;
        line(
          12 + cos(a) * 7,
          12 + sin(a) * 7,
          12 + cos(a) * 10,
          12 + sin(a) * 10,
        );
      }
      dot(12, 12, 6, gold);
      oval(9, 9, 15, 15, Paint()..color = AppColors.tealDeep);
    } else if (icon == Icons.smart_toy_rounded) {
      rounded(3, 7, 21, 20, 4);
      line(12, 7, 12, 4);
      dot(12, 3, 1.7, gold);
      dot(8, 12, 1.2, fill);
      dot(16, 12, 1.2, fill);
      canvas.drawArc(
        const Rect.fromLTRB(8, 12, 16, 18),
        0.15,
        pi - 0.3,
        false,
        ink,
      );
      line(3, 13, 1.5, 13);
      line(21, 13, 22.5, 13);
    } else if (icon == Icons.sports_esports_rounded) {
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
      canvas.drawPath(pad, ink);
      line(6, 12, 10, 12);
      line(8, 10, 8, 14);
      dot(16, 11, 1.3, gold);
      dot(19, 13, 1.3, gold);
    } else if (icon == Icons.people_alt_rounded ||
        icon == Icons.person_add_alt_rounded ||
        icon == Icons.person_pin_rounded) {
      oval(8, 3, 16, 11);
      canvas.drawArc(const Rect.fromLTRB(4, 12, 20, 25), pi, pi, false, ink);
      if (icon == Icons.people_alt_rounded) {
        oval(2, 7, 7, 12);
        oval(17, 7, 22, 12);
        line(2, 18, 5, 15);
        line(22, 18, 19, 15);
      } else if (icon == Icons.person_add_alt_rounded) {
        line(18, 5, 23, 5, gold);
        line(20.5, 2.5, 20.5, 7.5, gold);
      } else if (icon == Icons.person_pin_rounded) {
        dot(19, 6, 3.2, gold);
        dot(19, 6, 1, fill);
      }
    } else if (icon == Icons.public_rounded) {
      oval(2, 2, 22, 22);
      oval(7, 2, 17, 22);
      line(3, 12, 21, 12);
      line(6, 6, 18, 6, gold);
      line(6, 18, 18, 18, gold);
    } else if (icon == Icons.flag_rounded) {
      line(5, 3, 5, 22);
      poly(
        const [Offset(5, 4), Offset(19, 5), Offset(16, 12), Offset(5, 12)],
        close: true,
        paint: gold,
      );
      line(5, 12, 5, 4);
    } else if (icon == Icons.diamond_rounded) {
      poly(const [
        Offset(6, 5),
        Offset(18, 5),
        Offset(22, 10),
        Offset(12, 21),
        Offset(2, 10),
      ], close: true);
      poly(const [Offset(2, 10), Offset(22, 10)]);
      poly(const [
        Offset(6, 5),
        Offset(9, 10),
        Offset(12, 21),
        Offset(15, 10),
        Offset(18, 5),
      ]);
    } else if (icon == Icons.savings_rounded) {
      rounded(3, 8, 21, 19, 5);
      line(8, 8, 9, 5);
      line(15, 8, 14, 5);
      line(8, 19, 8, 21);
      line(17, 19, 17, 21);
      dot(16.5, 12, 1.2, gold);
      line(10, 10, 14, 10);
      dot(12, 4, 2, gold);
    } else if (icon == Icons.category_rounded) {
      rounded(3, 3, 10, 10, 1.5, gold);
      rounded(14, 3, 21, 10, 1.5);
      rounded(3, 14, 10, 21, 1.5);
      poly(const [
        Offset(17.5, 13),
        Offset(22, 21),
        Offset(13, 21),
      ], close: true);
    } else if (icon == Icons.check_circle_rounded ||
        icon == Icons.block_rounded) {
      oval(2, 2, 22, 22);
      if (icon == Icons.check_circle_rounded) {
        poly(const [Offset(6, 12), Offset(10, 16), Offset(18, 8)], paint: ink);
      } else {
        line(5, 19, 19, 5);
      }
    } else if (icon == Icons.lock_rounded) {
      rounded(4, 10, 20, 21, 2);
      canvas.drawArc(const Rect.fromLTRB(7, 2, 17, 15), pi, pi, false, ink);
      dot(12, 15, 1.5, gold);
    } else if (icon == Icons.info_outline_rounded) {
      oval(2, 2, 22, 22);
      dot(12, 7, 1.3, gold);
      line(12, 11, 12, 17);
    } else if (icon == Icons.lightbulb_rounded) {
      final bulb = Path()
        ..moveTo(8, 17)
        ..quadraticBezierTo(7, 14, 5, 12)
        ..arcToPoint(const Offset(19, 12), radius: const Radius.circular(7))
        ..quadraticBezierTo(17, 14, 16, 17)
        ..close();
      canvas.drawPath(bulb, ink);
      line(9, 19, 15, 19);
      line(10, 22, 14, 22);
      dot(12, 10, 2, gold);
    } else if (icon == Icons.volume_up_rounded ||
        icon == Icons.volume_off_rounded) {
      poly(const [
        Offset(3, 9),
        Offset(7, 9),
        Offset(12, 5),
        Offset(12, 19),
        Offset(7, 15),
        Offset(3, 15),
      ], close: true);
      if (icon == Icons.volume_up_rounded) {
        canvas.drawArc(
          const Rect.fromLTRB(11, 6, 20, 18),
          -pi / 2,
          pi,
          false,
          ink,
        );
        canvas.drawArc(
          const Rect.fromLTRB(10, 2, 24, 22),
          -pi / 2,
          pi,
          false,
          ink,
        );
      } else {
        line(16, 9, 21, 15);
        line(21, 9, 16, 15);
      }
    } else if (icon == Icons.vibration_rounded) {
      rounded(7, 3, 17, 21, 2);
      line(10, 18, 14, 18, gold);
      line(3, 8, 3, 16);
      line(21, 8, 21, 16);
    } else if (icon == Icons.motion_photos_off_rounded) {
      oval(5, 5, 19, 19);
      dot(12, 12, 3, gold);
      line(3, 21, 21, 3);
    } else if (icon == Icons.palette_rounded) {
      final shape = Path()
        ..moveTo(12, 3)
        ..arcToPoint(const Offset(21, 12), radius: const Radius.circular(9))
        ..quadraticBezierTo(21, 16, 17, 16)
        ..lineTo(15, 15)
        ..quadraticBezierTo(12, 14, 12, 18)
        ..quadraticBezierTo(12, 22, 8, 21)
        ..arcToPoint(const Offset(12, 3), radius: const Radius.circular(9));
      canvas.drawPath(shape, ink);
      dot(8, 8, 1.3, gold);
      dot(15, 7, 1.3, gold);
      dot(7, 15, 1.3, gold);
    } else if (icon == Icons.login_rounded || icon == Icons.save_alt_rounded) {
      if (icon == Icons.login_rounded) {
        poly(const [
          Offset(10, 3),
          Offset(20, 3),
          Offset(20, 21),
          Offset(10, 21),
        ]);
        line(3, 12, 15, 12);
        poly(const [Offset(11, 8), Offset(15, 12), Offset(11, 16)]);
      } else {
        line(12, 3, 12, 15);
        poly(const [Offset(8, 11), Offset(12, 15), Offset(16, 11)]);
        poly(const [
          Offset(4, 17),
          Offset(4, 21),
          Offset(20, 21),
          Offset(20, 17),
        ]);
      }
    } else if (icon == Icons.cloud_off_rounded) {
      final cloud = Path()
        ..moveTo(5, 18)
        ..quadraticBezierTo(1, 16, 3, 12)
        ..quadraticBezierTo(4, 9, 7, 9)
        ..quadraticBezierTo(9, 3, 15, 5)
        ..quadraticBezierTo(19, 6, 19, 10)
        ..quadraticBezierTo(23, 12, 21, 16)
        ..quadraticBezierTo(20, 18, 17, 18);
      canvas.drawPath(cloud, ink);
      line(3, 3, 21, 21);
    } else {
      // Chỉ dùng khi thêm hành động mới mà chưa có nét vẽ riêng.
      dot(12, 12, 7, gold);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_FolkIconPainter old) =>
      old.icon != icon || old.color != color;
}
