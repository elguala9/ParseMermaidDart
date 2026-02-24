import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:path/path.dart' as p;

import '../models/class_info.dart';

/// Parses Dart files and extracts class information.
class DartParser {
  /// Parse all files and return class information.
  /// Requires [filePaths] and [rootPath] to work correctly.
  Future<List<ClassInfo>> parseFiles(
    List<String> filePaths,
    String rootPath,
  ) async {
    // First pass: collect all known class names
    final knownClassNames = <String>{};
    final tempClasses = <ClassInfo>[];

    for (final filePath in filePaths) {
      try {
        final content = File(filePath).readAsStringSync();
        final result = parseString(
          content: content,
          throwIfDiagnostics: false,
        );

        final visitor = _ClassVisitor(
          filePath: filePath,
          rootPath: rootPath,
        );
        result.unit.accept(visitor);

        for (final classInfo in visitor.classes) {
          knownClassNames.add(classInfo.name);
          tempClasses.add(classInfo);
        }
      } catch (e) {
        // Skip files that can't be parsed
      }
    }

    // Second pass: filter usesList to only include known classes
    final finalClasses = <ClassInfo>[];
    for (final classInfo in tempClasses) {
      final filteredUses = classInfo.usesList
          .where((name) => knownClassNames.contains(name))
          .toList();

      final updatedClassInfo = ClassInfo(
        name: classInfo.name,
        filePath: classInfo.filePath,
        kind: classInfo.kind,
        extendsClass: classInfo.extendsClass,
        implementsList: classInfo.implementsList,
        withList: classInfo.withList,
        usesList: filteredUses,
      );

      finalClasses.add(updatedClassInfo);
    }

    return finalClasses;
  }
}

/// AST visitor to extract class information.
class _ClassVisitor extends RecursiveAstVisitor<void> {
  final String filePath;
  final String rootPath;
  final List<ClassInfo> classes = [];

  _ClassVisitor({
    required this.filePath,
    required this.rootPath,
  });

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final name = node.name.lexeme;
    final relativePath = p.relative(filePath, from: rootPath);

    // Determine the kind of class
    ClassKind kind = ClassKind.classKind;
    if (node.sealedKeyword != null) {
      kind = ClassKind.sealedClass;
    } else if (node.abstractKeyword != null) {
      if (node.interfaceKeyword != null) {
        kind = ClassKind.interfaceClass;
      } else {
        kind = ClassKind.abstractClass;
      }
    }

    // Extract extends clause
    String? extendsClass;
    if (node.extendsClause != null) {
      extendsClass = node.extendsClause!.superclass.name2.lexeme;
    }

    // Extract implements clause
    final implementsList = <String>[];
    if (node.implementsClause != null) {
      for (final interface in node.implementsClause!.interfaces) {
        implementsList.add(interface.name2.lexeme);
      }
    }

    // Extract with clause (mixins)
    final withList = <String>[];
    if (node.withClause != null) {
      for (final mixin in node.withClause!.mixinTypes) {
        withList.add(mixin.name2.lexeme);
      }
    }

    // Extract used classes from field types
    final usesList = <String>[];
    for (final member in node.members) {
      if (member is FieldDeclaration) {
        final fieldType = member.fields.type;
        if (fieldType != null) {
          final typeName = _extractTypeName(fieldType);
          if (typeName != null) {
            usesList.add(typeName);
          }
        }
      }
    }

    final classInfo = ClassInfo(
      name: name,
      filePath: relativePath,
      kind: kind,
      extendsClass: extendsClass,
      implementsList: implementsList,
      withList: withList,
      usesList: usesList,
    );

    classes.add(classInfo);

    // Continue visiting nested classes
    super.visitClassDeclaration(node);
  }

  @override
  void visitMixinDeclaration(MixinDeclaration node) {
    final name = node.name.lexeme;
    final relativePath = p.relative(filePath, from: rootPath);

    // Extract on clause (on constraint)
    final onList = <String>[];
    if (node.onClause != null) {
      for (final constraint in node.onClause!.superclassConstraints) {
        onList.add(constraint.name2.lexeme);
      }
    }

    // Extract implements clause
    final implementsList = <String>[];
    if (node.implementsClause != null) {
      for (final interface in node.implementsClause!.interfaces) {
        implementsList.add(interface.name2.lexeme);
      }
    }

    // Mixins appear as part of relationships but aren't tracked as using other classes
    // in the same way as regular classes

    final classInfo = ClassInfo(
      name: name,
      filePath: relativePath,
      kind: ClassKind.mixin,
      implementsList: implementsList,
      withList: onList, // Store 'on' constraints in withList for now
    );

    classes.add(classInfo);

    super.visitMixinDeclaration(node);
  }

  @override
  void visitEnumDeclaration(EnumDeclaration node) {
    final name = node.name.lexeme;
    final relativePath = p.relative(filePath, from: rootPath);

    // Extract implements clause
    final implementsList = <String>[];
    if (node.implementsClause != null) {
      for (final interface in node.implementsClause!.interfaces) {
        implementsList.add(interface.name2.lexeme);
      }
    }

    final classInfo = ClassInfo(
      name: name,
      filePath: relativePath,
      kind: ClassKind.enumKind,
      implementsList: implementsList,
    );

    classes.add(classInfo);

    super.visitEnumDeclaration(node);
  }

  @override
  void visitExtensionTypeDeclaration(ExtensionTypeDeclaration node) {
    final name = node.name.lexeme;
    final relativePath = p.relative(filePath, from: rootPath);

    final classInfo = ClassInfo(
      name: name,
      filePath: relativePath,
      kind: ClassKind.extensionType,
    );

    classes.add(classInfo);

    super.visitExtensionTypeDeclaration(node);
  }

  /// Extract a simple type name from a TypeAnnotation.
  String? _extractTypeName(TypeAnnotation typeAnnotation) {
    if (typeAnnotation is NamedType) {
      return typeAnnotation.name2.lexeme;
    }
    return null;
  }
}
