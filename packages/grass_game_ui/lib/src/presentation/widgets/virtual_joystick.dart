import 'package:flutter/material.dart';

class VirtualJoystick extends StatefulWidget {
  const VirtualJoystick({
    super.key,
    required this.onChanged,
  });

  final ValueChanged<Offset> onChanged;

  @override
  State<VirtualJoystick> createState() => _VirtualJoystickState();
}

class _VirtualJoystickState extends State<VirtualJoystick> {
  static const double _size = 112;
  static const double _knobSize = 40;
  static const double _maxDistance = (_size - _knobSize) / 2;

  Offset _knobOffset = Offset.zero;

  void _updateFromLocalPosition(Offset localPosition) {
    const center = Offset(_size / 2, _size / 2);
    var offset = localPosition - center;
    if (offset.distance > _maxDistance) {
      offset = Offset.fromDirection(offset.direction, _maxDistance);
    }

    setState(() {
      _knobOffset = offset;
    });
    widget.onChanged(offset / _maxDistance);
  }

  void _reset() {
    setState(() {
      _knobOffset = Offset.zero;
    });
    widget.onChanged(Offset.zero);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (details) => _updateFromLocalPosition(details.localPosition),
      onPanUpdate: (details) => _updateFromLocalPosition(details.localPosition),
      onPanEnd: (_) => _reset(),
      onPanCancel: _reset,
      child: SizedBox(
        width: _size,
        height: _size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.16),
            border: Border.all(color: Colors.white24),
          ),
          child: Center(
            child: Transform.translate(
              offset: _knobOffset,
              child: Container(
                width: _knobSize,
                height: _knobSize,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white70,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
