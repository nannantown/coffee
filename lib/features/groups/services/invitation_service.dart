import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/group_invitation.dart';

class InvitationService {
  final SupabaseClient _supabase;
  final _uuid = const Uuid();

  InvitationService(this._supabase);

  // 招待リンク生成
  Future<GroupInvitation> createInvitation(
    String groupId,
    String userId, {
    DateTime? expiresAt,
  }) async {
    try {
      final inviteCode = _uuid.v4().substring(0, 8);
      final now = DateTime.now().toIso8601String();

      final response = await _supabase
          .from('group_invitations')
          .insert({
            'group_id': groupId,
            'invite_code': inviteCode,
            'created_by': userId,
            'expires_at': expiresAt?.toIso8601String(),
            'created_at': now,
          })
          .select()
          .single();

      final invitation = GroupInvitation.fromJson(response);
      print('✅ Invitation created: $inviteCode');
      return invitation;
    } catch (e) {
      print('❌ Error creating invitation: $e');
      rethrow;
    }
  }

  // 招待コードからグループに参加
  Future<void> joinGroupByInviteCode(String inviteCode, String userId) async {
    try {
      // 招待コードを検証
      final invitationResponse = await _supabase
          .from('group_invitations')
          .select()
          .eq('invite_code', inviteCode)
          .maybeSingle();

      if (invitationResponse == null) {
        throw Exception('Invalid invite code');
      }

      final invitation = GroupInvitation.fromJson(invitationResponse);

      if (invitation.isExpired) {
        throw Exception('Invite code has expired');
      }

      // すでにメンバーでないかチェック
      final existingMember = await _supabase
          .from('group_members')
          .select()
          .eq('group_id', invitation.groupId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existingMember != null) {
        throw Exception('You are already a member of this group');
      }

      // メンバーとして追加
      await _supabase.from('group_members').insert({
        'group_id': invitation.groupId,
        'user_id': userId,
        'role': 'member',
        'joined_at': DateTime.now().toIso8601String(),
      });

      print('✅ Joined group via invite code: $inviteCode');
    } catch (e) {
      print('❌ Error joining group: $e');
      rethrow;
    }
  }

  // グループの招待リンク一覧を取得
  Future<List<GroupInvitation>> getGroupInvitations(String groupId) async {
    try {
      final response = await _supabase
          .from('group_invitations')
          .select()
          .eq('group_id', groupId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => GroupInvitation.fromJson(json))
          .toList();
    } catch (e) {
      print('❌ Error fetching invitations: $e');
      rethrow;
    }
  }

  // 招待リンクを削除
  Future<void> deleteInvitation(String invitationId) async {
    try {
      await _supabase
          .from('group_invitations')
          .delete()
          .eq('id', invitationId);

      print('✅ Invitation deleted: $invitationId');
    } catch (e) {
      print('❌ Error deleting invitation: $e');
      rethrow;
    }
  }
}
