import 'abstract_animal.dart';
import 'pet_owner.dart';
import 'runnable.dart';
import 'swimmer_mixin.dart';

/// A concrete dog class that demonstrates multiple relationships
class Dog extends Animal with Swimmer, PetOwner implements Runnable {
  @override
  final String name;

  Dog(this.name);

  @override
  void makeSound() {
    print('Woof!');
  }

  @override
  void run() {
    print('Dog is running!');
  }

  @override
  void move() {
    print('Dog is moving!');
  }

  @override
  int getAge() {
    return 5;
  }

  void fetch() {
    print('Fetching...');
  }
}
