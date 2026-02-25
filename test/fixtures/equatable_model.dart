import 'package:equatable/equatable.dart';

/// A model class that extends Equatable from the equatable package
/// This demonstrates inheritance from external pub.dev libraries
class UserModel extends Equatable {
  final String id;
  final String name;
  final String email;
  final int age;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.age,
  });

  @override
  List<Object> get props => [id, name, email, age];

  String getDisplayName() {
    return '$name ($email)';
  }

  bool isAdult() {
    return age >= 18;
  }
}
