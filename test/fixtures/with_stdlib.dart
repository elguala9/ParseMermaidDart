/// Example class that uses standard library types
class StringProcessor {
  /// Process a string from the standard library
  String processString(String input) {
    return input.toUpperCase();
  }

  /// Return a list of strings
  List<String> splitLines(String text) {
    return text.split('\n');
  }

  /// Check if async
  Future<String> fetchString() async {
    return Future.value('hello');
  }
}

/// Example class that uses collections
class CollectionHandler {
  /// Store items in a map
  Map<String, int> itemCount = {};

  /// Add an item
  void addItem(String name, int count) {
    itemCount[name] = count;
  }

  /// Get all items as a set
  Set<String> getAllItems() {
    return itemCount.keys.toSet();
  }
}
