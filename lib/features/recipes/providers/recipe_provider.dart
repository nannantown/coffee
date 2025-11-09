import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/espresso_recipe.dart';
import '../services/recipe_service.dart';
import '../services/storage_service.dart';
import '../../groups/providers/group_provider.dart';

// Recipe service provider
final recipeServiceProvider = Provider<RecipeService>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return RecipeService(supabase);
});

// Storage service provider
final storageServiceProvider = Provider<StorageService>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return StorageService(supabase);
});

// グループのレシピ一覧を取得
final groupRecipesProvider =
    FutureProvider.family.autoDispose<List<EspressoRecipe>, String>(
        (ref, groupId) async {
  final recipeService = ref.watch(recipeServiceProvider);
  return recipeService.getGroupRecipes(groupId);
});

// レシピ詳細を取得
final recipeDetailProvider =
    FutureProvider.family.autoDispose<EspressoRecipe, String>(
        (ref, recipeId) async {
  final recipeService = ref.watch(recipeServiceProvider);
  return recipeService.getRecipe(recipeId);
});

// レシピ作成・更新・削除アクション
class RecipeNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<EspressoRecipe?> createRecipe({
    required String groupId,
    required String userId,
    required double coffeeWeight,
    required String grinderSetting,
    int? extractionTime,
    double? roastLevel,
    required int rating,
    String? photoUrl,
  }) async {
    state = const AsyncValue.loading();
    try {
      final recipeService = ref.read(recipeServiceProvider);
      final recipe = await recipeService.createRecipe(
        groupId: groupId,
        userId: userId,
        coffeeWeight: coffeeWeight,
        grinderSetting: grinderSetting,
        extractionTime: extractionTime,
        roastLevel: roastLevel,
        rating: rating,
        photoUrl: photoUrl,
      );
      state = const AsyncValue.data(null);
      return recipe;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return null;
    }
  }

  Future<EspressoRecipe?> updateRecipe({
    required String recipeId,
    required String userId,
    double? coffeeWeight,
    String? grinderSetting,
    int? extractionTime,
    double? roastLevel,
    int? rating,
    String? photoUrl,
  }) async {
    state = const AsyncValue.loading();
    try {
      final recipeService = ref.read(recipeServiceProvider);
      final recipe = await recipeService.updateRecipe(
        recipeId: recipeId,
        userId: userId,
        coffeeWeight: coffeeWeight,
        grinderSetting: grinderSetting,
        extractionTime: extractionTime,
        roastLevel: roastLevel,
        rating: rating,
        photoUrl: photoUrl,
      );
      state = const AsyncValue.data(null);
      return recipe;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return null;
    }
  }

  Future<void> deleteRecipe(String recipeId, String userId) async {
    state = const AsyncValue.loading();
    try {
      final recipeService = ref.read(recipeServiceProvider);
      await recipeService.deleteRecipe(recipeId, userId);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final recipeNotifierProvider =
    NotifierProvider<RecipeNotifier, AsyncValue<void>>(RecipeNotifier.new);
