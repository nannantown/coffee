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
          min: 10.0,
          max: 30.0,
          label: '${value.toStringAsFixed(1)}g',
          onChanged: onChanged,
        ),
      ],
    );
  }
}
