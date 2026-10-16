import 'package:flutter/material.dart';

/// Phóng to bàn chơi bằng hai ngón (hoặc con lăn chuột trên web), từ 1× đến
/// [maxScale]×. Khi đã phóng to thì kéo một ngón để di chuyển; ở 1× không
/// kéo được, để chạm chọn ô không bị cử chỉ kéo tranh mất.
class BoardZoom extends StatefulWidget {
  const BoardZoom({super.key, required this.child, this.maxScale = 3});
  final Widget child;
  final double maxScale;

  @override
  State<BoardZoom> createState() => _BoardZoomState();
}

class _BoardZoomState extends State<BoardZoom> {
  final _controller = TransformationController();
  bool _zoomed = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onInteractionEnd(ScaleEndDetails _) {
    final zoomed = _controller.value.getMaxScaleOnAxis() > 1.01;
    if (zoomed != _zoomed) setState(() => _zoomed = zoomed);
  }

  @override
  Widget build(BuildContext context) => InteractiveViewer(
    transformationController: _controller,
    minScale: 1,
    maxScale: widget.maxScale,
    panEnabled: _zoomed,
    onInteractionEnd: _onInteractionEnd,
    child: widget.child,
  );
}
