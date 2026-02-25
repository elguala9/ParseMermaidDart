/// User model for package_a
class User {
  final String id;
  final String name;

  User({required this.id, required this.name});
}

/// Base user interface
abstract interface class UserInterface {
  String getId();
}
