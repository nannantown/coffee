import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/espresso_recipe.dart';

class RecipeService {
  final SupabaseClient _supabase;

  RecipeService(this._supabase);

  // レシピ作成
  Future<EspressoRecipe> createRecipe({
    required String groupId,
    required String userId,
    required double coffeeWeight,
    required String grinderSetting,
    int? extractionTime,
    double? roastLevel,
    required int rating,
    String? photoUrl,
  }) async {
    try {
      final now = DateTime.now().toIso8601String();

      final response = await _supabase
          .from('espresso_recipes')
          .insert({
            'group_id': groupId,
            'created_by': userId,
            'coffee_weight': coffeeWeight,
            'grinder_setting': grinderSetting,
            'extraction_time': extractionTime,
            'roast_level': roastLevel,
            'rating': rating,
            'photo_url': photoUrl,
            'created_at': now,
            'updated_at': now,
          })
          .select()
          .single();

      final recipe = EspressoRecipe.fromJson(response);
      print('✅ Recipe created: ${recipe.id}');
      return recipe;
    } catch (e) {
      print('❌ Error creating recipe: $e');
      rethrow;
    }
  }

  // グループのレシピ一覧を取得
  Future<List<EspressoRecipe>> getGroupRecipes(String groupId) async {
    try {
      final response = await _supabase
          .from('espresso_recipes')
          .select()
          .eq('group_id', groupId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => EspressoRecipe.fromJson(json))
          .toList();
    } catch (e) {
      print('❌ Error fetching recipes: $e');
      rethrow;
    }
  }

  // レシピ詳細を取得
  Future<EspressoRecipe> getRecipe(String recipeId) async {
    try {
      final response = await _supabase
          .from('espresso_recipes')
          .select()
          .eq('id', recipeId)
          .single();

      return EspressoRecipe.fromJson(response);
    } catch (e) {
      print('❌ Error fetching recipe: $e');
      rethrow;
    }
  }

  // レシピ更新
  Future<EspressoRecipe> updateRecipe({
    required String recipeId,
    required String userId,
    double? coffeeWeight,
    String? grinderSetting,
    int? extractionTime,
    double? roastLevel,
    int? rating,
    String? photoUrl,
  }) async {
    try {
      // 作成者のみ更新可能
      final existing = await getRecipe(recipeId);
      if (existing.createdBy != userId) {
        throw Exception('Only the creator can update this recipe');
      }

      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (coffeeWeight != null) updateData['coffee_weight'] = coffeeWeight;
      if (grinderSetting != null) {
        updateData['grinder_setting'] = grinderSetting;
      }
      if (extractionTime != null) updateData['extraction_time'] = extractionTime;
      if (roastLevel != null) updateData['roast_level'] = roastLevel;
      if (rating != null) updateData['rating'] = rating;
      if (photoUrl != null) updateData['photo_url'] = photoUrl;

      final response = await _supabase
          .from('espresso_recipes')
          .update(updateData)
          .eq('id', recipeId)
          .select()
          .single();

      final recipe = EspressoRecipe.fromJson(response);
      print('✅ Recipe updated: ${recipe.id}');
      return recipe;
    } catch (e) {
      print('❌ Error updating recipe: $e');
      rethrow;
    }
  }

  // レシピ削除
  Future<void> deleteRecipe(String recipeId, String userId) async {
    try {
      // 作成者のみ削除可能
      final existing = await getRecipe(recipeId);
      if (existing.createdBy != userId) {
        throw Exception('Only the creator can delete this recipe');
      }

      await _supabase.from('espresso_recipes').delete().eq('id', recipeId);

      print('✅ Recipe deleted: $recipeId');
    } catch (e) {
      print('❌ Error deleting recipe: $e');
      rethrow;
    }
  }
}
