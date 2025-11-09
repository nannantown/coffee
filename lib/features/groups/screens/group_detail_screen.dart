import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/group_provider.dart';
import '../../recipes/providers/recipe_provider.dart';
import '../../recipes/widgets/recipe_list_item.dart';

class GroupDetailScreen extends ConsumerWidget {
  final String groupId;

  const GroupDetailScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupAsync = ref.watch(groupDetailProvider(groupId));
    final recipesAsync = ref.watch(groupRecipesProvider(groupId));
    final membersAsync = ref.watch(groupMembersProvider(groupId));

    return Scaffold(
      appBar: AppBar(
        title: groupAsync.when(
          data: (group) => Text(group.name),
          loading: () => const Text('Loading...'),
          error: (_, __) => const Text('Error'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _showInviteDialog(context, ref),
            tooltip: 'Invite',
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Text('Delete Group'),
              ),
            ],
            onSelected: (value) {
              if (value == 'delete') {
                _confirmDelete(context, ref);
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(groupRecipesProvider(groupId));
          ref.invalidate(groupMembersProvider(groupId));
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // メンバー数表示（タップでメンバー一覧を表示）
            membersAsync.when(
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
                        Text('${members.length} members'),
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
            const SizedBox(height: 16),
            // レシピ一覧
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recipes',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                FilledButton.icon(
                  onPressed: () => context.push('/groups/$groupId/recipes/create'),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Recipe'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            recipesAsync.when(
              data: (recipes) {
                if (recipes.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(Icons.coffee_outlined, size: 48, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No recipes yet',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return Column(
                  children: recipes
                      .map((recipe) => RecipeListItem(recipe: recipe))
                      .toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
            ),
          ],
        ),
      ),
    );
  }

  void _showMembersDialog(BuildContext context, List<dynamic> members) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Group Members'),
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
                subtitle: Text(member.role == 'owner' ? 'Owner' : 'Member'),
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
            child: const Text('Close'),
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
      final invitation = await invitationService.createInvitation(groupId, userId);

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Invite to Group'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Share this invite code:'),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        invitation.inviteCode,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy),
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(text: invitation.inviteCode),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Copied to clipboard'),
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
                child: const Text('Close'),
              ),
              FilledButton.icon(
                onPressed: () {
                  Share.share('Join my coffee group! Invite code: ${invitation.inviteCode}');
                },
                icon: const Icon(Icons.share),
                label: const Text('Share'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Group'),
        content: const Text(
          'Are you sure you want to delete this group? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      try {
        final notifier = ref.read(groupNotifierProvider.notifier);
        await notifier.deleteGroup(groupId, userId);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Group deleted')),
          );
          ref.invalidate(userGroupsProvider);
          context.pop();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }
}
