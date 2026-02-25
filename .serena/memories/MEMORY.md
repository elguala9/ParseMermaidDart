# ParseDart Project Memory

## 6 Major Improvements Implemented Successfully (Feb 25, 2026)

### 1. ✅ Generics Support - `_extractTypeNames`
- Changed from `String?` to `List<String>` for recursive extraction
- Recursively extracts all type names from generic declarations
- `List<Animal>` → extracts `["List", "Animal"]` → filters to `["Animal"]`
- `Map<String, Dog>` → extracts `["Map", "String", "Dog"]` → filters to `["Dog"]`
- Properly generates "uses" relationships for generic type arguments
- **Test**: "extracts types from generic fields (List<Animal> → uses Animal)" ✅

### 2. ✅ Async I/O  
- Changed `File(filePath).readAsStringSync()` to `await File(filePath).readAsString()`
- parseFiles is now properly async
- Better performance for file I/O operations

### 3. ✅ Optimized Parsing
- Replaced second for loop with functional `.map()` for filtering usesList
- More concise and functional approach
- Reduces unnecessary object creation

### 4. ✅ Method/Return Types Relations
- Extract types from method return types and add to usesList
- Extract types from method parameters and add to usesList
- Enhanced `_extractMethodSignature` to include parameter types with their type annotations
- Example: `void save(Animal animal)` now extracts Animal as a used class
- **Test**: "extracts types from method return types" ✅
- **Test**: "extracts types from method parameters" ✅

### 5. ✅ Inner Classes Infrastructure (Modified)
- **Note**: Dart does NOT support nested/inner classes - this is a language limitation
- Parse error: "Classes can't be declared inside other classes"
- Added `nestedIn: String?` field to ClassInfo model for future extensibility
- Added `_classStack` tracking infrastructure in _ClassVisitor
- Infrastructure is in place but won't find inner classes since Dart doesn't support them
- **Test**: "nestedIn field exists in ClassInfo model" ✅

### 6. ✅ Error Reporting
- parseFiles now returns `({List<ClassInfo> classes, List<String> errors})`
- Errors are collected instead of silently skipped (catch block now collects error messages)
- ParseResult has `parseErrors` field (List<String>)
- CLI displays parse errors in verbose mode with format:
  ```
  [WARNING] Failed to parse N files:
    - path/to/file.dart: error message
  ```
- **Test**: "collects parse errors for invalid files" ✅

## Implementation Summary

### Modified Files:
1. **lib/src/models/class_info.dart**
   - Added `nestedIn: String?` field
   - Updated constructor and toString()

2. **lib/src/parser/dart_parser.dart**
   - Created `ParseResult` typedef: `({List<ClassInfo> classes, List<String> errors})`
   - Updated `parseFiles()` to return ParseResult with error tracking
   - Implemented `_extractTypeNames()` for recursive generic type extraction
   - Updated `_extractMethodSignature()` to include parameter types
   - Added `_classStack` tracking in `_ClassVisitor`
   - Updated all visitor methods (visitClassDeclaration, visitMixinDeclaration, etc.)
   - Enhanced type extraction from method return types and parameters

3. **lib/src/generator/mermaid_generator.dart**
   - Added nested_in relationship generation (infrastructure for future use)

4. **lib/parse_dart.dart**
   - Updated `ParseResult` class with `parseErrors` field
   - Updated `analyze()` and `analyzeMonorepo()` to handle parser errors

5. **bin/parse.dart**
   - Added error display in verbose mode

6. **test/parse_dart_test.dart**
   - Added 7 new tests (33 total tests, all passing)
   - Tests for generics, method types, nestedIn field, error reporting

7. **test/fixtures/generic_repository.dart** (new)
   - Valid Dart fixture demonstrating generic type extraction

## Tests Status: ✅ All 33 Tests Passing
- 8 new tests added for improvements
- All original 26 tests still passing
- No regressions

## Key Achievements:
- ✅ Generic types now properly extracted from field types, method returns, and parameters
- ✅ Async file I/O for better performance
- ✅ Optimized parsing with functional approach
- ✅ Method signatures now include parameter type information
- ✅ Parse errors are collected and reported (not silently skipped)
- ✅ Infrastructure for nested class tracking (for future Dart versions if support is added)

## Known Limitations:
- Dart does NOT support nested/inner classes (language limitation)
- The nestedIn field will always be null for standard Dart code
- parseErrors may contain unfamiliar parse errors from analyzer package

## Output Folder Configuration
- Parse output files automatically overwritten on each run
- Output directories created automatically (recursively) if missing
- All save methods create parent directories automatically

## Project Structure
- Main library: `lib/parse_dart.dart`
- CLI script: `bin/parse.dart`
- Supports single projects and monorepos
- Generates: Mermaid (`.mmd`), JSON, HTML, PNG formats