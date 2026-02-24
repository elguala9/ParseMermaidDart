# Scripts and Commands

This project uses **Melos** for managing development scripts and commands. You can run commands either via Melos, Make, shell scripts, or Dart CLI directly.

## Setup

### 1. Install Melos (globally)

```bash
dart pub global activate melos
```

### 2. Bootstrap the workspace

```bash
melos bootstrap
```

## Running Commands

### Option 1: Using Melos (Recommended)

```bash
# Run tests
melos test

# Run tests in watch mode
melos test:watch

# Run tests with coverage
melos test:coverage

# Analyze code
melos analyze

# Format code (check)
melos format

# Format code (fix)
melos format:fix

# Complete dev setup
melos dev

# CI checks
melos ci

# All checks (format, analyze, test)
melos check:all

# Build example
melos build:example
```

### Option 2: Using Make (Unix/Linux/macOS)

```bash
# Show all available commands
make help

# Run tests
make test

# Run tests in watch mode
make test-watch

# Run tests with coverage
make test-coverage

# Analyze code
make analyze

# Format code (check)
make format

# Format code (fix)
make format-fix

# Run lint checks
make lint

# Complete dev setup
make dev

# CI checks
make ci

# All checks
make check-all

# Build example
make build-example

# Clean artifacts
make clean
```

### Option 3: Using Shell Scripts

```bash
# Run tests
./test.sh

# Run tests in watch mode
./test.sh watch

# Run tests with coverage
./test.sh coverage

# Complete dev setup
./dev.sh

# Pre-commit checks
./check.sh

# Build example
./example.sh
```

### Option 4: Using Dart CLI directly

```bash
# Run tests
dart test

# Analyze code
dart analyze

# Format code
dart format .

# Run example
dart run example/main.dart
```

## Common Tasks

### Before Committing

Run all checks to ensure code quality:

```bash
# Using Melos
melos check:all

# Using Make
make check-all

# Using script
./check.sh

# Using Dart
dart format . --set-exit-if-changed && dart analyze --fatal-infos && dart test
```

### Continuous Development

Run tests in watch mode for continuous feedback:

```bash
# Using Melos
melos test:watch

# Using Make
make test-watch

# Using Dart
dart test --watch
```

### With Coverage

Generate code coverage reports:

```bash
# Using Melos
melos test:coverage

# Using Make
make test-coverage

# Using script
./test.sh coverage
```

### Setup Development Environment

Complete setup for new developers:

```bash
# Using Melos
melos dev

# Using Make
make dev

# Using script
./dev.sh
```

## Melos Configuration

The `melos.yaml` file defines all available scripts and commands. You can view it to see all available options or extend it with custom scripts.

Key scripts defined:
- `test` - Run all tests
- `test:watch` - Watch mode testing
- `test:coverage` - Tests with coverage
- `analyze` - Code analysis
- `format` / `format:fix` - Code formatting
- `lint` - Lint checks
- `dev` - Complete dev setup
- `ci` - CI pipeline checks
- `check:all` - All quality checks
- `clean` - Clean build artifacts

## CI/CD Integration

For automated testing in CI/CD pipelines:

```bash
# Using Melos
melos ci

# Using Make
make ci

# Using Dart (most basic)
dart analyze --fatal-infos && dart test
```

## Troubleshooting

### Melos not found
Install it globally:
```bash
dart pub global activate melos
```

### Permission denied on shell scripts
Make them executable:
```bash
chmod +x test.sh dev.sh check.sh example.sh
```

### Make not found
- On macOS/Linux: Usually pre-installed
- On Windows: Install from http://gnuwin32.sourceforge.net/packages/make.htm
- Or just use the shell scripts or Melos

### .dart_tool or pubspec.lock issues
Clean and reinstall dependencies:
```bash
melos clean
melos pub:get
# or
make clean
make pub-get
```

## Quick Reference

| Task | Melos | Make | Shell |
|------|-------|------|-------|
| Test | `melos test` | `make test` | `./test.sh` |
| Test (watch) | `melos test:watch` | `make test-watch` | `./test.sh watch` |
| Test (coverage) | `melos test:coverage` | `make test-coverage` | `./test.sh coverage` |
| Analyze | `melos analyze` | `make analyze` | - |
| Format (check) | `melos format` | `make format` | - |
| Format (fix) | `melos format:fix` | `make format-fix` | - |
| Dev setup | `melos dev` | `make dev` | `./dev.sh` |
| Pre-commit | `melos check:all` | `make check-all` | `./check.sh` |
| Example | `melos build:example` | `make build-example` | `./example.sh` |

## Custom Scripts

To add custom scripts, edit `melos.yaml` and add a new entry under `scripts:`. Example:

```yaml
scripts:
  my:command:
    description: My custom command
    run: echo "Running custom command"
```

Then run with:
```bash
melos my:command
```
