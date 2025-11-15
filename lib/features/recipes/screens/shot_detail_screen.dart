import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/espresso_shot.dart';
import '../providers/shot_provider.dart';

class ShotDetailScreen extends ConsumerWidget {
  final String shotId;

  const ShotDetailScreen({super.key, required this.shotId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shotAsync = ref.watch(shotDetailProvider(shotId));
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ショット詳細'),
        actions: shotAsync.whenOrNull(
          data: (shot) {
            final isOwnShot = currentUserId != null && shot.createdBy == currentUserId;
            if (isOwnShot) {
              return [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => context.push('/shots/$shotId/edit'),
                ),
              ];
            }
            return null;
          },
        ),
      ),
      body: shotAsync.when(
        data: (shot) => _buildContent(context, shot),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('エラー: $error')),
      ),
    );
  }

  Widget _buildContent(BuildContext context, EspressoShot shot) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Photo
        if (shot.photoUrl != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              shot.photoUrl!,
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

        // Creator info
        Row(
          children: [
            Icon(Icons.person, size: 20, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Text(
              shot.createdByUsername,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Text(
              _formatDate(shot.createdAt),
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
                _buildInfoRow('コーヒー豆', '${shot.coffeeWeight}g'),
                _buildInfoRow('グラインダー', shot.grinderSetting),
                if (shot.extractionTime != null)
                  _buildInfoRow('抽出時間', '${shot.extractionTime}秒'),
                if (shot.roastLevel != null)
                  _buildRoastLevel(shot.roastLevel!),
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
                    _buildRatingStars(shot.rating),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('速度: ', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Chip(
                      label: Text(
                        shot.extractionSpeed == 'too_slow' ? '遅すぎ' :
                        shot.extractionSpeed == 'too_fast' ? '速すぎ' : '最適',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      backgroundColor: shot.extractionSpeed == 'optimal'
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
        if (shot.notes != null && shot.notes!.isNotEmpty) ...[
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
                    shot.notes!,
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
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
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
              const Text(
                '焙煎度',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
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
