import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/profile_provider.dart';
import '../providers/auth_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _updateUsername() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    setState(() => _isLoading = true);

    try {
      final notifier = ref.read(profileNotifierProvider.notifier);
      await notifier.updateUsername(userId, _usernameController.text.trim());

      if (mounted) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ユーザー名を更新しました')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラー: $e')),
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
    final profileAsync = ref.watch(currentUserProfileProvider);
    final currentUser = ref.watch(currentUserProvider);
    final authService = ref.watch(authServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('プロフィール'),
        actions: [
          if (_isEditing && !_isLoading)
            TextButton(
              onPressed: () {
                setState(() => _isEditing = false);
                // Reset to original value
                profileAsync.whenData((profile) {
                  _usernameController.text = profile['username'] ?? '';
                });
              },
              child: const Text('キャンセル'),
            ),
        ],
      ),
      body: profileAsync.when(
        data: (profile) {
          if (!_isEditing && _usernameController.text.isEmpty) {
            _usernameController.text = profile['username'] ?? '';
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 32),
                // Profile Avatar
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Text(
                    (profile['username'] as String?)?.isNotEmpty == true
                        ? (profile['username'] as String)[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Email
                Text(
                  currentUser?.email ?? '',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 32),
                // Username Section
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'ユーザー名',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (!_isEditing)
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => setState(() => _isEditing = true),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (_isEditing)
                            Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  TextFormField(
                                    controller: _usernameController,
                                    decoration: const InputDecoration(
                                      labelText: 'ユーザー名',
                                      border: OutlineInputBorder(),
                                      hintText: 'ユーザー名を入力',
                                    ),
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'ユーザー名を入力してください';
                                      }
                                      if (value.trim().length < 2) {
                                        return 'ユーザー名は2文字以上で入力してください';
                                      }
                                      return null;
                                    },
                                    enabled: !_isLoading,
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    child: FilledButton(
                                      onPressed: _isLoading ? null : _updateUsername,
                                      child: _isLoading
                                          ? const SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(strokeWidth: 2),
                                            )
                                          : const Text('保存'),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            Text(
                              profile['username'] ?? '',
                              style: const TextStyle(fontSize: 18),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Logout Section
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final shouldLogout = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('ログアウト'),
                            content: const Text('ログアウトしますか？'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('キャンセル'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('ログアウト'),
                              ),
                            ],
                          ),
                        );

                        if (shouldLogout == true && mounted) {
                          try {
                            await authService.signOut();
                            if (mounted) {
                              context.go('/login');
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('ログアウトしました')),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('エラー: $e')),
                              );
                            }
                          }
                        }
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text('ログアウト'),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('エラー: $error'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.refresh(currentUserProfileProvider),
                child: const Text('再試行'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
