import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final dartFiles = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  String norm(File f) => f.path.replaceAll('\\', '/');

  test('no raw Material buttons in lib/', () {
    final forbidden = RegExp(
      r'\b(ElevatedButton|FilledButton|OutlinedButton|TextButton|IconButton|'
      r'FilterChip|ChoiceChip|ActionChip|InputChip|FloatingActionButton)'
      r'(\.\w+)?\s*\(',
    );
    final offenders = <String>[];
    for (final file in dartFiles) {
      final path = norm(file);
      // Theme files only build ButtonStyle/ThemeData safety nets.
      if (path.startsWith('lib/core/theme/')) continue;
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i].trimLeft();
        if (line.startsWith('//')) continue;
        if (forbidden.hasMatch(line)) offenders.add('$path:${i + 1}: $line');
      }
    }
    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

  test('legacy button widgets are gone', () {
    const legacy = [
      'OurnegoPrimaryButton',
      'OurnegoNeutralPrimaryButton',
      'OurnegoButtonStyles',
      'SheetControlButton',
      'BusinessPanelIconButton',
      '_MapControlButton',
      '_CrystalNavItem',
      '_CrystalItemContainer',
      '_LegacyActionButton',
      '_LegacyWideButton',
      '_CompactAction',
      '_brandedSheetButtonStyle',
      '_compactDropdown',
      'circularSurface',
      'authOutlinedOnSurface',
      'authFilledOnSurface',
      'tonalCardButton',
      'BentoActionGrid',
    ];
    final offenders = <String>[];
    for (final file in dartFiles) {
      final content = file.readAsStringSync();
      for (final name in legacy) {
        if (RegExp('\\b$name\\b').hasMatch(content)) {
          offenders.add('${norm(file)}: $name');
        }
      }
    }
    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });
}
