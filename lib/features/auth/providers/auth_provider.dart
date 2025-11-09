import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';

/// 認証サービスのプロバイダー
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// 現在の認証状態を提供するプロバイダー
/// ログイン中のユーザー情報を監視し、変更があれば自動で更新される
final authStateProvider = StreamProvider<AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

/// 現在のユーザー情報を取得するプロバイダー
/// ログインしていない場合はnullを返す
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.whenData((state) => state.session?.user).value;
});
