import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'src/generator/html_generator.dart';
import 'src/generator/mermaid_generator.dart';
import 'src/models/class_info.dart';
import 'src/parser/dart_parser.dart';
import 'src/parser/file_walker.dart';

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
    final classes = await parser.parseFiles(filePaths, projectPath);

    return ParseResult(classes, projectPath);
  }
}

/// Result of analyzing a Dart project.
class ParseResult {
  /// All classes found in the project.
  final List<ClassInfo> classes;

  /// Root path of the analyzed project.
  final String projectPath;

  ParseResult(this.classes, this.projectPath);

  /// Generate Mermaid diagram as a string.
  String toMermaid() {
    final generator = MermaidGenerator();
    return generator.generate(classes);
  }

  /// Generate Mermaid diagram as JSON (Mermaid Live Editor format).
  Map<String, dynamic> toMermaidJson() {
    final generator = MermaidGenerator();
    return generator.generateJson(classes);
  }

  /// Save Mermaid diagram to a file.
  Future<void> saveMermaidFile(String outputPath) async {
    final content = toMermaid();
    await File(outputPath).writeAsString(content);
  }

  /// Save Mermaid JSON to a file.
  Future<void> saveJsonFile(String outputPath) async {
    final json = toMermaidJson();
    final content = jsonEncode(json);
    await File(outputPath).writeAsString(content);
  }

  /// Generate interactive HTML with embedded Mermaid diagram.
  String toHtml() {
    final generator = HtmlGenerator();
    return generator.generateHtml(classes);
  }

  /// Save interactive HTML file.
  Future<void> saveHtmlFile(String outputPath) async {
    final content = toHtml();
    await File(outputPath).writeAsString(content);
  }
}
