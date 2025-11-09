import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/espresso_recipe.dart';
import '../providers/recipe_provider.dart';
import '../widgets/recipe_form.dart';

class EditRecipeScreen extends ConsumerStatefulWidget {
  final String recipeId;

  const EditRecipeScreen({super.key, required this.recipeId});

  @override
  ConsumerState<EditRecipeScreen> createState() => _EditRecipeScreenState();
}

class _EditRecipeScreenState extends ConsumerState<EditRecipeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _coffeeWeightController = TextEditingController();
  final _grinderSettingController = TextEditingController();
  final _extractionTimeController = TextEditingController();

  double _roastLevel = 0.5;
  int _rating = 3;
  File? _selectedImage;
  String? _existingPhotoUrl;
  bool _isLoading = false;
  bool _isInitialized = false;

  void _initializeForm(EspressoRecipe recipe) {
    if (_isInitialized) return;
    _coffeeWeightController.text = recipe.coffeeWeight.toString();
    _grinderSettingController.text = recipe.grinderSetting;
    _extractionTimeController.text = recipe.extractionTime?.toString() ?? '';
    _roastLevel = recipe.roastLevel ?? 0.5;
    _rating = recipe.rating;
    _existingPhotoUrl = recipe.photoUrl;
    _isInitialized = true;
  }

  @override
  void dispose() {
    _coffeeWeightController.dispose();
    _grinderSettingController.dispose();
    _extractionTimeController.dispose();
    super.dispose();
  }

  Future<void> _updateRecipe() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // 新しい写真がある場合はアップロード
      String? photoUrl = _existingPhotoUrl;
      if (_selectedImage != null) {
        final storageService = ref.read(storageServiceProvider);
        photoUrl = await storageService.uploadPhoto(_selectedImage!);

        // 古い写真を削除
        if (_existingPhotoUrl != null) {
          try {
            await storageService.deletePhoto(_existingPhotoUrl!);
          } catch (e) {
            print('Error deleting old photo: $e');
          }
        }
      }

      // レシピを更新
      final notifier = ref.read(recipeNotifierProvider.notifier);
      final recipe = await notifier.updateRecipe(
        recipeId: widget.recipeId,
        userId: userId,
        coffeeWeight: double.parse(_coffeeWeightController.text),
        grinderSetting: _grinderSettingController.text,
        extractionTime: _extractionTimeController.text.isNotEmpty
            ? int.parse(_extractionTimeController.text)
            : null,
        roastLevel: _roastLevel,
        rating: _rating,
        photoUrl: photoUrl,
      );

      if (recipe != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recipe updated successfully')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final recipeAsync = ref.watch(recipeDetailProvider(widget.recipeId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Recipe'),
      ),
      body: recipeAsync.when(
        data: (recipe) {
          _initializeForm(recipe);
          return RecipeForm(
            formKey: _formKey,
            coffeeWeightController: _coffeeWeightController,
            grinderSettingController: _grinderSettingController,
            extractionTimeController: _extractionTimeController,
            roastLevel: _roastLevel,
            rating: _rating,
            selectedImage: _selectedImage,
            onRoastLevelChanged: (value) => setState(() => _roastLevel = value),
            onRatingChanged: (value) => setState(() => _rating = value),
            onImageSelected: (image) => setState(() => _selectedImage = image),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: _isLoading ? null : _updateRecipe,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Update Recipe'),
          ),
        ),
      ),
    );
  }
}
