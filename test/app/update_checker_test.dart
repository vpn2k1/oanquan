import 'package:flutter_test/flutter_test.dart';
import 'package:o_quan_viet/app/update/app_version.dart';
import 'package:o_quan_viet/app/update/update_checker.dart';

AppVersion v(String s) => AppVersion.tryParse(s)!;

void main() {
  test('parse và so sánh phiên bản', () {
    expect(AppVersion.tryParse('abc'), isNull);
    expect(v('1.2').compareTo(v('1.2.0+0')), 0);
    expect(v('1.2.0+5').compareTo(v('1.10.0')), lessThan(0));
  });

  test('quyết định cập nhật', () {
    final cur = v('1.0.0+3');
    expect(UpdateChecker.decide(cur), UpdateNeeded.none);
    expect(
      UpdateChecker.decide(cur, required: v('1.0.1'), latest: v('2.0.0')),
      UpdateNeeded.required,
    );
    expect(
      UpdateChecker.decide(cur, required: v('0.9.0'), latest: v('1.0.0+4')),
      UpdateNeeded.soft,
    );
    expect(
      UpdateChecker.decide(cur, required: v('1.0.0'), latest: v('1.0.0+3')),
      UpdateNeeded.none,
    );
  });
}
