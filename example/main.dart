import 'dart:io';

import 'package:parse_dart/parse_dart.dart';

Future<void> main() async {
  // Analyze the test fixtures
  final parser = ParseDart('test/fixtures');
  print('Analyzing Dart project...\n');

  final result = await parser.analyze();

  print('Found ${result.classes.length} classes:\n');
  for (final classInfo in result.classes) {
    print('  - ${classInfo.name} (${classInfo.kind})');
    if (classInfo.extendsClass != null) {
      print('      extends: ${classInfo.extendsClass}');
    }
    if (classInfo.implementsList.isNotEmpty) {
      print('      implements: ${classInfo.implementsList.join(", ")}');
    }
    if (classInfo.withList.isNotEmpty) {
      print('      with: ${classInfo.withList.join(", ")}');
    }
    if (classInfo.usesList.isNotEmpty) {
      print('      uses: ${classInfo.usesList.join(", ")}');
    }
  }

  print('\n--- Mermaid Diagram ---\n');
  print(result.toMermaid());

  // Save outputs
  await result.saveMermaidFile('diagram.mmd');
  await result.saveJsonFile('diagram.json');

  print('\n✓ Saved diagram.mmd and diagram.json');
  print('Copy the JSON output to https://mermaid.live to visualize!');
}
