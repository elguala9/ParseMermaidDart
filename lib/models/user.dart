import 'base_entity.dart';

/// User class that extends BaseEntity and implements Comparable
class User extends BaseEntity implements Comparable<User> {
  final String _id;
  final String name;
  final int age;

  User({
    required String id,
    required this.name,
    required this.age,
  }) : _id = id;

  @override
  String get id => _id;

  @override
  int compareTo(User other) {
    return age.compareTo(other.age);
  }

  @override
  String toString() => 'User($id, $name, age: $age)';
}
