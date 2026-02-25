import 'dart:convert';
import 'dart:io';

import 'src/generator/html_generator.dart';
import 'src/generator/mermaid_generator.dart';
import 'src/models/class_info.dart';
import 'src/parser/dart_parser.dart';
import 'src/parser/file_walker.dart';
import 'src/parser/monorepo_walker.dart';

// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;

export 'src/models/class_info.dart';
export 'src/models/relationship.dart';

/// Main entry point for analyzing a Dart project.
class ParseDart {
  /// The root path of the project to analyze.
  final String projectPath;

  ParseDart(this.projectPath);

  /// Analyze the project and return the results.
  Future<ParseResult> analyze() async {
    final walker = FileWalker();
    final filePaths = await walker.walk(projectPath);

    if (filePaths.isEmpty) {
      return ParseResult([], projectPath);
    }

    final parser = DartParser();
    final result = await parser.parseFiles(filePaths, projectPath);

    return ParseResult(result.classes, projectPath, result.errors);
  }

  /// Analyze a monorepo structure, finding all packages and analyzing them together.
  Future<ParseResult> analyzeMonorepo() async {
    final monorepoWalker = MonorepoWalker();
    final packages = await monorepoWalker.findPackages(projectPath);

    if (packages.isEmpty) {
      return ParseResult([], projectPath);
    }

    final allClasses = <ClassInfo>[];
    final allErrors = <String>[];
    final parser = DartParser();

    // Analyze each package
    for (final packagePath in packages) {
      final walker = FileWalker();
      final filePaths = await walker.walk(packagePath);

      if (filePaths.isNotEmpty) {
        final result = await parser.parseFiles(filePaths, projectPath);
        allClasses.addAll(result.classes);
        allErrors.addAll(result.errors);
      }
    }

    return ParseResult(allClasses, projectPath, allErrors);
  }
}

/// Result of analyzing a Dart project.
class ParseResult {
  /// All classes found in the project.
  final List<ClassInfo> classes;

  /// Root path of the analyzed project.
  final String projectPath;

  /// Any errors encountered during parsing.
  final List<String> parseErrors;

  ParseResult(
    this.classes,
    this.projectPath, [
    this.parseErrors = const [],
  ]);

  /// Generate Mermaid diagram as a string.
  String toMermaid() {
    final generator = MermaidGenerator();
    return generator.generate(classes, projectPath: projectPath);
  }

  /// Generate Mermaid diagram for PNG rendering (without click handlers).
  String toMermaidForPng() {
    final generator = MermaidGenerator();
    return generator.generateForPng(classes);
  }

  /// Generate Mermaid diagram as JSON (Mermaid Live Editor format).
  Map<String, dynamic> toMermaidJson() {
    final generator = MermaidGenerator();
    return generator.generateJson(classes, projectPath: projectPath);
  }

  /// Save Mermaid diagram to a file.
  Future<void> saveMermaidFile(String outputPath) async {
    final content = toMermaid();
    final file = File(outputPath);
    await file.parent.create(recursive: true);
    await file.writeAsString(content);
  }

  /// Save Mermaid JSON to a file.
  Future<void> saveJsonFile(String outputPath) async {
    final json = toMermaidJson();
    final encoder = JsonEncoder.withIndent('  ');
    final content = encoder.convert(json);
    final file = File(outputPath);
    await file.parent.create(recursive: true);
    await file.writeAsString(content);
  }

  /// Generate interactive HTML with embedded Mermaid diagram.
  String toHtml() {
    final generator = HtmlGenerator();
    return generator.generateHtml(classes);
  }

  /// Save interactive HTML file.
  Future<void> saveHtmlFile(String outputPath) async {
    final content = toHtml();
    final file = File(outputPath);
    await file.parent.create(recursive: true);
    await file.writeAsString(content);
  }

  /// Save Mermaid diagram as PNG using kroki.io service.
  Future<void> savePngFile(String outputPath) async {
    final mermaidCode = toMermaidForPng();

    try {
      // Use kroki.io to render the diagram via POST request
      final url = Uri.parse('https://kroki.io/mermaid/png');
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'diagram_source': mermaidCode}),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final file = File(outputPath);
        await file.parent.create(recursive: true);
        await file.writeAsBytes(response.bodyBytes);
      } else {
        throw Exception('Failed to render PNG: HTTP ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error saving PNG file: $e');
    }
  }
}
