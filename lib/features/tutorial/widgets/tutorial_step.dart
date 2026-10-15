import '../../../l10n/strings.dart';

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
