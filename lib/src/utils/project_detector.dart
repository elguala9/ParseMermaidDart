import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

/// Detects project metadata from pubspec.yaml
class ProjectDetector {
  /// Extract project name from pubspec.yaml
  static Future<String?> getProjectName(String projectPath) async {
    try {
      final pubspecFile = File(p.join(projectPath, 'pubspec.yaml'));
      if (!pubspecFile.existsSync()) {
        return null;
      }

      final content = await pubspecFile.readAsString();
      final yaml = loadYaml(content) as Map;
      final name = yaml['name'] as String?;
      return name;
    } catch (e) {
      return null;
    }
  }

  /// Get project name or fallback to directory name
  static Future<String> getProjectNameOrDefault(String projectPath) async {
    final name = await getProjectName(projectPath);
    if (name != null && name.isNotEmpty) {
      return name;
    }

    // Fallback to directory name
    return p.basename(projectPath.replaceAll('\\', '/'));
  }

  /// Create output directory if it doesn't exist
  static Future<String> createOutputDirectory(String projectPath) async {
    final outputDir = Directory(p.join(projectPath, 'output'));
    if (!await outputDir.exists()) {
      await outputDir.create(recursive: true);
    }
    return outputDir.path;
  }

  /// Generate output filename with project name
  static Future<String> generateOutputFilePath(
    String projectPath,
    String format, {
    bool useSubdirectory = true,
  }) async {
    final projectName = await getProjectNameOrDefault(projectPath);
    final sanitizedName = projectName.replaceAll(RegExp(r'[^\w-]'), '_');
    final filename = '${sanitizedName}_parse_diagram.$format';

    if (useSubdirectory) {
      final outputDir = await createOutputDirectory(projectPath);
      return p.join(outputDir, filename);
    } else {
      return p.join(projectPath, filename);
    }
  }
}
