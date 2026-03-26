#!/usr/bin/env dart
import 'dart:io';

import 'package:diagram_dart/diagram_dart.dart';
import 'package:diagram_dart/src/utils/parse_ignore_generator.dart';
import 'package:diagram_dart/src/utils/project_detector.dart';

void main(List<String> args) async {
  try {
    if (args.isEmpty || args.contains('--help') || args.contains('-h')) {
      printHelp();
      return;
    }

    if (args.contains('--version') || args.contains('-v')) {
      print('diagram_dart version 0.4.0');
      return;
    }

    // Parse command line arguments
    var projectPath = '.';
    var outputFormat = 'all'; // all, mermaid, json, html, png
    String? prefix;
    var outputDir = 'mermaid_output_parse';
    var verbose = false;
    var isMonorepo = false;
    var perLibrary = false;
    var noPrivate = false;
    var noExternal = false;
    var noMethods = false;
    Set<String>? onlyRelations;
    final layoutsSpec = <String>[]; // layouts specified by user

    for (int i = 0; i < args.length; i++) {
      final arg = args[i];
      if (arg == '--input' && i + 1 < args.length) {
        projectPath = args[++i];
      } else if (arg == '--format' && i + 1 < args.length) {
        outputFormat = args[++i];
      } else if (arg == '--prefix' && i + 1 < args.length) {
        prefix = args[++i];
      } else if (arg == '--output-dir' && i + 1 < args.length) {
        outputDir = args[++i];
      } else if (arg == '--layout') {
        // Collect all following non-flag arguments as layouts
        i++;
        while (i < args.length && !args[i].startsWith('--')) {
          layoutsSpec.add(args[i]);
          i++;
        }
        i--; // Back up one since the loop will increment
      } else if (arg == '--verbose') {
        verbose = true;
      } else if (arg == '--monorepo') {
        isMonorepo = true;
      } else if (arg == '--per-package') {
        perLibrary = true;
        isMonorepo = true; // implies monorepo mode
      } else if (arg == '--no-private') {
        noPrivate = true;
      } else if (arg == '--no-external') {
        noExternal = true;
      } else if (arg == '--no-methods') {
        noMethods = true;
      } else if (arg == '--only-relations' && i + 1 < args.length) {
        onlyRelations = args[++i].split(',').map((s) => s.trim().toLowerCase()).toSet();
      } else if (i == 0 && !arg.startsWith('--')) {
        // Legacy support: first positional argument as input path
        projectPath = arg;
      }
    }

    // Auto-detect project name if prefix not specified (unless per-package mode)
    if (!perLibrary) {
      final projectName =
          await ProjectDetector.getProjectNameOrDefault(projectPath);
      prefix ??= projectName;
    }

    // Determine which Graphviz layouts to use (default: fdp)
    final layoutsToUse = layoutsSpec.isEmpty ? ['fdp'] : layoutsSpec;

    // Validate project path first (before creating output directory)
    final projectDir = Directory(projectPath);
    if (!projectDir.existsSync()) {
      stderr.writeln('❌ Error: Directory not found: $projectPath');
      exit(1);
    }

    // Create output directory
    final outputDirectory = Directory(outputDir);
    if (!await outputDirectory.exists()) {
      await outputDirectory.create(recursive: true);
    }

    // Ensure .parseignore exists
    final parseIgnoreCreated =
        await ParseIgnoreGenerator.ensureParseIgnoreExists(projectPath);
    if (parseIgnoreCreated && verbose) {
      print('📝 Created .parseignore with default patterns\n');
    }

    if (verbose) {
      if (perLibrary) {
        print('📦 Analyzing monorepo per-package: $projectPath\n');
      } else if (isMonorepo) {
        print('📦 Analyzing monorepo: $projectPath\n');
      } else {
        print('📁 Analyzing project: $projectPath\n');
      }
    }

    // Analyze the project or monorepo
    final parser = ParseDart(projectPath);

    // If --per-package mode, use the separate per-library analysis
    if (perLibrary) {
      final libraryResults = await parser.analyzeMonorepoPerLibrary();

      if (libraryResults.isEmpty) {
        print('⚠️  No packages found in the monorepo.');
        return;
      }

      if (verbose) print('Found ${libraryResults.length} packages.\n');

      // Process each library separately
      final allSavedFiles = <String>[];

      for (final entry in libraryResults.entries) {
        final libName = entry.key;
        final libResult = entry.value;
        final libPrefix = prefix ?? libName;

        if (verbose) print('📦 Generating diagrams for: $libName');

        if (libResult.classes.isEmpty) {
          if (verbose) print('  ⚠️  No classes found in $libName');
          continue;
        }

        if (verbose) print('  ✅ Found ${libResult.classes.length} classes');

        // Check if 'dot' command is available for Graphviz PNG rendering
        final dotAvailable = await _isDotAvailable();

        // Generate outputs based on format
        var formats = outputFormat == 'all'
            ? ['mermaid', 'json', 'html', 'png', 'graphviz', 'graphviz_html']
            : [outputFormat];

        // Only add graphviz_png if dot is available and explicitly requested
        if (dotAvailable && outputFormat == 'all') {
          formats.add('graphviz_png');
        }

        for (final format in formats) {
          try {
            // Map format to subdirectory and file extension
            final (String subDir, String ext) = switch (format) {
              'mermaid' => ('mermaid', 'mmd'),
              'json' => ('mermaid', 'json'),
              'html' => ('mermaid', 'html'),
              'png' => ('mermaid', 'png'),
              'graphviz' || 'dot' => ('graphviz', 'dot'),
              'graphviz_html' => ('graphviz', 'html'),
              'graphviz_png' => ('graphviz', 'png'),
              _ => throw ArgumentError('Unknown format: $format'),
            };

            final filename = '${libPrefix}_parse_diagram.$ext';
            // Create separate subdirectory for each package
            final filepath = '$outputDir/$subDir/$libName/$filename';

            switch (format) {
              case 'mermaid':
                await libResult.saveMermaidFile(filepath, noPrivate: noPrivate, noExternal: noExternal, noMethods: noMethods, onlyRelations: onlyRelations);
                allSavedFiles.add('$subDir/$libName/$filename');
                if (verbose) print('    ✓ Saved $subDir/$libName/$filename');
              case 'json':
                await libResult.saveJsonFile(filepath, noPrivate: noPrivate, noExternal: noExternal, noMethods: noMethods, onlyRelations: onlyRelations);
                allSavedFiles.add('$subDir/$libName/$filename');
                if (verbose) print('    ✓ Saved $subDir/$libName/$filename');
              case 'html':
                await libResult.saveHtmlFile(filepath, noPrivate: noPrivate, noExternal: noExternal, noMethods: noMethods, onlyRelations: onlyRelations);
                allSavedFiles.add('$subDir/$libName/$filename');
                if (verbose) print('    ✓ Saved $subDir/$libName/$filename');
              case 'png':
                await libResult.savePngFile(filepath, noPrivate: noPrivate, noExternal: noExternal, noMethods: noMethods, onlyRelations: onlyRelations);
                allSavedFiles.add('$subDir/$libName/$filename');
                if (verbose) print('    ✓ Saved $subDir/$libName/$filename');
              case 'graphviz' || 'dot':
                // Generate .dot file for each layout
                for (final currentLayout in layoutsToUse) {
                  final layoutFilename = '${libPrefix}_parse_diagram_$currentLayout.dot';
                  final layoutFilepath = '$outputDir/$subDir/$libName/$layoutFilename';
                  await libResult.saveGraphvizFile(layoutFilepath, noPrivate: noPrivate, noExternal: noExternal, noMethods: noMethods, layout: currentLayout, onlyRelations: onlyRelations);
                  allSavedFiles.add('$subDir/$libName/$layoutFilename');
                  if (verbose) print('    ✓ Saved $subDir/$libName/$layoutFilename');

                  // Also generate PNG for each layout
                  final pngLayoutFilename = '${libPrefix}_parse_diagram_$currentLayout.png';
                  final pngLayoutFilepath = '$outputDir/$subDir/$libName/$pngLayoutFilename';
                  try {
                    await libResult.saveGraphvizPngFile(pngLayoutFilepath, noPrivate: noPrivate, noExternal: noExternal, noMethods: noMethods, layout: currentLayout, onlyRelations: onlyRelations);
                    allSavedFiles.add('$subDir/$libName/$pngLayoutFilename');
                    if (verbose) print('    ✓ Saved $subDir/$libName/$pngLayoutFilename');
                  } catch (pngError) {
                    if (verbose) print('    ⚠️  Could not generate PNG for layout $currentLayout: $pngError');
                  }
                }
              case 'graphviz_html':
                // Generate HTML for each layout
                for (final currentLayout in layoutsToUse) {
                  final layoutFilename = '${libPrefix}_parse_diagram_$currentLayout.html';
                  final layoutFilepath = '$outputDir/$subDir/$libName/$layoutFilename';
                  await libResult.saveGraphvizHtmlFile(layoutFilepath, noPrivate: noPrivate, noExternal: noExternal, noMethods: noMethods, layout: currentLayout, onlyRelations: onlyRelations);
                  allSavedFiles.add('$subDir/$libName/$layoutFilename');
                  if (verbose) print('    ✓ Saved $subDir/$libName/$layoutFilename');
                }
              case 'graphviz_png':
                // Generate PNG for each layout
                for (final currentLayout in layoutsToUse) {
                  final layoutFilename = '${libPrefix}_parse_diagram_$currentLayout.png';
                  final layoutFilepath = '$outputDir/$subDir/$libName/$layoutFilename';
                  try {
                    await libResult.saveGraphvizPngFile(layoutFilepath, noPrivate: noPrivate, noExternal: noExternal, noMethods: noMethods, layout: currentLayout, onlyRelations: onlyRelations);
                    allSavedFiles.add('$subDir/$libName/$layoutFilename');
                    if (verbose) print('    ✓ Saved $subDir/$libName/$layoutFilename');
                  } catch (pngError) {
                    if (verbose) print('    ⚠️  Could not generate PNG for layout $currentLayout: $pngError');
                  }
                }
              default:
                stderr.writeln('❌ Unknown format: $format');
                exit(1);
            }
          } catch (e) {
            if (format == 'png') {
              print(
                  '⚠️  Could not generate PNG for $libName (Mermaid CLI may not be installed): $e');
            } else if (format == 'graphviz_png') {
              print(
                  '⚠️  Could not generate Graphviz PNG for $libName (Graphviz/dot not installed)');
              print('   Install Graphviz from: https://graphviz.org/download/');
            } else {
              stderr.writeln('❌ Error generating $format for $libName: $e');
              exit(1);
            }
          }
        }
      }

      print('\n📊 Diagrams generated successfully for all packages!');
      print('📁 Output files:');
      for (final file in allSavedFiles) {
        print('   • $file');
      }
      return;
    }

    // Standard monorepo or single project analysis
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

    // Check if 'dot' command is available for Graphviz PNG rendering
    final dotAvailable = await _isDotAvailable();

    // Generate outputs based on format
    var formats = outputFormat == 'all'
        ? ['mermaid', 'json', 'html', 'png', 'graphviz', 'graphviz_html']
        : [outputFormat];

    // Only add graphviz_png if dot is available and explicitly requested
    if (dotAvailable && outputFormat == 'all') {
      formats.add('graphviz_png');
    }

    final savedFiles = <String>[];

    for (final format in formats) {
      try {
        // Map format to subdirectory and file extension
        final (String subDir, String ext) = switch (format) {
          'mermaid' => ('mermaid', 'mmd'),
          'json' => ('mermaid', 'json'),
          'html' => ('mermaid', 'html'),
          'png' => ('mermaid', 'png'),
          'graphviz' || 'dot' => ('graphviz', 'dot'),
          'graphviz_html' => ('graphviz', 'html'),
          'graphviz_png' => ('graphviz', 'png'),
          _ => throw ArgumentError('Unknown format: $format'),
        };

        final filename = '${prefix}_parse_diagram.$ext';
        final filepath = '$outputDir/$subDir/$filename';

        switch (format) {
          case 'mermaid':
            await result.saveMermaidFile(filepath, noPrivate: noPrivate, noExternal: noExternal, noMethods: noMethods, onlyRelations: onlyRelations);
            savedFiles.add('$subDir/$filename');
            if (verbose) print('  ✓ Saved $subDir/$filename');
          case 'json':
            await result.saveJsonFile(filepath, noPrivate: noPrivate, noExternal: noExternal, noMethods: noMethods, onlyRelations: onlyRelations);
            savedFiles.add('$subDir/$filename');
            if (verbose) print('  ✓ Saved $subDir/$filename');
          case 'html':
            await result.saveHtmlFile(filepath, noPrivate: noPrivate, noExternal: noExternal, noMethods: noMethods, onlyRelations: onlyRelations);
            savedFiles.add('$subDir/$filename');
            if (verbose) print('  ✓ Saved $subDir/$filename');
          case 'png':
            await result.savePngFile(filepath, noPrivate: noPrivate, noExternal: noExternal, noMethods: noMethods, onlyRelations: onlyRelations);
            savedFiles.add('$subDir/$filename');
            if (verbose) print('  ✓ Saved $subDir/$filename');
          case 'graphviz' || 'dot':
            // Generate .dot file for each layout
            for (final currentLayout in layoutsToUse) {
              final layoutFilename = '${prefix}_parse_diagram_$currentLayout.dot';
              final layoutFilepath = '$outputDir/$subDir/$layoutFilename';
              await result.saveGraphvizFile(layoutFilepath, noPrivate: noPrivate, noExternal: noExternal, noMethods: noMethods, layout: currentLayout, onlyRelations: onlyRelations);
              savedFiles.add('$subDir/$layoutFilename');
              if (verbose) print('  ✓ Saved $subDir/$layoutFilename');

              // Also generate PNG for each layout
              final pngLayoutFilename = '${prefix}_parse_diagram_$currentLayout.png';
              final pngLayoutFilepath = '$outputDir/$subDir/$pngLayoutFilename';
              try {
                await result.saveGraphvizPngFile(pngLayoutFilepath, noPrivate: noPrivate, noExternal: noExternal, noMethods: noMethods, layout: currentLayout, onlyRelations: onlyRelations);
                savedFiles.add('$subDir/$pngLayoutFilename');
                if (verbose) print('  ✓ Saved $subDir/$pngLayoutFilename');
              } catch (pngError) {
                if (verbose) print('  ⚠️  Could not generate PNG for layout $currentLayout: $pngError');
              }
            }
          case 'graphviz_html':
            // Generate HTML for each layout
            for (final currentLayout in layoutsToUse) {
              final layoutFilename = '${prefix}_parse_diagram_$currentLayout.html';
              final layoutFilepath = '$outputDir/$subDir/$layoutFilename';
              await result.saveGraphvizHtmlFile(layoutFilepath, noPrivate: noPrivate, noExternal: noExternal, noMethods: noMethods, layout: currentLayout, onlyRelations: onlyRelations);
              savedFiles.add('$subDir/$layoutFilename');
              if (verbose) print('  ✓ Saved $subDir/$layoutFilename');
            }
          case 'graphviz_png':
            // Generate PNG for each layout
            for (final currentLayout in layoutsToUse) {
              final layoutFilename = '${prefix}_parse_diagram_$currentLayout.png';
              final layoutFilepath = '$outputDir/$subDir/$layoutFilename';
              try {
                await result.saveGraphvizPngFile(layoutFilepath, noPrivate: noPrivate, noExternal: noExternal, noMethods: noMethods, layout: currentLayout, onlyRelations: onlyRelations);
                savedFiles.add('$subDir/$layoutFilename');
                if (verbose) print('  ✓ Saved $subDir/$layoutFilename');
              } catch (pngError) {
                if (verbose) print('  ⚠️  Could not generate PNG for layout $currentLayout: $pngError');
              }
            }
          default:
            stderr.writeln('❌ Unknown format: $format');
            exit(1);
        }
      } catch (e) {
        if (format == 'png') {
          print(
              '⚠️  Could not generate PNG (Mermaid CLI may not be installed): $e');
        } else if (format == 'graphviz_png') {
          print(
              '⚠️  Could not generate Graphviz PNG (Graphviz/dot not installed)');
          print('   Install Graphviz from: https://graphviz.org/download/');
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
    if (savedFiles.any((f) => f.contains('${prefix}_parse_diagram.html'))) {
      print('   1. Open ${prefix}_parse_diagram.html in your browser (recommended)');
    }
    if (savedFiles.any((f) => f.contains('${prefix}_parse_diagram.png'))) {
      print('   2. Open ${prefix}_parse_diagram.png to view the rendered diagram');
    }
    if (savedFiles.any((f) => f.contains('${prefix}_parse_diagram.mmd'))) {
      print('   3. Copy content of ${prefix}_parse_diagram.mmd to https://mermaid.live');
    }
  } catch (e, stackTrace) {
    stderr.writeln('❌ Error: $e');
    if (Platform.environment['VERBOSE'] == 'true') {
      stderr.writeln('\nStack trace:\n$stackTrace');
    }
    exit(1);
  }
}

/// Check if 'dot' command is available on the system
Future<bool> _isDotAvailable() async {
  try {
    final result = await Process.run('dot', ['-V']);
    return result.exitCode == 0;
  } catch (e) {
    return false;
  }
}

void printHelp() {
  print('''
📊 diagram_dart - Generate Class Diagrams from Dart Projects

Usage: diagram_generator [options]

Options:
  --input <path>        Path to the Dart project to analyze (default: .)
  --output-dir <path>   Output directory path (default: mermaid_output_parse)
  --prefix <name>       Prefix for output filenames (default: auto-detect from pubspec.yaml)
  --format <format>     Output format: mermaid, json, html, png, graphviz, dot, graphviz_html, graphviz_png, or all (default)
  --layout <alg...>     Graphviz layout algorithm(s): dot, neato, fdp, sfdp, circo, twopi
                        Default (no --layout): fdp only
                        Multiple layouts: --layout fdp sfdp circo
  --monorepo            Analyze as a monorepo (scans all packages)
  --per-package         (monorepo) Generate a separate file for each package
  --no-private          Exclude all private elements (classes and methods starting with _)
  --no-external         Exclude external classes (stdlib and third-party libraries) from diagram
  --no-methods          Exclude all methods from class definitions
  --only-relations <types>  Show only the specified relation types (comma-separated).
                        Values: extends, implements, with, uses, nested
                        Default: all relation types shown
                        Example: --only-relations extends,implements
  --verbose             Show detailed analysis output
  -h, --help           Show this help message
  -v, --version        Show version information

Examples:
  # Analyze current directory
  diagram_generator

  # Analyze specific project
  diagram_generator --input ~/my_dart_project

  # Customize output directory and filename prefix
  diagram_generator --input . --output-dir ./diagrams --prefix my_name

  # Generate only Mermaid diagram
  diagram_generator --input . --format mermaid

  # Generate Graphviz DOT diagram
  diagram_generator --input . --format graphviz

  # Generate interactive Graphviz HTML
  diagram_generator --input . --format graphviz_html

  # Analyze monorepo with custom settings
  diagram_generator --input . --monorepo --output-dir ./my_diagrams --prefix monorepo_diagrams --verbose

  # Generate separate diagrams for each package in a monorepo
  diagram_generator --input . --per-package

  # Generate separate diagrams with all formats
  diagram_generator --input . --per-package --format all

  # Generate separate diagrams excluding private members
  diagram_generator --input . --per-package --no-private --format mermaid

  # Exclude private methods to reduce diagram size
  diagram_generator --input . --no-private

  # Exclude all methods (show only class names)
  diagram_generator --input . --no-methods

  # Exclude external libraries (for large projects)
  diagram_generator --input . --no-external

  # Combine filters to minimize diagram
  diagram_generator --input . --no-private --no-external --format html

  # Show only class hierarchy without methods
  diagram_generator --input . --no-methods --format mermaid

  # Generate Graphviz with default layout (fdp)
  diagram_generator --input . --format graphviz

  # Generate with specific layout
  diagram_generator --input . --format graphviz --layout sfdp

  # Generate multiple layouts at once
  diagram_generator --input . --format graphviz --layout fdp sfdp

  # Generate all layouts
  diagram_generator --input . --format graphviz --layout dot neato fdp sfdp circo twopi

Output:
  Files are saved to subdirectories within the output directory:

  Single project or combined monorepo (--monorepo):
  Mermaid format (--format mermaid/json/html/png):
  - {output-dir}/mermaid/my_project_parse_diagram.mmd
  - {output-dir}/mermaid/my_project_parse_diagram.json
  - {output-dir}/mermaid/my_project_parse_diagram.html
  - {output-dir}/mermaid/my_project_parse_diagram.png

  Graphviz format (--format graphviz/dot/graphviz_html/graphviz_png):
  One file per layout (default layout: fdp):
  - {output-dir}/graphviz/my_project_parse_diagram_fdp.dot
  - {output-dir}/graphviz/my_project_parse_diagram_fdp.png
  Multiple layouts (--layout fdp sfdp circo):
  - {output-dir}/graphviz/my_project_parse_diagram_fdp.dot/png
  - {output-dir}/graphviz/my_project_parse_diagram_sfdp.dot/png
  - {output-dir}/graphviz/my_project_parse_diagram_circo.dot/png

  Per-package monorepo (--per-package):
  Each package gets its own subdirectory within format directories:
  - {output-dir}/mermaid/package_a/package_a_parse_diagram.mmd
  - {output-dir}/mermaid/package_b/package_b_parse_diagram.mmd
  - {output-dir}/graphviz/package_a/package_a_parse_diagram.dot
  - {output-dir}/graphviz/package_b/package_b_parse_diagram.dot

Note:
  • PNG generation requires Mermaid CLI to be installed (npm install -g @mermaid-js/mermaid-cli)
  • HTML output is always recommended for best visualization
  • Graphviz HTML uses viz.js for client-side rendering (no installation needed)
  • A .parseignore file is automatically created in the project root with common patterns
  • You can customize .parseignore to exclude additional paths or un-exclude with !pattern
  • The tool respects .parseignore files in the project root
  • Project name is auto-detected from pubspec.yaml

Learn more: https://github.com/elguala9/ParseMermaidDart
''');
}
