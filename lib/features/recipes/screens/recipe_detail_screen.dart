import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/espresso_recipe.dart';
import '../providers/recipe_provider.dart';
import '../widgets/roast_level_label.dart';

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
            if (isOwnRecipe) {
              return [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => context.push('/recipes/$recipeId/edit'),
                ),
              ];
            }
            return null;
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
        // Creator info and favorite badge
        Row(
          children: [
            Icon(Icons.person, size: 20, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Text(
              recipe.updatedByUsername,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Text(
              _formatDate(recipe.updatedAt),
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
                _buildInfoRow('コーヒー豆', '${recipe.coffeeWeight}g', context),
                _buildInfoRow('グラインダー', recipe.grinderSetting, context),
                if (recipe.extractionTime != null)
                  _buildInfoRow('抽出時間', '${recipe.extractionTime}秒', context),
                if (recipe.roastLevel != null)
                  _buildRoastLevel(recipe.roastLevel!, context),
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

  Widget _buildInfoRow(String label, String value, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
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

  Widget _buildRoastLevel(double level, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '焙煎度',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          RoastLevelLabel(roastLevel: level, showLabel: false),
        ],
      ),
    );
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
