import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/shot_provider.dart';
import '../widgets/shot_form.dart';

class CreateShotScreen extends ConsumerStatefulWidget {
  final String groupId;

  const CreateShotScreen({super.key, required this.groupId});

  @override
  ConsumerState<CreateShotScreen> createState() => _CreateShotScreenState();
}

class _CreateShotScreenState extends ConsumerState<CreateShotScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();

  double _coffeeWeight = 18.0;
  int _grinderSetting = 240;
  int _extractionTime = 0;
  double _roastLevel = 0.5;
  int _rating = 3;
  String _extractionSpeed = 'optimal';
  File? _selectedImage;
  bool _isLoading = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _createShot() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // 写真をアップロード（選択されている場合）
      String? photoUrl;
      if (_selectedImage != null) {
        final storageService = ref.read(storageServiceProvider);
        photoUrl = await storageService.uploadPhoto(_selectedImage!);
      }

      // レシピを作成
      final notifier = ref.read(shotNotifierProvider.notifier);
      final recipe = await notifier.createShot(
        groupId: widget.groupId,
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ショットを記録しました')),
        );
        // レシピ一覧をリフレッシュ
        ref.invalidate(groupShotsProvider(widget.groupId));
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('ショットを記録'),
      ),
      body: ShotForm(
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
        onImageSelected: (image) => setState(() => _selectedImage = value),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: _isLoading ? null : _createShot,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('ショットを記録'),
          ),
        ),
      ),
    );
  }
}
