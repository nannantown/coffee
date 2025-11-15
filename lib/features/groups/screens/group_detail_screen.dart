import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/group_provider.dart';
import '../../recipes/providers/recipe_provider.dart';
import '../../recipes/providers/shot_provider.dart';
import '../../recipes/models/espresso_recipe.dart';
import '../../recipes/models/espresso_shot.dart';
import '../../recipes/widgets/recipe_list_item.dart';
import '../../recipes/widgets/shot_list_item.dart';
import '../../../core/widgets/invite_code_display.dart';

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
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/groups/${widget.groupId}/settings'),
            tooltip: '設定',
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
            // メンバー数表示（固定）
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: groupAsync.when(
                data: (group) => membersAsync.when(
                  data: (members) => Card(
                    child: InkWell(
                      onTap: () => _showMembersDialog(context, members),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                              backgroundImage: group.imageUrl != null
                                  ? NetworkImage(group.imageUrl!)
                                  : null,
                              child: group.imageUrl == null
                                  ? Icon(
                                      Icons.coffee,
                                      size: 14,
                                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
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

  Future<void> _showMembersDialog(
      BuildContext context, List<dynamic> members) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    // 招待コードを取得
    String? inviteCode;
    try {
      final invitationService = ref.read(invitationServiceProvider);
      final invitation =
          await invitationService.createInvitation(widget.groupId, userId);
      inviteCode = invitation.inviteCode;
    } catch (e) {
      print('❌ Error creating invitation: $e');
    }

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('グループメンバー'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // メンバーリスト
              Flexible(
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
                      subtitle:
                          Text(member.role == 'owner' ? 'オーナー' : 'メンバー'),
                      trailing: member.role == 'owner'
                          ? const Icon(Icons.star, color: Colors.amber, size: 20)
                          : null,
                    );
                  },
                ),
              ),
              // 招待コードセクション
              if (inviteCode != null) ...[
                const Divider(height: 32),
                const Text(
                  '招待コード',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                InviteCodeDisplay(
                  inviteCode: inviteCode,
                  padding: const EdgeInsets.all(12),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
          if (inviteCode != null)
            FilledButton.icon(
              onPressed: () async {
                final box = context.findRenderObject() as RenderBox?;
                await Share.share(
                  'コーヒーグループに参加しましょう！招待コード: $inviteCode!',
                  sharePositionOrigin:
                      box!.localToGlobal(Offset.zero) & box.size,
                );
              },
              icon: const Icon(Icons.share),
              label: const Text('共有'),
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
                InviteCodeDisplay(inviteCode: invitation.inviteCode),
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

}
