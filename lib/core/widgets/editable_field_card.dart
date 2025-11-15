import 'package:flutter/material.dart';
import 'primary_action_button.dart';

/// Reusable card for displaying and editing a field
class EditableFieldCard extends StatelessWidget {
  final String title;
  final String value;
  final bool isEditing;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final VoidCallback? onEdit;
  final VoidCallback? onCancel;
  final VoidCallback? onSave;
  final bool isLoading;
  final String? labelText;
  final String? hintText;

  const EditableFieldCard({
    super.key,
    required this.title,
    required this.value,
    this.isEditing = false,
    this.controller,
    this.validator,
    this.onEdit,
    this.onCancel,
    this.onSave,
    this.isLoading = false,
    this.labelText,
    this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (!isEditing && onEdit != null)
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: onEdit,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (isEditing && controller != null)
              Column(
                children: [
                  TextFormField(
                    controller: controller,
                    decoration: InputDecoration(
                      labelText: labelText ?? title,
                      border: const OutlineInputBorder(),
                      hintText: hintText,
                    ),
                    validator: validator,
                    enabled: !isLoading,
                  ),
                  const SizedBox(height: 16),
                  PrimaryActionButton(
                    onPressed: onSave,
                    label: '保存',
                    isLoading: isLoading,
                  ),
                ],
              )
            else
              Text(
                value,
                style: const TextStyle(fontSize: 18),
              ),
          ],
        ),
      ),
    );
  }
}
