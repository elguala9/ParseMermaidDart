/// Status enum that implements Comparable
enum Status implements Comparable<Status> {
  pending(0),
  active(1),
  completed(2);

  final int value;

  const Status(this.value);

  @override
  int compareTo(Status other) => value.compareTo(other.value);
}
