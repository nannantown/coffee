import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/espresso_recipe.dart';

class RecipeService {
  final SupabaseClient _supabase;

  RecipeService(this._supabase);

  // レシピ作成
  Future<EspressoRecipe> createRecipe({
    required String groupId,
    required String userId,
    String? sourceShotId,
    required double coffeeWeight,
    required String grinderSetting,
    int? extractionTime,
    double? roastLevel,
    required int rating,
    required String extractionSpeed,
    String? notes,
    String? photoUrl,
  }) async {
    try {
      final now = DateTime.now().toIso8601String();

      final response = await _supabase
          .from('espresso_recipes')
          .insert({
            'group_id': groupId,
            'created_by': userId,
            'updated_by': userId, // 作成時は作成者が更新者
            'source_shot_id': sourceShotId,
            'coffee_weight': coffeeWeight,
            'grinder_setting': grinderSetting,
            'extraction_time': extractionTime,
            'roast_level': roastLevel,
            'rating': rating,
            'extraction_speed': extractionSpeed,
            'notes': notes,
            'photo_url': photoUrl,
            'created_at': now,
            'updated_at': now,
          })
          .select()
          .single();

      // ユーザー名を取得
      final user = _supabase.auth.currentUser;
      final username = user?.userMetadata?['username'] as String? ?? 'Unknown';

      // レシピオブジェクトにユーザー名を追加
      final recipeWithUsername = {
        ...response,
        'created_by_username': username,
        'updated_by_username': username, // 作成時は作成者が更新者
      };

      final recipe = EspressoRecipe.fromJson(recipeWithUsername);
      print('✅ Recipe created: ${recipe.id}');
      return recipe;
    } catch (e) {
      print('❌ Error creating recipe: $e');
      rethrow;
    }
  }

  // グループのレシピ一覧を取得（ユーザー名付き）
  Future<List<EspressoRecipe>> getGroupRecipes(String groupId) async {
    try {
      final response = await _supabase
          .rpc('get_recipes_with_usernames', params: {'p_group_id': groupId});

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
          .rpc('get_recipe_with_username', params: {'p_recipe_id': recipeId});

      if (response == null || (response as List).isEmpty) {
        throw Exception('Recipe not found');
      }

      return EspressoRecipe.fromJson(response[0]);
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
    String? extractionSpeed,
    String? notes,
    String? photoUrl,
  }) async {
    try {
      // 作成者のみ更新可能
      final existing = await getRecipe(recipeId);
      if (existing.createdBy != userId) {
        throw Exception('Only the creator can update this recipe');
      }

      final updateData = <String, dynamic>{
        'updated_by': userId, // 更新者を記録
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (coffeeWeight != null) updateData['coffee_weight'] = coffeeWeight;
      if (grinderSetting != null) {
        updateData['grinder_setting'] = grinderSetting;
      }
      if (extractionTime != null) updateData['extraction_time'] = extractionTime;
      if (roastLevel != null) updateData['roast_level'] = roastLevel;
      if (rating != null) updateData['rating'] = rating;
      if (extractionSpeed != null) updateData['extraction_speed'] = extractionSpeed;
      if (notes != null) updateData['notes'] = notes;
      if (photoUrl != null) updateData['photo_url'] = photoUrl;

      await _supabase
          .from('espresso_recipes')
          .update(updateData)
          .eq('id', recipeId);

      // 更新後のデータをRPC関数で取得（ユーザー名付き）
      final recipe = await getRecipe(recipeId);
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

  // ショットからレシピを作成
  Future<EspressoRecipe> createRecipeFromShot({
    required String shotId,
    required String userId,
    String? additionalNotes,
  }) async {
    try {
      // ショットデータを取得
      final shot = await _supabase
          .from('espresso_shots')
          .select()
          .eq('id', shotId)
          .single();

      // レシピとして保存
      return await createRecipe(
        groupId: shot['group_id'] as String,
        userId: userId,
        sourceShotId: shotId,
        coffeeWeight: (shot['coffee_weight'] as num).toDouble(),
        grinderSetting: shot['grinder_setting'] as String,
        extractionTime: shot['extraction_time'] as int?,
        roastLevel: shot['roast_level'] != null
            ? (shot['roast_level'] as num).toDouble()
            : null,
        rating: shot['rating'] as int,
        extractionSpeed: shot['extraction_speed'] as String? ?? 'optimal',
        notes: additionalNotes ?? shot['notes'] as String?,
        photoUrl: shot['photo_url'] as String?,
      );
    } catch (e) {
      print('❌ Error creating recipe from shot: $e');
      rethrow;
    }
  }
}
