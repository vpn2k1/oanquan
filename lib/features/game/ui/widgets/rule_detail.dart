import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/widgets.dart';
import '../../../../l10n/strings.dart';
import '../../../tutorial/widgets/tutorial_row_painter.dart';
import '../../../tutorial/widgets/tutorial_step.dart';

/// Một mục luật: hình minh họa, chú thích màu, các ý chính.
class RuleDetail extends StatelessWidget {
  const RuleDetail({super.key, required this.step, this.footer});
  final TutorialStep step;

  /// Dòng ghi chú nhỏ cuối mục (vd. nguồn luật).
  final String? footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final legend = <Widget>[
      if (step.arrows)
        _LegendItem(
          swatch: FolkIcon(
            Icons.swap_horiz_rounded,
            size: 18.r,
            color: theme.colorScheme.primary,
          ),
          label: Strings.markDirection,
        ),
      for (final m in step.marks)
        _LegendItem(
          swatch: _MarkSwatch(color: markColor(m)!),
          label: markLabel(m),
        ),
    ];
    final points = step.points;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          step.title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 8.r),
        AspectRatio(
          aspectRatio: 4,
          child: CustomPaint(
            painter: TutorialRowPainter(step.cells, step.arrows, step.note),
          ),
        ),
        if (legend.isNotEmpty) ...[
          SizedBox(height: 6.r),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 14.r,
            runSpacing: 4.r,
            children: legend,
          ),
        ],
        SizedBox(height: 10.r),
        for (var i = 0; i < points.length; i++)
          _Point(text: points[i], last: i == points.length - 1),
        if (footer != null) ...[
          SizedBox(height: 6.r),
          Text(
            footer!,
            style: theme.textTheme.bodySmall?.copyWith(
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }
}

/// Một ý chính: chấm tròn + câu.
class _Point extends StatelessWidget {
  const _Point({required this.text, required this.last});
  final String text;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    var gap = 6.r;
    if (last) gap = 0;
    return Padding(
      padding: EdgeInsets.only(bottom: gap),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 7.r, right: 10.r),
            child: Container(
              width: 7.r,
              height: 7.r,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.swatch, required this.label});
  final Widget swatch;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      swatch,
      SizedBox(width: 6.r),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
    ],
  );
}

/// Ô vuông nhỏ viền màu, giống viền đánh dấu trong hình.
class _MarkSwatch extends StatelessWidget {
  const _MarkSwatch({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 16.r,
    height: 16.r,
    decoration: BoxDecoration(
      color: const Color(0xFFA9692F),
      borderRadius: BorderRadius.circular(4.r),
      border: Border.all(color: color, width: 2.5),
    ),
  );
}
