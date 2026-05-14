import 'package:flutter/material.dart';

import 'odt_splash_animation.dart';

class OdtSplashPage extends StatelessWidget {
  const OdtSplashPage({
    super.key,
    required this.onCompleted,
  });

  final VoidCallback onCompleted;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          color: Color(0xFF08120E),
        ),
        child: SafeArea(
          child: Center(
            child: OdtSplashAnimation(
              onCompleted: onCompleted,
            ),
          ),
        ),
      ),
    );
  }
}
