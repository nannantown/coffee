import 'package:flutter/material.dart';
import '../models/espresso_recipe.dart';

class RecipeListItem extends StatelessWidget {
  final EspressoRecipe recipe;

  const RecipeListItem({super.key, required this.recipe});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.person, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            recipe.createdByUsername,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${recipe.coffeeWeight}g - ${recipe.grinderSetting}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (recipe.extractionTime != null)
                        Text(
                          '${recipe.extractionTime}s extraction',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                    ],
                  ),
                ),
                _buildRatingStars(recipe.rating),
              ],
            ),
            if (recipe.roastLevel != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('Roast: '),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: recipe.roastLevel!,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation(
                        _getRoastColor(recipe.roastLevel!),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('${(recipe.roastLevel! * 100).toInt()}%'),
                ],
              ),
            ],
            if (recipe.photoUrl != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  recipe.photoUrl!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      color: Colors.grey[300],
                      child: const Icon(Icons.error),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              _formatDate(recipe.createdAt),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
          size: 20,
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
}
