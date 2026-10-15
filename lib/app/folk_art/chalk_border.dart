import 'package:flutter/painting.dart';

import 'folk_pen.dart';
import 'folk_style.dart';

/// Viền nét phấn run tay cho nút/thẻ. Hình dạng (vùng bấm, nền) là hình chữ
/// nhật bo góc bình thường; chỉ đường viền được vẽ như kẻ phấn. Seed lấy theo
/// kích thước nên cùng một nút luôn vẽ y như nhau (không nhấp nháy).
class ChalkBorder extends OutlinedBorder {
  const ChalkBorder({
    this.radius = 16,
    this.color = const Color(0xFFF7F4EC),
    this.width = 2.2,
    super.side,
  });

  final double radius;
  final Color color;
  final double width;

  RRect _rrect(Rect rect) =>
      RRect.fromRectAndRadius(rect, Radius.circular(radius));

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(width);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRRect(_rrect(rect).deflate(width));

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRRect(_rrect(rect));

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (rect.isEmpty) return;
    final path = Path()..addRRect(_rrect(rect).deflate(width * 0.9));
    final seed =
        (rect.width.round() * 131 + rect.height.round() * 7) & 0x7fffffff;
    FolkPen.stroke(
      canvas,
      path,
      PenKind.chalk,
      width: width,
      color: color,
      seed: seed,
    );
  }

  @override
  ChalkBorder copyWith({
    BorderSide? side,
    double? radius,
    Color? color,
    double? width,
  }) => ChalkBorder(
    radius: radius ?? this.radius,
    color: color ?? this.color,
    width: width ?? this.width,
    side: side ?? this.side,
  );

  @override
  ShapeBorder scale(double t) => ChalkBorder(
    radius: radius * t,
    color: color,
    width: width * t,
    side: side.scale(t),
  );

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) {
    if (a is ChalkBorder) {
      return ChalkBorder(
        radius: radius,
        color: Color.lerp(a.color, color, t)!,
        width: width,
      );
    }
    return super.lerpFrom(a, t);
  }

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) {
    if (b is ChalkBorder) {
      return ChalkBorder(
        radius: radius,
        color: Color.lerp(color, b.color, t)!,
        width: width,
      );
    }
    return super.lerpTo(b, t);
  }

  @override
  bool operator ==(Object other) =>
      other is ChalkBorder &&
      other.radius == radius &&
      other.color == color &&
      other.width == width;

  @override
  int get hashCode => Object.hash(radius, color, width);
}
