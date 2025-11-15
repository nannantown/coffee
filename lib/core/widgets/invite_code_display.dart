import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 招待コード表示ウィジェット
/// 招待コードをコピー可能な形式で表示する
class InviteCodeDisplay extends StatelessWidget {
  final String inviteCode;
  final EdgeInsets? padding;

  const InviteCodeDisplay({
    super.key,
    required this.inviteCode,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            inviteCode,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[900],
            ),
          ),
          IconButton(
            icon: Icon(Icons.copy, color: Colors.grey[700]),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: inviteCode));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('クリップボードにコピーしました'),
                ),
              );
            },
            tooltip: 'コピー',
          ),
        ],
      ),
    );
  }
}
