import 'dart:io';
import 'package:flutter/material.dart';

/// Reusable circular image picker widget for avatars and group images
class ImagePickerAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? fallbackText;
  final IconData fallbackIcon;
  final bool isUploading;
  final VoidCallback onTap;
  final double radius;

  const ImagePickerAvatar({
    super.key,
    this.imageUrl,
    this.fallbackText,
    this.fallbackIcon = Icons.image,
    this.isUploading = false,
    required this.onTap,
    this.radius = 50,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          backgroundImage: imageUrl != null ? NetworkImage(imageUrl!) : null,
          child: imageUrl == null
              ? (fallbackText != null
                  ? Text(
                      fallbackText!.isNotEmpty
                          ? fallbackText![0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontSize: radius * 0.8,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    )
                  : Icon(
                      fallbackIcon,
                      size: radius * 0.8,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ))
              : null,
        ),
        if (isUploading)
          Positioned.fill(
            child: CircleAvatar(
              radius: radius,
              backgroundColor: Colors.black54,
              child: const CircularProgressIndicator(color: Colors.white),
            ),
          ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Material(
            color: Theme.of(context).colorScheme.primary,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: isUploading ? null : onTap,
              customBorder: const CircleBorder(),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  Icons.camera_alt,
                  size: 20,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
