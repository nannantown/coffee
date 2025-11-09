import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/coffee_group.dart';
import '../models/group_member.dart';
import '../services/group_service.dart';
import '../services/invitation_service.dart';

// Supabase client provider
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// Group service provider
final groupServiceProvider = Provider<GroupService>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return GroupService(supabase);
});

// Invitation service provider
final invitationServiceProvider = Provider<InvitationService>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return InvitationService(supabase);
});

// ユーザーが参加しているグループ一覧を取得
final userGroupsProvider =
    FutureProvider.autoDispose<List<CoffeeGroup>>((ref) async {
  final groupService = ref.watch(groupServiceProvider);
  final userId = Supabase.instance.client.auth.currentUser?.id;

  if (userId == null) {
    throw Exception('User not authenticated');
  }

  return groupService.getUserGroups(userId);
});

// 特定のグループの詳細を取得
final groupDetailProvider =
    FutureProvider.family.autoDispose<CoffeeGroup, String>((ref, groupId) async {
  final groupService = ref.watch(groupServiceProvider);
  return groupService.getGroup(groupId);
});

// グループメンバー一覧を取得
final groupMembersProvider =
    FutureProvider.family.autoDispose<List<GroupMember>, String>(
        (ref, groupId) async {
  final groupService = ref.watch(groupServiceProvider);
  return groupService.getGroupMembers(groupId);
});

// グループ作成アクション
class GroupNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<CoffeeGroup?> createGroup(String name, String userId) async {
    state = const AsyncValue.loading();
    try {
      final groupService = ref.read(groupServiceProvider);
      final group = await groupService.createGroup(name, userId);
      state = const AsyncValue.data(null);
      return group;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return null;
    }
  }

  Future<void> deleteGroup(String groupId, String userId) async {
    state = const AsyncValue.loading();
    try {
      final groupService = ref.read(groupServiceProvider);
      await groupService.deleteGroup(groupId, userId);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final groupNotifierProvider =
    NotifierProvider<GroupNotifier, AsyncValue<void>>(GroupNotifier.new);
