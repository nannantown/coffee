import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  final SupabaseClient _supabase;
  final _uuid = const Uuid();
  static const String bucketName = 'recipe-photos';

  StorageService(this._supabase);

  // 写真をアップロード
  Future<String> uploadPhoto(File imageFile) async {
    try {
      final fileExt = imageFile.path.split('.').last;
      final fileName = '${_uuid.v4()}.$fileExt';
      final filePath = fileName;

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

      print('✅ Photo uploaded: $fileName');
      return publicUrl;
    } catch (e) {
      print('❌ Error uploading photo: $e');
      rethrow;
    }
  }

  // 写真を削除
  Future<void> deletePhoto(String photoUrl) async {
    try {
      // URLからファイル名を抽出
      final uri = Uri.parse(photoUrl);
      final pathSegments = uri.pathSegments;
      final fileName = pathSegments.last;

      await _supabase.storage.from(bucketName).remove([fileName]);

      print('✅ Photo deleted: $fileName');
    } catch (e) {
      print('❌ Error deleting photo: $e');
      rethrow;
    }
  }
}
