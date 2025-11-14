import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/espresso_shot.dart';
import '../services/shot_service.dart';
import '../../groups/providers/group_provider.dart';

// Shot service provider
final shotServiceProvider = Provider<ShotService>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return ShotService(supabase);
});

// グループのショット一覧を取得
final groupShotsProvider =
    FutureProvider.family.autoDispose<List<EspressoShot>, String>(
        (ref, groupId) async {
  final shotService = ref.watch(shotServiceProvider);
  return shotService.getGroupShots(groupId);
});

// ショット詳細を取得
final shotDetailProvider =
    FutureProvider.family.autoDispose<EspressoShot, String>(
        (ref, shotId) async {
  final shotService = ref.watch(shotServiceProvider);
  return shotService.getShot(shotId);
});

// ショット作成・更新・削除アクション
class ShotNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<EspressoShot?> createShot({
    required String groupId,
    required String userId,
    required double coffeeWeight,
    required String grinderSetting,
    int? extractionTime,
    double? roastLevel,
    required int rating,
    required int appearanceRating,
    required int tasteRating,
    String? notes,
    String? photoUrl,
  }) async {
    state = const AsyncValue.loading();
    try {
      final shotService = ref.read(shotServiceProvider);
      final shot = await shotService.createShot(
        groupId: groupId,
        userId: userId,
        coffeeWeight: coffeeWeight,
        grinderSetting: grinderSetting,
        extractionTime: extractionTime,
        roastLevel: roastLevel,
        rating: rating,
        appearanceRating: appearanceRating,
        tasteRating: tasteRating,
        notes: notes,
        photoUrl: photoUrl,
      );
      state = const AsyncValue.data(null);
      return shot;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return null;
    }
  }

  Future<EspressoShot?> updateShot({
    required String shotId,
    required String userId,
    double? coffeeWeight,
    String? grinderSetting,
    int? extractionTime,
    double? roastLevel,
    int? rating,
    int? appearanceRating,
    int? tasteRating,
    String? notes,
    String? photoUrl,
  }) async {
    state = const AsyncValue.loading();
    try {
      final shotService = ref.read(shotServiceProvider);
      final shot = await shotService.updateShot(
        shotId: shotId,
        userId: userId,
        coffeeWeight: coffeeWeight,
        grinderSetting: grinderSetting,
        extractionTime: extractionTime,
        roastLevel: roastLevel,
        rating: rating,
        appearanceRating: appearanceRating,
        tasteRating: tasteRating,
        notes: notes,
        photoUrl: photoUrl,
      );
      state = const AsyncValue.data(null);
      return shot;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return null;
    }
  }

  Future<void> deleteShot(String shotId, String userId) async {
    state = const AsyncValue.loading();
    try {
      final shotService = ref.read(shotServiceProvider);
      final shot = await shotService.getShot(shotId);
      await shotService.deleteShot(shotId, userId);

      // ショット一覧を更新
      ref.invalidate(groupShotsProvider(shot.groupId));

      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }
}

final shotNotifierProvider =
    NotifierProvider<ShotNotifier, AsyncValue<void>>(ShotNotifier.new);
