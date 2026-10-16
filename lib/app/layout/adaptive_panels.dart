import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'fit_to_screen.dart';
import 'screen_layout.dart';

/// Thân màn menu gồm hai phần nội dung, xếp theo [ScreenLayout]:
/// - điện thoại ngang: hai cột cạnh nhau ([primary] trái, [secondary] phải),
///   vừa một màn hình;
/// - điện thoại dọc: một cột vừa màn hình;
/// - màn rộng (web, tablet): một cột giữa màn, cuộn khi cần.
class AdaptivePanels extends StatelessWidget {
  const AdaptivePanels({
    super.key,
    required this.primary,
    required this.secondary,
    required this.columnMaxWidth,
    this.gap,
    this.padding,
  });
  final List<Widget> primary;
  final List<Widget> secondary;

  /// Bề ngang tối đa của cột đơn (dọc, màn rộng).
  final double columnMaxWidth;

  /// Khoảng cách giữa hai phần (dọc) hoặc hai cột (ngang).
  final double? gap;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final layout = ScreenLayout.of(context);
    final space = gap ?? 16.r;
    final pad = padding ?? EdgeInsets.all(16.r);
    if (layout == ScreenLayout.compactLandscape) {
      return Padding(
        padding: pad,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: columnMaxWidth * 2),
            child: FitToScreen(
              child: Row(
                children: [
                  Expanded(child: _column(primary)),
                  SizedBox(width: space * 1.5),
                  Expanded(child: _column(secondary)),
                ],
              ),
            ),
          ),
        ),
      );
    }
    final all = [...primary, SizedBox(height: space), ...secondary];
    if (layout == ScreenLayout.compactPortrait) {
      return Padding(
        padding: pad,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: columnMaxWidth),
            child: FitToScreen(child: _column(all)),
          ),
        ),
      );
    }
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: columnMaxWidth),
        child: ListView(padding: pad, shrinkWrap: true, children: all),
      ),
    );
  }

  Widget _column(List<Widget> children) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: children,
  );
}
