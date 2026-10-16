import 'package:flutter/material.dart';

import '../../../../app/widgets.dart';
import '../../../../l10n/strings.dart';

export 'rules_sheet.dart' show showRulesDialog;

/// Menu tạm dừng; trả 'resume' | 'restart' | 'rules' | 'settings' | 'exit'.
Future<String?> showPauseMenu(BuildContext context) {
  Widget item(BuildContext ctx, IconData icon, String title, String value) =>
      ListTile(
        leading: FolkIcon(icon),
        title: Text(title),
        onTap: () => Navigator.pop(ctx, value),
      );
  return showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          item(ctx, Icons.play_arrow_rounded, Strings.resume, 'resume'),
          item(ctx, Icons.replay_rounded, Strings.restart, 'restart'),
          item(ctx, Icons.rule_rounded, Strings.rules, 'rules'),
          item(ctx, Icons.settings_rounded, Strings.settings, 'settings'),
          item(ctx, Icons.save_alt_rounded, Strings.saveAndExit, 'exit'),
        ],
      ),
    ),
  );
}

/// Hỏi xác nhận rời ván.
Future<bool?> confirmExitDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      content: Text(Strings.confirmExit),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(Strings.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(Strings.ok),
        ),
      ],
    ),
  );
}
