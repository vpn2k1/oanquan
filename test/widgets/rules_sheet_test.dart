import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:o_quan_viet/app/layout/fit_to_screen.dart';
import 'package:o_quan_viet/features/game/ui/widgets/rule_detail.dart';
import 'package:o_quan_viet/features/game/ui/widgets/rules_sheet.dart';
import 'package:o_quan_viet/features/tutorial/widgets/tutorial_step.dart';

import 'app_flow_test.dart' show pumpApp;
import 'real_fonts.dart';

void main() {
  setUpAll(loadRealFonts);

  test('lời luật tách thành từng ý, có chú thích màu', () {
    final steps = tutorialSteps();
    expect(steps.every((s) => s.points.isNotEmpty), isTrue);
    expect(steps[3].marks, containsAll(['src', 'gap', 'eat']));
  });

  for (final size in const [Size(800, 360), Size(640, 360), Size(360, 640)]) {
    testWidgets('bảng luật vừa màn hình, chuyển mục được ở $size', (t) async {
      await pumpApp(t, size);
      showRulesDialog(t.element(find.byType(Scaffold).first));
      await t.pumpAndSettle();
      final steps = tutorialSteps();
      for (var i = 0; i < steps.length; i++) {
        await t.tap(find.byKey(Key('rule$i')));
        await t.pumpAndSettle();
        expect(t.takeException(), isNull, reason: 'mục ${i + 1} tràn');
        expect(
          find.descendant(
            of: find.byType(RuleDetail),
            matching: find.text(steps[i].title),
          ),
          findsOneWidget,
        );
        final fit = find
            .ancestor(
              of: find.byType(RuleDetail),
              matching: find.byType(FitToScreen),
            )
            .first;
        final box = t.renderObject<RenderBox>(
          find.descendant(of: fit, matching: find.byType(FittedBox)).first,
        );
        final child = (box as RenderProxyBox).child!;
        final scale = box.size.height / child.size.height;
        expect(
          scale,
          greaterThanOrEqualTo(0.8),
          reason: 'mục ${i + 1} co còn ${scale.toStringAsFixed(2)} ở $size',
        );
      }
      await t.tap(find.byKey(const Key('closeRules')));
      await t.pumpAndSettle();
      expect(find.byType(RulesSheet), findsNothing);
    });
  }
}
