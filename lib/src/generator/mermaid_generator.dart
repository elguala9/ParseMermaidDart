import 'package:path/path.dart' as p;

import '../models/class_info.dart';
import '../utils/diagram_utils.dart';

/// Generates Mermaid class diagrams from ClassInfo objects.
class MermaidGenerator {
  /// Generate a Mermaid class diagram string with file paths.
  String generate(List<ClassInfo> classes, {String? projectPath, bool noPrivate = false, bool noExternal = false, bool noMethods = false, Set<String>? onlyRelations}) {
    return _generateCode(classes, includeFilePath: true, projectPath: projectPath, noPrivate: noPrivate, noExternal: noExternal, noMethods: noMethods, onlyRelations: onlyRelations);
  }

  /// Generate Mermaid code for PNG rendering (without file paths to avoid kroki.io parsing issues).
  String _generateBaseCode(List<ClassInfo> classes, {bool noPrivate = false, bool noExternal = false, bool noMethods = false, Set<String>? onlyRelations}) {
    return _generateCode(classes, includeFilePath: false, noPrivate: noPrivate, noExternal: noExternal, noMethods: noMethods, onlyRelations: onlyRelations);
  }

  /// Generate Mermaid code with optional file path information.
  String _generateCode(List<ClassInfo> classes, {required bool includeFilePath, String? projectPath, bool noPrivate = false, bool noExternal = false, bool noMethods = false, Set<String>? onlyRelations}) {
    final buffer = StringBuffer();
    buffer.writeln('classDiagram');

    // Create a map of original names to display paths (for stereotypes)
    final nameToDisplayPath = <String, String>{};
    for (final classInfo in classes) {
      if (includeFilePath) {
        // Use only the filename to reduce diagram size (e.g., "dog.dart" instead of "path/to/dog.dart")
        final displayPath = p.basename(classInfo.filePath);
        nameToDisplayPath[classInfo.name] = displayPath;
      }
    }

    // Add class definitions with annotations
    for (final classInfo in classes) {
      // Skip external classes if noExternal is true
      if (noExternal && classInfo.isExternal) {
        continue;
      }

      // Skip private classes if noPrivate is true
      if (noPrivate && classInfo.name.startsWith('_')) {
        continue;
      }

      buffer.write('  class ${escapeName(classInfo.name)}');

      // Add stereotypes and methods if present
      final kindStereotype = getStereotype(classInfo.kind);
      final displayPath = includeFilePath ? nameToDisplayPath[classInfo.name] : null;

      // Filter private methods if noPrivate is true, or all methods if noMethods is true
      final filteredMethods = noMethods
          ? <String>[]
          : (noPrivate
              ? classInfo.methodsList.where((m) => !isPrivateMethod(m)).toList()
              : classInfo.methodsList);

      final hasMethods = filteredMethods.isNotEmpty;

      if (kindStereotype.isNotEmpty || displayPath != null || hasMethods || classInfo.isExternal) {
        buffer.write(' {\n');
        // Always add the kind stereotype (class, interface, abstract, etc.)
        if (kindStereotype.isNotEmpty) {
          buffer.write('    $kindStereotype\n');
        }
        // Add external stereotype if from external library
        if (classInfo.isExternal) {
          buffer.write('    <<external>>\n');
        }
        // Add file path if available
        if (displayPath != null) {
          buffer.write('    📁 $displayPath\n');
        }
        for (final method in filteredMethods) {
          buffer.write('    $method\n');
        }
        buffer.write('  }');
      }

      buffer.writeln();
    }

    // Add relationships
    buffer.writeln();

    // Build a set of internal class names for filtering relationships
    final internalClassNames = <String>{};
    if (noExternal) {
      for (final classInfo in classes) {
        if (!classInfo.isExternal) {
          internalClassNames.add(classInfo.name);
        }
      }
    }

    // Collect all relationships
    final relationships = <String>[];

    for (final classInfo in classes) {
      // Skip relationships for external classes if noExternal is true
      if (noExternal && classInfo.isExternal) {
        continue;
      }

      // Skip relationships for private classes if noPrivate is true
      if (noPrivate && classInfo.name.startsWith('_')) {
        continue;
      }

      final className = classInfo.name;

      // Extends relationship
      if (classInfo.extendsClass != null && (onlyRelations == null || onlyRelations.contains('extends'))) {
        bool shouldInclude = true;
        if (noExternal && !internalClassNames.contains(classInfo.extendsClass!)) {
          shouldInclude = false;
        }
        if (noPrivate && classInfo.extendsClass!.startsWith('_')) {
          shouldInclude = false;
        }
        if (shouldInclude) {
          relationships.add('${escapeName(classInfo.extendsClass!)} <|-- ${escapeName(className)} : extends');
        }
      }

      // Implements relationships
      if (onlyRelations == null || onlyRelations.contains('implements')) {
        for (final interface in classInfo.implementsList) {
          bool shouldInclude = true;
          if (noExternal && !internalClassNames.contains(interface)) {
            shouldInclude = false;
          }
          if (noPrivate && interface.startsWith('_')) {
            shouldInclude = false;
          }
          if (shouldInclude) {
            relationships.add('${escapeName(interface)} <|.. ${escapeName(className)} : implements');
          }
        }
      }

      // With relationships (mixins)
      if (onlyRelations == null || onlyRelations.contains('with')) {
        for (final mixin in classInfo.withList) {
          bool shouldInclude = true;
          if (noExternal && !internalClassNames.contains(mixin)) {
            shouldInclude = false;
          }
          if (noPrivate && mixin.startsWith('_')) {
            shouldInclude = false;
          }
          if (shouldInclude) {
            relationships.add('${escapeName(mixin)} <|.. ${escapeName(className)} : with');
          }
        }
      }

      // Uses relationships
      if (onlyRelations == null || onlyRelations.contains('uses')) {
        for (final used in classInfo.usesList) {
          bool shouldInclude = true;
          if (noExternal && !internalClassNames.contains(used)) {
            shouldInclude = false;
          }
          if (noPrivate && used.startsWith('_')) {
            shouldInclude = false;
          }
          if (shouldInclude) {
            relationships.add('${escapeName(className)} --> ${escapeName(used)} : uses');
          }
        }
      }

      // Nested class relationships
      if (classInfo.nestedIn != null && (onlyRelations == null || onlyRelations.contains('nested'))) {
        relationships.add('${escapeName(className)} --> ${escapeName(classInfo.nestedIn!)} : nested_in');
      }
    }

    // Remove duplicates and sort
    final uniqueRelationships = relationships.toSet().toList()..sort();
    for (final rel in uniqueRelationships) {
      buffer.writeln('  $rel');
    }

    return buffer.toString();
  }

  /// Generate Mermaid code suitable for PNG rendering (without click handlers).
  String generateForPng(List<ClassInfo> classes, {bool noPrivate = false, bool noExternal = false, bool noMethods = false, Set<String>? onlyRelations}) {
    return _generateBaseCode(classes, noPrivate: noPrivate, noExternal: noExternal, noMethods: noMethods, onlyRelations: onlyRelations);
  }

  /// Generate JSON compatible with Mermaid Live Editor.
  Map<String, dynamic> generateJson(List<ClassInfo> classes, {String? projectPath, bool noPrivate = false, bool noExternal = false, bool noMethods = false, Set<String>? onlyRelations}) {
    return {
      'code': generate(classes, projectPath: projectPath, noPrivate: noPrivate, noExternal: noExternal, noMethods: noMethods, onlyRelations: onlyRelations),
      'mermaid': {
        'theme': 'default',
      },
      'updateEditor': false,
    };
  }
}
