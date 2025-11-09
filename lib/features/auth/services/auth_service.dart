import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../config/supabase_config.dart';

/// 認証関連のビジネスロジックを管理するサービスクラス
class AuthService {
  final SupabaseClient _supabase = supabase;

  /// 認証状態の変更を監視するStream
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  /// 現在ログインしているユーザー
  User? get currentUser => _supabase.auth.currentUser;

  /// メールアドレスとパスワードでサインアップ
  /// [email] ユーザーのメールアドレス
  /// [password] パスワード（6文字以上推奨）
  /// [username] ユーザー名（表示名）
  ///
  /// 成功時: AuthResponseを返す
  /// 失敗時: 例外をスロー
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'username': username,
        },
        emailRedirectTo: kIsWeb ? null : 'io.supabase.flutterquickstart://login-callback/',
      );
      debugPrint('✅ Sign up successful: ${response.user?.email} (${response.user?.userMetadata?['username']})');
      return response;
    } catch (e) {
      debugPrint('❌ Sign up failed: $e');
      rethrow;
    }
  }

  /// メールアドレスとパスワードでサインイン
  /// [email] ユーザーのメールアドレス
  /// [password] パスワード
  ///
  /// 成功時: AuthResponseを返す
  /// 失敗時: 例外をスロー
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      debugPrint('✅ Sign in successful: ${response.user?.email}');
      return response;
    } catch (e) {
      debugPrint('❌ Sign in failed: $e');
      rethrow;
    }
  }

  /// パスワードリセットメールを送信
  /// [email] パスワードリセット用のメールアドレス
  ///
  /// 成功時: voidを返す
  /// 失敗時: 例外をスロー
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: kIsWeb ? null : 'io.supabase.flutterquickstart://reset-password/',
      );
      debugPrint('✅ Password reset email sent to: $email');
    } catch (e) {
      debugPrint('❌ Password reset failed: $e');
      rethrow;
    }
  }

  /// サインアウト
  ///
  /// 成功時: voidを返す
  /// 失敗時: 例外をスロー
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
      debugPrint('✅ Sign out successful');
    } catch (e) {
      debugPrint('❌ Sign out failed: $e');
      rethrow;
    }
  }

  /// アカウント削除
  /// ユーザーの関連データとアカウント自体を完全に削除します
  ///
  /// 注意: この操作は取り消せません
  ///
  /// 成功時: voidを返す
  /// 失敗時: 例外をスロー
  Future<void> deleteAccount() async {
    try {
      final user = currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Edge Functionを呼び出してアカウントを削除
      final response = await _supabase.functions.invoke('delete-user-account');

      if (response.status != 200) {
        throw Exception('Failed to delete account: ${response.data}');
      }

      debugPrint('✅ Account deleted successfully');
    } catch (e) {
      debugPrint('❌ Account deletion failed: $e');
      rethrow;
    }
  }
}
