import 'dart:io';

import 'package:glob/glob.dart';
import 'package:path/path.dart' as p;

/// Walks a Dart project directory and returns all .dart files, respecting .parseignore.
class FileWalker {
  /// Walk the directory at [rootPath] and return all .dart files.
  /// Respects .parseignore patterns if present.
  Future<List<String>> walk(String rootPath) async {
    final root = Directory(rootPath);
    if (!await root.exists()) {
      throw Exception('Root path does not exist: $rootPath');
    }

    final patterns = _readParseIgnore(rootPath);
    final dartFiles = <String>[];

    await _walkDirectory(root, rootPath, patterns, dartFiles);

    return dartFiles..sort();
  }

  /// Recursively walk directories and collect .dart files.
  Future<void> _walkDirectory(
    Directory dir,
    String rootPath,
    List<String> ignorePatterns,
    List<String> dartFiles,
  ) async {
    try {
      await for (final entity in dir.list(recursive: false)) {
        final relativePath = p.relative(entity.path, from: rootPath);

        // Check if this entity matches any ignore pattern
        if (_isIgnored(relativePath, ignorePatterns)) {
          continue;
        }

        if (entity is File && entity.path.endsWith('.dart')) {
          dartFiles.add(entity.path);
        } else if (entity is Directory) {
          await _walkDirectory(entity, rootPath, ignorePatterns, dartFiles);
        }
      }
    } catch (e) {
      // Skip directories we can't access
    }
  }

  /// Read and parse .parseignore from the project root.
  List<String> _readParseIgnore(String rootPath) {
    final patterns = [
      '.dart_tool/**',
      'build/**',
      '.git/**',
      '.packages',
      '.gitignore',
    ];

    final parseIgnoreFile = File(p.join(rootPath, '.parseignore'));
    if (parseIgnoreFile.existsSync()) {
      try {
        final content = parseIgnoreFile.readAsStringSync();
        final lines = content.split('\n');
        for (final line in lines) {
          final trimmed = line.trim();
          if (trimmed.isNotEmpty && !trimmed.startsWith('#')) {
            // Handle negation patterns (!) - for now we'll keep them as-is
            patterns.add(trimmed);
          }
        }
      } catch (e) {
        // If we can't read .parseignore, just use defaults
      }
    }

    return patterns;
  }

  /// Check if a relative path matches any ignore pattern.
  bool _isIgnored(String relativePath, List<String> patterns) {
    for (final pattern in patterns) {
      // Handle negation patterns
      if (pattern.startsWith('!')) {
        final negPattern = pattern.substring(1);
        if (_matchesGlob(relativePath, negPattern)) {
          return false;
        }
      } else {
        if (_matchesGlob(relativePath, pattern)) {
          return true;
        }
      }
    }
    return false;
  }

  /// Check if a path matches a glob pattern.
  bool _matchesGlob(String path, String pattern) {
    try {
      // Normalize path separators for glob matching
      final normalizedPath = path.replaceAll('\\', '/');
      final glob = Glob(pattern, recursive: true);
      return glob.matches(normalizedPath);
    } catch (e) {
      return false;
    }
  }
}
