import 'package:flutter/material.dart';

import 'folk_icon/icon_pen.dart';
import 'folk_icon/media_icons.dart';
import 'folk_icon/misc_icons.dart';
import 'folk_icon/nav_icons.dart';
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
    if (semanticLabel == null) return image;
    return Semantics(label: semanticLabel, child: image);
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
    final pen = IconPen(canvas, color);
    final drawn =
        paintMediaIcon(pen, icon) ||
        paintNavIcon(pen, icon) ||
        paintMiscIcon(pen, icon);
    if (!drawn) {
      // Chỉ dùng khi thêm hành động mới mà chưa có nét vẽ riêng.
      pen.dot(12, 12, 7, pen.gold);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_FolkIconPainter old) =>
      old.icon != icon || old.color != color;
}
