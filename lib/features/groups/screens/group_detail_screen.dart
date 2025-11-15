import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/group_provider.dart';
import '../models/group_member.dart';
import '../models/coffee_group.dart';
import '../../recipes/providers/recipe_provider.dart';
import '../../recipes/providers/shot_provider.dart';
import '../../recipes/models/espresso_recipe.dart';
import '../../recipes/models/espresso_shot.dart';
import '../../recipes/widgets/recipe_list_item.dart';
import '../../recipes/widgets/shot_list_item.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/utils/image_picker_util.dart';

class GroupDetailScreen extends ConsumerStatefulWidget {
  final String groupId;

  const GroupDetailScreen({super.key, required this.groupId});

  @override
  ConsumerState<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends ConsumerState<GroupDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groupAsync = ref.watch(groupDetailProvider(widget.groupId));
    final shotsAsync = ref.watch(groupShotsProvider(widget.groupId));
    final recipesAsync = ref.watch(groupRecipesProvider(widget.groupId));
    final membersAsync = ref.watch(groupMembersProvider(widget.groupId));

    return Scaffold(
      appBar: AppBar(
        title: groupAsync.when(
          data: (group) => Text(group.name),
          loading: () => const Text('読み込み中...'),
          error: (_, __) => const Text('エラー'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _showInviteDialog(context, ref),
            tooltip: '招待',
          ),
          PopupMenuButton(
            itemBuilder: (context) {
              final currentUserId = Supabase.instance.client.auth.currentUser?.id;
              final isOwner = groupAsync.value?.ownerId == currentUserId;

              return [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 8),
                      Text('グループを編集'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'leave',
                  child: Row(
                    children: [
                      Icon(Icons.exit_to_app, size: 20),
                      SizedBox(width: 8),
                      Text('グループを退会'),
                    ],
                  ),
                ),
                if (isOwner)
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 20, color: Colors.red),
                        SizedBox(width: 8),
                        Text('グループを削除', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
              ];
            },
            onSelected: (value) {
              if (value == 'edit') {
                groupAsync.whenData((group) {
                  _showEditGroupDialog(context, ref, group);
                });
              } else if (value == 'leave') {
                _confirmLeaveGroup(context, ref);
              } else if (value == 'delete') {
                _confirmDelete(context, ref);
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(groupRecipesProvider(widget.groupId));
          ref.invalidate(groupMembersProvider(widget.groupId));
        },
        child: Column(
          children: [
            // Group Image Header
            groupAsync.when(
              data: (group) => group.imageUrl != null
                  ? Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Center(
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: DecorationImage(
                              image: NetworkImage(group.imageUrl!),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            // メンバー数表示（固定）
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: membersAsync.when(
                data: (members) => Card(
                  child: InkWell(
                    onTap: () => _showMembersDialog(context, members),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.people),
                          const SizedBox(width: 8),
                          Text('${members.length}人のメンバー'),
                          const Spacer(),
                          const Icon(Icons.chevron_right, size: 20),
                        ],
                      ),
                    ),
                  ),
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),
            // タブバー
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'ショット'),
                Tab(text: 'レシピ'),
              ],
            ),
            // タブビュー
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // ショットタブ
                  _buildShotList(context, ref, shotsAsync),
                  // レシピタブ
                  _buildRecipeList(context, ref, recipesAsync),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: ListenableBuilder(
        listenable: _tabController,
        builder: (context, child) {
          final isShots = _tabController.index == 0;
          return FloatingActionButton(
            onPressed: () {
              if (isShots) {
                context.push('/groups/${widget.groupId}/shots/create');
              } else {
                context.push('/groups/${widget.groupId}/recipes/create');
              }
            },
            tooltip: isShots ? 'ショットを記録' : 'レシピを作成',
            child: Icon(isShots ? Icons.local_cafe : Icons.receipt_long),
          );
        },
      ),
    );
  }

  Widget _buildShotList(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<EspressoShot>> shotsAsync,
  ) {
    return shotsAsync.when(
      data: (shots) {
        if (shots.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.local_cafe,
                    size: 48,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'ショットがありません',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '右下のボタンからショットを記録しましょう',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: shots.length,
          itemBuilder: (context, index) {
            return ShotListItem(shot: shots[index]);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('エラー: $error')),
    );
  }

  Widget _buildRecipeList(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<EspressoRecipe>> recipesAsync,
  ) {
    return recipesAsync.when(
      data: (recipes) {
        if (recipes.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.book_outlined,
                    size: 48,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'レシピがありません',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ショットをレシピとして保存しましょう',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: recipes.length,
          itemBuilder: (context, index) {
            return RecipeListItem(recipe: recipes[index]);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('エラー: $error')),
    );
  }

  void _showMembersDialog(BuildContext context, List<dynamic> members) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('グループメンバー'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: members.length,
            itemBuilder: (context, index) {
              final member = members[index];
              return ListTile(
                leading: CircleAvatar(
                  child: Text(
                    member.username.isNotEmpty
                        ? member.username[0].toUpperCase()
                        : '?',
                  ),
                ),
                title: Text(member.username),
                subtitle: Text(member.role == 'owner' ? 'オーナー' : 'メンバー'),
                trailing: member.role == 'owner'
                    ? const Icon(Icons.star, color: Colors.amber, size: 20)
                    : null,
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  Future<void> _showInviteDialog(BuildContext context, WidgetRef ref) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final invitationService = ref.read(invitationServiceProvider);
      final invitation = await invitationService.createInvitation(widget.groupId, userId);

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('グループに招待'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('この招待コードを共有してください:'),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!, width: 1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        invitation.inviteCode,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[900],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.copy, color: Colors.grey[700]),
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(text: invitation.inviteCode),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('クリップボードにコピーしました'),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('閉じる'),
              ),
              FilledButton.icon(
                onPressed: () async {
                  final box = context.findRenderObject() as RenderBox?;
                  await Share.share(
                    'コーヒーグループに参加しましょう！招待コード: ${invitation.inviteCode}',
                    sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
                  );
                },
                icon: const Icon(Icons.share),
                label: const Text('共有'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラー: $e')),
        );
      }
    }
  }

  Future<void> _confirmLeaveGroup(BuildContext context, WidgetRef ref) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      // グループとメンバー情報を取得
      final group = await ref.read(groupDetailProvider(widget.groupId).future);
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
                ...otherMembers.map((member) => ListTile(
                  title: Text(member.username),
                  onTap: () => Navigator.pop(context, member),
                )),
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

        if (confirmed == true && context.mounted) {
          final notifier = ref.read(groupNotifierProvider.notifier);
          await notifier.leaveGroup(
            groupId: widget.groupId,
            userId: userId,
            isOwner: true,
            newOwnerId: selectedMember.userId,
            memberCount: memberCount,
          );

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('グループを退会しました')),
            );
            ref.invalidate(userGroupsProvider);
            context.pop();
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

        if (confirmed == true && context.mounted) {
          final notifier = ref.read(groupNotifierProvider.notifier);
          await notifier.leaveGroup(
            groupId: widget.groupId,
            userId: userId,
            isOwner: true,
            memberCount: 1,
          );

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('グループを削除しました')),
            );
            ref.invalidate(userGroupsProvider);
            context.pop();
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

        if (confirmed == true && context.mounted) {
          final notifier = ref.read(groupNotifierProvider.notifier);
          await notifier.leaveGroup(
            groupId: widget.groupId,
            userId: userId,
            isOwner: false,
            memberCount: memberCount,
          );

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('グループを退会しました')),
            );
            ref.invalidate(userGroupsProvider);
            context.pop();
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラー: $e')),
        );
      }
    }
  }

  Future<void> _showEditGroupDialog(
    BuildContext context,
    WidgetRef ref,
    CoffeeGroup group,
  ) async {
    final nameController = TextEditingController(text: group.name);
    final formKey = GlobalKey<FormState>();
    File? selectedImage;
    bool imageChanged = false;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('グループを編集'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Group Image Section
                  GestureDetector(
                    onTap: () async {
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

                      if (source != null) {
                        final File? imageFile = source == 'gallery'
                            ? await ImagePickerUtil.pickImageFromGallery()
                            : await ImagePickerUtil.pickImageFromCamera();

                        if (imageFile != null) {
                          setState(() {
                            selectedImage = imageFile;
                            imageChanged = true;
                          });
                        }
                      }
                    },
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                        image: selectedImage != null
                            ? DecorationImage(
                                image: FileImage(selectedImage!),
                                fit: BoxFit.cover,
                              )
                            : (group.imageUrl != null
                                ? DecorationImage(
                                    image: NetworkImage(group.imageUrl!),
                                    fit: BoxFit.cover,
                                  )
                                : null),
                      ),
                      child: selectedImage == null && group.imageUrl == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate,
                                  size: 40,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'グループ画像',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Group Name Field
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'グループ名',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'グループ名を入力してください';
                      }
                      if (value.trim().length < 2) {
                        return 'グループ名は2文字以上で入力してください';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(context, {
                    'name': nameController.text.trim(),
                    'image': selectedImage,
                    'imageChanged': imageChanged,
                  });
                }
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );

    if (result != null && context.mounted) {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      try {
        final newName = result['name'] as String;
        final newImage = result['image'] as File?;
        final imageChanged = result['imageChanged'] as bool;

        // Update image if changed
        if (imageChanged && newImage != null) {
          final storageService = StorageService(Supabase.instance.client);
          final imageUrl = await storageService.uploadGroupImage(newImage);

          final groupService = ref.read(groupServiceProvider);
          await groupService.updateGroupImage(widget.groupId, userId, imageUrl);
        }

        // Update name if changed
        if (newName != group.name) {
          final notifier = ref.read(groupNotifierProvider.notifier);
          await notifier.updateGroupName(widget.groupId, userId, newName);
        }

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('グループを更新しました')),
          );
          ref.invalidate(groupDetailProvider(widget.groupId));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('エラー: $e')),
          );
        }
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
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

    if (confirmed == true && context.mounted) {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      try {
        final notifier = ref.read(groupNotifierProvider.notifier);
        await notifier.deleteGroup(widget.groupId, userId);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('グループを削除しました')),
          );
          ref.invalidate(userGroupsProvider);
          context.pop();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('エラー: $e')),
          );
        }
      }
    }
  }
}
