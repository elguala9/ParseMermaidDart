import '../models/class_info.dart';

/// Generates Mermaid class diagrams from ClassInfo objects.
class MermaidGenerator {
  /// Generate a Mermaid class diagram string with file paths.
  String generate(List<ClassInfo> classes, {String? projectPath}) {
    return _generateCode(classes, includeFilePath: true, projectPath: projectPath);
  }

  /// Generate Mermaid code for PNG rendering (without file paths to avoid kroki.io parsing issues).
  String _generateBaseCode(List<ClassInfo> classes) {
    return _generateCode(classes, includeFilePath: false);
  }

  /// Generate Mermaid code with optional file path information.
  String _generateCode(List<ClassInfo> classes, {required bool includeFilePath, String? projectPath}) {
    final buffer = StringBuffer();
    buffer.writeln('classDiagram');

    // Create a map of original names to display paths (for stereotypes)
    final nameToDisplayPath = <String, String>{};
    for (final classInfo in classes) {
      if (includeFilePath) {
        // If projectPath is provided and is not '.', prepend it to get the full path
        String displayPath = classInfo.filePath.replaceAll('\\', '/');
        if (projectPath != null && projectPath != '.' && !displayPath.startsWith(projectPath)) {
          final normalizedProjectPath = projectPath.replaceAll('\\', '/');
          displayPath = '$normalizedProjectPath/$displayPath';
        }
        nameToDisplayPath[classInfo.name] = displayPath;
      }
    }

    // Add class definitions with annotations
    for (final classInfo in classes) {
      buffer.write('  class ${_escapeName(classInfo.name)}');

      // Add stereotypes and methods if present
      final kindStereotype = _getStereotype(classInfo.kind);
      final displayPath = includeFilePath ? nameToDisplayPath[classInfo.name] : null;
      final hasMethods = classInfo.methodsList.isNotEmpty;

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
        for (final method in classInfo.methodsList) {
          buffer.write('    $method\n');
        }
        buffer.write('  }');
      }

      buffer.writeln();
    }

    // Add relationships
    buffer.writeln();

    // Collect all relationships
    final relationships = <String>[];

    for (final classInfo in classes) {
      final className = classInfo.name;

      // Extends relationship
      if (classInfo.extendsClass != null) {
        relationships.add('${_escapeName(classInfo.extendsClass!)} <|-- ${_escapeName(className)} : extends');
      }

      // Implements relationships
      for (final interface in classInfo.implementsList) {
        relationships.add('${_escapeName(interface)} <|.. ${_escapeName(className)} : implements');
      }

      // With relationships (mixins)
      for (final mixin in classInfo.withList) {
        relationships.add('${_escapeName(mixin)} <|.. ${_escapeName(className)} : with');
      }

      // Uses relationships
      for (final used in classInfo.usesList) {
        relationships.add('${_escapeName(className)} --> ${_escapeName(used)} : uses');
      }

      // Nested class relationships
      if (classInfo.nestedIn != null) {
        relationships.add('${_escapeName(className)} --> ${_escapeName(classInfo.nestedIn!)} : nested_in');
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
  String generateForPng(List<ClassInfo> classes) {
    return _generateBaseCode(classes);
  }

  /// Generate JSON compatible with Mermaid Live Editor.
  Map<String, dynamic> generateJson(List<ClassInfo> classes, {String? projectPath}) {
    return {
      'code': generate(classes, projectPath: projectPath),
      'mermaid': {
        'theme': 'default',
      },
      'updateEditor': false,
    };
  }

  /// Get the stereotype annotation for a class kind.
  String _getStereotype(dynamic kind) {
    if (kind.toString() == 'ClassKind.abstractClass') {
      return '<<abstract>>';
    } else if (kind.toString() == 'ClassKind.mixin') {
      return '<<mixin>>';
    } else if (kind.toString() == 'ClassKind.interfaceClass') {
      return '<<interface>>';
    } else if (kind.toString() == 'ClassKind.sealedClass') {
      return '<<sealed>>';
    } else if (kind.toString() == 'ClassKind.enumKind') {
      return '<<enumeration>>';
    } else if (kind.toString() == 'ClassKind.extensionType') {
      return '<<extension>>';
    }
    // Default for regular class
    return '<<class>>';
  }

  /// Escape a class name for Mermaid syntax.
  /// Replace special characters with underscores for Mermaid compatibility.
  String _escapeName(String name) {
    // Replace special characters (including $) with underscores
    return name.replaceAll(RegExp(r'[^\w]'), '_');
  }

}
