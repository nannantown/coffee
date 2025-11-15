import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../core/utils/image_picker_util.dart';

class ShotForm extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final double coffeeWeight;
  final int grinderSetting;
  final int extractionTime;
  final TextEditingController? notesController;
  final double roastLevel;
  final int rating;
  final String extractionSpeed;
  final File? selectedImage;
  final Function(double) onCoffeeWeightChanged;
  final Function(int) onGrinderSettingChanged;
  final Function(int) onExtractionTimeChanged;
  final Function(double) onRoastLevelChanged;
  final Function(int) onRatingChanged;
  final Function(String) onExtractionSpeedChanged;
  final Function(File?) onImageSelected;

  const ShotForm({
    super.key,
    required this.formKey,
    required this.coffeeWeight,
    required this.grinderSetting,
    required this.extractionTime,
    this.notesController,
    required this.roastLevel,
    required this.rating,
    required this.extractionSpeed,
    this.selectedImage,
    required this.onCoffeeWeightChanged,
    required this.onGrinderSettingChanged,
    required this.onExtractionTimeChanged,
    required this.onRoastLevelChanged,
    required this.onRatingChanged,
    required this.onExtractionSpeedChanged,
    required this.onImageSelected,
  });

  @override
  State<ShotForm> createState() => _ShotFormState();
}

class _ShotFormState extends State<ShotForm> {
  Timer? _timer;
  int _elapsedMilliseconds = 0;
  bool _isStopwatchRunning = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startStopwatch() {
    setState(() {
      _isStopwatchRunning = true;
    });
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        _elapsedMilliseconds += 100;
        // リアルタイムで抽出時間を更新
        final seconds = (_elapsedMilliseconds / 1000).round();
        widget.onExtractionTimeChanged(seconds);
      });
    });
  }

  void _stopStopwatch() {
    _timer?.cancel();
    setState(() {
      _isStopwatchRunning = false;
    });
  }

  void _resetStopwatch() {
    _timer?.cancel();
    setState(() {
      _isStopwatchRunning = false;
      _elapsedMilliseconds = 0;
      widget.onExtractionTimeChanged(0);
    });
  }

  String _formatTime(int milliseconds) {
    final seconds = (milliseconds / 1000).floor();
    final centiseconds = ((milliseconds % 1000) / 10).floor();
    return '${seconds.toString().padLeft(2, '0')}.${centiseconds.toString().padLeft(2, '0')}';
  }

  Future<void> _showTimePicker() async {
    final currentSeconds = (_elapsedMilliseconds / 1000).round();
    int selectedSeconds = currentSeconds;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      builder: (context) => Container(
        height: 250,
        decoration: BoxDecoration(
          color: Colors.grey[900],
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
                    child: const Text(
                      'キャンセル',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _elapsedMilliseconds = selectedSeconds * 1000;
                        widget.onExtractionTimeChanged(selectedSeconds);
                      });
                      Navigator.pop(context);
                    },
                    child: const Text(
                      '完了',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: Colors.grey[800]),
            // Picker
            Expanded(
              child: CupertinoPicker(
                scrollController: FixedExtentScrollController(
                  initialItem: currentSeconds.clamp(5, 180) - 5,
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
                        style: const TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                        ),
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

          // Extraction time stopwatch
          const Text('抽出時間', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Timer display (tappable)
                  InkWell(
                    onTap: _isStopwatchRunning ? null : _showTimePicker,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      child: Column(
                        children: [
                          Text(
                            _formatTime(_elapsedMilliseconds),
                            style: const TextStyle(
                              fontSize: 64,
                              fontWeight: FontWeight.bold,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                          if (!_isStopwatchRunning)
                            Text(
                              'タップして手動入力',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Reset button (left)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _elapsedMilliseconds > 0 ? _resetStopwatch : null,
                          icon: const Icon(Icons.refresh),
                          label: const Text('リセット'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Start/Stop button (right)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isStopwatchRunning ? _stopStopwatch : _startStopwatch,
                          icon: Icon(_isStopwatchRunning ? Icons.stop : Icons.play_arrow),
                          label: Text(_isStopwatchRunning ? '終了' : '開始'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isStopwatchRunning ? Colors.red : Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
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
              Text('ライト', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              Text('ミディアム', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              Text('ダーク', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ],
          ),
          const SizedBox(height: 24),

          // Extraction Rating
          const Text('抽出評価', style: TextStyle(fontSize: 16)),
          const SizedBox(height: 8),
          Row(
            children: List.generate(5, (index) {
              final starValue = index + 1;
              return IconButton(
                icon: Icon(
                  starValue <= widget.rating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 32,
                ),
                onPressed: () => widget.onRatingChanged(starValue),
              );
            }),
          ),
          const SizedBox(height: 24),

          // Extraction Speed
          const Text('抽出速度', style: TextStyle(fontSize: 16)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('遅すぎ'),
                selected: widget.extractionSpeed == 'too_slow',
                onSelected: (selected) {
                  if (selected) widget.onExtractionSpeedChanged('too_slow');
                },
              ),
              ChoiceChip(
                label: const Text('最適'),
                selected: widget.extractionSpeed == 'optimal',
                onSelected: (selected) {
                  if (selected) widget.onExtractionSpeedChanged('optimal');
                },
              ),
              ChoiceChip(
                label: const Text('速すぎ'),
                selected: widget.extractionSpeed == 'too_fast',
                onSelected: (selected) {
                  if (selected) widget.onExtractionSpeedChanged('too_fast');
                },
              ),
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
            const SizedBox(height: 24),
          ],

          // Photo
          const Text('写真（任意）', style: TextStyle(fontSize: 16)),
          const SizedBox(height: 8),
          if (widget.selectedImage != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                widget.selectedImage!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => widget.onImageSelected(null),
              icon: const Icon(Icons.delete),
              label: const Text('写真を削除'),
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final image = await ImagePickerUtil.pickImageFromGallery();
                      widget.onImageSelected(image);
                    },
                    icon: const Icon(Icons.photo_library),
                    label: const Text('ギャラリー'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final image = await ImagePickerUtil.pickImageFromCamera();
                      widget.onImageSelected(image);
                    },
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('カメラ'),
                  ),
                ),
              ],
            ),
          ],
        ],
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
}
