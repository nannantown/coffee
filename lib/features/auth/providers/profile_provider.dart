import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/profile_service.dart';
import '../../../config/supabase_config.dart';

// Profile service provider
final profileServiceProvider = Provider<ProfileService>((ref) {
  return ProfileService(supabase);
});

// Current user's profile provider
final currentUserProfileProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) {
    throw Exception('User not authenticated');
  }

  final profileService = ref.watch(profileServiceProvider);
  return profileService.getProfile(userId);
});

// Profile notifier for updates
class ProfileNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<void> updateUsername(String userId, String newUsername) async {
    state = const AsyncValue.loading();
    try {
      final profileService = ref.read(profileServiceProvider);
      await profileService.updateUsername(userId, newUsername);

      // Refresh the profile
      ref.invalidate(currentUserProfileProvider);

      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }
}

final profileNotifierProvider =
    NotifierProvider<ProfileNotifier, AsyncValue<void>>(ProfileNotifier.new);
