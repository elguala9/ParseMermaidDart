#!/bin/bash
# Pre-commit checks: format, analyze, test
# Usage: ./check.sh

set -e

echo "🎨 Checking code format..."
dart format . --set-exit-if-changed

echo "🔍 Analyzing code..."
dart analyze --fatal-infos

echo "✅ Running tests..."
dart test

echo "✨ All checks passed! Ready to commit."
