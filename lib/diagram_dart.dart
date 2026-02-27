import 'dart:convert';
import 'dart:io';

import 'src/generator/graphviz_generator.dart';
import 'src/generator/graphviz_html_generator.dart';
import 'src/generator/html_generator.dart';
import 'src/generator/mermaid_generator.dart';
import 'src/models/class_info.dart';
import 'src/parser/dart_parser.dart';
import 'src/parser/file_walker.dart';
import 'src/parser/monorepo_walker.dart';
import 'src/utils/project_detector.dart';

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

  /// Analyzes each package in a monorepo separately.
  /// Returns a map of package name → ParseResult.
  /// Each package result contains only classes from that package.
  Future<Map<String, ParseResult>> analyzeMonorepoPerLibrary() async {
    final monorepoWalker = MonorepoWalker();
    final packages = await monorepoWalker.findPackages(projectPath);

    if (packages.isEmpty) {
      return {};
    }

    final results = <String, ParseResult>{};
    final parser = DartParser();

    for (final packagePath in packages) {
      final walker = FileWalker();
      final filePaths = await walker.walk(packagePath);

      if (filePaths.isNotEmpty) {
        // Pass packagePath as rootPath so filePaths are relative to package root
        final result = await parser.parseFiles(filePaths, packagePath);

        // Get package name from pubspec.yaml
        final packageName =
            await ProjectDetector.getProjectNameOrDefault(packagePath);

        results[packageName] =
            ParseResult(result.classes, packagePath, result.errors);
      }
    }

    return results;
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
  String toMermaid({bool noPrivate = false, bool noExternal = false, bool noMethods = false}) {
    final generator = MermaidGenerator();
    return generator.generate(classes, projectPath: projectPath, noPrivate: noPrivate, noExternal: noExternal, noMethods: noMethods);
  }

  /// Generate Mermaid diagram for PNG rendering (without click handlers).
  String toMermaidForPng({bool noPrivate = false, bool noExternal = false, bool noMethods = false}) {
    final generator = MermaidGenerator();
    return generator.generateForPng(classes, noPrivate: noPrivate, noExternal: noExternal, noMethods: noMethods);
  }

  /// Generate Mermaid diagram as JSON (Mermaid Live Editor format).
  Map<String, dynamic> toMermaidJson({bool noPrivate = false, bool noExternal = false, bool noMethods = false}) {
    final generator = MermaidGenerator();
    return generator.generateJson(classes, projectPath: projectPath, noPrivate: noPrivate, noExternal: noExternal, noMethods: noMethods);
  }

  /// Save Mermaid diagram to a file.
  Future<void> saveMermaidFile(String outputPath, {bool noPrivate = false, bool noExternal = false, bool noMethods = false}) async {
    final content = toMermaid(noPrivate: noPrivate, noExternal: noExternal, noMethods: noMethods);
    final file = File(outputPath);
    await file.parent.create(recursive: true);
    await file.writeAsString(content);
  }

  /// Save Mermaid JSON to a file.
  Future<void> saveJsonFile(String outputPath, {bool noPrivate = false, bool noExternal = false, bool noMethods = false}) async {
    final json = toMermaidJson(noPrivate: noPrivate, noExternal: noExternal, noMethods: noMethods);
    final encoder = JsonEncoder.withIndent('  ');
    final content = encoder.convert(json);
    final file = File(outputPath);
    await file.parent.create(recursive: true);
    await file.writeAsString(content);
  }

  /// Generate interactive HTML with embedded Mermaid diagram.
  String toHtml({bool noPrivate = false, bool noExternal = false, bool noMethods = false}) {
    final generator = HtmlGenerator();
    return generator.generateHtml(classes, noPrivate: noPrivate, noExternal: noExternal, noMethods: noMethods);
  }

  /// Save interactive HTML file.
  Future<void> saveHtmlFile(String outputPath, {bool noPrivate = false, bool noExternal = false, bool noMethods = false}) async {
    final content = toHtml(noPrivate: noPrivate, noExternal: noExternal, noMethods: noMethods);
    final file = File(outputPath);
    await file.parent.create(recursive: true);
    await file.writeAsString(content);
  }

  /// Save Mermaid diagram as PNG using kroki.io service.
  Future<void> savePngFile(String outputPath, {bool noPrivate = false, bool noExternal = false, bool noMethods = false}) async {
    final mermaidCode = toMermaidForPng(noPrivate: noPrivate, noExternal: noExternal, noMethods: noMethods);

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

  /// Generate Graphviz DOT diagram as a string.
  String toGraphviz({bool noPrivate = false, bool noExternal = false, bool noMethods = false, String layout = 'dot'}) {
    final generator = GraphvizGenerator();
    return generator.generate(classes, noPrivate: noPrivate, noExternal: noExternal, noMethods: noMethods, layout: layout);
  }

  /// Save Graphviz DOT diagram to a file.
  Future<void> saveGraphvizFile(String outputPath, {bool noPrivate = false, bool noExternal = false, bool noMethods = false, String layout = 'dot'}) async {
    final content = toGraphviz(noPrivate: noPrivate, noExternal: noExternal, noMethods: noMethods, layout: layout);
    final file = File(outputPath);
    await file.parent.create(recursive: true);
    await file.writeAsString(content);
  }

  /// Generate interactive HTML with embedded Graphviz diagram.
  String toGraphvizHtml({bool noPrivate = false, bool noExternal = false, bool noMethods = false, String layout = 'dot'}) {
    final generator = GraphvizHtmlGenerator();
    return generator.generateHtml(classes, noPrivate: noPrivate, noExternal: noExternal, noMethods: noMethods, layout: layout);
  }

  /// Save interactive Graphviz HTML file using kroki.io rendering.
  Future<void> saveGraphvizHtmlFile(String outputPath, {bool noPrivate = false, bool noExternal = false, bool noMethods = false, String layout = 'dot'}) async {
    final dotCode = toGraphviz(noPrivate: noPrivate, noExternal: noExternal, noMethods: noMethods, layout: layout);
    final content = _generateGraphvizHtmlWithKroki(dotCode);
    final file = File(outputPath);
    await file.parent.create(recursive: true);
    await file.writeAsString(content);
  }

  /// Save Graphviz SVG file.
  Future<void> saveGraphvizSvgFile(String outputPath, {bool noPrivate = false, bool noExternal = false, bool noMethods = false, String layout = 'dot'}) async {
    final dotCode = toGraphviz(noPrivate: noPrivate, noExternal: noExternal, noMethods: noMethods, layout: layout);
    final svg = await _renderGraphvizToSvg(dotCode, layout: layout);
    final file = File(outputPath);
    await file.parent.create(recursive: true);
    await file.writeAsString(svg);
  }

  /// Save Graphviz as PNG file.
  Future<void> saveGraphvizPngFile(String outputPath, {bool noPrivate = false, bool noExternal = false, bool noMethods = false, String layout = 'dot'}) async {
    final dotCode = toGraphviz(noPrivate: noPrivate, noExternal: noExternal, noMethods: noMethods, layout: layout);

    try {
      final png = await _renderGraphvizToPng(dotCode, layout: layout);
      final file = File(outputPath);
      await file.parent.create(recursive: true);
      await file.writeAsBytes(png);
    } catch (e) {
      throw Exception('Error saving Graphviz PNG: $e');
    }
  }

  /// Render Graphviz DOT to SVG using system 'dot' command.
  Future<String> _renderGraphvizToSvg(String dotCode, {String layout = 'dot'}) async {
    final process = await Process.start('dot', ['-K$layout', '-Tsvg']);
    process.stdin.write(dotCode);
    await process.stdin.close();

    final output = await process.stdout.transform(utf8.decoder).join();
    final exitCode = await process.exitCode;

    if (exitCode != 0) {
      throw Exception('dot command failed with exit code $exitCode');
    }

    return output;
  }

  /// Render Graphviz DOT to PNG using system 'dot' command.
  Future<List<int>> _renderGraphvizToPng(String dotCode, {String layout = 'dot'}) async {
    final process = await Process.start('dot', ['-K$layout', '-Tpng']);
    process.stdin.write(dotCode);
    await process.stdin.close();

    final output = await process.stdout.expand((x) => x).toList();
    final exitCode = await process.exitCode;

    if (exitCode != 0) {
      throw Exception('dot command failed with exit code $exitCode');
    }

    return output;
  }

  /// Fallback HTML generation using kroki.io.
  String _generateGraphvizHtmlWithKroki(String dotCode) {
    final encodedDot = base64Url.encode(utf8.encode(dotCode)).toString().replaceAll('=', '');

    return '''<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Dart Class Diagram (Graphviz)</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); min-height: 100vh; display: flex; align-items: center; justify-content: center; padding: 20px; }
        .container { background: white; border-radius: 12px; box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3); padding: 40px; max-width: 1200px; width: 100%; }
        h1 { color: #333; margin-bottom: 30px; font-size: 28px; }
        .diagram-wrapper { display: flex; justify-content: center; padding: 20px; background: #f8f9fa; border-radius: 8px; border: 1px solid #e0e0e0; overflow-x: auto; }
        footer { margin-top: 30px; text-align: center; color: #999; font-size: 12px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>📊 Dart Class Diagram (Graphviz)</h1>
        <div class="diagram-wrapper">
            <img src="https://kroki.io/graphviz/svg/$encodedDot" alt="Dart Class Diagram" style="max-width: 100%; height: auto;">
        </div>
        <footer>
            <p>Generated by diagram_dart • Graphviz DOT rendering via kroki.io (fallback)</p>
        </footer>
    </div>
</body>
</html>''';
  }
}
