import 'package:flutter/material.dart';

class Fader extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;

  const Fader({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Fondo del fader (canal)
          Container(
            width: 36,
            height: 180,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey[900],
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(2, 4),
                ),
              ],
            ),
          ),
          // Slider vertical
          RotatedBox(
            quarterTurns: -1,
            child: Slider(
              value: value,
              onChanged: onChanged,
              min: 0.0,
              max: 1.0,
              divisions: 100,
            ),
          ),
        ],
      ),
    );
  }
}
