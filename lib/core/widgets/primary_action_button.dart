import 'package:flutter/material.dart';

enum ButtonType { filled, outlined }

/// Primary action button component for all action buttons
///
/// Provides consistent styling and loading state handling across the app
/// Supports both filled and outlined button styles with optional icons
class PrimaryActionButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final bool isLoading;
  final ButtonType type;
  final Color? color;
  final IconData? icon;

  const PrimaryActionButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.isLoading = false,
    this.type = ButtonType.filled,
    this.color,
    this.icon,
  });

  const PrimaryActionButton.outlined({
    super.key,
    required this.onPressed,
    required this.label,
    this.isLoading = false,
    this.color,
    this.icon,
  }) : type = ButtonType.outlined;

  @override
  Widget build(BuildContext context) {
    final buttonChild = isLoading
        ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : (icon != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon),
                  const SizedBox(width: 8),
                  Text(label),
                ],
              )
            : Text(label));

    if (type == ButtonType.outlined) {
      return OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          foregroundColor: color,
          side: color != null ? BorderSide(color: color!) : null,
        ),
        child: buttonChild,
      );
    }

    return FilledButton(
      onPressed: isLoading ? null : onPressed,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        backgroundColor: color,
      ),
      child: buttonChild,
    );
  }
}
