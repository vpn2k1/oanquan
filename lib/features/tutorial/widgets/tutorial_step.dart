import 'package:flutter/painting.dart';

import '../../../app/theme.dart';
import '../../../l10n/strings.dart';

/// Màu viền đánh dấu ô minh họa (dùng chung cho hình vẽ và chú thích).
Color? markColor(String? mark) => switch (mark) {
  'src' => const Color(0xFFFFFFFF),
  'gap' => const Color(0xFF3FE0C5),
  'eat' => AppColors.gold,
  'pick' => const Color(0xFF7FD1C4),
  'stop' => const Color(0xFFE5604D),
  _ => null,
};

/// Tên gọi của dấu trên ô, cho phần chú thích.
String markLabel(String mark) => switch (mark) {
  'src' => Strings.markSrc,
  'gap' => Strings.markGap,
  'eat' => Strings.markEat,
  'pick' => Strings.markPick,
  _ => Strings.markStop,
};

/// Ô minh họa: số dân, ô quan, có token.
class TutorialCell {
  const TutorialCell(
    this.dan, {
    this.quan = false,
    this.token = false,
    this.mark,
  });
  final int dan;
  final bool quan;
  final bool token;

  /// 'src' nguồn, 'gap' ô trống, 'eat' bị ăn, 'pick' bốc tiếp, 'stop' dừng.
  final String? mark;
}

class TutorialStep {
  const TutorialStep(
    this.title,
    this.body,
    this.cells, {
    this.arrows = false,
    this.note,
  });
  final String title;
  final String body;
  final List<TutorialCell> cells;
  final bool arrows;
  final String? note;

  /// Các loại dấu xuất hiện trong hình (theo thứ tự gặp), để vẽ chú thích.
  List<String> get marks => <String>{
    for (final c in cells)
      if (c.mark != null) c.mark!,
  }.toList();

  /// Lời giải tách thành từng ý (mỗi câu một dòng) cho dễ đọc.
  List<String> get points => [
    for (final p in body.split(RegExp(r'(?<=[.!?])\s+')))
      if (p.trim().isNotEmpty) p.trim(),
  ];
}

/// Các bước hướng dẫn, mỗi bước có hàng ô minh họa.
List<TutorialStep> tutorialSteps() {
  return [
    TutorialStep(Strings.tutStep1Title, Strings.tutStep1, const [
      TutorialCell(0, quan: true, token: true),
      TutorialCell(5),
      TutorialCell(5),
      TutorialCell(5),
      TutorialCell(5),
      TutorialCell(5),
      TutorialCell(0, quan: true, token: true),
    ]),
    TutorialStep(Strings.tutStep2Title, Strings.tutStep2, const [
      TutorialCell(0, quan: true, token: true),
      TutorialCell(5),
      TutorialCell(5, mark: 'src'),
      TutorialCell(5),
      TutorialCell(5),
      TutorialCell(5),
      TutorialCell(0, quan: true, token: true),
    ], arrows: true),
    TutorialStep(Strings.tutStep3Title, Strings.tutStep3, const [
      TutorialCell(0, quan: true, token: true),
      TutorialCell(0, mark: 'src'),
      TutorialCell(6),
      TutorialCell(6),
      TutorialCell(6),
      TutorialCell(6),
      TutorialCell(1, quan: true, token: true, mark: 'stop'),
    ]),
    TutorialStep(Strings.tutStep4Title, Strings.tutStep4, const [
      TutorialCell(0, quan: true, token: true),
      TutorialCell(1, mark: 'src'),
      TutorialCell(0, mark: 'gap'),
      TutorialCell(3, mark: 'eat'),
      TutorialCell(0, mark: 'gap'),
      TutorialCell(2, mark: 'eat'),
      TutorialCell(4, quan: true, token: true),
    ]),
    TutorialStep(Strings.tutStep5Title, Strings.tutStep5, const [
      TutorialCell(0, quan: true, token: true),
      TutorialCell(0),
      TutorialCell(0),
      TutorialCell(1, mark: 'src'),
      TutorialCell(0),
      TutorialCell(0, mark: 'gap'),
      TutorialCell(5, quan: true, token: true, mark: 'eat'),
    ], note: '+5 +10'),
    TutorialStep(Strings.tutStep6Title, Strings.tutStep6, const [
      TutorialCell(2, quan: true, token: true),
      TutorialCell(1, mark: 'pick'),
      TutorialCell(1, mark: 'pick'),
      TutorialCell(1, mark: 'pick'),
      TutorialCell(1, mark: 'pick'),
      TutorialCell(1, mark: 'pick'),
      TutorialCell(0, quan: true),
    ], note: '−5'),
  ];
}
