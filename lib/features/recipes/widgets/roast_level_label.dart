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
    if (level < 0.33) return 'ライトロースト';
    if (level < 0.66) return 'ミディアムロースト';
    return 'ダークロースト';
  }

  Color _getRoastColor(double level) {
    if (level < 0.33) return Colors.brown[300]!;
    if (level < 0.66) return Colors.brown[500]!;
    return Colors.brown[800]!;
  }

  Color _getRoastTextColor(double level) {
    // Light roast (brown[300]) - use dark text
    if (level < 0.33) return Colors.brown[900]!;
    // Medium roast (brown[500]) - use white text
    if (level < 0.66) return Colors.white;
    // Dark roast (brown[800]) - use white text
    return Colors.white;
  }
}
