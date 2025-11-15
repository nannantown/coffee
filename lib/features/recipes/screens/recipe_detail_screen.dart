import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/espresso_recipe.dart';
import '../providers/recipe_provider.dart';

class RecipeDetailScreen extends ConsumerWidget {
  final String recipeId;

  const RecipeDetailScreen({super.key, required this.recipeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipeAsync = ref.watch(recipeDetailProvider(recipeId));
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('レシピ詳細'),
        actions: recipeAsync.whenOrNull(
          data: (recipe) {
            final isOwnRecipe = currentUserId != null && recipe.createdBy == currentUserId;
            return [
              // Favorite button
              IconButton(
                icon: Icon(
                  recipe.isFavorite ? Icons.star : Icons.star_border,
                  color: recipe.isFavorite ? Colors.amber : null,
                ),
                onPressed: () async {
                  try {
                    final notifier = ref.read(recipeNotifierProvider.notifier);
                    await notifier.toggleFavorite(recipe.id, recipe.groupId);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  }
                },
              ),
              // Edit button (only for own recipes)
              if (isOwnRecipe)
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => context.push('/recipes/$recipeId/edit'),
                ),
            ];
          },
        ),
      ),
      body: recipeAsync.when(
        data: (recipe) => _buildContent(context, recipe),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('エラー: $error')),
      ),
    );
  }

  Widget _buildContent(BuildContext context, EspressoRecipe recipe) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Photo
        if (recipe.photoUrl != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              recipe.photoUrl!,
              height: 300,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 300,
                  color: Colors.grey[300],
                  child: const Icon(Icons.error, size: 64),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Creator info and favorite badge
        Row(
          children: [
            Icon(Icons.person, size: 20, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Text(
              recipe.createdByUsername,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
            if (recipe.isFavorite) ...[
              const SizedBox(width: 8),
              const Chip(
                label: Text('お気に入り', style: TextStyle(fontSize: 12)),
                backgroundColor: Colors.amber,
                padding: EdgeInsets.symmetric(horizontal: 8),
                visualDensity: VisualDensity.compact,
              ),
            ],
            const Spacer(),
            Text(
              _formatDate(recipe.createdAt),
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Main parameters card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '抽出パラメータ',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildInfoRow('コーヒー豆', '${recipe.coffeeWeight}g'),
                _buildInfoRow('グラインダー', recipe.grinderSetting),
                if (recipe.extractionTime != null)
                  _buildInfoRow('抽出時間', '${recipe.extractionTime}秒'),
                if (recipe.roastLevel != null)
                  _buildRoastLevel(recipe.roastLevel!),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Rating card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '評価',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('抽出: ', style: TextStyle(fontSize: 16)),
                    _buildRatingStars(recipe.rating),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('速度: ', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Chip(
                      label: Text(
                        recipe.extractionSpeed == 'too_slow' ? '遅すぎ' :
                        recipe.extractionSpeed == 'too_fast' ? '速すぎ' : '最適',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      backgroundColor: recipe.extractionSpeed == 'optimal'
                          ? Colors.green[700]
                          : Colors.orange[700],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Notes card
        if (recipe.notes != null && recipe.notes!.isNotEmpty) ...[
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'コメント',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    recipe.notes!,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[800],
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildRoastLevel(double level) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '焙煎度',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[800],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                _getRoastLevelName(level),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _getRoastColor(level),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: level,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation(_getRoastColor(level)),
            minHeight: 8,
          ),
        ],
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
          size: 24,
        );
      }),
    );
  }

  String _getRoastLevelName(double level) {
    if (level < 0.33) return 'ライトロースト';
    if (level < 0.66) return 'ミディアムロースト';
    return 'ダークロースト';
  }

  Color _getRoastColor(double level) {
    if (level < 0.33) return Colors.brown[300]!;
    if (level < 0.66) return Colors.brown[500]!;
    return Colors.brown[800]!;
  }

  String _formatDate(DateTime date) {
    final year = date.year;
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$year/$month/$day $hour:$minute';
  }
}
