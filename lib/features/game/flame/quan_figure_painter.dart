import 'dart:math';
import 'dart:ui';

final _shadow = Paint()..color = const Color(0x44000000);
final _ink = Paint()..color = const Color(0xFF38281E);

/// Quan chibi mặc áo truyền thống, đội khăn xếp, ngồi trên đài sen.
void paintQuanFigure(Canvas c, Offset p, double r, {double glow = 0}) {
  if (glow > 0) {
    c.drawCircle(
      p,
      r * (1.5 + glow * 0.4),
      Paint()
        ..color = const Color(0xFFFFE08A).withValues(alpha: 0.35 * glow)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
  }
  c.save();
  c.translate(p.dx, p.dy);
  c.scale(r);
  const gold = Color(0xFFFFCD5B);
  const red = Color(0xFFB73343);
  const deepRed = Color(0xFF7E2537);
  const skin = Color(0xFFFFD6AC);
  // Cánh sen và đế tách khỏi áo để hình đọc rõ ở kích thước nhỏ.
  c.drawOval(const Rect.fromLTRB(-1.03, 0.64, 1.03, 1.05), _shadow);
  for (var i = -2; i <= 2; i++) {
    c.drawOval(
      Rect.fromCenter(
        center: Offset(i * 0.36, 0.68),
        width: 0.55,
        height: 0.42,
      ),
      Paint()..color = _petalColor(i),
    );
  }
  c.drawOval(
    const Rect.fromLTRB(-0.85, 0.64, 0.85, 0.9),
    Paint()..color = const Color(0xFFFFD990),
  );
  // Áo dài với nẹp vàng và tay áo xòe.
  final robe = Path()
    ..moveTo(-0.5, 0.12)
    ..quadraticBezierTo(-0.8, 0.28, -0.75, 0.7)
    ..quadraticBezierTo(0, 0.91, 0.75, 0.7)
    ..quadraticBezierTo(0.8, 0.28, 0.5, 0.12)
    ..close();
  c.drawPath(robe, Paint()..color = deepRed);
  c.drawOval(
    const Rect.fromLTRB(-0.72, 0.22, 0.72, 0.79),
    Paint()..color = red,
  );
  c.drawPath(
    Path()
      ..moveTo(-0.19, 0.17)
      ..lineTo(0, 0.31)
      ..lineTo(0.19, 0.17),
    Paint()
      ..color = gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.09
      ..strokeJoin = StrokeJoin.round,
  );
  c.drawLine(
    const Offset(0, 0.31),
    const Offset(0, 0.69),
    Paint()
      ..color = gold
      ..strokeWidth = 0.075,
  );
  c.drawCircle(const Offset(0, 0.49), 0.055, Paint()..color = gold);
  // Mặt tròn, tóc và khăn xếp gợi hình ông quan dân gian.
  c.drawCircle(const Offset(0, -0.32), 0.61, Paint()..color = deepRed);
  c.drawCircle(const Offset(0, -0.29), 0.54, Paint()..color = skin);
  c.drawOval(
    const Rect.fromLTRB(-0.52, -0.94, 0.52, -0.52),
    Paint()..color = deepRed,
  );
  c.drawRRect(
    RRect.fromRectAndRadius(
      const Rect.fromLTRB(-0.66, -0.82, 0.66, -0.56),
      const Radius.circular(0.12),
    ),
    Paint()..color = red,
  );
  c.drawLine(
    const Offset(-0.53, -0.69),
    const Offset(0.53, -0.69),
    Paint()
      ..color = gold
      ..strokeWidth = 0.075,
  );
  c.drawCircle(const Offset(0, -0.7), 0.08, Paint()..color = gold);
  c.drawCircle(const Offset(-0.22, -0.29), 0.055, _ink);
  c.drawCircle(const Offset(0.22, -0.29), 0.055, _ink);
  c.drawCircle(
    const Offset(-0.4, -0.12),
    0.09,
    Paint()..color = const Color(0x99F28F83),
  );
  c.drawCircle(
    const Offset(0.4, -0.12),
    0.09,
    Paint()..color = const Color(0x99F28F83),
  );
  c.drawArc(
    const Rect.fromLTRB(-0.15, -0.2, 0.15, 0.04),
    0.15,
    pi - 0.3,
    false,
    Paint()
      ..color = _ink.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.055
      ..strokeCap = StrokeCap.round,
  );
  c.restore();
}

Color _petalColor(int i) {
  if (i.isEven) return const Color(0xFFFFB6A6);
  return const Color(0xFFF28D8C);
}
