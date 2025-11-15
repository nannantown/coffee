import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/espresso_shot.dart';

class ShotService {
  final SupabaseClient _supabase;

  ShotService(this._supabase);

  // ショット作成
  Future<EspressoShot> createShot({
    required String groupId,
    required String userId,
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
          .from('espresso_shots')
          .insert({
            'group_id': groupId,
            'created_by': userId,
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

      // ショットオブジェクトにユーザー名を追加
      final shotWithUsername = {
        ...response,
        'created_by_username': username,
      };

      final shot = EspressoShot.fromJson(shotWithUsername);
      print('✅ Shot created: ${shot.id}');
      return shot;
    } catch (e) {
      print('❌ Error creating shot: $e');
      rethrow;
    }
  }

  // グループのショット一覧を取得（ユーザー名付き）
  Future<List<EspressoShot>> getGroupShots(String groupId) async {
    try {
      final response = await _supabase
          .rpc('get_shots_with_usernames', params: {'p_group_id': groupId});

      return (response as List)
          .map((json) => EspressoShot.fromJson(json))
          .toList();
    } catch (e) {
      print('❌ Error fetching shots: $e');
      rethrow;
    }
  }

  // ショット詳細を取得
  Future<EspressoShot> getShot(String shotId) async {
    try {
      final response = await _supabase
          .from('espresso_shots')
          .select()
          .eq('id', shotId)
          .single();

      return EspressoShot.fromJson(response);
    } catch (e) {
      print('❌ Error fetching shot: $e');
      rethrow;
    }
  }

  // ショット更新
  Future<EspressoShot> updateShot({
    required String shotId,
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
      final existing = await getShot(shotId);
      if (existing.createdBy != userId) {
        throw Exception('Only the creator can update this shot');
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
      if (extractionSpeed != null) updateData['extraction_speed'] = extractionSpeed;
      if (notes != null) updateData['notes'] = notes;
      if (photoUrl != null) updateData['photo_url'] = photoUrl;

      final response = await _supabase
          .from('espresso_shots')
          .update(updateData)
          .eq('id', shotId)
          .select()
          .single();

      final shot = EspressoShot.fromJson(response);
      print('✅ Shot updated: ${shot.id}');
      return shot;
    } catch (e) {
      print('❌ Error updating shot: $e');
      rethrow;
    }
  }

  // ショット削除
  Future<void> deleteShot(String shotId, String userId) async {
    try {
      // 作成者のみ削除可能
      final existing = await getShot(shotId);
      if (existing.createdBy != userId) {
        throw Exception('Only the creator can delete this shot');
      }

      await _supabase.from('espresso_shots').delete().eq('id', shotId);

      print('✅ Shot deleted: $shotId');
    } catch (e) {
      print('❌ Error deleting shot: $e');
      rethrow;
    }
  }
}
