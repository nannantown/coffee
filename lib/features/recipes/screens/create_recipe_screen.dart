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
  final _notesController = TextEditingController();

  double _coffeeWeight = 18.0;
  int _grinderSetting = 240;
  int _extractionTime = 0;
  double _roastLevel = 0.5;

  bool _isLoading = false;

  @override
  void dispose() {
    _notesController.dispose();
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

      // レシピを作成
      final notifier = ref.read(recipeNotifierProvider.notifier);
      final recipe = await notifier.createRecipe(
        groupId: widget.groupId,
        userId: userId,
        coffeeWeight: _coffeeWeight,
        grinderSetting: _grinderSetting.toString(),
        extractionTime: _extractionTime,
        roastLevel: _roastLevel,
        rating: 3, // デフォルト値
        extractionSpeed: 'optimal', // デフォルト値
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      if (recipe != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('レシピを作成しました')),
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
        title: const Text('レシピを作成'),
      ),
      body: RecipeForm(
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
                : const Text('レシピを作成'),
          ),
        ),
      ),
    );
  }
}
