import 'dart:convert';

import '../models/class_info.dart';

/// Generates Mermaid class diagrams from ClassInfo objects.
class MermaidGenerator {
  /// Generate a Mermaid class diagram string.
  String generate(List<ClassInfo> classes) {
    final buffer = StringBuffer();
    buffer.writeln('classDiagram');

    // Add class definitions with annotations
    for (final classInfo in classes) {
      buffer.write('  class ${_escapeName(classInfo.name)}');

      // Add stereotype annotation if needed
      final stereotype = _getStereotype(classInfo.kind);
      if (stereotype.isNotEmpty) {
        buffer.write(' {\n    $stereotype\n  }');
      }

      buffer.writeln();
    }

    // Add relationships
    buffer.writeln();

    // Collect all relationships
    final relationships = <String>[];

    for (final classInfo in classes) {
      // Extends relationship
      if (classInfo.extendsClass != null) {
        final superclass = _escapeName(classInfo.extendsClass!);
        final subclass = _escapeName(classInfo.name);
        relationships
            .add('$superclass <|-- $subclass : extends');
      }

      // Implements relationships
      for (final interface in classInfo.implementsList) {
        final interfaceName = _escapeName(interface);
        final className = _escapeName(classInfo.name);
        relationships.add('$interfaceName <|.. $className : implements');
      }

      // With relationships (mixins)
      for (final mixin in classInfo.withList) {
        final mixinName = _escapeName(mixin);
        final className = _escapeName(classInfo.name);
        relationships.add('$mixinName <|.. $className : with');
      }

      // Uses relationships
      for (final used in classInfo.usesList) {
        final usedName = _escapeName(used);
        final className = _escapeName(classInfo.name);
        relationships.add('$className --> $usedName : uses');
      }
    }

    // Remove duplicates and sort
    final uniqueRelationships = relationships.toSet().toList()..sort();
    for (final rel in uniqueRelationships) {
      buffer.writeln('  $rel');
    }

    return buffer.toString();
  }

  /// Generate JSON compatible with Mermaid Live Editor.
  Map<String, dynamic> generateJson(List<ClassInfo> classes) {
    return {
      'code': generate(classes),
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
    }
    return '';
  }

  /// Escape a class name for Mermaid syntax.
  /// If it contains special characters, quote it.
  String _escapeName(String name) {
    if (name.contains(RegExp(r'[^\w]'))) {
      return '"$name"';
    }
    return name;
  }
}
