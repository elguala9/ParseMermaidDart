# Scripts and Commands

This project uses **Melos** for managing development scripts and commands.

## Setup

### Install Melos (globally)

```bash
dart pub global activate melos
```

### Bootstrap the workspace

```bash
melos bootstrap
```

## Available Commands

### Testing

```bash
# Run all tests
melos test

# Run tests in watch mode
melos test:watch

# Run tests with coverage
melos test:coverage
```

### Code Quality

```bash
# Analyze code
melos analyze

# Check code format
melos format

# Fix code format
melos format:fix

# Run lint checks (strict)
melos lint
```

### Development

```bash
# Complete dev setup (get deps, analyze, test)
melos dev

# Pre-commit checks (format, analyze, test)
melos check:all

# CI checks (analyze, strict, test)
melos ci
```

### Dependencies

```bash
# Get dependencies
melos pub:get

# Upgrade dependencies
melos pub:upgrade

# Show outdated packages
melos pub:outdated

# Clean cache
melos clean
```

### Example

```bash
# Run example
melos build:example
```

## Using Dart CLI Directly

If you prefer not to use Melos:

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

## Melos Configuration

The `melos.yaml` file defines all available scripts. Scripts are organized in sections:
- Testing scripts (test, test:watch, test:coverage)
- Code quality (analyze, format, lint)
- Development workflows (dev, check:all, ci)
- Dependency management (pub:get, pub:upgrade, pub:outdated, clean)
- Build tasks (build:example)

To add custom scripts, edit `melos.yaml`:

```yaml
scripts:
  my:command:
    description: My custom command
    run: echo "Running custom command"
```

Then run with: `melos my:command`

## Quick Reference

| Task | Command |
|------|---------|
| Test | `melos test` |
| Test (watch) | `melos test:watch` |
| Test (coverage) | `melos test:coverage` |
| Analyze | `melos analyze` |
| Format (check) | `melos format` |
| Format (fix) | `melos format:fix` |
| Dev setup | `melos dev` |
| Pre-commit | `melos check:all` |
| CI checks | `melos ci` |
| Example | `melos build:example` |
