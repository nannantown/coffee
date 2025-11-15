import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/espresso_shot.dart';
import '../providers/shot_provider.dart';
import '../providers/recipe_provider.dart';

class ShotListItem extends ConsumerWidget {
  final EspressoShot shot;

  const ShotListItem({super.key, required this.shot});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final isOwnShot = currentUserId != null && shot.createdBy == currentUserId;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 80×80 Thumbnail
            if (shot.photoUrl != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  shot.photoUrl!,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[300],
                      child: const Icon(Icons.error),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
            ],
            // Shot Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User and Action Buttons Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(Icons.person, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                shot.createdByUsername,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // レシピとして保存ボタン
                          IconButton(
                            icon: const Icon(Icons.bookmark_add, size: 20),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: 'レシピとして保存',
                            onPressed: () => _saveAsRecipe(context, ref),
                          ),
                          if (isOwnShot) ...[
                            const SizedBox(width: 4),
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert, size: 20),
                              padding: EdgeInsets.zero,
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit, size: 20),
                                      SizedBox(width: 8),
                                      Text('編集'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete, size: 20, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text('削除', style: TextStyle(color: Colors.red)),
                                    ],
                                  ),
                                ),
                              ],
                              onSelected: (value) {
                                if (value == 'edit') {
                                  context.push('/shots/${shot.id}/edit');
                                } else if (value == 'delete') {
                                  _confirmDelete(context, ref);
                                }
                              },
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Coffee weight and grinder setting
                  Text(
                    '${shot.coffeeWeight}g - ${shot.grinderSetting}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (shot.extractionTime != null)
                    Text(
                      '${shot.extractionTime}s extraction',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  // Roast level
                  if (shot.roastLevel != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('焙煎度: '),
                        Expanded(
                          child: LinearProgressIndicator(
                            value: shot.roastLevel!,
                            backgroundColor: Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation(
                              _getRoastColor(shot.roastLevel!),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('${(shot.roastLevel! * 100).toInt()}%'),
                      ],
                    ),
                  ],
                  // Extraction Rating and Speed
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('抽出: ', style: TextStyle(fontSize: 12)),
                          _buildRatingStars(shot.rating),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('速度: ', style: TextStyle(fontSize: 12)),
                          Text(
                            shot.extractionSpeed == 'too_slow' ? '遅すぎ' :
                            shot.extractionSpeed == 'too_fast' ? '速すぎ' : '最適',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Notes
                  if (shot.notes != null && shot.notes!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      shot.notes!,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  // Date
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(shot.createdAt),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingStars(int rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 16,
        );
      }),
    );
  }

  Color _getRoastColor(double level) {
    if (level < 0.3) return Colors.brown[300]!;
    if (level < 0.6) return Colors.brown[500]!;
    return Colors.brown[800]!;
  }

  String _formatDate(DateTime date) {
    // 年なしの日時表記（月/日 時:分）
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$month/$day $hour:$minute';
  }

  Future<void> _saveAsRecipe(BuildContext context, WidgetRef ref) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final notifier = ref.read(recipeNotifierProvider.notifier);
      await notifier.createRecipeFromShot(
        shotId: shot.id,
        userId: userId,
        groupId: shot.groupId,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('レシピとして保存しました')),
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
        title: const Text('ショットを削除'),
        content: const Text('このショットを削除してもよろしいですか？'),
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
        final notifier = ref.read(shotNotifierProvider.notifier);
        await notifier.deleteShot(shot.id, userId);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ショットを削除しました')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('削除に失敗しました: $e')),
          );
        }
      }
    }
  }
}
