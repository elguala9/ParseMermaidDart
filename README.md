# parse_mermaid_dart

A Dart library that analyzes Dart projects and generates Mermaid class diagrams, extracting class relationships (extends, implements, with, uses) automatically.

## Features

- **Automatic Analysis**: Walks your Dart project and extracts all class information
- **Relationship Detection**: Detects:
  - `extends` relationships (inheritance)
  - `implements` relationships (interfaces)
  - `with` relationships (mixins)
  - `uses` relationships (detected from field types)
  - `on` constraints for mixins
- **Type Support**: Handles:
  - Regular classes
  - Abstract classes
  - Interface classes
  - Sealed classes
  - Mixins
  - Enums
  - Extension types
- **Mermaid Output**: Generates multiple formats:
  - `.mmd` files (Mermaid diagram syntax)
  - `.json` files (Mermaid Live Editor compatible)
  - `.html` files (Interactive HTML with embedded Mermaid)
  - `.png` files (Rendered diagrams via kroki.io)
- **Interactive Comments**: Dart doc comments (`///`) automatically become clickable tooltips in diagrams
- **Customizable**: Supports `.parseignore` file for excluding directories/files

## Installation

### As a Library

Add to your `pubspec.yaml`:

```yaml
dependencies:
  parse_mermaid_dart: ^0.1.0
```

Then run:

```bash
dart pub get
```

### As a CLI Tool

Install globally:

```bash
dart pub global activate parse_mermaid_dart
```

Then use the `parse` command from anywhere:

```bash
parse <path> [options]
```

## Interactive Comments

Dart documentation comments (`///`) in your code automatically become **interactive click handlers** in generated diagrams!

### How It Works

When you document your classes with Dart doc comments:

```dart
/// Abstract base class for all animals
abstract class Animal {
  void makeSound();
}

/// A concrete dog class with special abilities
class Dog extends Animal {
  @override
  void makeSound() => print('Woof!');
}

/// Repository for managing dogs
class DogRepository {
  Animal getAnimal() => Dog();
}
```

These comments are automatically extracted and added to your diagrams as **interactive click handlers**. When you click on a class in the diagram, an alert shows the documentation comment.

### Supported Formats

The interactive comments appear in all output formats:

- **`.mmd`** - Click handlers in Mermaid syntax: `click Dog "javascript:alert('/// A concrete dog class...')"`
- **`.json`** - Mermaid JSON with click handlers (compatible with Mermaid Live Editor)
- **`.html`** - Interactive HTML diagram with clickable classes showing comments
- **`.png`** - PNG diagram (rendered cleanly without interactive handlers, but generated from documented classes)

### Example Output

Your `.mmd` file will include:

```mermaid
classDiagram
  class Animal {
    <<abstract>>
  }
  class Dog
  class DogRepository

  Animal <|-- Dog : extends
  DogRepository --> Animal : uses

  click Animal "javascript:alert('/// Abstract base class for all animals')"
  click Dog "javascript:alert('/// A concrete dog class with special abilities')"
  click DogRepository "javascript:alert('/// Repository for managing dogs')"
```

### What Gets Included

✅ **Included in diagrams:**
- Documentation comments using `///` (single line or multiple lines)
- Documentation comments using `/** ... */` (block comments)

❌ **Not included:**
- Regular comments using `//` (these are only for code)

### Tips

