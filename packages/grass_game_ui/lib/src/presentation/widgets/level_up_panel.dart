import 'package:flutter/material.dart';
import 'package:grass_game_domain/grass_game_domain.dart';

class LevelUpPanel extends StatelessWidget {
  const LevelUpPanel({
    super.key,
    required this.options,
    required this.onSelected,
  });

  final List<SkillConfig> options;
  final ValueChanged<SkillConfig> onSelected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'LEVEL UP',
                style: TextStyle(
                  color: Color(0xFFE8FFF2),
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  for (final option in options)
                    _SkillCard(
                      option: option,
                      onTap: () => onSelected(option),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkillCard extends StatelessWidget {
  const _SkillCard({
    required this.option,
    required this.onTap,
  });

  final SkillConfig option;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 136,
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF102418),
          foregroundColor: const Color(0xFFE8FFF2),
          padding: const EdgeInsets.all(14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Color(0x6649D17D)),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _colorFor(option.id),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _titleFor(option.id),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _descFor(option.id),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xBFE8FFF2),
                fontSize: 12,
                height: 1.25,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _colorFor(String id) {
    return switch (id) {
      'boots' => const Color(0xFFFFC857),
      'magnet' => const Color(0xFF8FE388),
      'haste' => const Color(0xFF7FDBFF),
      'might' => const Color(0xFFFF6B6B),
      _ => const Color(0xFF49D17D),
    };
  }

  String _titleFor(String id) {
    return switch (id) {
      'boots' => 'Swift Boots',
      'magnet' => 'Magnet Glove',
      'haste' => 'Cooldown Core',
      'might' => 'Power Glove',
      _ => 'Arrow Boost',
    };
  }

  String _descFor(String id) {
    return switch (id) {
      'boots' => 'Move speed +12%',
      'magnet' => 'Pickup range +22%',
      'haste' => 'Fire faster',
      'might' => 'Damage +1',
      _ => 'Damage +1, cooldown -6%',
    };
  }
}
