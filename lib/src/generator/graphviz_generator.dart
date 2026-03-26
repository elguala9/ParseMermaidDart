import '../models/class_info.dart';
import '../utils/diagram_utils.dart';

/// Generates Graphviz DOT format diagrams from ClassInfo objects.
class GraphvizGenerator {
  /// Generate a Graphviz DOT diagram string.
  String generate(List<ClassInfo> classes, {bool noPrivate = false, bool noExternal = false, bool noMethods = false, String layout = 'dot', Set<String>? onlyRelations}) {
    return _generateCode(classes, noPrivate: noPrivate, noExternal: noExternal, noMethods: noMethods, layout: layout, onlyRelations: onlyRelations);
  }

  /// Generate DOT code with optional filtering.
  String _generateCode(List<ClassInfo> classes, {bool noPrivate = false, bool noExternal = false, bool noMethods = false, String layout = 'dot', Set<String>? onlyRelations}) {
    final buffer = StringBuffer();
    buffer.writeln('digraph UMLClassDiagram {');

    // Configure layout based on selected algorithm
    final layoutConfig = _getLayoutConfig(layout);
    buffer.writeln('  graph [$layoutConfig fontname="Helvetica"];');
    buffer.writeln('  node  [shape=none, margin=0, fontname="Helvetica", fontsize=10];');
    buffer.writeln('  edge  [fontname="Helvetica", fontsize=9];');
    buffer.writeln();

    // Add node definitions
    for (final classInfo in classes) {
      // Skip external classes if noExternal is true
      if (noExternal && classInfo.isExternal) {
        continue;
      }

      // Skip private classes if noPrivate is true
      if (noPrivate && classInfo.name.startsWith('_')) {
        continue;
      }

      final nodeId = _nodeId(classInfo.name);
      final nodeLabel = _generateNodeLabel(classInfo, noPrivate: noPrivate, noMethods: noMethods);
      buffer.writeln('  $nodeId [label=$nodeLabel];');
    }

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
      final classNodeId = _nodeId(className);

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
          final parentNodeId = _nodeId(classInfo.extendsClass!);
          relationships.add('$parentNodeId -> $classNodeId [arrowhead=empty, dir=back, style=solid, label="extends"];');
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
            final interfaceNodeId = _nodeId(interface);
            relationships.add('$interfaceNodeId -> $classNodeId [arrowhead=empty, dir=back, style=dashed, label="implements"];');
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
            final mixinNodeId = _nodeId(mixin);
            relationships.add('$mixinNodeId -> $classNodeId [arrowhead=empty, dir=back, style=dashed, label="with"];');
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
            final usedNodeId = _nodeId(used);
            relationships.add('$classNodeId -> $usedNodeId [arrowhead=open, dir=forward, style=solid, label="uses"];');
          }
        }
      }

      // Nested class relationships
      if (classInfo.nestedIn != null && (onlyRelations == null || onlyRelations.contains('nested'))) {
        final nestedInNodeId = _nodeId(classInfo.nestedIn!);
        relationships.add('$classNodeId -> $nestedInNodeId [arrowhead=odiamond, dir=forward, style=solid, label="nestedIn"];');
      }
    }

    // Remove duplicates and sort
    final uniqueRelationships = relationships.toSet().toList()..sort();
    for (final rel in uniqueRelationships) {
      buffer.writeln('  $rel');
    }

    buffer.writeln('}');
    return buffer.toString();
  }

  /// Generate HTML table label for a node (Graphviz DOT table format).
  String _generateNodeLabel(ClassInfo classInfo, {bool noPrivate = false, bool noMethods = false}) {
    final buffer = StringBuffer();
    final (headerBg, bodyBg) = _getColors(classInfo.kind, classInfo.isExternal);
    final stereotype = getStereotype(classInfo.kind);

    // Filter private methods if noPrivate is true, or all methods if noMethods is true
    final filteredMethods = noMethods
        ? <String>[]
        : (noPrivate
            ? classInfo.methodsList.where((m) => !isPrivateMethod(m)).toList()
            : classInfo.methodsList);

    buffer.write('<\n    <TABLE BORDER="1" CELLBORDER="0" CELLSPACING="0" CELLPADDING="4" BGCOLOR="$bodyBg">\n');

    // Stereotype row (if needed)
    if (stereotype.isNotEmpty || classInfo.isExternal) {
      buffer.write('      <TR><TD ALIGN="CENTER" BGCOLOR="$headerBg"><FONT COLOR="white"><B>');
      if (stereotype.isNotEmpty) {
        buffer.write('&lt;&lt;$stereotype&gt;&gt;');
      }
      if (classInfo.isExternal) {
        if (stereotype.isNotEmpty) {
          buffer.write(', ');
        }
        buffer.write('&lt;&lt;external&gt;&gt;');
      }
      buffer.write('</B></FONT></TD></TR>\n');
    }

    // Class name row
    buffer.write('      <TR><TD ALIGN="CENTER"><B>${_xmlEscape(classInfo.name)}</B></TD></TR>\n');

    // Horizontal separator (only if there are methods)
    if (filteredMethods.isNotEmpty) {
      buffer.write('      <HR/>\n');

      // Method rows
      for (final method in filteredMethods) {
        buffer.write('      <TR><TD ALIGN="LEFT">${_xmlEscape(method)}</TD></TR>\n');
      }
    }

    buffer.write('    </TABLE>\n  >');
    return buffer.toString();
  }

  /// Get colors for a class kind.
  (String headerBg, String bodyBg) _getColors(dynamic kind, bool isExternal) {
    if (isExternal) {
      return ('#616161', '#F5F5F5');
    }

    final kindStr = kind.toString();
    if (kindStr == 'ClassKind.abstractClass') {
      return ('#2E7D32', '#E8F5E9');
    } else if (kindStr == 'ClassKind.mixin') {
      return ('#6A1B9A', '#F3E5F5');
    } else if (kindStr == 'ClassKind.interfaceClass') {
      return ('#E65100', '#FFF3E0');
    } else if (kindStr == 'ClassKind.sealedClass') {
      return ('#AD1457', '#FCE4EC');
    } else if (kindStr == 'ClassKind.enumKind') {
      return ('#00695C', '#E0F2F1');
    } else if (kindStr == 'ClassKind.extensionType') {
      return ('#4527A0', '#EDE7F6');
    }

    // Default for regular class
    return ('#1565C0', '#E3F2FD');
  }

  /// Get the stereotype annotation for a class kind.
  String getStereotype(ClassKind kind) {
    return switch (kind) {
      ClassKind.abstractClass => 'abstract',
      ClassKind.mixin => 'mixin',
      ClassKind.interfaceClass => 'interface',
      ClassKind.sealedClass => 'sealed',
      ClassKind.enumKind => 'enumeration',
      ClassKind.extensionType => 'extension',
      ClassKind.classKind => 'class',
    };
  }

  /// Sanitize a node ID for Graphviz (replace invalid characters).
  String _nodeId(String name) {
    // Replace any character that's not alphanumeric or underscore with underscore
    return name.replaceAll(RegExp(r'[^\w]'), '_');
  }

  /// Escape text for Graphviz HTML-like labels.
  String _xmlEscape(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  /// Get layout configuration for Graphviz based on layout algorithm.
  String _getLayoutConfig(String layout) {
    switch (layout.toLowerCase()) {
      case 'dot':
        // Hierarchical layout (default) - good for trees and hierarchies
        return 'rankdir=BT, splines=ortho, nodesep=0.8, ranksep=1.2';
      case 'neato':
        // Force-directed layout - better for general graphs, fewer crossings
        return 'splines=spline, overlap=false, sep=0.5';
      case 'fdp':
        // Fruchterman-Reingold force-directed - excellent for reducing crossings
        return 'splines=spline, overlap=false, sep=0.5, repulsiveforce=2.0';
      case 'sfdp':
        // Scalable force-directed - good for large graphs
        return 'splines=spline, overlap=false, sep=0.5';
      case 'circo':
        // Circular layout - nodes arranged in circle
        return 'splines=spline, overlap=false, sep=0.5';
      case 'twopi':
        // Radial layout - nodes radiate from center
        return 'splines=spline, overlap=false, sep=0.5';
      default:
        // Fallback to dot
        return 'rankdir=BT, splines=ortho, nodesep=0.8, ranksep=1.2';
    }
  }
}
