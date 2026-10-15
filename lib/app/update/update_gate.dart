import 'package:flutter/material.dart';

import '../../l10n/strings.dart';
import 'store_links.dart';
import 'update_checker.dart';

/// Kiểm tra cập nhật một lần khi trang mở, hiện popup nếu cần.
/// Bọc màn hình chính bằng widget này.
class UpdateGate extends StatefulWidget {
  final Widget child;
  const UpdateGate({super.key, required this.child});

  @override
  State<UpdateGate> createState() => _UpdateGateState();
}

class _UpdateGateState extends State<UpdateGate> {
  static bool _shown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  Future<void> _check() async {
    if (_shown) return;
    final need = await UpdateChecker().check();
    if (!mounted || need == UpdateNeeded.none) return;
    _shown = true;
    await showDialog<void>(
      context: context,
      barrierDismissible: need == UpdateNeeded.soft,
      builder: (_) => UpdateDialog(required: need == UpdateNeeded.required),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class UpdateDialog extends StatelessWidget {
  /// true: bản đang cài thấp hơn phiên bản tối thiểu, không cho "Để sau".
  final bool required;
  const UpdateDialog({super.key, required this.required});

  String get _message {
    if (required) return Strings.updateRequiredMsg;
    return Strings.updateSoftMsg;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !required,
      child: AlertDialog(
        title: Text(Strings.updateTitle),
        content: Text(_message),
        actions: [
          if (!required)
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(Strings.updateLater),
            ),
          FilledButton(
            onPressed: StoreLinks.open,
            child: Text(Strings.updateNow),
          ),
        ],
      ),
    );
  }
}
