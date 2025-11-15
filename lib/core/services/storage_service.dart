import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// Generic storage service for uploading images to Supabase Storage
class StorageService {
  final SupabaseClient _supabase;
  final _uuid = const Uuid();

  StorageService(this._supabase);

  /// Upload image to specified bucket
  /// Returns the public URL of the uploaded image
  Future<String> uploadImage({
    required File imageFile,
    required String bucketName,
    String? folder,
  }) async {
    try {
      final fileExt = imageFile.path.split('.').last;
      final fileName = '${_uuid.v4()}.$fileExt';
      final filePath = folder != null ? '$folder/$fileName' : fileName;

      await _supabase.storage.from(bucketName).upload(
            filePath,
            imageFile,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: false,
            ),
          );

      final publicUrl =
          _supabase.storage.from(bucketName).getPublicUrl(filePath);

      print('✅ Image uploaded to $bucketName: $fileName');
      return publicUrl;
    } catch (e) {
      print('❌ Error uploading image: $e');
      rethrow;
    }
  }

  /// Delete image from specified bucket
  Future<void> deleteImage({
    required String imageUrl,
    required String bucketName,
  }) async {
    try {
      // Extract file path from URL
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;

      // Get the path after the bucket name
      final bucketIndex = pathSegments.indexOf(bucketName);
      if (bucketIndex == -1 || bucketIndex == pathSegments.length - 1) {
        throw Exception('Invalid image URL format');
      }

      final filePath = pathSegments.sublist(bucketIndex + 1).join('/');

      await _supabase.storage.from(bucketName).remove([filePath]);

      print('✅ Image deleted from $bucketName: $filePath');
    } catch (e) {
      print('❌ Error deleting image: $e');
      rethrow;
    }
  }

  /// Upload avatar image (for user profiles)
  Future<String> uploadAvatar(File imageFile) {
    return uploadImage(
      imageFile: imageFile,
      bucketName: 'avatars',
    );
  }

  /// Upload group thumbnail image
  Future<String> uploadGroupImage(File imageFile) {
    return uploadImage(
      imageFile: imageFile,
      bucketName: 'group-images',
    );
  }

  /// Delete avatar image
  Future<void> deleteAvatar(String imageUrl) {
    return deleteImage(
      imageUrl: imageUrl,
      bucketName: 'avatars',
    );
  }

  /// Delete group thumbnail image
  Future<void> deleteGroupImage(String imageUrl) {
    return deleteImage(
      imageUrl: imageUrl,
      bucketName: 'group-images',
    );
  }
}
