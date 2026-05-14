import 'package:flutter/material.dart';

class GrassGameHud extends StatelessWidget {
  const GrassGameHud({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('HP 100', style: TextStyle(color: Colors.white)),
        Text('Lv 1', style: TextStyle(color: Colors.white)),
        Text('00:00', style: TextStyle(color: Colors.white)),
      ],
    );
  }
}
