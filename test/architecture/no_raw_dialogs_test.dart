import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final dartFiles = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  String norm(File f) => f.path.replaceAll('\\', '/');

  test('dialogs open through showOurnegoDialog, never showDialog', () {
    final forbidden = RegExp(r'\bshowDialog\s*(<[^>]*>)?\s*\(');
    final offenders = <String>[];
    for (final file in dartFiles) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i].trimLeft();
        if (line.startsWith('//')) continue;
        if (forbidden.hasMatch(line)) {
          offenders.add('${norm(file)}:${i + 1}: $line');
        }
      }
    }
    expect(
      offenders,
      isEmpty,
      reason:
          'Use showOurnegoDialog / showOurnegoMenu so every window shares the '
          'same spring, scrim and closing behavior.\n${offenders.join('\n')}',
    );
  });

  test('sheets open through showOurnegoSheet, never showModalBottomSheet', () {
    final forbidden = RegExp(r'\bshowModalBottomSheet\s*(<[^>]*>)?\s*\(');
    final offenders = <String>[];
    for (final file in dartFiles) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i].trimLeft();
        if (line.startsWith('//')) continue;
        if (forbidden.hasMatch(line)) {
          offenders.add('${norm(file)}:${i + 1}: $line');
        }
      }
    }
    expect(
      offenders,
      isEmpty,
      reason:
          'Use showOurnegoSheet so every sheet shares the same spring, scrim '
          'and drag to dismiss.\n${offenders.join('\n')}',
    );
  });
}
