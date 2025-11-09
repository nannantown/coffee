import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

/// ホーム画面（ログイン後のサンプル画面）
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final authService = ref.watch(authServiceProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ホーム'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              // ログアウト確認ダイアログ
              final shouldLogout = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('ログアウト'),
                  content: const Text('ログアウトしますか？'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('キャンセル'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('ログアウト'),
                    ),
                  ],
                ),
              );

              if (shouldLogout == true && context.mounted) {
                try {
                  await authService.signOut();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('ログアウトしました')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('エラー: ${e.toString()}')),
                    );
                  }
                }
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ユーザーアイコン
              CircleAvatar(
                radius: 50,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(
                  Icons.person,
                  size: 50,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 24),

              // ウェルカムメッセージ
              Text(
                'ようこそ！',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // ユーザー情報カード
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ユーザー情報',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _InfoRow(
                        icon: Icons.email_outlined,
                        label: 'メール',
                        value: currentUser?.email ?? '未設定',
                      ),
                      const SizedBox(height: 8),
                      _InfoRow(
                        icon: Icons.badge_outlined,
                        label: 'ユーザーID',
                        value: currentUser?.id ?? '不明',
                      ),
                      const SizedBox(height: 8),
                      _InfoRow(
                        icon: Icons.calendar_today_outlined,
                        label: '登録日',
                        value: currentUser?.createdAt != null
                            ? _formatDate(currentUser!.createdAt)
                            : '不明',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 説明テキスト
              Text(
                'このテンプレートをベースに、あなたのアプリを作成してください！',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 日付をフォーマット
  String _formatDate(String date) {
    try {
      final parsedDate = DateTime.parse(date);
      return '${parsedDate.year}/${parsedDate.month}/${parsedDate.day}';
    } catch (e) {
      return date;
    }
  }
}

/// 情報行ウィジェット
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
