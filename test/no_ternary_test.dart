import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Quy ước: không dùng toán tử 3 ngôi (docs/code_conventions.md).
/// Dựa vào `dart format`: `?` của toán tử 3 ngôi luôn có khoảng trắng hai bên,
/// còn `?.`, `??`, `?[`, `...?` và kiểu nullable thì không.
const scanDirs = ['lib', 'test'];
final generated = RegExp(r'(app_localizations[^/\\]*|l10n[/\\]strings)\.dart$');
final ternary = RegExp(r'\s\?\s');
final identChar = RegExp(r'[A-Za-z0-9_$]');

/// Thay comment và nội dung chuỗi bằng khoảng trắng (giữ xuống dòng),
/// nhưng vẫn giữ code trong `${...}`.
String stripNonCode(String src) {
  final out = StringBuffer();
  // Ngữ cảnh lồng nhau: chuỗi đang mở ('\'', '"""', 'r\'', ...) hoặc '{'.
  final stack = <String>[];
  var i = 0;
  while (i < src.length) {
    if (stack.isNotEmpty && stack.last != '{') {
      i = _stepInString(src, i, stack, out);
    } else {
      i = _stepInCode(src, i, stack, out);
    }
  }
  return out.toString();
}

int _stepInString(String src, int i, List<String> stack, StringBuffer out) {
  final ctx = stack.last;
  final isRaw = ctx.startsWith('r');
  final quote = ctx.replaceFirst('r', '');
  if (!isRaw && src[i] == r'\') {
    out.write('  ');
    return i + 2;
  }
  if (src.startsWith(quote, i)) {
    stack.removeLast();
    out.write(quote);
    return i + quote.length;
  }
  if (!isRaw && src.startsWith(r'${', i)) {
    stack.add('{');
    out.write(r'${');
    return i + 2;
  }
  out.write(_blank(src[i]));
  return i + 1;
}

int _stepInCode(String src, int i, List<String> stack, StringBuffer out) {
  if (src.startsWith('//', i)) {
    var end = src.indexOf('\n', i);
    if (end < 0) end = src.length;
    return end;
  }
  if (src.startsWith('/*', i)) {
    var end = src.indexOf('*/', i + 2);
    if (end < 0) {
      end = src.length;
    } else {
      end += 2;
    }
    for (final ch in src.substring(i, end).split('')) {
      out.write(_blank(ch));
    }
    return end;
  }
  final quoteStart = _quoteStart(src, i);
  if (quoteStart >= 0) {
    var quote = src[quoteStart];
    if (src.startsWith(quote * 3, quoteStart)) quote = quote * 3;
    var ctx = quote;
    if (quoteStart > i) ctx = 'r$quote';
    stack.add(ctx);
    out.write(' ' * (quoteStart - i));
    out.write(quote);
    return quoteStart + quote.length;
  }
  final c = src[i];
  if (c == '{' && stack.isNotEmpty) stack.add('{');
  if (c == '}' && stack.isNotEmpty) stack.removeLast();
  out.write(c);
  return i + 1;
}

/// Vị trí dấu nháy mở chuỗi tại [i] (kể cả chuỗi raw `r'...'`), hoặc -1.
int _quoteStart(String src, int i) {
  bool isQuote(int k) => k < src.length && (src[k] == "'" || src[k] == '"');
  final afterIdent = i > 0 && identChar.hasMatch(src[i - 1]);
  if (isQuote(i)) return i;
  if (src[i] == 'r' && !afterIdent && isQuote(i + 1)) return i + 1;
  return -1;
}

String _blank(String ch) {
  if (ch == '\n') return '\n';
  return ' ';
}

void main() {
  test('stripNonCode bỏ chuỗi/comment, giữ nội suy', () {
    expect(ternary.hasMatch(stripNonCode("'a ? b : c' // x ? y")), isFalse);
    expect(ternary.hasMatch(stripNonCode(r"'${a ? 1 : 2}'")), isTrue);
    expect(ternary.hasMatch(stripNonCode('String? a = b ?? c;')), isFalse);
  });

  test('không dùng toán tử 3 ngôi trong lib/ và test/', () {
    final hits = <String>[];
    for (final dir in scanDirs) {
      for (final f in Directory(dir).listSync(recursive: true)) {
        if (f is! File || !f.path.endsWith('.dart')) continue;
        if (generated.hasMatch(f.path)) continue;
        final raw = f.readAsLinesSync();
        final code = stripNonCode(f.readAsStringSync()).split('\n');
        for (var n = 0; n < code.length; n++) {
          if (ternary.hasMatch(' ${code[n]} ')) {
            hits.add('${f.path}:${n + 1}: ${raw[n].trim()}');
          }
        }
      }
    }
    expect(hits, isEmpty, reason: '${hits.length} chỗ:\n${hits.join('\n')}');
  });
}
