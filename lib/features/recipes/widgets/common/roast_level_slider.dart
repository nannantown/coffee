import 'package:flutter/material.dart';

class RoastLevelSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;

  const RoastLevelSlider({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with level name
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '焙煎レベル: ${(value * 100).toInt()}%',
              style: const TextStyle(fontSize: 16),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getRoastColor(value),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _getRoastLevelName(value),
                style: TextStyle(
                  fontSize: 12,
                  color: _getRoastTextColor(value),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        // Slider
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: _getRoastColor(value),
            thumbColor: _getRoastColor(value),
            inactiveTrackColor: _getRoastColor(value).withValues(alpha: 0.3),
          ),
          child: Slider(
            value: value,
            min: 0.0,
            max: 1.0,
            onChanged: onChanged,
          ),
        ),
        // Labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('ライト', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
            Text('シナモン', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
            Text('ミディアム', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
            Text('ハイ', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
            Text('ダーク', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
          ],
        ),
      ],
    );
  }

  String _getRoastLevelName(double level) {
    if (level < 0.2) return 'ライトロースト';
    if (level < 0.4) return 'シナモンロースト';
    if (level < 0.6) return 'ミディアムロースト';
    if (level < 0.8) return 'ハイロースト';
    return 'ダークロースト';
  }

  Color _getRoastColor(double level) {
    if (level < 0.2) return Colors.brown[200]!;
    if (level < 0.4) return Colors.brown[300]!;
    if (level < 0.6) return Colors.brown[500]!;
    if (level < 0.8) return Colors.brown[700]!;
    return Colors.brown[900]!;
  }

  Color _getRoastTextColor(double level) {
    // Light and Cinnamon roast - use dark text
    if (level < 0.4) return Colors.brown[900]!;
    // Medium roast - use white text for better contrast
    if (level < 0.6) return Colors.white;
    // High and Dark roast - use white text
    return Colors.white;
  }
}
