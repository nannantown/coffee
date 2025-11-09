import 'package:flutter_dotenv/flutter_dotenv.dart';

/// 環境変数を管理するクラス
/// .envファイルから値を読み込み、アプリ全体で使用できるようにする
class Env {
  /// Supabase プロジェクトのURL
  /// Supabase Dashboard > Settings > API > Project URL から取得
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';

  /// Supabase の匿名キー (Anon Key)
  /// Supabase Dashboard > Settings > API > Project API keys > anon public から取得
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  /// 環境変数が正しく設定されているか検証
  static bool validate() {
    if (supabaseUrl.isEmpty) {
      throw Exception('SUPABASE_URL が設定されていません');
    }
    if (supabaseAnonKey.isEmpty) {
      throw Exception('SUPABASE_ANON_KEY が設定されていません');
    }
    return true;
  }
}
