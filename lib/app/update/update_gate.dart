import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';

import '../../l10n/strings.dart';
import 'store_links.dart';
import 'store_update.dart';
import 'update_checker.dart';
import 'update_snooze.dart';

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
    final result = await UpdateChecker().check();
    final need = result.need;
    if (!mounted || need == UpdateNeeded.none) return;
    final store = result.store;
    // Nhắc nhẹ mà người chơi vừa bấm "Để sau" cho đúng bản này → thôi.
    if (need == UpdateNeeded.soft && store != null) {
      if (await UpdateSnooze.isSnoozed(store.id)) return;
      if (!mounted) return;
    }
    _shown = true;
    await showDialog<void>(
      context: context,
      barrierDismissible: need == UpdateNeeded.soft,
      builder: (_) =>
          UpdateDialog(required: need == UpdateNeeded.required, store: store),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class UpdateDialog extends StatelessWidget {
  /// true: bản đang cài thấp hơn phiên bản tối thiểu, không cho "Để sau".
  final bool required;

  /// Bản mới trên store (nếu biết): tên phiên bản, link, cập nhật trong app.
  final StoreUpdate? store;
  const UpdateDialog({super.key, required this.required, this.store});

  String get _message {
    if (required) return Strings.updateRequiredMsg;
    final version = store?.version;
    if (version != null) return Strings.updateVersionMsg(version);
    return Strings.updateSoftMsg;
  }

  /// Android có Play In-App Updates: cập nhật ngay trong app; không được thì
  /// (hoặc iOS) mở trang app trên store.
  Future<void> _update() async {
    final s = store;
    if (s != null && s.inApp) {
      try {
        final r = await InAppUpdate.performImmediateUpdate();
        if (r == AppUpdateResult.success) return;
      } on Object {
        // Play từ chối luồng trong app → mở store.
      }
    }
    await StoreLinks.open(s?.url);
  }

  void _later(BuildContext context) {
    final s = store;
    if (s != null) UpdateSnooze.snooze(s.id);
    Navigator.pop(context);
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
              key: const Key('updateLater'),
              onPressed: () => _later(context),
              child: Text(Strings.updateLater),
            ),
          FilledButton(
            key: const Key('updateNow'),
            onPressed: _update,
            child: Text(Strings.updateNow),
          ),
        ],
      ),
    );
  }
}
