import 'package:flutter/material.dart';

class LevelUpPanel extends StatelessWidget {
  const LevelUpPanel({
    super.key,
    required this.options,
    required this.onSelected,
  });

  final List<String> options;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      child: Center(
        child: Wrap(
          spacing: 12,
          children: [
            for (final option in options)
              ElevatedButton(
                onPressed: () => onSelected(option),
                child: Text(option),
              ),
          ],
        ),
      ),
    );
  }
}
