#!/bin/bash
# Complete dev setup: get dependencies, analyze, and test
# Usage: ./dev.sh

set -e

echo "📦 Getting dependencies..."
dart pub get

echo "🔍 Analyzing code..."
dart analyze

echo "✅ Running tests..."
dart test

echo "✨ Dev setup complete!"
