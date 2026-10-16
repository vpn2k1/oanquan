import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../app/widgets.dart';
import '../../../l10n/strings.dart';
import '../stats_repository.dart';

Color _iconColor(ThemeData theme, bool ok) {
  if (ok) return theme.colorScheme.secondary;
  return theme.disabledColor;
}

Color? _titleColor(ThemeData theme, bool ok) {
  if (ok) return null;
  return theme.disabledColor;
}

IconData _statusIcon(bool ok) {
  if (ok) return Icons.check_circle_rounded;
  return Icons.lock_rounded;
}

Color _statusColor(ThemeData theme, bool ok) {
  if (ok) return Colors.green;
  return theme.disabledColor;
}

IconData _icon(Achievement a) => switch (a) {
  Achievement.firstGame => Icons.flag_rounded,
  Achievement.beatAi => Icons.smart_toy_rounded,
  Achievement.beatHard => Icons.workspace_premium_rounded,
  Achievement.quanHunter => Icons.diamond_rounded,
  Achievement.highScore => Icons.savings_rounded,
  Achievement.allBoards => Icons.category_rounded,
};

/// Một thành tích: biểu tượng, tên, mô tả, trạng thái mở khóa.
/// [dense] cho điện thoại (xếp lưới, gọn hơn).
class AchievementTile extends StatelessWidget {
  const AchievementTile({
    super.key,
    required this.achievement,
    required this.unlocked,
    this.dense = false,
  });
  final Achievement achievement;
  final bool unlocked;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icon = FolkIcon(
      _icon(achievement),
      color: _iconColor(theme, unlocked),
      size: _leadingSize(dense),
    );
    final title = Text(
      Strings.achievement(achievement),
      style: TextStyle(
        fontWeight: FontWeight.w700,
        color: _titleColor(theme, unlocked),
      ),
    );
    final status = FolkIcon(
      _statusIcon(unlocked),
      color: _statusColor(theme, unlocked),
      size: _statusSize(dense),
    );
    final desc = Text(Strings.achievementDesc(achievement));
    if (!dense) {
      return Card(
        child: ListTile(
          leading: icon,
          title: title,
          subtitle: desc,
          trailing: status,
        ),
      );
    }
    // Bản gọn cho điện thoại: tự xếp thay cho ListTile (đỡ khoảng đệm).
    return Card(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10.r, vertical: 8.r),
        child: Row(
          children: [
            icon,
            SizedBox(width: 10.r),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  title,
                  DefaultTextStyle.merge(
                    style: theme.textTheme.bodySmall,
                    child: desc,
                  ),
                ],
              ),
            ),
            SizedBox(width: 6.r),
            status,
          ],
        ),
      ),
    );
  }
}

double _statusSize(bool dense) {
  if (dense) return 18.r;
  return 24.r;
}

double _leadingSize(bool dense) {
  if (dense) return 26.r;
  return 32.r;
}
