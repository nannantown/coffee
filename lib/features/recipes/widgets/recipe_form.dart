import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class RecipeForm extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final double coffeeWeight;
  final int grinderSetting;
  final int extractionTime;
  final TextEditingController? notesController;
  final double roastLevel;
  final Function(double) onCoffeeWeightChanged;
  final Function(int) onGrinderSettingChanged;
  final Function(int) onExtractionTimeChanged;
  final Function(double) onRoastLevelChanged;

  const RecipeForm({
    super.key,
    required this.formKey,
    required this.coffeeWeight,
    required this.grinderSetting,
    required this.extractionTime,
    this.notesController,
    required this.roastLevel,
    required this.onCoffeeWeightChanged,
    required this.onGrinderSettingChanged,
    required this.onExtractionTimeChanged,
    required this.onRoastLevelChanged,
  });

  @override
  State<RecipeForm> createState() => _RecipeFormState();
}

class _RecipeFormState extends State<RecipeForm> {

  Future<void> _showTimePicker() async {
    int selectedSeconds = widget.extractionTime > 0 ? widget.extractionTime : 25;

    await showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        height: 250,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('キャンセル'),
                  ),
                  TextButton(
                    onPressed: () {
                      widget.onExtractionTimeChanged(selectedSeconds);
                      Navigator.pop(context);
                    },
                    child: const Text('完了'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Picker
            Expanded(
              child: CupertinoPicker(
                scrollController: FixedExtentScrollController(
                  initialItem: selectedSeconds.clamp(5, 180) - 5,
                ),
                itemExtent: 40,
                onSelectedItemChanged: (index) {
                  selectedSeconds = index + 5;
                },
                children: List.generate(
                  176, // 5秒から180秒まで (180 - 5 + 1 = 176)
                  (index) {
                    final seconds = index + 5;
                    return Center(
                      child: Text(
                        '$seconds秒',
                        style: const TextStyle(fontSize: 20),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Coffee weight slider
          Text('コーヒー豆: ${widget.coffeeWeight.toStringAsFixed(1)}g',
            style: const TextStyle(fontSize: 16)),
          Slider(
            value: widget.coffeeWeight,
            min: 10.0,
            max: 30.0,
            label: '${widget.coffeeWeight.toStringAsFixed(1)}g',
            onChanged: widget.onCoffeeWeightChanged,
          ),
          const SizedBox(height: 8),

          // Grinder setting slider
          Text('グラインダーセッティング: ${widget.grinderSetting}',
            style: const TextStyle(fontSize: 16)),
          Slider(
            value: widget.grinderSetting.toDouble(),
            min: 140.0,
            max: 350.0,
            label: '${widget.grinderSetting}',
            onChanged: (value) => widget.onGrinderSettingChanged(value.round()),
          ),
          const SizedBox(height: 8),

          // Extraction time (tappable)
          const Text('抽出時間', style: TextStyle(fontSize: 16)),
          const SizedBox(height: 8),
          InkWell(
            onTap: _showTimePicker,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.extractionTime > 0
                        ? '${widget.extractionTime}秒'
                        : '時間を設定',
                    style: TextStyle(
                      fontSize: 16,
                      color: widget.extractionTime > 0
                          ? Theme.of(context).colorScheme.onSurface
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Icon(
                    Icons.access_time,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Roast level slider
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '焙煎レベル: ${(widget.roastLevel * 100).toInt()}%',
                style: const TextStyle(fontSize: 16),
              ),
              Text(
                _getRoastLevelName(widget.roastLevel),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _getRoastColor(widget.roastLevel),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: _getRoastColor(widget.roastLevel),
              thumbColor: _getRoastColor(widget.roastLevel),
              inactiveTrackColor: _getRoastColor(widget.roastLevel).withValues(alpha: 0.3),
            ),
            child: Slider(
              value: widget.roastLevel,
              min: 0.0,
              max: 1.0,
              onChanged: widget.onRoastLevelChanged,
            ),
          ),
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
          const SizedBox(height: 24),

          // Notes (Comment)
          if (widget.notesController != null) ...[
            const Text('コメント（任意）', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            TextFormField(
              controller: widget.notesController,
              decoration: const InputDecoration(
                hintText: '味の感想、改善点など',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              keyboardType: TextInputType.multiline,
            ),
          ],
        ],
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
}
