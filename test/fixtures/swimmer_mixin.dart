import 'abstract_animal.dart';

/// Mixin for animals that can swim
/// Can only be mixed into classes that extend Animal
mixin Swimmer on Animal {
  void swim() {
    print('Swimming...');
  }
}
