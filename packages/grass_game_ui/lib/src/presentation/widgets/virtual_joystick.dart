import 'package:flutter/material.dart';

class VirtualJoystick extends StatelessWidget {
  const VirtualJoystick({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.16),
        border: Border.all(color: Colors.white24),
      ),
      alignment: Alignment.center,
      child: Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white54,
        ),
      ),
    );
  }
}
