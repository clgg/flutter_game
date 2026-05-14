abstract interface class AppLogger {
  void debug(String message, {Object? error, StackTrace? stackTrace});

  void warning(String message, {Object? error, StackTrace? stackTrace});
}
