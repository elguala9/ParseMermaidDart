/// Sealed class for shapes - can only be subclassed in this file
sealed class Shape {
  double get area;
}

/// Circle shape
class Circle extends Shape {
  final double radius;

  Circle(this.radius);

  @override
  double get area => 3.14159 * radius * radius;
}

/// Rectangle shape
class Rect extends Shape {
  final double width;
  final double height;

  Rect(this.width, this.height);

  @override
  double get area => width * height;
}
