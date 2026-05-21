import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class CrashLogEntry {
  const CrashLogEntry({
    required this.path,
    required this.name,
    required this.modifiedAt,
    required this.bytes,
  });

  final String path;
  final String name;
  final DateTime modifiedAt;
  final int bytes;
}

class CrashLogService {
  CrashLogService._();

  static final CrashLogService instance = CrashLogService._();
  static const MethodChannel _channel =
      MethodChannel('com.odt.game/crash_logs');

  Directory? _logDirectory;

  Directory? get logDirectory => _logDirectory;

  Future<void> init() async {
    if (kIsWeb) {
      return;
    }
    if (_logDirectory != null) {
      return;
    }

    var path = await _nativeCrashLogDirectory();
    path ??= '${Directory.systemTemp.path}/flutter_game_crash_logs';
    final directory = Directory(path);
    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
    }
    _logDirectory = directory;
  }

  void installFlutterHandlers() {
    final previousFlutterHandler = FlutterError.onError;
    FlutterError.onError = (details) {
      recordFlutterError(details);
      if (previousFlutterHandler != null) {
        previousFlutterHandler(details);
      } else {
        FlutterError.presentError(details);
      }
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      recordError(error, stack, source: 'platform_dispatcher');
      return true;
    };
  }

  Future<void> recordInfo(String message, {String? details}) async {
    _writeLog(
      source: 'info',
      error: message,
      stackTrace: details,
      isFatal: false,
    );
  }

  void recordFlutterError(FlutterErrorDetails details) {
    _writeLog(
      source: 'flutter',
      error: details.exceptionAsString(),
      stackTrace: details.stack?.toString(),
      library: details.library,
      context: details.context?.toDescription(),
      isFatal: false,
    );
  }

  void recordError(
    Object error,
    StackTrace stackTrace, {
    String source = 'zone',
    bool isFatal = true,
  }) {
    _writeLog(
      source: source,
      error: error.toString(),
      stackTrace: stackTrace.toString(),
      isFatal: isFatal,
    );
  }

  Future<List<CrashLogEntry>> listLogs() async {
    if (kIsWeb) {
      return const [];
    }
    await init();
    final directory = _logDirectory;
    if (directory == null || !directory.existsSync()) {
      return const [];
    }

    final files = directory
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.log'))
        .map((file) {
      final stat = file.statSync();
      return CrashLogEntry(
        path: file.path,
        name: file.uri.pathSegments.last,
        modifiedAt: stat.modified,
        bytes: stat.size,
      );
    }).toList()
      ..sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
    return files;
  }

  Future<String> readLog(String path) async {
    if (kIsWeb) {
      return '';
    }
    final file = File(path);
    if (!file.existsSync()) {
      return '';
    }
    return file.readAsString();
  }

  Future<void> shareLog(String path) async {
    if (kIsWeb) {
      return;
    }
    try {
      await _channel.invokeMethod<void>('shareCrashLog', {'path': path});
    } on PlatformException {
      rethrow;
    }
  }

  Future<void> deleteLog(String path) async {
    if (kIsWeb) {
      return;
    }
    final file = File(path);
    if (file.existsSync()) {
      await file.delete();
    }
  }

  Future<void> clearLogs() async {
    if (kIsWeb) {
      return;
    }
    final logs = await listLogs();
    for (final log in logs) {
      await deleteLog(log.path);
    }
  }

  Future<String?> _nativeCrashLogDirectory() async {
    try {
      return await _channel.invokeMethod<String>('getCrashLogDirectory');
    } on Object {
      return null;
    }
  }

  void _writeLog({
    required String source,
    required String error,
    required bool isFatal,
    String? stackTrace,
    String? library,
    String? context,
  }) {
    if (kIsWeb) {
      return;
    }
    final directory = _logDirectory;
    if (directory == null) {
      return;
    }

    try {
      final now = DateTime.now();
      final file = File(
        '${directory.path}/${_fileStamp(now)}_${source}_${isFatal ? 'fatal' : 'event'}.log',
      );
      final buffer = StringBuffer()
        ..writeln('time: ${now.toIso8601String()}')
        ..writeln('source: $source')
        ..writeln('fatal: $isFatal')
        ..writeln('flutter_mode: ${kReleaseMode ? 'release' : 'debug/profile'}')
        ..writeln('error:')
        ..writeln(error);
      if (library != null) {
        buffer
          ..writeln()
          ..writeln('library:')
          ..writeln(library);
      }
      if (context != null) {
        buffer
          ..writeln()
          ..writeln('context:')
          ..writeln(context);
      }
      if (stackTrace != null && stackTrace.trim().isNotEmpty) {
        buffer
          ..writeln()
          ..writeln('stack:')
          ..writeln(stackTrace);
      }
      file.writeAsStringSync(buffer.toString(), mode: FileMode.writeOnly);
      _trimOldLogs(directory);
    } on Object {
      // Crash logging must never create a second crash path.
    }
  }

  void _trimOldLogs(Directory directory) {
    final logs = directory
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.log'))
        .toList()
      ..sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
    for (final file in logs.skip(40)) {
      try {
        file.deleteSync();
      } on Object {
        // Ignore cleanup failures.
      }
    }
  }

  String _fileStamp(DateTime time) {
    String two(int value) => value.toString().padLeft(2, '0');
    String three(int value) => value.toString().padLeft(3, '0');
    return [
      time.year,
      two(time.month),
      two(time.day),
      '_',
      two(time.hour),
      two(time.minute),
      two(time.second),
      '_',
      three(time.millisecond),
    ].join();
  }
}
