import 'dart:io';

import 'package:path/path.dart' as p;

/// Generates a default .parseignore file if it doesn't exist.
class ParseIgnoreGenerator {
  /// Creates a default .parseignore file in the given project path if it doesn't already exist.
  /// Returns true if a new file was created, false if it already exists.
  static Future<bool> ensureParseIgnoreExists(String projectPath) async {
    final parseIgnoreFile = File(p.join(projectPath, '.parseignore'));

    if (await parseIgnoreFile.exists()) {
      return false; // File already exists, don't overwrite
    }

    try {
      await parseIgnoreFile.writeAsString(_defaultParseIgnoreContent);
      return true;
    } catch (e) {
      // If we can't create the file, just continue without it
      return false;
    }
  }

  /// Default .parseignore content with common patterns to exclude
  static const String _defaultParseIgnoreContent = '''# ParseDart ignore patterns
# This file specifies which directories and files to exclude from analysis

# Build and generated files
.dart_tool/**
build/**
.packages
pubspec.lock
*.g.dart

# Version control
.git/**
.gitignore

# IDE and editor settings
.vscode/**
.idea/**
*.iml
.DS_Store
Thumbs.db

# Testing and coverage
coverage/**
test/**

# Flutter-specific
.flutter_plugins
.flutter_plugins_dependencies

# Environment and secrets
.env
.env.*

# Node modules (if applicable)
node_modules/**

# Generated documentation
doc/api/**

# Temporary files
*.swp
*.swo
*~
.#*
*.tmp

# Other
pubspec.lock.backup
''';
}
