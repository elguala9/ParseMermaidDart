#!/usr/bin/env dart
import 'dart:io';

void main(List<String> args) async {
  if (args.isEmpty) {
    printHelp();
    return;
  }

  final command = args[0];
  final extraArgs = args.length > 1 ? args.sublist(1) : [];

  switch (command) {
    case 'test':
      await runCommand('dart', ['test', ...extraArgs]);
    case 'test:watch':
      await runCommand('dart', ['test', '--watch']);
    case 'test:coverage':
      await runCommand('dart', ['test', '--coverage=coverage']);
    case 'analyze':
      await runCommand('dart', ['analyze']);
    case 'format':
      await runCommand('dart', ['format', '.', '--set-exit-if-changed']);
    case 'format:fix':
      await runCommand('dart', ['format', '.']);
    case 'lint':
      await runCommand('dart', ['analyze', '--fatal-infos']);
    case 'pub:get':
      await runCommand('dart', ['pub', 'get']);
    case 'pub:upgrade':
      await runCommand('dart', ['pub', 'upgrade']);
    case 'pub:outdated':
      await runCommand('dart', ['pub', 'outdated']);
    case 'dev':
      print('📦 Getting dependencies...');
      await runCommand('dart', ['pub', 'get']);
      print('\n🔍 Analyzing code...');
      await runCommand('dart', ['analyze']);
      print('\n✅ Running tests...');
      await runCommand('dart', ['test']);
      print('\n✨ Dev setup complete!');
    case 'ci':
      print('🔍 Analyzing code...');
      await runCommand('dart', ['analyze', '--fatal-infos']);
      print('\n✅ Running tests...');
      await runCommand('dart', ['test']);
      print('\n✨ CI checks passed!');
    case 'check:all':
      print('🎨 Checking format...');
      await runCommand('dart', ['format', '.', '--set-exit-if-changed']);
      print('\n🔍 Analyzing code...');
      await runCommand('dart', ['analyze', '--fatal-infos']);
      print('\n✅ Running tests...');
      await runCommand('dart', ['test']);
      print('\n✨ All checks passed!');
    case 'build:example':
      print('🚀 Running example...');
      await runCommand('dart', ['run', 'example/main.dart']);
    default:
      print('Unknown command: $command');
      printHelp();
  }
}

Future<void> runCommand(String executable, List<String> args) async {
  final result = await Process.run(executable, args);
  stdout.write(result.stdout);
  stderr.write(result.stderr);
  if (result.exitCode != 0) {
    exit(result.exitCode);
  }
}

void printHelp() {
  print('''
parse_dart - Development Commands

Usage: dart run bin/run_scripts.dart <command>

Commands:
  test              Run all tests
  test:watch        Run tests in watch mode
  test:coverage     Run tests with coverage
  analyze           Analyze code
  format            Check code format
  format:fix        Fix code format
  lint              Run lint checks (strict)
  pub:get           Get dependencies
  pub:upgrade       Upgrade dependencies
  pub:outdated      Show outdated packages
  dev               Complete dev setup (get, analyze, test)
  ci                CI checks (analyze, test)
  check:all         All checks (format, analyze, test)
  build:example     Run example

Examples:
  dart run bin/run_scripts.dart test
  dart run bin/run_scripts.dart dev
  dart run bin/run_scripts.dart check:all
''');
}
