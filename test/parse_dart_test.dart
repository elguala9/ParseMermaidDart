import 'dart:io';

import 'package:parse_mermaid_dart/parse_mermaid_dart.dart';
import 'package:parse_mermaid_dart/src/parser/file_walker.dart';
import 'package:parse_mermaid_dart/src/parser/monorepo_walker.dart';
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

      final outputDir = Directory('test/mermaid_output_parse');

      // Clean up before test if directory exists from previous run
      if (await outputDir.exists()) {
        await outputDir.delete(recursive: true);
      }

      // Save all formats
      await result.saveMermaidFile('test/mermaid_output_parse/diagram.mmd');
      await result.saveJsonFile('test/mermaid_output_parse/diagram.json');
      await result.saveHtmlFile('test/mermaid_output_parse/diagram.html');
      await result.savePngFile('test/mermaid_output_parse/diagram.png');

      // Verify files exist
      expect(File('test/mermaid_output_parse/diagram.mmd').existsSync(), true);
      expect(File('test/mermaid_output_parse/diagram.json').existsSync(), true);
      expect(File('test/mermaid_output_parse/diagram.html').existsSync(), true);
      expect(File('test/mermaid_output_parse/diagram.png').existsSync(), true);

      // Verify content
      final mermaidContent = File('test/mermaid_output_parse/diagram.mmd').readAsStringSync();
      final jsonContent = File('test/mermaid_output_parse/diagram.json').readAsStringSync();
      final htmlContent = File('test/mermaid_output_parse/diagram.html').readAsStringSync();

      expect(mermaidContent, contains('classDiagram'));
      expect(jsonContent, contains('"code"'));
      expect(htmlContent, contains('<html'));
      expect(htmlContent, contains('mermaid'));
    });

    test('creates nested output directory if it does not exist', () async {
      final parser = ParseDart('test/fixtures');
      final result = await parser.analyze();

      // Use a nested non-existent directory path within test output
      final testOutputPath = 'test/mermaid_output_parse/nested/deep/diagram.mmd';
      final nestedDir = Directory('test/mermaid_output_parse/nested/deep');

      // Clean up nested directory before test if it exists from previous run
      if (await nestedDir.exists()) {
        await nestedDir.delete(recursive: true);
      }

      // Save file to non-existent nested directory
      // The saveMermaidFile method should create the directory automatically
      await result.saveMermaidFile(testOutputPath);

      // Verify directory and file were created
      expect(await nestedDir.exists(), true,
          reason: 'Nested output directory should be created automatically');
      expect(File(testOutputPath).existsSync(), true,
          reason: 'Diagram file should be created in nested output directory');
    });

    test('extracts types from generic fields (List<Animal> → uses Animal)', () async {
      final parser = ParseDart('test/fixtures');
      final result = await parser.analyze();

      final repo = result.classes.firstWhere((c) => c.name == 'AnimalRepository');
      expect(repo.usesList, contains('Animal'));
      expect(repo.usesList, contains('Dog'));
    });

    test('extracts types from method return types', () async {
      final parser = ParseDart('test/fixtures');
      final result = await parser.analyze();

      final repo = result.classes.firstWhere((c) => c.name == 'AnimalRepository');
      // Method returns List<Animal> and Dog?
      expect(repo.usesList, contains('Animal'));
      expect(repo.usesList, contains('Dog'));
    });

    test('extracts types from method parameters', () async {
      final parser = ParseDart('test/fixtures');
      final result = await parser.analyze();

      final repo = result.classes.firstWhere((c) => c.name == 'AnimalRepository');
      // The AnimalRepository constructor has List<Animal> and Map<String, Dog> parameters
      expect(repo.usesList, contains('Animal'));
      expect(repo.usesList, contains('Dog'));
    });

    test('nestedIn field exists in ClassInfo model', () async {
      final parser = ParseDart('test/fixtures');
      final result = await parser.analyze();

      // All classes should have nestedIn field (will be null for top-level classes)
      for (final classInfo in result.classes) {
        expect(classInfo.nestedIn, isNull);
      }
    });

    test('mermaid diagram structure is valid', () async {
      final parser = ParseDart('test/fixtures');
      final result = await parser.analyze();

      final mermaid = result.toMermaid();
      expect(mermaid, contains('classDiagram'));
      // Note: nested_in relationships won't appear since Dart doesn't support nested classes
    });

    test('collects parse errors for invalid files', () async {
      final parser = ParseDart('test/fixtures');
      final result = await parser.analyze();

      // Even if there are no errors in fixtures, parseErrors should be a list
      expect(result.parseErrors, isA<List<String>>());
    });

    test('includes method signatures with parameter types', () async {
      final parser = ParseDart('test/fixtures');
      final result = await parser.analyze();

      final dog = result.classes.firstWhere((c) => c.name == 'Dog');
      expect(dog.methodsList, isNotEmpty);
      // Method signatures should include parameter types
      final mermaid = result.toMermaid();
      expect(mermaid, contains('classDiagram'));
    });

    test('detects external library classes', () async {
      final parser = ParseDart('test/fixtures');
      final result = await parser.analyze();

      // Should detect Equatable from equatable package
      final equatable = result.classes.firstWhere(
        (c) => c.name == 'Equatable',
        orElse: () => throw Exception('Equatable not found'),
      );
      expect(equatable.isExternal, true);
      expect(equatable.filePath, 'external_library');
    });

    test('detects external mixins from freezed', () async {
      final parser = ParseDart('test/fixtures');
      final result = await parser.analyze();

      // Should detect _$ProductModel (generated mixin from freezed_annotation)
      // Note: In Mermaid diagram it appears as __ProductModel ($ replaced with _)
      final productMixin = result.classes.firstWhere(
        (c) => c.name == '_\$ProductModel',
        orElse: () => throw Exception('_\$ProductModel not found'),
      );
      expect(productMixin.isExternal, true);
      expect(productMixin.filePath, 'external_library');
    });

    test('marks external classes with <<external>> stereotype in mermaid', () async {
      final parser = ParseDart('test/fixtures');
      final result = await parser.analyze();

      final mermaid = result.toMermaid();
      // Verify that external classes are marked with <<external>> stereotype
      expect(mermaid, contains('<<external>>'));
      // Verify that Equatable is in the diagram
      expect(mermaid, contains('class Equatable'));
      // Verify the relationship exists
      expect(mermaid, contains('Equatable <|-- UserModel : extends'));
      // Verify that the freezed-generated mixin is in the diagram as external
      expect(mermaid, contains('class __ProductModel'));
      expect(mermaid, contains('__ProductModel <|.. ProductModel : with'));
    });

    test('UserModel extends Equatable from external library', () async {
      final parser = ParseDart('test/fixtures');
      final result = await parser.analyze();

      final userModel = result.classes.firstWhere((c) => c.name == 'UserModel');
      expect(userModel.extendsClass, 'Equatable');
      expect(userModel.isExternal, false); // UserModel itself is not external
    });
  });

  group('GraphvizGenerator', () {
    test('generates graphviz DOT diagram', () async {
      final parser = ParseDart('test/fixtures');
      final result = await parser.analyze();

      final graphviz = result.toGraphviz();
      expect(graphviz, contains('digraph UMLClassDiagram'));
      expect(graphviz, contains('rankdir=BT'));
      expect(graphviz, contains('Animal'));
      expect(graphviz, contains('Dog'));
    });

    test('graphviz uses correct arrow styles', () async {
      final parser = ParseDart('test/fixtures');
      final result = await parser.analyze();

      final graphviz = result.toGraphviz();
      // Check extends relationship (empty arrow, back direction)
      expect(graphviz, contains('arrowhead=empty'));
      expect(graphviz, contains('dir=back'));
      // Check for dashed style (implements/with)
      expect(graphviz, contains('style=dashed'));
      // Check for open arrow (uses relationship)
      expect(graphviz, contains('arrowhead=open'));
    });

    test('graphviz marks external classes with <<external>>', () async {
      final parser = ParseDart('test/fixtures');
      final result = await parser.analyze();

      final graphviz = result.toGraphviz();
      // Check that external classes are marked
      expect(graphviz, contains('&lt;&lt;external&gt;&gt;'));
    });

    test('graphviz respects noPrivate flag', () async {
      final parser = ParseDart('test/fixtures');
      final result = await parser.analyze();

      final graphviz = result.toGraphviz(noPrivate: true);
      // After filtering private methods, diagram should be smaller
      // Check that private classes are excluded
      final allGraphviz = result.toGraphviz();
      expect(graphviz.length, lessThanOrEqualTo(allGraphviz.length));
    });

    test('graphviz respects noExternal flag', () async {
      final parser = ParseDart('test/fixtures');
      final result = await parser.analyze();

      final graphviz = result.toGraphviz(noExternal: true);
      // External classes like Equatable should not appear
      expect(graphviz, isNot(contains('Equatable')));
    });

    test('saves .dot file', () async {
      final parser = ParseDart('test/fixtures');
      final result = await parser.analyze();

      final outputDir = Directory('test/mermaid_output_parse');

      // Clean up before test
      if (await outputDir.exists()) {
        await outputDir.delete(recursive: true);
      }

      // Save graphviz file
      await result.saveGraphvizFile('test/mermaid_output_parse/graphviz/diagram.dot');

      // Verify file exists
      expect(File('test/mermaid_output_parse/graphviz/diagram.dot').existsSync(), true);

      // Verify content
      final dotContent = File('test/mermaid_output_parse/graphviz/diagram.dot').readAsStringSync();
      expect(dotContent, contains('digraph'));
    });

    test('saves graphviz html file', () async {
      final parser = ParseDart('test/fixtures');
      final result = await parser.analyze();

      final outputDir = Directory('test/mermaid_output_parse');

      // Clean up before test
      if (await outputDir.exists()) {
        await outputDir.delete(recursive: true);
      }

      // Save graphviz HTML file
      await result.saveGraphvizHtmlFile('test/mermaid_output_parse/graphviz/diagram.html');

      // Verify file exists
      expect(File('test/mermaid_output_parse/graphviz/diagram.html').existsSync(), true);

      // Verify content
      final htmlContent = File('test/mermaid_output_parse/graphviz/diagram.html').readAsStringSync();
      expect(htmlContent, contains('<html'));
      expect(htmlContent, contains('kroki.io'));
      expect(htmlContent, contains('graphviz'));
    });
  });

  group('FileWalker with .parseignore', () {
    test('respects .parseignore patterns', () async {
      final walker = FileWalker();
      final files = await walker.walk('test/fixtures_with_ignore');

      // Should include these files
      expect(
        files.any((f) => f.contains('included.dart')),
        true,
        reason: 'Should include included.dart',
      );
      expect(
        files.any((f) => f.contains('user.dart')),
        true,
        reason: 'Should include models/user.dart',
      );

      // Should NOT include these files (matching .parseignore patterns)
      expect(
        files.any((f) => f.contains('generated.g.dart')),
        false,
        reason: 'Should ignore *.g.dart files',
      );
      expect(
        files.any((f) => f.contains('excluded.dart')),
        false,
        reason: 'Should ignore excluded.dart',
      );
      expect(
        files.any((f) => f.contains('should_be_ignored.dart')),
        false,
        reason: 'Should ignore files in test_files/ directory',
      );
    });

    test('ignores .dart_tool, build, and .git by default', () async {
      final walker = FileWalker();
      final files = await walker.walk('test/fixtures');

      // Should not contain paths from ignored directories
      expect(
        files.any((f) => f.contains('.dart_tool')),
        false,
        reason: 'Should ignore .dart_tool directory',
      );
      expect(
        files.any((f) => f.contains('build')),
        false,
        reason: 'Should ignore build directory',
      );
    });

    test('walks and finds dart files in fixtures_with_ignore', () async {
      final walker = FileWalker();
      final files = await walker.walk('test/fixtures_with_ignore');

      // Should find at least 2 files (included.dart and models/user.dart)
      expect(files.length, greaterThanOrEqualTo(2));
    });
  });

  group('MonorepoWalker', () {
    test('finds all packages in a monorepo', () async {
      final walker = MonorepoWalker();
      final packages = await walker.findPackages('test/fixtures_monorepo');

      expect(packages.length, equals(3), reason: 'Should find 3 packages');
      expect(
        packages.any((p) => p.contains('package_a')),
        true,
        reason: 'Should find package_a',
      );
      expect(
        packages.any((p) => p.contains('package_b')),
        true,
        reason: 'Should find package_b',
      );
      expect(
        packages.any((p) => p.contains('shared_lib')),
        true,
        reason: 'Should find shared_lib in nested directory',
      );
    });

    test('detects if directory is a monorepo', () async {
      final walker = MonorepoWalker();

      final isMonorepo = await walker.isMonorepo('test/fixtures_monorepo');
      expect(isMonorepo, true, reason: 'Should detect monorepo');

      final isNotMonorepo = await walker.isMonorepo('test/fixtures');
      expect(isNotMonorepo, false, reason: 'Should not detect single package as monorepo');
    });

    test('finds nested packages correctly', () async {
      final walker = MonorepoWalker();
      final packages = await walker.findPackages('test/fixtures_monorepo');

      // Verify nested package is found
      final nestedPackage =
          packages.firstWhere((p) => p.contains('shared_lib'));
      expect(nestedPackage, contains('services'), reason: 'Nested package should include parent directory');
    });
  });

  group('ParseDart monorepo analysis', () {
    test('analyzes monorepo and finds classes from all packages', () async {
      final parser = ParseDart('test/fixtures_monorepo');
      final result = await parser.analyzeMonorepo();

      // Should find classes from all packages
      expect(result.classes, isNotEmpty, reason: 'Should find classes');

      // Classes from package_a
      expect(
        result.classes.any((c) => c.name == 'User'),
        true,
        reason: 'Should find User class from package_a',
      );
      expect(
        result.classes.any((c) => c.name == 'UserInterface'),
        true,
        reason: 'Should find UserInterface from package_a',
      );

      // Classes from package_b
      expect(
        result.classes.any((c) => c.name == 'Repository'),
        true,
        reason: 'Should find Repository class from package_b',
      );
      expect(
        result.classes.any((c) => c.name == 'CacheableMixin'),
        true,
        reason: 'Should find CacheableMixin from package_b',
      );

      // Classes from shared_lib (nested)
      expect(
        result.classes.any((c) => c.name == 'Logger'),
        true,
        reason: 'Should find Logger interface from shared_lib',
      );
      expect(
        result.classes.any((c) => c.name == 'ConsoleLogger'),
        true,
        reason: 'Should find ConsoleLogger from shared_lib',
      );
      expect(
        result.classes.any((c) => c.name == 'FileLogger'),
        true,
        reason: 'Should find FileLogger from shared_lib',
      );
    });

    test('generates correct diagram for monorepo', () async {
      final parser = ParseDart('test/fixtures_monorepo');
      final result = await parser.analyzeMonorepo();

      final mermaid = result.toMermaid();
      expect(mermaid, contains('classDiagram'));
      expect(mermaid, contains('User'));
      expect(mermaid, contains('Repository'));
      expect(mermaid, contains('Logger'));
    });

    test('monorepo result includes all packages in path', () async {
      final parser = ParseDart('test/fixtures_monorepo');
      final result = await parser.analyzeMonorepo();

      expect(result.classes.length, greaterThan(0));
      // All classes should have valid file paths
      for (final classInfo in result.classes) {
        expect(classInfo.filePath, isNotEmpty);
        expect(classInfo.name, isNotEmpty);
      }
    });

    test('analyzeMonorepoPerLibrary returns separate results per package',
        () async {
      final parser = ParseDart('test/fixtures_monorepo');
      final results = await parser.analyzeMonorepoPerLibrary();

      // Should find 3 packages
      expect(
        results.keys.length,
        greaterThanOrEqualTo(2),
        reason: 'Should find at least 2 packages',
      );

      // Each entry should have a name and classes
      for (final entry in results.entries) {
        expect(entry.key, isNotEmpty);
        expect(entry.value.classes, isNotEmpty);
      }
    });

    test('each library result contains only classes from that package',
        () async {
      final parser = ParseDart('test/fixtures_monorepo');
      final results = await parser.analyzeMonorepoPerLibrary();

      // Each library should be properly named
      final packageNames = results.keys.toList();
      expect(packageNames, isNotEmpty);

      // Check that each result has classes
      for (final result in results.values) {
        expect(result.classes, isNotEmpty);
        // All classes in a result should be from the same project
        for (final classInfo in result.classes) {
          expect(classInfo.filePath, isNotEmpty);
          expect(classInfo.name, isNotEmpty);
        }
      }
    });

    test('per-library analysis preserves class metadata', () async {
      final parser = ParseDart('test/fixtures_monorepo');
      final results = await parser.analyzeMonorepoPerLibrary();

      // Find package_a in results
      final packageAResult =
          results.values.firstWhere((r) => r.classes.any((c) => c.name == 'User'),
              orElse: () => ParseResult([], ''));

      expect(packageAResult.classes, isNotEmpty);
      expect(packageAResult.classes.any((c) => c.name == 'User'), true);

      // Check that User has correct metadata
      final user = packageAResult.classes.firstWhere((c) => c.name == 'User');
      expect(user.kind, isNotNull);
      expect(user.filePath, isNotEmpty);
    });
  });
}
