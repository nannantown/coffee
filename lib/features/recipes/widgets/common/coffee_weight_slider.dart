import 'package:flutter/material.dart';

class CoffeeWeightSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;

  const CoffeeWeightSlider({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'コーヒー豆: ${value.toStringAsFixed(1)}g',
          style: const TextStyle(fontSize: 16),
        ),
        Slider(
          value: value,
          min: 12.0,
          max: 24.0,
          divisions: 24, // 0.5g increments: (24 - 12) / 0.5 = 24
          label: '${value.toStringAsFixed(1)}g',
          onChanged: onChanged,
        ),
      ],
    );
  }
}
