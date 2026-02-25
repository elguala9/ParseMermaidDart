/// Enum representing the kind of class or type declaration.
enum ClassKind {
  /// Regular class
  classKind,

  /// Abstract class
  abstractClass,

  /// Mixin declaration
  mixin,

  /// Interface class (abstract interface)
  interfaceClass,

  /// Sealed class
  sealedClass,

  /// Enum declaration
  enumKind,

  /// Extension type
  extensionType,
}

/// Information about a Dart class extracted from the AST.
class ClassInfo {
  /// Name of the class
  final String name;

  /// File path relative to the project root
  final String filePath;

  /// Kind of class declaration
  final ClassKind kind;

  /// Name of the class this extends, if any
  final String? extendsClass;

  /// List of interface names this class implements
  final List<String> implementsList;

  /// List of mixin names this class uses
  final List<String> withList;

  /// List of class names used internally (detected from field types)
  final List<String> usesList;

  /// List of method signatures in the class
  final List<String> methodsList;

  /// Documentation comment for the class, if present
  final String? documentation;

  /// Name of the outer class if this is an inner class, null otherwise
  final String? nestedIn;

  /// Whether this class is from an external library (not part of the project)
  final bool isExternal;

  ClassInfo({
    required this.name,
    required this.filePath,
    required this.kind,
    this.extendsClass,
    List<String>? implementsList,
    List<String>? withList,
    List<String>? usesList,
    List<String>? methodsList,
    this.documentation,
    this.nestedIn,
    this.isExternal = false,
  })  : implementsList = implementsList ?? [],
        withList = withList ?? [],
        usesList = usesList ?? [],
        methodsList = methodsList ?? [];

  @override
  String toString() {
    return 'ClassInfo(name: $name, kind: $kind, extends: $extendsClass, '
        'implements: $implementsList, with: $withList, uses: $usesList, methods: $methodsList, nestedIn: $nestedIn)';
  }
}
