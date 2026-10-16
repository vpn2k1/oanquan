import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/layout/fit_to_screen.dart';
import '../../../../app/widgets.dart';
import '../../../../l10n/strings.dart';
import '../../../tutorial/widgets/tutorial_step.dart';
import 'rule_detail.dart';

/// Bảng luật trong ván: chọn mục ở danh sách, xem hình + giải thích.
void showRulesDialog(BuildContext context) {
  showDialog<void>(context: context, builder: (_) => const RulesSheet());
}

class RulesSheet extends StatefulWidget {
  const RulesSheet({super.key});

  @override
  State<RulesSheet> createState() => _RulesSheetState();
}

class _RulesSheetState extends State<RulesSheet> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final steps = tutorialSteps();
    final screen = MediaQuery.sizeOf(context);
    final landscape = screen.width > screen.height;
    String? footer;
    if (_index == steps.length - 1) footer = Strings.rulesetNote;
    final detail = Padding(
      padding: EdgeInsets.fromLTRB(16.r, 4.r, 16.r, 12.r),
      child: FitToScreen(
        alignment: Alignment.topCenter,
        child: RuleDetail(
          key: ValueKey(_index),
          step: steps[_index],
          footer: footer,
        ),
      ),
    );
    final titles = [for (final s in steps) s.title];
    // Ngang: mục luật thành cột bên trái; dọc: hàng số bên trên.
    Widget body = Column(
      children: [
        _NumberRow(count: steps.length, index: _index, onSelect: _select),
        Expanded(child: detail),
      ],
    );
    if (landscape) {
      body = Row(
        children: [
          SizedBox(
            width: 190.r,
            child: _RuleList(titles: titles, index: _index, onSelect: _select),
          ),
          VerticalDivider(width: 1, color: Theme.of(context).dividerColor),
          Expanded(child: detail),
        ],
      );
    }
    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 16.r, vertical: 12.r),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 900.r,
          maxHeight: min(screen.height - 24.r, 640.r),
        ),
        child: Column(
          children: [
            _Header(onClose: () => Navigator.pop(context)),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }

  void _select(int i) => setState(() => _index = i);
}

class _Header extends StatelessWidget {
  const _Header({required this.onClose});
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(16.r, 6.r, 4.r, 0),
    child: Row(
      children: [
        FolkIcon(
          Icons.rule_rounded,
          color: Theme.of(context).colorScheme.primary,
        ),
        SizedBox(width: 10.r),
        Expanded(
          child: Text(
            Strings.currentRules,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        IconButton(
          key: const Key('closeRules'),
          tooltip: Strings.ok,
          icon: const FolkIcon(Icons.close_rounded),
          onPressed: onClose,
        ),
      ],
    ),
  );
}

/// Danh sách mục luật (màn ngang): số thứ tự + tên mục.
class _RuleList extends StatelessWidget {
  const _RuleList({
    required this.titles,
    required this.index,
    required this.onSelect,
  });
  final List<String> titles;
  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) => FitToScreen(
    alignment: Alignment.topCenter,
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.r, vertical: 4.r),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < titles.length; i++)
            _RuleItem(
              key: Key('rule$i'),
              number: i + 1,
              title: titles[i],
              selected: i == index,
              onTap: () => onSelect(i),
            ),
        ],
      ),
    ),
  );
}

class _RuleItem extends StatelessWidget {
  const _RuleItem({
    super.key,
    required this.number,
    required this.title,
    required this.selected,
    required this.onTap,
  });
  final int number;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    Color? fill;
    if (selected) fill = cs.primary.withValues(alpha: 0.16);
    return Material(
      color: fill ?? Colors.transparent,
      borderRadius: BorderRadius.circular(12.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.r),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.r, vertical: 7.r),
          child: Row(
            children: [
              NumberBadge(number: number, selected: selected),
              SizedBox(width: 10.r),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontWeight: _weight(selected)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Hàng số thứ tự mục luật (màn dọc).
class _NumberRow extends StatelessWidget {
  const _NumberRow({
    required this.count,
    required this.index,
    required this.onSelect,
  });
  final int count;
  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(vertical: 6.r),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          InkWell(
            key: Key('rule$i'),
            customBorder: const CircleBorder(),
            onTap: () => onSelect(i),
            child: Padding(
              padding: EdgeInsets.all(5.r),
              child: NumberBadge(number: i + 1, selected: i == index),
            ),
          ),
      ],
    ),
  );
}

/// Vòng tròn số thứ tự; đang chọn thì tô màu chính.
class NumberBadge extends StatelessWidget {
  const NumberBadge({super.key, required this.number, required this.selected});
  final int number;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    var fill = Colors.transparent;
    var text = cs.onSurface;
    if (selected) {
      fill = cs.primary;
      text = cs.onPrimary;
    }
    return Container(
      width: 28.r,
      height: 28.r,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fill,
        shape: BoxShape.circle,
        border: Border.all(color: cs.primary, width: 2),
      ),
      child: Text(
        '$number',
        style: TextStyle(fontWeight: FontWeight.w900, color: text),
      ),
    );
  }
}

FontWeight _weight(bool selected) {
  if (selected) return FontWeight.w800;
  return FontWeight.w600;
}
