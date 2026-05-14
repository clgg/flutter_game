import 'package:flutter/material.dart';

import 'router/app_router.dart';

class FlutterGameApp extends StatelessWidget {
  const FlutterGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Game',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      routes: AppRouter.routes,
      initialRoute: AppRouter.home,
    );
  }
}
