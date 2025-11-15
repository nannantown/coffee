import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/profile_provider.dart';
import '../providers/auth_provider.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/utils/image_picker_util.dart';
import '../../../core/widgets/image_picker_avatar.dart';
import '../../../core/widgets/editable_field_card.dart';

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
                ImagePickerAvatar(
                  imageUrl: profile['avatar_url'] as String?,
                  fallbackText: profile['username'] as String?,
                  isUploading: _isUploadingAvatar,
                  onTap: _pickAndUploadAvatar,
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
                  child: Form(
                    key: _formKey,
                    child: EditableFieldCard(
                      title: 'ユーザー名',
                      value: profile['username'] ?? '',
                      isEditing: _isEditing,
                      controller: _usernameController,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'ユーザー名を入力してください';
                        }
                        if (value.trim().length < 2) {
                          return 'ユーザー名は2文字以上で入力してください';
                        }
                        return null;
                      },
                      onEdit: () => setState(() => _isEditing = true),
                      onSave: _updateUsername,
                      isLoading: _isLoading,
                      labelText: 'ユーザー名',
                      hintText: 'ユーザー名を入力',
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
