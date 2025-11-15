import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/group_provider.dart';
import '../models/group_member.dart';
import '../models/coffee_group.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/utils/image_picker_util.dart';
import '../../../core/widgets/image_picker_avatar.dart';
import '../../../core/widgets/editable_field_card.dart';

class GroupSettingsScreen extends ConsumerStatefulWidget {
  final String groupId;

  const GroupSettingsScreen({super.key, required this.groupId});

  @override
  ConsumerState<GroupSettingsScreen> createState() =>
      _GroupSettingsScreenState();
}

class _GroupSettingsScreenState extends ConsumerState<GroupSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isLoading = false;
  bool _isEditing = false;
  bool _isUploadingImage = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _updateGroupName(CoffeeGroup group) async {
    if (!_formKey.currentState!.validate()) return;

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    setState(() => _isLoading = true);

    try {
      final notifier = ref.read(groupNotifierProvider.notifier);
      await notifier.updateGroupName(
        widget.groupId,
        userId,
        _nameController.text.trim(),
      );

      if (mounted) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('グループ名を更新しました')),
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

  Future<void> _pickAndUploadImage() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    // Show image source selection
    final source = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('グループ画像を選択'),
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

    setState(() => _isUploadingImage = true);

    try {
      // Upload to storage
      final storageService = StorageService(Supabase.instance.client);
      final imageUrl = await storageService.uploadGroupImage(imageFile);

      // Update group
      final groupService = ref.read(groupServiceProvider);
      await groupService.updateGroupImage(widget.groupId, userId, imageUrl);

      // Refresh group data
      ref.invalidate(groupDetailProvider(widget.groupId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('グループ画像を更新しました')),
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
        setState(() => _isUploadingImage = false);
      }
    }
  }

  Future<void> _confirmLeaveGroup(CoffeeGroup group) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final members = await ref.read(groupMembersProvider(widget.groupId).future);
      final isOwner = group.ownerId == userId;
      final memberCount = members.length;

      // オーナーで他にメンバーがいる場合は、オーナー譲渡先を選択
      if (isOwner && memberCount > 1) {
        final otherMembers = members.where((m) => m.userId != userId).toList();

        final selectedMember = await showDialog<GroupMember>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('オーナー権限の譲渡'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('グループのオーナー権限を譲渡するメンバーを選択してください'),
                const SizedBox(height: 16),
                ...otherMembers.map(
                  (member) => ListTile(
                    title: Text(member.username),
                    onTap: () => Navigator.pop(context, member),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('キャンセル'),
              ),
            ],
          ),
        );

        if (selectedMember == null) return;

        // 確認ダイアログ
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('グループを退会'),
            content: Text(
              '${selectedMember.username}にオーナー権限を譲渡して退会しますか？',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('キャンセル'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('退会'),
              ),
            ],
          ),
        );

        if (confirmed == true && mounted) {
          final notifier = ref.read(groupNotifierProvider.notifier);
          await notifier.leaveGroup(
            groupId: widget.groupId,
            userId: userId,
            isOwner: true,
            newOwnerId: selectedMember.userId,
            memberCount: memberCount,
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('グループを退会しました')),
            );
            ref.invalidate(userGroupsProvider);
            context.go('/groups');
          }
        }
      }
      // オーナーで最後のメンバーの場合はグループ削除確認
      else if (isOwner && memberCount == 1) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('グループを削除'),
            content: const Text(
              'あなたは最後のメンバーです。グループを削除しますか？',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('キャンセル'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('削除'),
              ),
            ],
          ),
        );

        if (confirmed == true && mounted) {
          final notifier = ref.read(groupNotifierProvider.notifier);
          await notifier.leaveGroup(
            groupId: widget.groupId,
            userId: userId,
            isOwner: true,
            memberCount: 1,
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('グループを削除しました')),
            );
            ref.invalidate(userGroupsProvider);
            context.go('/groups');
          }
        }
      }
      // 通常メンバーの場合
      else {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('グループを退会'),
            content: const Text('本当にグループを退会しますか？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('キャンセル'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('退会'),
              ),
            ],
          ),
        );

        if (confirmed == true && mounted) {
          final notifier = ref.read(groupNotifierProvider.notifier);
          await notifier.leaveGroup(
            groupId: widget.groupId,
            userId: userId,
            isOwner: false,
            memberCount: memberCount,
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('グループを退会しました')),
            );
            ref.invalidate(userGroupsProvider);
            context.go('/groups');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラー: $e')),
        );
      }
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('グループを削除'),
        content: const Text(
          'このグループを削除してもよろしいですか？この操作は取り消せません。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      try {
        final notifier = ref.read(groupNotifierProvider.notifier);
        await notifier.deleteGroup(widget.groupId, userId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('グループを削除しました')),
          );
          ref.invalidate(userGroupsProvider);
          context.go('/groups');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('エラー: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupAsync = ref.watch(groupDetailProvider(widget.groupId));
    final currentUser = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('グループ設定'),
        actions: [
          if (_isEditing && !_isLoading)
            TextButton(
              onPressed: () {
                setState(() => _isEditing = false);
                groupAsync.whenData((group) {
                  _nameController.text = group.name;
                });
              },
              child: const Text('キャンセル'),
            ),
        ],
      ),
      body: groupAsync.when(
        data: (group) {
          if (!_isEditing && _nameController.text.isEmpty) {
            _nameController.text = group.name;
          }

          final isOwner = group.ownerId == currentUser?.id;

          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 32),
                // Group Image
                ImagePickerAvatar(
                  imageUrl: group.imageUrl,
                  fallbackIcon: Icons.coffee,
                  isUploading: _isUploadingImage,
                  onTap: _pickAndUploadImage,
                ),
                const SizedBox(height: 32),
                // Group Name Section
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: EditableFieldCard(
                      title: 'グループ名',
                      value: group.name,
                      isEditing: _isEditing,
                      controller: _nameController,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'グループ名を入力してください';
                        }
                        if (value.trim().length < 2) {
                          return 'グループ名は2文字以上で入力してください';
                        }
                        return null;
                      },
                      onEdit: () => setState(() => _isEditing = true),
                      onSave: () => _updateGroupName(group),
                      isLoading: _isLoading,
                      labelText: 'グループ名',
                      hintText: 'グループ名を入力',
                    ),
                  ),
                ),
                // Leave Group Section
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _confirmLeaveGroup(group),
                      icon: const Icon(Icons.exit_to_app),
                      label: const Text('グループを退会'),
                    ),
                  ),
                ),
                // Delete Group Section (Owner only)
                if (isOwner)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _confirmDelete,
                        icon: const Icon(Icons.delete, color: Colors.red),
                        label: const Text(
                          'グループを削除',
                          style: TextStyle(color: Colors.red),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                        ),
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
                onPressed: () =>
                    ref.refresh(groupDetailProvider(widget.groupId)),
                child: const Text('再試行'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
