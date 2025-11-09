import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';

/// パスワードリセット画面
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  /// パスワードリセットメールを送信
  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      await authService.resetPassword(_emailController.text.trim());

      if (mounted) {
        setState(() => _emailSent = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('パスワードリセットメールを送信しました'),
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラー: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // アイコン
                  Icon(
                    _emailSent ? Icons.mark_email_read_outlined : Icons.lock_reset,
                    size: 80,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 24),

                  // タイトル
                  Text(
                    _emailSent ? 'メールを送信しました' : 'パスワードをリセット',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  // 説明文
                  Text(
                    _emailSent
                        ? 'メールをご確認いただき、リンクからパスワードをリセットしてください'
                        : '登録されているメールアドレスを入力してください。パスワードリセット用のリンクをお送りします。',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  if (!_emailSent) ...[
                    // メールアドレス入力フィールド
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'メールアドレス',
                        hintText: 'example@email.com',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'メールアドレスを入力してください';
                        }
                        if (!value.contains('@')) {
                          return '有効なメールアドレスを入力してください';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // リセットメール送信ボタン
                    FilledButton(
                      onPressed: _isLoading ? null : _resetPassword,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('リセットメールを送信'),
                    ),
                  ] else ...[
                    // メール再送信ボタン
                    FilledButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              setState(() => _emailSent = false);
                            },
                      child: const Text('別のメールアドレスで試す'),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // ログイン画面へ戻るリンク
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('パスワードを思い出しましたか？'),
                      TextButton(
                        onPressed: () => context.go('/login'),
                        child: const Text('ログイン'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
