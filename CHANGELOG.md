# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.4.0] - 2026-03-26

### Added
- **Relationship Type Filter (`--only-relations`)**:
  - New CLI flag `--only-relations <types>` to show only specific relationship types
  - Accepted values (comma-separated): `extends`, `implements`, `with`, `uses`, `nested`
  - Default behavior (flag absent): all relationship types shown — fully backward compatible
  - Works with all output formats: mermaid, json, html, png, graphviz, dot, graphviz_html, graphviz_png
  - Composes with existing filters (`--no-private`, `--no-external`, `--no-methods`)
  - Available as `onlyRelations` parameter on all `ParseResult` API methods

### Examples
```bash
# Show only inheritance hierarchy
diagram_generator . --only-relations extends

# Show only interface and mixin relationships
diagram_generator . --only-relations implements,with

# Show only dependency arrows
diagram_generator . --only-relations uses

# Combine with other filters
diagram_generator . --only-relations extends,implements --no-external --format html
```

## [0.1.0] - 2026-02-27

### Added
- **Enhanced Parser Support:**
  - Enum field type extraction for `usesList` relationships
  - Full extension type parsing with methods and relationships
  - Class type alias support (`class Foo = Bar with Baz` syntax)
  - Preserved generic type parameters in class names (e.g., `Repository<T>`)
  - Improved type variable heuristic to exclude common abbreviations (IO, UI, DB, API, etc.)

- **Code Quality Improvements:**
  - Created `lib/src/utils/diagram_utils.dart` for shared utility functions
  - Extracted common functions: `getStereotype()`, `escapeName()`, `isPrivateMethod()`
  - Replaced fragile `kind.toString()` comparisons with exhaustive switch statements (compile-time safety)

- **Stability & Dependencies:**
  - Pinned Mermaid CDN to v10 to prevent breaking changes

### Fixed
- Visualization tips now display correctly (fixed path checking logic)
- Input directory validation now occurs before output directory creation
- Layout engine flag (`-K<layout>`) now properly applied to Graphviz PNG rendering
- Removed Italian text from CLI (internationalization consistency)
- Removed dead code: unused `_generateGraphvizHtmlWithSvg` method and unused `publicClassNames` sets

### Changed
- Internal refactoring: eliminated code duplication between MermaidGenerator and GraphvizGenerator

### Developer Notes
- All 47 tests passing with no regressions
- Zero analyzer warnings
- Ready for production

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
