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
  final _notesController = TextEditingController();

  double _coffeeWeight = 18.0;
  int _grinderSetting = 240;
  int _extractionTime = 30;
  double _roastLevel = 0.5;

  bool _isLoading = false;
  bool _isInitialized = false;

  void _initializeForm(EspressoRecipe recipe) {
    if (_isInitialized) return;
    _coffeeWeight = recipe.coffeeWeight;
    _grinderSetting = int.tryParse(recipe.grinderSetting) ?? 240;
    _extractionTime = recipe.extractionTime ?? 30;
    _notesController.text = recipe.notes ?? '';
    _roastLevel = recipe.roastLevel ?? 0.5;
    _isInitialized = true;
  }

  @override
  void dispose() {
    _notesController.dispose();
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

      // レシピを更新
      final notifier = ref.read(recipeNotifierProvider.notifier);
      final recipe = await notifier.updateRecipe(
        recipeId: widget.recipeId,
        userId: userId,
        coffeeWeight: _coffeeWeight,
        grinderSetting: _grinderSetting.toString(),
        extractionTime: _extractionTime,
        roastLevel: _roastLevel,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      if (recipe != null && mounted) {
        // レシピ一覧と詳細を更新
        ref.invalidate(groupRecipesProvider(recipe.groupId));
        ref.invalidate(recipeDetailProvider(widget.recipeId));

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('レシピを更新しました')),
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('レシピを編集'),
      ),
      body: recipeAsync.when(
        data: (recipe) {
          _initializeForm(recipe);
          return RecipeForm(
            formKey: _formKey,
            coffeeWeight: _coffeeWeight,
            grinderSetting: _grinderSetting,
            extractionTime: _extractionTime,
            notesController: _notesController,
            roastLevel: _roastLevel,
            onCoffeeWeightChanged: (value) => setState(() => _coffeeWeight = value),
            onGrinderSettingChanged: (value) => setState(() => _grinderSetting = value),
            onExtractionTimeChanged: (value) => setState(() => _extractionTime = value),
            onRoastLevelChanged: (value) => setState(() => _roastLevel = value),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('エラー: $error')),
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
                : const Text('更新'),
          ),
        ),
      ),
    );
  }
}
