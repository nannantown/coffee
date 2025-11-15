import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/espresso_shot.dart';
import '../providers/shot_provider.dart';
import '../widgets/shot_form.dart';

class EditShotScreen extends ConsumerStatefulWidget {
  final String shotId;

  const EditShotScreen({super.key, required this.shotId});

  @override
  ConsumerState<EditShotScreen> createState() => _EditShotScreenState();
}

class _EditShotScreenState extends ConsumerState<EditShotScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();

  double _coffeeWeight = 18.0;
  int _grinderSetting = 240;
  int _extractionTime = 30;
  double _roastLevel = 0.5;
  int _rating = 3;
  String _extractionSpeed = 'optimal';
  File? _selectedImage;
  String? _existingPhotoUrl;
  bool _isLoading = false;
  bool _isInitialized = false;

  void _initializeForm(EspressoShot recipe) {
    if (_isInitialized) return;
    _coffeeWeight = recipe.coffeeWeight;
    _grinderSetting = int.tryParse(recipe.grinderSetting) ?? 240;
    _extractionTime = recipe.extractionTime ?? 30;
    _notesController.text = recipe.notes ?? '';
    _roastLevel = recipe.roastLevel ?? 0.5;
    _rating = recipe.rating;
    _extractionSpeed = recipe.extractionSpeed;
    _existingPhotoUrl = recipe.photoUrl;
    _isInitialized = true;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _updateShot() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // 新しい写真がある場合はアップロード
      String? photoUrl = _existingPhotoUrl;
      if (_selectedImage != null) {
        final storageService = ref.read(storageServiceProvider);
        photoUrl = await storageService.uploadPhoto(_selectedImage!);

        // 古い写真を削除
        if (_existingPhotoUrl != null) {
          try {
            await storageService.deletePhoto(_existingPhotoUrl!);
          } catch (e) {
            print('Error deleting old photo: $e');
          }
        }
      }

      // レシピを更新
      final notifier = ref.read(shotNotifierProvider.notifier);
      final recipe = await notifier.updateShot(
        shotId: widget.shotId,
        userId: userId,
        coffeeWeight: _coffeeWeight,
        grinderSetting: _grinderSetting.toString(),
        extractionTime: _extractionTime,
        roastLevel: _roastLevel,
        rating: _rating,
        extractionSpeed: _extractionSpeed,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        photoUrl: photoUrl,
      );

      if (recipe != null && mounted) {
        // レシピ一覧と詳細を更新
        ref.invalidate(groupShotsProvider(recipe.groupId));
        ref.invalidate(shotDetailProvider(widget.shotId));

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ショットを更新しました')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final recipeAsync = ref.watch(shotDetailProvider(widget.shotId));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('ショットを編集'),
      ),
      body: recipeAsync.when(
        data: (recipe) {
          _initializeForm(recipe);
          return ShotForm(
            formKey: _formKey,
            coffeeWeight: _coffeeWeight,
            grinderSetting: _grinderSetting,
            extractionTime: _extractionTime,
            notesController: _notesController,
            roastLevel: _roastLevel,
            rating: _rating,
            extractionSpeed: _extractionSpeed,
            selectedImage: _selectedImage,
            onCoffeeWeightChanged: (value) => setState(() => _coffeeWeight = value),
            onGrinderSettingChanged: (value) => setState(() => _grinderSetting = value),
            onExtractionTimeChanged: (value) => setState(() => _extractionTime = value),
            onRoastLevelChanged: (value) => setState(() => _roastLevel = value),
            onRatingChanged: (value) => setState(() => _rating = value),
            onExtractionSpeedChanged: (value) => setState(() => _extractionSpeed = value),
            onImageSelected: (image) => setState(() => _selectedImage = image),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('エラー: $error')),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: _isLoading ? null : _updateShot,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 20),
              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('更新'),
          ),
        ),
      ),
    );
  }
}
