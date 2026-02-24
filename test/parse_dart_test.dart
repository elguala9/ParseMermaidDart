import 'dart:io';

import 'package:parse_dart/parse_dart.dart';
import 'package:test/test.dart';

void main() {
  group('ParseDart', () {
    test('analyzes dart files and extracts class information', () async {
      final parser = ParseDart('test/fixtures');
      final result = await parser.analyze();

      expect(result.classes, isNotEmpty);
    });

    test('detects abstract classes', () async {
      final parser = ParseDart('test/fixtures');
      final result = await parser.analyze();

      final animal = result.classes.firstWhere((c) => c.name == 'Animal');
      expect(animal.kind, ClassKind.abstractClass);
    });

    test('detects interface classes', () async {
      final parser = ParseDart('test/fixtures');
      final result = await parser.analyze();

      final runnable = result.classes.firstWhere((c) => c.name == 'Runnable');
      expect(runnable.kind, ClassKind.interfaceClass);
    });

    test('detects mixins', () async {
      final parser = ParseDart('test/fixtures');
      final result = await parser.analyze();

      final swimmer = result.classes.firstWhere((c) => c.name == 'Swimmer');
      expect(swimmer.kind, ClassKind.mixin);
    });

    test('detects sealed classes', () async {
      final parser = ParseDart('test/fixtures');
      final result = await parser.analyze();

      final shape = result.classes.firstWhere((c) => c.name == 'Shape');
      expect(shape.kind, ClassKind.sealedClass);
    });

    test('detects enums', () async {
      final parser = ParseDart('test/fixtures');
      final result = await parser.analyze();

      final status = result.classes.firstWhere((c) => c.name == 'Status');
      expect(status.kind, ClassKind.enumKind);
    });

    test('detects extends relationships', () async {
      final parser = ParseDart('test/fixtures');
      final result = await parser.analyze();

      final dog = result.classes.firstWhere((c) => c.name == 'Dog');
      expect(dog.extendsClass, 'Animal');

      final circle = result.classes.firstWhere((c) => c.name == 'Circle');
      expect(circle.extendsClass, 'Shape');
    });

    test('detects implements relationships', () async {
      final parser = ParseDart('test/fixtures');
      final result = await parser.analyze();

      final dog = result.classes.firstWhere((c) => c.name == 'Dog');
      expect(dog.implementsList, contains('Runnable'));
    });

    test('detects with (mixin) relationships', () async {
      final parser = ParseDart('test/fixtures');
      final result = await parser.analyze();

      final dog = result.classes.firstWhere((c) => c.name == 'Dog');
      expect(dog.withList, contains('Swimmer'));
      expect(dog.withList, contains('PetOwner'));
    });

    test('detects uses relationships from field types', () async {
      final parser = ParseDart('test/fixtures');
      final result = await parser.analyze();

      final repo = result.classes.firstWhere((c) => c.name == 'DogRepository');
      expect(repo.usesList, contains('Dog'));
      expect(repo.usesList, contains('Animal'));
    });

    test('generates mermaid diagram', () async {
      final parser = ParseDart('test/fixtures');
      final result = await parser.analyze();

      final mermaid = result.toMermaid();
      expect(mermaid, contains('classDiagram'));
      expect(mermaid, contains('Animal'));
      expect(mermaid, contains('Dog'));
      expect(mermaid, contains('extends'));
    });

    test('generates mermaid json', () async {
      final parser = ParseDart('test/fixtures');
      final result = await parser.analyze();

      final json = result.toMermaidJson();
      expect(json, containsPair('code', anything));
      expect(json, containsPair('mermaid', anything));
    });

    test('mermaid diagram includes all relationship types', () async {
      final parser = ParseDart('test/fixtures');
      final result = await parser.analyze();

      final mermaid = result.toMermaid();
      expect(mermaid, contains('extends'));
      expect(mermaid, contains('implements'));
      expect(mermaid, contains('with'));
      expect(mermaid, contains('uses'));
    });

    test('detects mixin on constraints', () async {
      final parser = ParseDart('test/fixtures');
      final result = await parser.analyze();

      final swimmer = result.classes.firstWhere((c) => c.name == 'Swimmer');
      expect(swimmer.withList, contains('Animal'));
    });

    test('handles multi-level inheritance', () async {
      final parser = ParseDart('test/fixtures');
      final result = await parser.analyze();

      final b = result.classes.firstWhere((c) => c.name == 'B');
      expect(b.extendsClass, 'A');

      final c = result.classes.firstWhere((c) => c.name == 'C');
      expect(c.extendsClass, 'B');
    });

    test('saves mermaid, json, and html output files', () async {
      final parser = ParseDart('test/fixtures');
      final result = await parser.analyze();

      // Create output directory
      final outputDir = Directory('test/output');
      await outputDir.create(recursive: true);

      // Save all formats
      await result.saveMermaidFile('test/output/diagram.mmd');
      await result.saveJsonFile('test/output/diagram.json');
      await result.saveHtmlFile('test/output/diagram.html');

      // Verify files exist
      expect(File('test/output/diagram.mmd').existsSync(), true);
      expect(File('test/output/diagram.json').existsSync(), true);
      expect(File('test/output/diagram.html').existsSync(), true);

      // Verify content
      final mermaidContent = File('test/output/diagram.mmd').readAsStringSync();
      final jsonContent = File('test/output/diagram.json').readAsStringSync();
      final htmlContent = File('test/output/diagram.html').readAsStringSync();

      expect(mermaidContent, contains('classDiagram'));
      expect(jsonContent, contains('"code"'));
      expect(htmlContent, contains('<html'));
      expect(htmlContent, contains('mermaid'));
    });
  });
}
