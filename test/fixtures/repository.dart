import 'abstract_animal.dart';
import 'dog.dart';

/// Repository for dogs - demonstrates "uses" relationship
class DogRepository {
  final Dog _dog;
  final Animal _animal;
  String name = 'DefaultRepo';

  DogRepository(this._dog, this._animal);

  void saveDog() {
    print('Saving ${_dog.name}');
  }

  Dog? getDog() {
    return _dog;
  }

  List<Animal> getAllAnimals() {
    return [_dog, _animal];
  }

  void deleteDog() {
    print('Deleting dog...');
  }
}
