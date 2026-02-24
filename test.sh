#!/bin/bash
# Run tests with optional flags
# Usage: ./test.sh [watch|coverage]

if [ "$1" == "watch" ]; then
    echo "Running tests in watch mode..."
    dart test --watch
elif [ "$1" == "coverage" ]; then
    echo "Running tests with coverage..."
    dart test --coverage=coverage
    echo "Formatting coverage..."
    dart pub global activate coverage
    dart pub global run coverage:format_coverage --lcov --in=coverage --out=coverage/lcov.info --packages=.packages
else
    echo "Running tests..."
    dart test
fi
