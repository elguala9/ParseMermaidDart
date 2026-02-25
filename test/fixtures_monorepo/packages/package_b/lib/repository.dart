/// Repository for managing data
class Repository {
  final String name;

  Repository(this.name);

  Future<void> save() async {
    // Implementation
  }
}

/// Cache mixin
mixin CacheableMixin {
  late DateTime cachedAt;
}
