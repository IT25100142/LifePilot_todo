#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "=== Step 1: Getting Dependencies ==="
flutter pub get

echo "=== Step 2: Running Code Generation ==="
dart run build_runner build --delete-conflicting-outputs

echo "=== Step 3: Checking Code Formatting ==="
dart format --set-exit-if-changed .

echo "=== Step 4: Running Static Analysis ==="
flutter analyze

echo "=== Step 5: Running Automated Tests with Coverage ==="
flutter test --coverage

echo "=== All checks passed successfully! Ready for check-in. ==="
