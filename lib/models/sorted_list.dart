import 'dart:collection';

/// Custom sorted list that extends ListBase
class SortedList<T extends Comparable<T>> extends ListBase<T> {
  final List<T> _items = [];

  @override
  int get length => _items.length;

  @override
  set length(int newLength) {
    _items.length = newLength;
  }

  @override
  T operator [](int index) => _items[index];

  @override
  void operator []=(int index, T value) {
    _items[index] = value;
    _sort();
  }

  @override
  void add(T value) {
    _items.add(value);
    _sort();
  }

  void _sort() {
    _items.sort((a, b) => a.compareTo(b));
  }
}
