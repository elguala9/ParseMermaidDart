.PHONY: help test test-watch test-coverage analyze format lint dev ci check-all clean build-example pub-get pub-upgrade

help:
	@echo "parse_dart - Dart Class Analysis Library"
	@echo ""
	@echo "Available commands:"
	@echo "  make test              Run all tests"
	@echo "  make test-watch        Run tests in watch mode"
	@echo "  make test-coverage     Run tests with coverage"
	@echo "  make analyze           Analyze code"
	@echo "  make format            Check code format"
	@echo "  make format-fix        Format code"
	@echo "  make lint              Run lint checks"
	@echo "  make dev               Complete dev setup (get, analyze, test)"
	@echo "  make ci                CI checks (analyze, test)"
	@echo "  make check-all         All checks (format, analyze, test)"
	@echo "  make clean             Clean build artifacts"
	@echo "  make build-example     Run example"
	@echo "  make pub-get           Get dependencies"
	@echo "  make pub-upgrade       Upgrade dependencies"
	@echo "  make pub-outdated      Show outdated packages"

test:
	dart test

test-watch:
	dart test --watch

test-coverage:
	dart test --coverage=coverage
	dart pub global activate coverage
	dart pub global run coverage:format_coverage --lcov --in=coverage --out=coverage/lcov.info --packages=.packages

analyze:
	dart analyze

format:
	dart format . --set-exit-if-changed

format-fix:
	dart format .

lint:
	dart analyze --fatal-infos

dev:
	dart pub get
	dart analyze
	dart test

ci:
	dart analyze --fatal-infos
	dart test

check-all:
	dart format . --set-exit-if-changed
	dart analyze --fatal-infos
	dart test

clean:
	dart pub cache clean
	find . -type d -name ".dart_tool" -exec rm -rf {} + 2>/dev/null || true
	find . -type f -name "pubspec.lock" -delete 2>/dev/null || true

build-example:
	dart run example/main.dart

pub-get:
	dart pub get

pub-upgrade:
	dart pub upgrade

pub-outdated:
	dart pub outdated
