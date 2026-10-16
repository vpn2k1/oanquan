import 'package:flutter/widgets.dart';

/// Giữ nội dung trong đúng khung đang có, không cuộn: giữ bề ngang, chiều cao
/// theo nội dung, và chỉ thu nhỏ đều khi nội dung cao hơn khung (máy rất nhỏ,
/// bàn phím đang mở). Nội dung vừa khung thì hiển thị nguyên cỡ.
class FitToScreen extends StatelessWidget {
  const FitToScreen({
    super.key,
    required this.child,
    this.alignment = Alignment.center,
  });
  final Widget child;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) => FittedBox(
      fit: BoxFit.scaleDown,
      alignment: alignment,
      child: SizedBox(width: c.maxWidth, child: child),
    ),
  );
}
