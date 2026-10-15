import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/game_models/player.dart';
import '../../../l10n/strings.dart';
import 'choice_card.dart';

/// Hàng 3 thẻ chọn độ khó máy (số chấm = độ khó).
class LevelPicker extends StatelessWidget {
  const LevelPicker({super.key, required this.level, required this.onChanged});
  final AiLevel level;
  final ValueChanged<AiLevel> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final levels = [(AiLevel.easy, 1), (AiLevel.medium, 2), (AiLevel.hard, 3)];
    return Row(
      children: [
        for (final (lv, stars) in levels)
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.r),
              child: ChoiceCard(
                key: Key('level_${lv.name}'),
                selected: level == lv,
                onTap: () => onChanged(lv),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var k = 0; k < 3; k++)
                          Icon(
                            Icons.circle,
                            size: 10.r,
                            color: _dotColor(theme, k < stars),
                          ),
                      ],
                    ),
                    SizedBox(height: 6.r),
                    Text(
                      Strings.level(lv),
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16.sp,
                      ),
                    ),
                    Text(
                      Strings.levelDesc(lv),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

Color _dotColor(ThemeData theme, bool filled) {
  if (filled) return theme.colorScheme.primary;
  return theme.colorScheme.outline;
}
