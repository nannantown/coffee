import 'package:flutter/material.dart';

class GrinderSettingSlider extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const GrinderSettingSlider({
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
          'グラインダーセッティング: $value',
          style: const TextStyle(fontSize: 16),
        ),
        Slider(
          value: value.toDouble(),
          min: 140.0,
          max: 350.0,
          label: '$value',
          onChanged: (val) => onChanged(val.round()),
        ),
      ],
    );
  }
}
