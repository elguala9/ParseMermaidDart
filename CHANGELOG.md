# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.1] - 2026-02-26

### Fixed
- Optimized diagram file paths: now displays only filenames (e.g., `user.dart`) instead of full paths (e.g., `lib/models/user.dart`)
  - Significantly reduces diagram text size
  - Prevents "Maximum Text Size In Diagram Exceeded" errors on large projects
  - Improves diagram readability
- Removed invalid `publish_to` value in pubspec.yaml
- Fixed analysis warnings:
  - Removed unused imports in library files
  - Removed unnecessary non-null assertions
  - Added proper `analysis_options.yaml` configuration

### Changed
- Improved package metadata for better pub.dev quality score
- Added comprehensive `.pubignore` to reduce published package size (20 KB vs 26 KB)
- Optimized file exclusions for cleaner pub.dev packages

### Documentation
- Added section on how to update the CLI tool
- Clarified global installation and usage instructions

## [0.1.0] - 2026-02-26

### Added
- Initial release of `parse_mermaid_dart`
- Automatic analysis of Dart projects to extract class information
- Detection of class relationships:
  - `extends` (inheritance)
  - `implements` (interfaces)
  - `with` (mixins)
  - `uses` (detected from field types)
  - `on` constraints for mixins
- Support for multiple class types:
  - Regular classes
  - Abstract classes
  - Interface classes
  - Sealed classes
  - Mixins
  - Enums
  - Extension types
- Multiple output formats:
  - Mermaid diagram syntax (`.mmd`)
  - Mermaid JSON format (Mermaid Live Editor compatible)
  - Interactive HTML diagrams
  - PNG diagrams (via kroki.io)
- Interactive comments: Dart doc comments (`///`) automatically become clickable tooltips in diagrams
- Customizable file exclusion via `.parseignore` file
- CLI tool for command-line usage: `parse <path> [options]`
- Monorepo support: Analyze multiple packages together
- Comprehensive test suite (26 tests)
- Full documentation with usage examples
