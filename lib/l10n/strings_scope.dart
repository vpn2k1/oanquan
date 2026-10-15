import 'package:flutter/widgets.dart';

import 'app_localizations.dart';
import 'strings.dart';

/// Đặt trong `MaterialApp.builder`. Mỗi khi locale đổi: nạp [Strings] mới
/// rồi đánh dấu cả cây con cần build lại (widget đọc `Strings.x` tĩnh nên
/// Flutter không tự biết). Trạng thái các màn được giữ nguyên.
class StringsScope extends StatefulWidget {
  const StringsScope({super.key, required this.child});

  final Widget child;

  @override
  State<StringsScope> createState() => _StringsScopeState();
}

class _StringsScopeState extends State<StringsScope> {
  AppLocalizations? _l;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final l = AppLocalizations.of(context);
    if (identical(l, _l)) return;
    final changed = _l != null;
    _l = l;
    Strings.use(l);
    if (changed) (context as Element).visitChildren(_rebuild);
  }

  static void _rebuild(Element e) {
    e.markNeedsBuild();
    e.visitChildren(_rebuild);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
