import 'package:flutter/material.dart';

class RoastLevelLabel extends StatelessWidget {
  final double roastLevel;
  final bool showLabel;

  const RoastLevelLabel({
    super.key,
    required this.roastLevel,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getRoastColor(roastLevel),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        showLabel
            ? '焙煎度: ${_getRoastLevelName(roastLevel)}'
            : _getRoastLevelName(roastLevel),
        style: TextStyle(
          fontSize: 12,
          color: _getRoastTextColor(roastLevel),
          fontWeight: FontWeight.w500,
        ),
      ),
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
