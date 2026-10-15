import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../app/folk_art.dart';

class ChoiceCard extends StatelessWidget {
  const ChoiceCard({
    super.key,
    required this.selected,
    required this.onTap,
    required this.child,
  });
  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    var fill = Theme.of(context).cardTheme.color;
    // Viền phấn: phấn cam khi đang chọn, phấn kem mờ khi không.
    var border = cs.onSurface.withValues(alpha: 0.45);
    var borderWidth = 2.0;
    if (selected) {
      fill = cs.primary.withValues(alpha: 0.14);
      border = cs.primary;
      borderWidth = 2.8;
    }
    return Material(
      color: fill,
      shape: ChalkBorder(radius: 18.r, color: border, width: borderWidth),
      child: InkWell(
        borderRadius: BorderRadius.circular(18.r),
        onTap: onTap,
        child: Padding(padding: EdgeInsets.all(10.r), child: child),
      ),
    );
  }
}
