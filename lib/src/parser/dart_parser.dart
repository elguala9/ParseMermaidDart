import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:path/path.dart' as p;

import '../models/class_info.dart';

/// Standard Dart library classes that should be included in diagrams
const _stdlibClasses = {
  // dart:core
  'Object': 'dart:core',
  'String': 'dart:core',
  'int': 'dart:core',
  'double': 'dart:core',
  'bool': 'dart:core',
  'List': 'dart:core',
  'Map': 'dart:core',
  'Set': 'dart:core',
  'Iterable': 'dart:core',
  'Iterator': 'dart:core',
  'Exception': 'dart:core',
  'Error': 'dart:core',
  'Comparable': 'dart:core',
  'Symbol': 'dart:core',
  'Type': 'dart:core',
  'Function': 'dart:core',
  'Duration': 'dart:core',
  'DateTime': 'dart:core',
  'RegExp': 'dart:core',
  // dart:async
  'Future': 'dart:async',
  'Stream': 'dart:async',
  'Completer': 'dart:async',
  'Zone': 'dart:async',
  'Timer': 'dart:async',
  // dart:collection
  'ListBase': 'dart:collection',
  'SetBase': 'dart:collection',
  'MapBase': 'dart:collection',
  'Queue': 'dart:collection',
  'DoubleLinkedQueue': 'dart:collection',
  'HashMap': 'dart:collection',
  'LinkedHashMap': 'dart:collection',
  'HashSet': 'dart:collection',
  'LinkedHashSet': 'dart:collection',
  'SplayTreeMap': 'dart:collection',
  'SplayTreeSet': 'dart:collection',
  // dart:convert
  'Codec': 'dart:convert',
  'Encoding': 'dart:convert',
  'Decoder': 'dart:convert',
  'Encoder': 'dart:convert',
};

/// Types that should be excluded from diagrams (primitives and basic types)
const _primitiveTypes = {
  'void',
  'dynamic',
  'Never',
  'Null',
  'String',
  'int',
  'double',
  'bool',
  'Object',
};

/// Result of parsing containing both classes and any errors encountered.
typedef ParseResult = ({List<ClassInfo> classes, List<String> errors});

