/// Enum representing different types of relationships between classes.
enum RelationshipKind {
  /// Class A extends Class B
  extendsRelationship,

  /// Class A implements Interface B
  implementsRelationship,

  /// Class A uses Mixin B
  withRelationship,

  /// Class A uses Class B (detected from field types)
  usesRelationship,
}
