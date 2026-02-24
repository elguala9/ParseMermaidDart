# Scripts and Commands

This project uses a custom Dart script runner for managing development commands.

## Usage

All commands use the same pattern:

```bash
dart run bin/run_scripts.dart <command>
```

Or with the shell wrapper (Unix/Linux/macOS):

```bash
./run.sh <command>
```

## Available Commands

### Testing

```bash
dart run bin/run_scripts.dart test              # Run all tests
dart run bin/run_scripts.dart test:watch        # Run tests in watch mode
dart run bin/run_scripts.dart test:coverage     # Run tests with coverage
```

### Code Quality

```bash
dart run bin/run_scripts.dart analyze           # Analyze code
dart run bin/run_scripts.dart format            # Check code format
dart run bin/run_scripts.dart format:fix        # Fix code format
dart run bin/run_scripts.dart lint              # Lint checks (strict)
```

### Development Workflows

```bash
dart run bin/run_scripts.dart dev               # Full setup (get, analyze, test)
dart run bin/run_scripts.dart check:all         # All checks (format, analyze, test)
dart run bin/run_scripts.dart ci                # CI checks (analyze, test)
```

### Dependencies

```bash
dart run bin/run_scripts.dart pub:get           # Get dependencies
dart run bin/run_scripts.dart pub:upgrade       # Upgrade dependencies
dart run bin/run_scripts.dart pub:outdated      # Show outdated packages
```

### Build & Examples

```bash
dart run bin/run_scripts.dart build:example     # Run example
```

## Shell Wrapper

For easier access on Unix/Linux/macOS:

```bash
./run.sh test
./run.sh dev
./run.sh check:all
./run.sh build:example
```

## Direct Dart Commands

You can always use Dart CLI directly:

```bash
dart test
dart analyze
dart format .
dart run example/main.dart
```

## Customizing Commands

Edit `bin/run_scripts.dart` to add new commands or modify existing ones.

Each command is a case in the switch statement:

```dart
case 'my:command':
  await runCommand('dart', ['my', 'command', 'args']);
```

## Quick Reference

| Task | Command |
|------|---------|
| Test | `dart run bin/run_scripts.dart test` |
| Test (watch) | `dart run bin/run_scripts.dart test:watch` |
| Test (coverage) | `dart run bin/run_scripts.dart test:coverage` |
| Analyze | `dart run bin/run_scripts.dart analyze` |
| Format (check) | `dart run bin/run_scripts.dart format` |
| Format (fix) | `dart run bin/run_scripts.dart format:fix` |
| Dev setup | `dart run bin/run_scripts.dart dev` |
| Pre-commit | `dart run bin/run_scripts.dart check:all` |
| CI checks | `dart run bin/run_scripts.dart ci` |
| Example | `dart run bin/run_scripts.dart build:example` |

Or with wrapper:

| Task | Command |
|------|---------|
| Test | `./run.sh test` |
| All checks | `./run.sh check:all` |
| Dev setup | `./run.sh dev` |