1. **Document all your classes** - The more detailed your comments, the more useful your diagrams!
2. **Use Mermaid Live Editor** - Copy your JSON output to [mermaid.live](https://mermaid.live) to get an interactive viewer
3. **Open `.html` files in browser** - The HTML version provides the best interactive experience with clickable comments
4. **Share diagrams** - The generated PNG files are perfect for documentation and presentations

## Usage

### Basic Usage

```dart
import 'package:parse_mermaid_dart/parse_mermaid_dart.dart';

void main() async {
  final parser = ParseDart('path/to/your/project');
  final result = await parser.analyze();

  // Print results
  for (final classInfo in result.classes) {
    print('${classInfo.name} (${classInfo.kind})');
  }

  // Generate Mermaid diagram
  print(result.toMermaid());

  // Save to files
  await result.saveMermaidFile('diagram.mmd');
  await result.saveJsonFile('diagram.json');
}
```

### Command Line Usage

#### Using the CLI Tool

```bash
# Analyze current directory (generate all formats)
parse .

# Analyze a specific project
parse ~/my_dart_project

# Analyze a monorepo with multiple packages
parse . --monorepo

# Generate only Mermaid diagram
parse . --format mermaid

# Generate specific format with custom output name
parse . --format html --output my_architecture

# Verbose output
parse . --verbose

# Show help
parse --help
```

**Options:**
- `--format <format>` - Output format: `mermaid`, `json`, `html`, `png`, or `all` (default)
- `--output <name>` - Custom project name for output files (default: auto-detect from pubspec.yaml)
- `--monorepo` - Analyze as a monorepo (finds and analyzes all packages in nested directories)
- `--verbose` - Show detailed analysis output
- `-h, --help` - Show help message
- `-v, --version` - Show version

**Output Location and Naming:**

By default, all output files are saved to an `output/` folder in your current directory with this naming pattern:

```
output/
├── <project-name>_parse_diagram.mmd      # Mermaid syntax
├── <project-name>_parse_diagram.json     # Mermaid JSON (Live Editor compatible)
├── <project-name>_parse_diagram.html     # Interactive HTML diagram
└── <project-name>_parse_diagram.png      # Rendered PNG
```

The project name is automatically detected from `pubspec.yaml`. You can customize it with `--output`:

```bash
# Auto-detect from pubspec.yaml
parse . --format all

# Custom name
parse . --output my_architecture --format html
```

**Monorepo Support:**

The tool automatically scans for all packages (directories containing `pubspec.yaml`) and analyzes them together:

```bash
# For a monorepo with this structure:
# monorepo/
# ├── packages/
# │   ├── package_a/pubspec.yaml
# │   └── package_b/pubspec.yaml
# └── services/
#     └── shared_lib/pubspec.yaml

parse . --monorepo
```

This will generate a single diagram showing all classes from all packages and their relationships. Works with any nesting depth!

#### Using the Example Script

```bash
dart run example/main.dart
```

This analyzes the test fixtures and generates diagram files.

## Output Examples

### Class Information

```dart
ClassInfo(
  name: 'Dog',
  filePath: 'test/fixtures/dog.dart',
  kind: ClassKind.classKind,
  extendsClass: 'Animal',
  implementsList: ['Runnable'],
  withList: ['Swimmer', 'PetOwner'],
  usesList: [],
  documentation: '/// A concrete dog class that demonstrates multiple relationships',
)
```

### Mermaid Diagram (with Interactive Comments)

```mermaid
classDiagram
  class Animal {
    <<abstract>>
  }
  class Dog
  class Runnable {
    <<interface>>
  }
  class Swimmer {
    <<mixin>>
  }

  Animal <|-- Dog : extends
  Runnable <|.. Dog : implements
  Swimmer <|.. Dog : with

  click Animal "javascript:alert('/// Abstract base class for animals')"
  click Dog "javascript:alert('/// A concrete dog class that demonstrates multiple relationships')"
  click Runnable "javascript:alert('/// Abstract interface for things that can run')"
  click Swimmer "javascript:alert('/// Mixin for animals that can swim')"
```

**Click on a class name in the diagram above to see its documentation comment!**

## .parseignore

Create a `.parseignore` file in your project root to exclude directories/files:

```
# Example .parseignore
.dart_tool/
build/
.git/
test/vendor/**
```

Default exclusions:
- `.dart_tool/`
- `build/`
- `.git/`
- `.packages`
- `.gitignore`

## Project Structure

```
parse_mermaid_dart/
├── lib/
│   ├── parse_mermaid_dart.dart      # Public API entry point
│   └── src/
│       ├── models/
│       │   ├── class_info.dart      # ClassInfo and ClassKind
│       │   └── relationship.dart    # RelationshipKind enum
│       ├── parser/
│       │   ├── dart_parser.dart     # AST parser
│       │   └── file_walker.dart     # Filesystem walker
│       └── generator/
│           └── mermaid_generator.dart  # Mermaid diagram generation
├── test/
│   ├── parse_dart_test.dart         # Unit tests
│   └── fixtures/                    # Test case fixtures
├── example/
│   └── main.dart                    # Example usage
└── pubspec.yaml
```

## Testing

Run tests:

```bash
dart test
```

All tests are green ✓

## API Reference

### `ParseDart`

Main entry point for analyzing projects.

```dart
class ParseDart {
  /// Initialize with project path
  ParseDart(String projectPath);

  /// Analyze the project and return results
  Future<ParseResult> analyze();
}
```

### `ParseResult`

Result of analysis containing all classes found.

```dart
class ParseResult {
  /// All classes found in the project
  final List<ClassInfo> classes;

  /// Generate Mermaid diagram as string
  String toMermaid();

  /// Generate Mermaid JSON (Live Editor compatible)
  Map<String, dynamic> toMermaidJson();

  /// Save diagram to .mmd file
  Future<void> saveMermaidFile(String outputPath);

  /// Save JSON to file
  Future<void> saveJsonFile(String outputPath);
}
```

### `ClassInfo`

Information about a single class.

```dart
class ClassInfo {
  final String name;
  final String filePath;              // Relative to project root
  final ClassKind kind;
  final String? extendsClass;
  final List<String> implementsList;
  final List<String> withList;        // Mixins or 'on' constraints
  final List<String> usesList;        // Classes used in fields
  final String? documentation;        // Dart doc comments (///)
}
```

### `ClassKind`

Enum representing types of classes:

- `classKind` - Regular class
- `abstractClass` - Abstract class
- `mixin` - Mixin declaration
- `interfaceClass` - Abstract interface class
- `sealedClass` - Sealed class
- `enumKind` - Enum
- `extensionType` - Extension type

## Limitations

- Only detects relationships through field type annotations (not method parameters or return types)
- Only detects uses relationships for classes defined within the project
- Does not support generic type analysis in depth

## Dependencies

- `analyzer` ^6.0.0 - Dart AST parsing
- `glob` ^2.1.2 - File pattern matching
- `path` ^1.9.0 - Path utilities

## License

MIT

## Contributing

Contributions are welcome! Please ensure all tests pass and add tests for new features.

```bash
dart test
```

## Example Output

When run on the test fixtures, generates:

```
Found 13 classes:
  - Animal (ClassKind.abstractClass)
  - Dog (ClassKind.classKind)
      extends: Animal
      implements: Runnable
      with: Swimmer, PetOwner
  - Circle (ClassKind.classKind)
      extends: Shape
  - Status (ClassKind.enumKind)
      implements: Comparable
```

Copy the JSON output to [mermaid.live](https://mermaid.live) to visualize the diagram!
