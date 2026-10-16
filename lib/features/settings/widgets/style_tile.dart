import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../app/folk_art.dart';

/// Ô xem trước: mặt sân + một hàng ô kẻ bằng dụng cụ tương ứng.
class StyleTile extends StatelessWidget {
  const StyleTile({
    super.key,
    required this.label,
    required this.style,
    required this.selected,
    required this.onTap,
    this.width,
  });

  final String label;

  /// Bề ngang ô; mặc định 132 (.r).
  final double? width;
  final FolkStyle? style;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    var borderColor = scheme.onSurface.withValues(alpha: 0.45);
    var borderWidth = 1.8;
    if (selected) {
      borderColor = scheme.primary;
      borderWidth = 2.8;
    }
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14.r),
        child: Container(
          width: width ?? 132.r,
          padding: EdgeInsets.all(4.r),
          decoration: ShapeDecoration(
            shape: ChalkBorder(
              radius: 14.r,
              color: borderColor,
              width: borderWidth,
            ),
          ),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10.r),
                child: SizedBox(
                  height: _previewHeight(width),
                  width: double.infinity,
                  child: CustomPaint(painter: PreviewPainter(style)),
                ),
              ),
              SizedBox(height: 4.r),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PreviewPainter extends CustomPainter {
  PreviewPainter(this.style);
  final FolkStyle? style;

  @override
  void paint(Canvas canvas, Size size) {
    final st = style;
    if (st == null) {
      // "Ngẫu nhiên": ghép bốn mảnh mặt sân.
      final kinds = [
        GroundKind.dirt,
        GroundKind.concrete,
        GroundKind.tiles,
        GroundKind.concrete,
      ];
      for (var i = 0; i < 4; i++) {
        final r = Rect.fromLTWH(
          i * size.width / 4,
          0,
          size.width / 4,
          size.height,
        );
        canvas.save();
        canvas.clipRect(r);
        FolkGround.paint(canvas, size, kinds[i], 3 + i);
        canvas.restore();
      }
      final tp = TextPainter(
        text: TextSpan(
          text: '?',
          style: TextStyle(
            fontSize: 34.sp,
            fontWeight: FontWeight.w900,
            color: Color(0xFFF7F4EC),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, size.center(Offset(-tp.width / 2, -tp.height / 2)));
      return;
    }
    FolkGround.paint(canvas, size, st.ground, 11);
    final cell = size.height * 0.46;
    final top = (size.height - cell) / 2;
    final quan = Path()
      ..addArc(Rect.fromLTWH(8, top, cell, cell), pi / 2, pi)
      ..lineTo(8 + cell / 2, top + cell);
    final quanR = Path()
      ..addArc(
        Rect.fromLTWH(size.width - 8 - cell, top, cell, cell),
        -pi / 2,
        pi,
      );
    FolkPen.stroke(canvas, quan, st.pen, width: 2.6.r, seed: 1);
    FolkPen.stroke(canvas, quanR, st.pen, width: 2.6.r, seed: 2);
    final left = 8 + cell / 2;
    final w = (size.width - 16 - cell) / 3;
    for (var i = 0; i < 3; i++) {
      FolkPen.stroke(
        canvas,
        Path()..addRect(Rect.fromLTWH(left + i * w, top, w, cell)),
        st.pen,
        width: 2.4.r,
        seed: 10 + i,
      );
    }
  }

  @override
  bool shouldRepaint(PreviewPainter old) => old.style != style;
}

/// Ô hẹp hơn mặc định thì hình xem trước thấp theo tỉ lệ.
double _previewHeight(double? width) {
  if (width == null) return 64.r;
  return min(64.r, width * 0.36);
}
