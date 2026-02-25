// Test fixture for generic type extraction
abstract class Animal {}

class Dog extends Animal {}

/// Repository managing generic collections of animals
class AnimalRepository {
  final List<Animal> animals;
  final Map<String, Dog> dogMap;

  AnimalRepository({
    required this.animals,
    required this.dogMap,
  });

  List<Animal> getAll() => animals;

  Dog? findByName(String name) => dogMap[name];
}
