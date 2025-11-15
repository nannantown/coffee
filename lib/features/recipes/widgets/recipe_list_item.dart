import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/espresso_recipe.dart';

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
              // User info
              Row(
                children: [
                  Icon(Icons.person, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      recipe.updatedByUsername,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Roast level
              if (recipe.roastLevel != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getRoastColor(recipe.roastLevel!),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '焙煎度: ${_getRoastLevelName(recipe.roastLevel!)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: _getRoastTextColor(recipe.roastLevel!),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
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

  Color _getRoastTextColor(double level) {
    // Light roast (brown[300]) - use dark text
    if (level < 0.33) return Colors.brown[900]!;
    // Medium roast (brown[500]) - use white text
    if (level < 0.66) return Colors.white;
    // Dark roast (brown[800]) - use white text
    return Colors.white;
  }
}
