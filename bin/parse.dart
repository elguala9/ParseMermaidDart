#!/usr/bin/env dart
import 'dart:io';

import 'package:parse_mermaid_dart/parse_mermaid_dart.dart';
import 'package:parse_mermaid_dart/src/utils/parse_ignore_generator.dart';
import 'package:parse_mermaid_dart/src/utils/project_detector.dart';

void main(List<String> args) async {
  try {
    if (args.isEmpty || args.contains('--help') || args.contains('-h')) {
      printHelp();
      return;
    }

    if (args.contains('--version') || args.contains('-v')) {
      print('parse_mermaid_dart version 0.1.0');
      return;
    }

    // Parse command line arguments
    final projectPath = args[0];
    var outputFormat = 'all'; // all, mermaid, json, html, png
    String? outputFile;
    var outputDir = 'mermaid_output_parse';
    var verbose = false;
    var isMonorepo = false;

    for (int i = 1; i < args.length; i++) {
      final arg = args[i];
      if (arg == '--format' && i + 1 < args.length) {
        outputFormat = args[++i];
      } else if (arg == '--output' && i + 1 < args.length) {
        outputFile = args[++i];
      } else if (arg == '--output-dir' && i + 1 < args.length) {
        outputDir = args[++i];
      } else if (arg == '--verbose') {
        verbose = true;
      } else if (arg == '--monorepo') {
        isMonorepo = true;
      }
    }

    // Auto-detect project name
    final projectName =
        await ProjectDetector.getProjectNameOrDefault(projectPath);
    outputFile ??= projectName;

    // Create output directory
    final outputDirectory = Directory(outputDir);
    if (!await outputDirectory.exists()) {
      await outputDirectory.create(recursive: true);
    }

    // Validate project path
    final projectDir = Directory(projectPath);
    if (!projectDir.existsSync()) {
      stderr.writeln('❌ Error: Directory not found: $projectPath');
      exit(1);
    }

    // Ensure .parseignore exists
    final parseIgnoreCreated =
        await ParseIgnoreGenerator.ensureParseIgnoreExists(projectPath);
    if (parseIgnoreCreated && verbose) {
      print('📝 Created .parseignore with default patterns\n');
    }

    if (verbose) {
      if (isMonorepo) {
        print('📦 Analyzing monorepo: $projectPath\n');
      } else {
        print('📁 Analyzing project: $projectPath\n');
      }
    }

    // Analyze the project or monorepo
    final parser = ParseDart(projectPath);
    final ParseResult result;
    if (isMonorepo) {
      result = await parser.analyzeMonorepo();
    } else {
      result = await parser.analyze();
    }

    if (result.classes.isEmpty) {
      print('⚠️  No Dart classes found in the project.');
      return;
    }

    print('✅ Found ${result.classes.length} classes\n');

    if (result.parseErrors.isNotEmpty && verbose) {
      print('[WARNING] Failed to parse ${result.parseErrors.length} files:');
      for (final error in result.parseErrors) {
        print('  - $error');
      }
      print('');
    }

    if (verbose) {
      print('Classes found:');
      for (final classInfo in result.classes) {
        print('  • ${classInfo.name} (${classInfo.kind})');
      }
      print('');
    }

    // Generate outputs based on format
    final formats = outputFormat == 'all'
        ? ['mermaid', 'json', 'html', 'png']
        : [outputFormat];

    final savedFiles = <String>[];

    for (final format in formats) {
      try {
        // Map format to file extension
        final extension = switch (format) {
          'mermaid' => 'mmd',
          'json' => 'json',
          'html' => 'html',
          'png' => 'png',
          _ => format,
        };

        final filename = '${outputFile}_parse_diagram.$extension';
        final filepath = '$outputDir/$filename';

        switch (format) {
          case 'mermaid':
            await result.saveMermaidFile(filepath);
            savedFiles.add(filename);
            if (verbose) print('  ✓ Saved $filename');
          case 'json':
            await result.saveJsonFile(filepath);
            savedFiles.add(filename);
            if (verbose) print('  ✓ Saved $filename');
          case 'html':
            await result.saveHtmlFile(filepath);
            savedFiles.add(filename);
            if (verbose) print('  ✓ Saved $filename');
          case 'png':
            await result.savePngFile(filepath);
            savedFiles.add(filename);
            if (verbose) print('  ✓ Saved $filename');
          default:
            stderr.writeln('❌ Unknown format: $format');
            exit(1);
        }
      } catch (e) {
        if (format == 'png') {
          print(
              '⚠️  Could not generate PNG (Mermaid CLI may not be installed): $e');
        } else {
          stderr.writeln('❌ Error generating $format: $e');
          exit(1);
        }
      }
    }

    print('\n📊 Diagram generated successfully!');
    print('📁 Output files:');
    for (final file in savedFiles) {
      print('   • $file');
    }

    print('\n💡 Visualization options:');
    if (savedFiles.contains('$outputFile.html')) {
      print('   1. Open $outputFile.html in your browser (recommended)');
    }
    if (savedFiles.contains('$outputFile.png')) {
      print('   2. Open $outputFile.png to view the rendered diagram');
    }
    if (savedFiles.contains('$outputFile.mmd')) {
      print('   3. Copy content of $outputFile.mmd to https://mermaid.live');
    }
  } catch (e, stackTrace) {
    stderr.writeln('❌ Error: $e');
    if (Platform.environment['VERBOSE'] == 'true') {
      stderr.writeln('\nStack trace:\n$stackTrace');
    }
    exit(1);
  }
}

void printHelp() {
  print('''
📊 parse_dart - Generate Mermaid Class Diagrams from Dart Projects

Usage: parse <path> [options]

Arguments:
  <path>                Path to the Dart project to analyze

Options:
  --format <format>     Output format: mermaid, json, html, png, or all (default)
  --output <name>       Custom project name for output files (default: auto-detect from pubspec.yaml)
  --output-dir <path>   Custom output directory name (default: mermaid_output_parse)
  --monorepo            Analyze as a monorepo (scans all packages)
  --verbose             Show detailed analysis output
  -h, --help           Show this help message
  -v, --version        Show version information

Examples:
  # Analyze current directory (creates ./mermaid_output_parse/)
  parse .

  # Analyze a specific project
  parse ~/my_dart_project

  # Analyze a monorepo with multiple packages
  parse . --monorepo

  # Generate only Mermaid diagram
  parse . --format mermaid

  # Customize project name in output
  parse . --output my_custom_name --format html

  # Use custom output directory name (creates ./diagrams/)
  parse . --output-dir ./diagrams

  # Use custom output directory path (creates /tmp/output/)
  parse . --output-dir /tmp/output

  # Analyze monorepo with custom output directory
  parse . --monorepo --output-dir ./my_diagrams --verbose

Output:
  Files are automatically saved to the 'mermaid_output_parse' folder with names like:
  - my_project_parse_diagram.mmd
  - my_project_parse_diagram.json
  - my_project_parse_diagram.html
  - my_project_parse_diagram.png

Note:
  • PNG generation requires Mermaid CLI to be installed (npm install -g @mermaid-js/mermaid-cli)
  • HTML output is always recommended for best visualization
  • A .parseignore file is automatically created in the project root with common patterns
  • You can customize .parseignore to exclude additional paths or un-exclude with !pattern
  • The tool respects .parseignore files in the project root
  • Project name is auto-detected from pubspec.yaml

Learn more: https://github.com/your-repo/parse_dart
''');
}
