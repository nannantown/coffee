import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/coffee_group.dart';
import '../models/group_member.dart';

class GroupService {
  final SupabaseClient _supabase;

  GroupService(this._supabase);

  // グループ作成
  Future<CoffeeGroup> createGroup(String name, String userId, {String? imageUrl}) async {
    try {
      final now = DateTime.now().toIso8601String();

      // グループを作成
      final groupResponse = await _supabase
          .from('coffee_groups')
          .insert({
            'name': name,
            'owner_id': userId,
            'image_url': imageUrl,
            'created_at': now,
            'updated_at': now,
          })
          .select()
          .single();

      final group = CoffeeGroup.fromJson(groupResponse);

      // 作成者をオーナーとしてメンバーに追加
      await _supabase.from('group_members').insert({
        'group_id': group.id,
        'user_id': userId,
        'role': 'owner',
        'joined_at': now,
      });

      print('✅ Group created: ${group.name}');
      return group;
    } catch (e) {
      print('❌ Error creating group: $e');
      rethrow;
    }
  }

  // ユーザーが参加しているグループ一覧を取得
  Future<List<CoffeeGroup>> getUserGroups(String userId) async {
    try {
      final response = await _supabase
          .from('group_members')
          .select('group_id, display_order, coffee_groups(*)')
          .eq('user_id', userId)
          .order('display_order');

      final groups = (response as List)
          .map((item) => CoffeeGroup.fromJson(item['coffee_groups']))
          .toList();

      print('✅ Fetched ${groups.length} groups');
      return groups;
    } catch (e) {
      print('❌ Error fetching user groups: $e');
      rethrow;
    }
  }

  // グループ詳細を取得
  Future<CoffeeGroup> getGroup(String groupId) async {
    try {
      final response = await _supabase
          .from('coffee_groups')
          .select()
          .eq('id', groupId)
          .single();

      return CoffeeGroup.fromJson(response);
    } catch (e) {
      print('❌ Error fetching group: $e');
      rethrow;
    }
  }

  // グループメンバー一覧を取得（ユーザー名付き）
  Future<List<GroupMember>> getGroupMembers(String groupId) async {
    try {
      final response = await _supabase
          .rpc('get_group_members_with_usernames', params: {'p_group_id': groupId});

      return (response as List)
          .map((json) => GroupMember.fromJson(json))
          .toList();
    } catch (e) {
      print('❌ Error fetching group members: $e');
      rethrow;
    }
  }

  // グループ削除（オーナーのみ）
  Future<void> deleteGroup(String groupId, String userId) async {
    try {
      // オーナーかチェック
      final member = await _supabase
          .from('group_members')
          .select()
          .eq('group_id', groupId)
          .eq('user_id', userId)
          .eq('role', 'owner')
          .maybeSingle();

      if (member == null) {
        throw Exception('Only the owner can delete the group');
      }

      // グループを削除（カスケード削除でメンバーとレシピも削除される想定）
      await _supabase.from('coffee_groups').delete().eq('id', groupId);

      print('✅ Group deleted: $groupId');
    } catch (e) {
      print('❌ Error deleting group: $e');
      rethrow;
    }
  }

  // ユーザーがグループのメンバーかチェック
  Future<bool> isGroupMember(String groupId, String userId) async {
    try {
      final response = await _supabase
          .from('group_members')
          .select()
          .eq('group_id', groupId)
          .eq('user_id', userId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('❌ Error checking group membership: $e');
      return false;
    }
  }

  // オーナー権限を譲渡
  Future<void> transferOwnership(String groupId, String newOwnerId) async {
    try {
      // グループのowner_idを更新
      await _supabase
          .from('coffee_groups')
          .update({'owner_id': newOwnerId, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', groupId);

      // 新オーナーをgroup_membersに追加（既に存在する場合はroleを更新）
      final existingMember = await _supabase
          .from('group_members')
          .select()
          .eq('group_id', groupId)
          .eq('user_id', newOwnerId)
          .maybeSingle();

      if (existingMember != null) {
        // 既存メンバーのroleを'owner'に更新
        await _supabase
            .from('group_members')
            .update({'role': 'owner'})
            .eq('group_id', groupId)
            .eq('user_id', newOwnerId);
      } else {
        // 新規メンバーとして'owner'で追加
        await _supabase
            .from('group_members')
            .insert({
              'group_id': groupId,
              'user_id': newOwnerId,
              'role': 'owner',
            });
      }

      // 注: 旧オーナーは呼び出し元でleaveGroup()により削除される
      print('✅ Ownership transferred to: $newOwnerId');
    } catch (e) {
      print('❌ Error transferring ownership: $e');
      rethrow;
    }
  }

  // グループから退会
  Future<void> leaveGroup(String groupId, String userId) async {
    try {
      await _supabase
          .from('group_members')
          .delete()
          .eq('group_id', groupId)
          .eq('user_id', userId);

      print('✅ User left group: $groupId');
    } catch (e) {
      print('❌ Error leaving group: $e');
      rethrow;
    }
  }

  // グループ名を更新（メンバーなら誰でも可能）
  Future<void> updateGroupName(String groupId, String userId, String newName) async {
    try {
      // メンバーかチェック
      final isMember = await isGroupMember(groupId, userId);
      if (!isMember) {
        throw Exception('Only group members can update the group name');
      }

      // グループ名を更新
      await _supabase
          .from('coffee_groups')
          .update({
            'name': newName,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', groupId);

      print('✅ Group name updated: $newName');
    } catch (e) {
      print('❌ Error updating group name: $e');
      rethrow;
    }
  }

  // グループ画像を更新（メンバーなら誰でも可能）
  Future<void> updateGroupImage(String groupId, String userId, String? imageUrl) async {
    try {
      // メンバーかチェック
      final isMember = await isGroupMember(groupId, userId);
      if (!isMember) {
        throw Exception('Only group members can update the group image');
      }

      // グループ画像を更新
      await _supabase
          .from('coffee_groups')
          .update({
            'image_url': imageUrl,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', groupId);

      print('✅ Group image updated');
    } catch (e) {
      print('❌ Error updating group image: $e');
      rethrow;
    }
  }

  // グループの並び替え順序を更新
  Future<void> updateGroupOrder(String userId, List<String> groupIds) async {
    try {
      // 各グループのdisplay_orderを更新
      for (int i = 0; i < groupIds.length; i++) {
        await _supabase
            .from('group_members')
            .update({'display_order': i})
            .eq('user_id', userId)
            .eq('group_id', groupIds[i]);
      }

      print('✅ Group order updated');
    } catch (e) {
      print('❌ Error updating group order: $e');
      rethrow;
    }
  }
}
