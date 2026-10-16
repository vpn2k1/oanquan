import 'package:flutter/widgets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Kiểu bố cục theo kích thước màn hình.
///
/// - [compactLandscape]: điện thoại nằm ngang (cách chơi chính trên mobile) →
///   chia cột, mọi thứ vừa một màn hình, không vuốt.
/// - [compactPortrait]: điện thoại dọc (trình duyệt điện thoại) → một cột, vừa
///   màn hình.
/// - [wide]: web trên máy tính, tablet → một cột giữa màn, cuộn khi cần.
enum ScreenLayout {
  compactLandscape,
  compactPortrait,
  wide;

  /// Cạnh ngắn dưới mốc này coi là điện thoại (mốc Material cho "compact").
  static const compactShortestSide = 600.0;

  static ScreenLayout fromSize(Size size) {
    if (size.shortestSide >= compactShortestSide) return wide;
    if (size.width > size.height) return compactLandscape;
    return compactPortrait;
  }

  static ScreenLayout of(BuildContext context) =>
      fromSize(MediaQuery.sizeOf(context));

  bool get isCompact => this != wide;
}

/// Chiều cao thanh tiêu đề: điện thoại ngang thấp → gọn hơn, còn lại mặc định.
double? toolbarHeightFor(ScreenLayout layout) {
  if (layout == ScreenLayout.compactLandscape) return 44.r;
  return null;
}
