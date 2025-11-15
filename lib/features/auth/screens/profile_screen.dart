import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/profile_provider.dart';
import '../providers/auth_provider.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/utils/image_picker_util.dart';

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
  bool _isUploadingAvatar = false;

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

  Future<void> _pickAndUploadAvatar() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    // Show image source selection
    final source = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('プロフィール画像を選択'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('ギャラリーから選択'),
              onTap: () => Navigator.pop(context, 'gallery'),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('カメラで撮影'),
              onTap: () => Navigator.pop(context, 'camera'),
            ),
          ],
        ),
      ),
    );

    if (source == null || !mounted) return;

    // Pick image
    final File? imageFile = source == 'gallery'
        ? await ImagePickerUtil.pickImageFromGallery()
        : await ImagePickerUtil.pickImageFromCamera();

    if (imageFile == null || !mounted) return;

    setState(() => _isUploadingAvatar = true);

    try {
      // Upload to storage
      final storageService = StorageService(Supabase.instance.client);
      final avatarUrl = await storageService.uploadAvatar(imageFile);

      // Update profile
      final profileService = ref.read(profileServiceProvider);
      await profileService.updateAvatar(userId, avatarUrl);

      // Refresh profile data
      ref.invalidate(currentUserProfileProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('プロフィール画像を更新しました')),
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
        setState(() => _isUploadingAvatar = false);
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
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      backgroundImage: profile['avatar_url'] != null
                          ? NetworkImage(profile['avatar_url'] as String)
                          : null,
                      child: profile['avatar_url'] == null
                          ? Text(
                              (profile['username'] as String?)?.isNotEmpty == true
                                  ? (profile['username'] as String)[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                            )
                          : null,
                    ),
                    if (_isUploadingAvatar)
                      Positioned.fill(
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.black54,
                          child: const CircularProgressIndicator(color: Colors.white),
                        ),
                      ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Material(
                        color: Theme.of(context).colorScheme.primary,
                        shape: const CircleBorder(),
                        child: InkWell(
                          onTap: _isUploadingAvatar ? null : _pickAndUploadAvatar,
                          customBorder: const CircleBorder(),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Icon(
                              Icons.camera_alt,
                              size: 20,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
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
