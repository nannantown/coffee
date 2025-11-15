import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/espresso_recipe.dart';
import 'roast_level_label.dart';
import 'creator_info_row.dart';

class RecipeListItem extends ConsumerWidget {
  final EspressoRecipe recipe;

  const RecipeListItem({super.key, required this.recipe});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/recipes/${recipe.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Creator info
              CreatorInfoRow(
                avatarUrl: recipe.createdByAvatarUrl,
                username: recipe.createdByUsername,
              ),
              const SizedBox(height: 8),
              // Roast level
              if (recipe.roastLevel != null) ...[
                RoastLevelLabel(roastLevel: recipe.roastLevel!),
                const SizedBox(height: 8),
              ],
              // Coffee weight and grinder setting
              Text(
                '${recipe.coffeeWeight}g - ${recipe.grinderSetting}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              // Date (updated_at)
              Text(
                _formatDate(recipe.updatedAt),
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    // 年なしの日時表記（月/日 時:分）
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$month/$day $hour:$minute';
  }
}
