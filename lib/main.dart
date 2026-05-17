import 'dart:async';

import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/diagnostics/crash_log_service.dart';

Future<void> main() async {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      final crashLogs = CrashLogService.instance;
      await crashLogs.init();
      crashLogs.installFlutterHandlers();

      runApp(const FlutterGameApp());
    },
    (error, stackTrace) {
      CrashLogService.instance.recordError(error, stackTrace);
    },
  );
}
