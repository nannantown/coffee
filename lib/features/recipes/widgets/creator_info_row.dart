import 'package:flutter/material.dart';

/// クリエーター情報を表示する共通ウィジェット
/// サイズを指定可能で、リスト項目と詳細画面の両方で使用できる
class CreatorInfoRow extends StatelessWidget {
  final String? avatarUrl;
  final String username;
  final DateTime? date;
  final double avatarRadius;
  final double fontSize;
  final double? dateTextSize;
  final bool showDate;

  const CreatorInfoRow({
    super.key,
    this.avatarUrl,
    required this.username,
    this.date,
    this.avatarRadius = 8,
    this.fontSize = 12,
    this.dateTextSize,
    this.showDate = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: avatarRadius,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
          child: avatarUrl == null
              ? Icon(
                  Icons.person,
                  size: avatarRadius * 1.2,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                )
              : null,
        ),
        SizedBox(width: avatarRadius * 0.75),
        Expanded(
          child: Text(
            username,
            style: TextStyle(
              fontSize: fontSize,
              color: showDate ? null : Colors.grey[600],
              fontWeight: showDate ? FontWeight.w500 : null,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (showDate && date != null) ...[
          const SizedBox(width: 8),
          Text(
            _formatDate(date!),
            style: TextStyle(
              fontSize: dateTextSize ?? (fontSize * 0.875),
              color: Colors.grey[600],
            ),
          ),
        ],
      ],
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