/// Parses Dart files and extracts class information.
class DartParser {
  /// Parse all files and return class information and errors.
  /// Requires [filePaths] and [rootPath] to work correctly.
  Future<ParseResult> parseFiles(
    List<String> filePaths,
    String rootPath,
  ) async {
    // First pass: collect all known class names and parse files
    final knownClassNames = <String>{};
    final tempClasses = <ClassInfo>[];
    final errors = <String>[];

    for (final filePath in filePaths) {
      try {
        final content = await File(filePath).readAsString();
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
        errors.add('$filePath: $e');
      }
    }

    // Second pass: build final classes with relationships
    final stdlibClassesUsed = <String>{};
    final externalClassesUsed = <String>{};

    // Collect all standard library classes and external classes referenced
    for (final c in tempClasses) {
      if (c.extendsClass != null && !_primitiveTypes.contains(c.extendsClass)) {
        if (_stdlibClasses.containsKey(c.extendsClass)) {
          stdlibClassesUsed.add(c.extendsClass!);
        } else if (!knownClassNames.contains(c.extendsClass)) {
          externalClassesUsed.add(c.extendsClass!);
        }
      }
      for (final iface in c.implementsList) {
        if (_primitiveTypes.contains(iface)) continue;

        if (_stdlibClasses.containsKey(iface)) {
          stdlibClassesUsed.add(iface);
        } else if (!knownClassNames.contains(iface)) {
          externalClassesUsed.add(iface);
        }
      }
      for (final mixin in c.withList) {
        if (_primitiveTypes.contains(mixin)) continue;

        if (_stdlibClasses.containsKey(mixin)) {
          stdlibClassesUsed.add(mixin);
        } else if (!knownClassNames.contains(mixin)) {
          externalClassesUsed.add(mixin);
        }
      }
      for (final used in c.usesList) {
        // Skip primitive types
        if (_primitiveTypes.contains(used)) continue;

        if (_stdlibClasses.containsKey(used)) {
          stdlibClassesUsed.add(used);
        } else if (!knownClassNames.contains(used)) {
          externalClassesUsed.add(used);
        }
      }
    }

    // Create ClassInfo for standard library classes
    final stdlibClasses = stdlibClassesUsed
        .map((name) => ClassInfo(
              name: name,
              filePath: _stdlibClasses[name]!,
              kind: ClassKind.interfaceClass,
              extendsClass: null,
              implementsList: const [],
              withList: const [],
              usesList: const [],
              methodsList: const [],
              documentation: null,
              nestedIn: null,
              isExternal: false,
            ))
        .toList();

    // Create ClassInfo for external library classes
    final externalClasses = externalClassesUsed
        .map((name) => ClassInfo(
              name: name,
              filePath: 'external_library',
              kind: ClassKind.interfaceClass,
              extendsClass: null,
              implementsList: const [],
              withList: const [],
              usesList: const [],
              methodsList: const [],
              documentation: null,
              nestedIn: null,
              isExternal: true,
            ))
        .toList();

    // Filter relationships to exclude primitive types
    final finalClasses = tempClasses
        .map((c) => ClassInfo(
              name: c.name,
              filePath: c.filePath,
              kind: c.kind,
              extendsClass: c.extendsClass != null && !_primitiveTypes.contains(c.extendsClass)
                  ? c.extendsClass
                  : null,
              implementsList: c.implementsList
                  .where((n) => !_primitiveTypes.contains(n))
                  .toList(),
              withList: c.withList
                  .where((n) => !_primitiveTypes.contains(n))
                  .toList(),
              usesList: c.usesList
                  .where((n) => !_primitiveTypes.contains(n) && (knownClassNames.contains(n) || _stdlibClasses.containsKey(n) || externalClassesUsed.contains(n)))
                  .toList(),
              methodsList: c.methodsList,
              documentation: c.documentation,
              nestedIn: c.nestedIn,
              isExternal: false,
            ))
        .toList();

    // Combine all classes and deduplicate by name (keep first occurrence)
    final allClasses = [...finalClasses, ...stdlibClasses, ...externalClasses];
    final seenNames = <String>{};
    final uniqueClasses = allClasses.where((c) {
      if (seenNames.contains(c.name)) return false;
      seenNames.add(c.name);
      return true;
    }).toList();

    return (classes: uniqueClasses, errors: errors);
  }
}

/// AST visitor to extract class information.
class _ClassVisitor extends RecursiveAstVisitor<void> {
  final String filePath;
  final String rootPath;
  final List<ClassInfo> classes = [];
  final _classStack = <String>[];

  _ClassVisitor({
    required this.filePath,
    required this.rootPath,
  });

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final name = node.name.lexeme;
    final relativePath = p.relative(filePath, from: rootPath);

    // Track nested classes
    final parentClass = _classStack.isNotEmpty ? _classStack.last : null;

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

    // Extract used classes from field types and method signatures
    final usesList = <String>[];
    // Extract methods
    final methodsList = <String>[];
    for (final member in node.members) {
      if (member is FieldDeclaration) {
        final fieldType = member.fields.type;
        if (fieldType != null) {
          usesList.addAll(_extractTypeNames(fieldType));
        }
      } else if (member is MethodDeclaration) {
        // Extract return type
        final returnType = member.returnType;
        if (returnType != null) {
          usesList.addAll(_extractTypeNames(returnType));
        }
        // Extract types from method parameters
        final params = member.parameters?.parameters ?? [];
        for (final param in params) {
          if (param is SimpleFormalParameter && param.type != null) {
            usesList.addAll(_extractTypeNames(param.type!));
          }
        }
        // Extract method signature
        final methodSignature = _extractMethodSignature(member);
        if (methodSignature != null) {
          methodsList.add(methodSignature);
        }
      }
    }

