import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/utils/image_picker_util.dart';

class RecipeForm extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController coffeeWeightController;
  final TextEditingController grinderSettingController;
  final TextEditingController extractionTimeController;
  final double roastLevel;
  final int rating;
  final File? selectedImage;
  final Function(double) onRoastLevelChanged;
  final Function(int) onRatingChanged;
  final Function(File?) onImageSelected;

  const RecipeForm({
    super.key,
    required this.formKey,
    required this.coffeeWeightController,
    required this.grinderSettingController,
    required this.extractionTimeController,
    required this.roastLevel,
    required this.rating,
    this.selectedImage,
    required this.onRoastLevelChanged,
    required this.onRatingChanged,
    required this.onImageSelected,
  });

  @override
  State<RecipeForm> createState() => _RecipeFormState();
}

class _RecipeFormState extends State<RecipeForm> {
  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Coffee weight
          TextFormField(
            controller: widget.coffeeWeightController,
            decoration: const InputDecoration(
              labelText: 'Coffee Weight (g)',
              hintText: 'e.g. 18.0',
              border: OutlineInputBorder(),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter coffee weight';
              }
              final weight = double.tryParse(value);
              if (weight == null || weight <= 0) {
                return 'Please enter a valid weight';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Grinder setting
          TextFormField(
            controller: widget.grinderSettingController,
            decoration: const InputDecoration(
              labelText: 'Grinder Setting',
              hintText: 'e.g. 325',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter grinder setting';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Extraction time (optional)
          TextFormField(
            controller: widget.extractionTimeController,
            decoration: const InputDecoration(
              labelText: 'Extraction Time (seconds) - Optional',
              hintText: 'e.g. 25',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 24),

          // Roast level slider
          const Text('Roast Level - Optional'),
          Slider(
            value: widget.roastLevel,
            min: 0.0,
            max: 1.0,
            divisions: 100,
            label: '${(widget.roastLevel * 100).toInt()}%',
            onChanged: widget.onRoastLevelChanged,
          ),
          const SizedBox(height: 24),

          // Rating
          const Text('Rating', style: TextStyle(fontSize: 16)),
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

          // Photo
          const Text('Photo - Optional', style: TextStyle(fontSize: 16)),
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
              label: const Text('Remove Photo'),
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
                    label: const Text('Gallery'),
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
                    label: const Text('Camera'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
