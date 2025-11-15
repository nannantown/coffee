import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'common/coffee_weight_slider.dart';
import 'common/grinder_setting_slider.dart';
import 'common/roast_level_slider.dart';
import 'common/notes_field.dart';

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
          CoffeeWeightSlider(
            value: widget.coffeeWeight,
            onChanged: widget.onCoffeeWeightChanged,
          ),
          const SizedBox(height: 8),

          // Grinder setting slider
          GrinderSettingSlider(
            value: widget.grinderSetting,
            onChanged: widget.onGrinderSettingChanged,
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
          RoastLevelSlider(
            value: widget.roastLevel,
            onChanged: widget.onRoastLevelChanged,
          ),
          const SizedBox(height: 24),

          // Notes (Comment)
          if (widget.notesController != null)
            NotesField(controller: widget.notesController!),
        ],
      ),
    );
  }
}
