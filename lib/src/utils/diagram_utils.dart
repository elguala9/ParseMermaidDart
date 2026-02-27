/// Shared utility functions for diagram generation.
library;

import '../models/class_info.dart';

/// Get the stereotype annotation for a class kind.
String getStereotype(ClassKind kind) {
  return switch (kind) {
    ClassKind.abstractClass => '<<abstract>>',
    ClassKind.mixin => '<<mixin>>',
    ClassKind.interfaceClass => '<<interface>>',
    ClassKind.sealedClass => '<<sealed>>',
    ClassKind.enumKind => '<<enumeration>>',
    ClassKind.extensionType => '<<extension>>',
    ClassKind.classKind => '<<class>>',
  };
}

/// Escape a class name for diagram syntax.
/// Replace special characters with underscores for compatibility.
String escapeName(String name) {
  // Replace special characters (including $) with underscores
  return name.replaceAll(RegExp(r'[^\w]'), '_');
}

/// Check if a method signature represents a private method.
/// Method format: "ReturnType methodName(params)" or "methodName(params)"
/// Private methods start with underscore: "_methodName"
bool isPrivateMethod(String methodSignature) {
  // Find the opening parenthesis
  final parenIndex = methodSignature.indexOf('(');
  if (parenIndex == -1) return false;

  // Get everything before the parenthesis
  final beforeParen = methodSignature.substring(0, parenIndex).trim();

  // Get the last word (method name) - it's after the last space
  final parts = beforeParen.split(' ');
  if (parts.isEmpty) return false;

  final methodName = parts.last;
  return methodName.startsWith('_');
}
