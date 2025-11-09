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
  ///
  /// 成功時: AuthResponseを返す
  /// 失敗時: 例外をスロー
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: kIsWeb ? null : 'io.supabase.flutterquickstart://login-callback/',
      );
      debugPrint('✅ Sign up successful: ${response.user?.email}');
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
}
