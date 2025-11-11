import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileService {
  final SupabaseClient _supabase;

  ProfileService(this._supabase);

  // ユーザー名を取得
  Future<String> getUsername(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('username')
          .eq('id', userId)
          .single();

      return response['username'] as String;
    } catch (e) {
      print('❌ Error fetching username: $e');
      rethrow;
    }
  }

  // ユーザー名を更新
  Future<void> updateUsername(String userId, String newUsername) async {
    try {
      await _supabase.from('profiles').update({
        'username': newUsername,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);

      print('✅ Username updated: $newUsername');
    } catch (e) {
      print('❌ Error updating username: $e');
      rethrow;
    }
  }

  // プロフィール情報を取得
  Future<Map<String, dynamic>> getProfile(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      return response;
    } catch (e) {
      print('❌ Error fetching profile: $e');
      rethrow;
    }
  }
}
