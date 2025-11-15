import 'package:flutter/material.dart';

class NotesField extends StatelessWidget {
  final TextEditingController controller;

  const NotesField({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('コメント（任意）', style: TextStyle(fontSize: 16)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '味の感想、改善点など',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
          keyboardType: TextInputType.multiline,
        ),
      ],
    );
  }
}
