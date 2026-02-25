import 'dart:io';

import 'package:path/path.dart' as p;

/// Detects and walks a monorepo structure, finding all packages.
class MonorepoWalker {
  /// Find all Dart packages in a monorepo by searching for pubspec.yaml files.
  /// Returns a list of package root directories.
  Future<List<String>> findPackages(String rootPath) async {
    final root = Directory(rootPath);
    if (!await root.exists()) {
      throw Exception('Root path does not exist: $rootPath');
    }

    final packages = <String>[];
    await _findPackagesRecursive(root, rootPath, packages, depth: 0);

    return packages..sort();
  }

  /// Recursively search for packages (directories containing pubspec.yaml).
  /// Stops searching deeper into packages once found (except at root level).
  Future<void> _findPackagesRecursive(
    Directory dir,
    String rootPath,
    List<String> packages, {
    required int depth,
    int maxDepth = 5, // Prevent infinite recursion
  }) async {
    if (depth > maxDepth) return;

    try {
      final pubspecFile = File(p.join(dir.path, 'pubspec.yaml'));
      final isAtRoot = dir.path == rootPath;

      // If this directory contains pubspec.yaml, it's a package
      if (pubspecFile.existsSync() && !isAtRoot) {
        final relativePath = p.relative(dir.path, from: rootPath);
        packages.add(p.join(rootPath, relativePath));
        // Don't search deeper into packages
        return;
      }

      // Search subdirectories (always at root level, even if pubspec.yaml exists)
      await for (final entity in dir.list(recursive: false)) {
        if (entity is Directory && !_shouldIgnoreDir(entity.path)) {
          await _findPackagesRecursive(
            entity,
            rootPath,
            packages,
            depth: depth + 1,
            maxDepth: maxDepth,
          );
        }
      }
    } catch (e) {
      // Skip directories we can't access
    }
  }

  /// Check if a directory should be ignored during the search.
  bool _shouldIgnoreDir(String dirPath) {
    final ignorePatterns = [
      '.dart_tool',
      'build',
      '.git',
      'node_modules',
      '.idea',
      '.vscode',
      'coverage',
      'dist',
    ];

    final dirName = p.basename(dirPath);
    return ignorePatterns.contains(dirName) ||
        dirName.startsWith('.') && !dirName.startsWith('..');
  }

  /// Check if a directory is likely a monorepo.
  /// A monorepo has multiple pubspec.yaml files in subdirectories.
  Future<bool> isMonorepo(String rootPath) async {
    final packages = await findPackages(rootPath);
    return packages.length > 1;
  }
}
