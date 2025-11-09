import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/env.dart';

/// Supabase クライアントへのグローバルアクセス
final supabase = Supabase.instance.client;

/// Supabase の初期化を行うクラス
class SupabaseConfig {
  /// Supabaseを初期化
  /// アプリ起動時に一度だけ呼び出す必要がある
  static Future<void> initialize() async {
    try {
      await Supabase.initialize(
        url: Env.supabaseUrl,
        anonKey: Env.supabaseAnonKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce, // PKCEフロー（より安全）
          autoRefreshToken: true, // トークンの自動更新を有効化
        ),
      );
      debugPrint('✅ Supabase initialized successfully');
    } catch (e) {
      debugPrint('❌ Failed to initialize Supabase: $e');
      rethrow;
    }
  }
}
