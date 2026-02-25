import 'sorted_list.dart';
import 'user.dart';

/// Repository for managing users with a sorted list
class UserRepository {
  final SortedList<User> users = SortedList<User>();

  /// Add a user to the repository
  void addUser(User user) {
    users.add(user);
  }

  /// Get all users sorted by age
  List<User> getAllUsers() {
    return List.from(users);
  }

  /// Find user by age
  User? findByAge(int age) {
    try {
      return users.firstWhere((u) => u.age == age);
    } catch (e) {
      return null;
    }
  }
}
