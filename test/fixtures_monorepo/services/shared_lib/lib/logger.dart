/// Logger interface
abstract interface class Logger {
  void log(String message);
}

/// Console logger implementation
class ConsoleLogger implements Logger {
  @override
  void log(String message) {
    print(message);
  }
}

/// File logger implementation
class FileLogger implements Logger {
  final String filePath;

  FileLogger(this.filePath);

  @override
  void log(String message) {
    // Implementation
  }
}