    // Extract documentation comment
    String? documentation;
    if (node.documentationComment != null) {
      final tokens = node.documentationComment!.tokens;
      if (tokens.isNotEmpty) {
        documentation = tokens.map((t) => t.lexeme).join('\n');
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
      methodsList: methodsList,
      documentation: documentation,
      nestedIn: parentClass,
    );

    classes.add(classInfo);

    // Push class name onto stack before visiting children
    _classStack.add(name);

    // Manually visit nested classes in members
    for (final member in node.members) {
      if (member is ClassDeclaration) {
        member.accept(this);
      }
    }

    // Pop class name after visiting children
    _classStack.removeLast();
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

    // Extract used classes from method signatures
    final usesList = <String>[];
    // Extract methods
    final methodsList = <String>[];
    for (final member in node.members) {
      if (member is MethodDeclaration) {
        // Extract return type
        final returnType = member.returnType;
        if (returnType != null) {
          usesList.addAll(_extractTypeNames(returnType));
        }
        // Extract types from method parameters
        final params = member.parameters?.parameters ?? [];
        for (final param in params) {
          if (param is SimpleFormalParameter && param.type != null) {
            usesList.addAll(_extractTypeNames(param.type!));
          }
        }
        // Extract method signature
        final methodSignature = _extractMethodSignature(member);
        if (methodSignature != null) {
          methodsList.add(methodSignature);
        }
      }
    }

    // Extract documentation comment
    String? documentation;
    if (node.documentationComment != null) {
      final tokens = node.documentationComment!.tokens;
      if (tokens.isNotEmpty) {
        documentation = tokens.map((t) => t.lexeme).join('\n');
      }
    }

    final classInfo = ClassInfo(
      name: name,
      filePath: relativePath,
      kind: ClassKind.mixin,
      implementsList: implementsList,
      withList: onList, // Store 'on' constraints in withList for now
      usesList: usesList,
      methodsList: methodsList,
      documentation: documentation,
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

    // Extract methods
    final methodsList = <String>[];
    for (final member in node.members) {
      if (member is MethodDeclaration) {
        final methodSignature = _extractMethodSignature(member);
        if (methodSignature != null) {
          methodsList.add(methodSignature);
        }
      }
    }

    // Extract documentation comment
    String? documentation;
    if (node.documentationComment != null) {
      final tokens = node.documentationComment!.tokens;
      if (tokens.isNotEmpty) {
        documentation = tokens.map((t) => t.lexeme).join('\n');
      }
    }

    final classInfo = ClassInfo(
      name: name,
      filePath: relativePath,
      kind: ClassKind.enumKind,
      implementsList: implementsList,
      methodsList: methodsList,
      documentation: documentation,
    );

    classes.add(classInfo);

    super.visitEnumDeclaration(node);
  }

  @override
  // ignore: experimental_member_use
  void visitExtensionTypeDeclaration(ExtensionTypeDeclaration node) {
    final name = node.name.lexeme;
    final relativePath = p.relative(filePath, from: rootPath);

    // Extract documentation comment
    String? documentation;
    if (node.documentationComment != null) {
      final tokens = node.documentationComment!.tokens;
      if (tokens.isNotEmpty) {
        documentation = tokens.map((t) => t.lexeme).join('\n');
      }
    }

    final classInfo = ClassInfo(
      name: name,
      filePath: relativePath,
      kind: ClassKind.extensionType,
      documentation: documentation,
    );

    classes.add(classInfo);

    super.visitExtensionTypeDeclaration(node);
  }

  /// Extract method signature from a MethodDeclaration with parameter types.
  String? _extractMethodSignature(MethodDeclaration node) {
    final name = node.name.lexeme;
    final returnType = node.returnType?.toString() ?? 'void';
    final parameters = node.parameters?.parameters.map((p) {
      final type =
          p is SimpleFormalParameter ? (p.type?.toString() ?? '') : '';
      final pName = p.name?.lexeme ?? '';
      return type.isNotEmpty ? '$type $pName' : pName;
    }).join(', ') ?? '';
    return '$returnType $name($parameters)';
  }

  /// Extract all type names from a TypeAnnotation recursively (handles generics).
  List<String> _extractTypeNames(TypeAnnotation typeAnnotation) {
    final names = <String>[];
    if (typeAnnotation is NamedType) {
      names.add(typeAnnotation.name2.lexeme);
      final typeArgs = typeAnnotation.typeArguments;
      if (typeArgs != null) {
        for (final arg in typeArgs.arguments) {
          names.addAll(_extractTypeNames(arg));
        }
      }
    }
    return names;
  }
}
