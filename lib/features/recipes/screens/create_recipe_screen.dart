import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/recipe_provider.dart';
import '../widgets/recipe_form.dart';

class CreateRecipeScreen extends ConsumerStatefulWidget {
  final String groupId;

  const CreateRecipeScreen({super.key, required this.groupId});

  @override
  ConsumerState<CreateRecipeScreen> createState() => _CreateRecipeScreenState();
}

class _CreateRecipeScreenState extends ConsumerState<CreateRecipeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _coffeeWeightController = TextEditingController();
  final _grinderSettingController = TextEditingController();
  final _extractionTimeController = TextEditingController();

  double _roastLevel = 0.5;
  int _rating = 3;
  File? _selectedImage;
  bool _isLoading = false;

  @override
  void dispose() {
    _coffeeWeightController.dispose();
    _grinderSettingController.dispose();
    _extractionTimeController.dispose();
    super.dispose();
  }

  Future<void> _createRecipe() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // 写真をアップロード（選択されている場合）
      String? photoUrl;
      if (_selectedImage != null) {
        final storageService = ref.read(storageServiceProvider);
        photoUrl = await storageService.uploadPhoto(_selectedImage!);
      }

      // レシピを作成
      final notifier = ref.read(recipeNotifierProvider.notifier);
      final recipe = await notifier.createRecipe(
        groupId: widget.groupId,
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
          const SnackBar(content: Text('Recipe created successfully')),
        );
        // レシピ一覧をリフレッシュ
        ref.invalidate(groupRecipesProvider(widget.groupId));
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Recipe'),
      ),
      body: RecipeForm(
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
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: _isLoading ? null : _createRecipe,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Create Recipe'),
          ),
        ),
      ),
    );
  }
}
