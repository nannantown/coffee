import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'config/router.dart';
import 'config/supabase_config.dart';
import 'core/constants/env.dart';

/// アプリのエントリーポイント
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 環境変数の読み込み
    await dotenv.load(fileName: '.env');
    debugPrint('✅ Environment variables loaded');

    // 環境変数の検証
    Env.validate();

    // Supabaseの初期化
    await SupabaseConfig.initialize();
  } catch (e) {
    debugPrint('❌ Initialization error: $e');
    // エラーがあっても続行（エラー画面を表示するため）
  }

  runApp(
    const ProviderScope(
      child: MainApp(),
    ),
  );
}

/// アプリのルートウィジェット
class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Account Template',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          filled: true,
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          filled: true,
        ),
      ),
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
