/// Base entity class that extends Object
abstract class BaseEntity {
  /// Unique identifier
  String get id;

  /// Get the string representation
  @override
  String toString() => 'Entity($id)';
}
