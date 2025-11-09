-- アカウント削除用のRPC関数
-- Edge Functionから呼び出されて、ユーザーの全データを削除します

CREATE OR REPLACE FUNCTION delete_own_data(user_id UUID)
RETURNS void AS $$
BEGIN
  -- espresso_recipesの削除（CASCADE設定があるため、関連する写真も削除される）
  DELETE FROM espresso_recipes WHERE user_id = delete_own_data.user_id;

  -- group_membersの削除
  DELETE FROM group_members WHERE user_id = delete_own_data.user_id;

  -- group_invitationsの削除（作成者として）
  DELETE FROM group_invitations WHERE created_by = delete_own_data.user_id;

  -- coffee_groupsの削除（オーナーとして）
  -- CASCADE設定により、関連するgroup_members, group_invitations, espresso_recipesも削除される
  DELETE FROM coffee_groups WHERE owner_id = delete_own_data.user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- この関数は認証済みユーザーのみ実行可能にする
GRANT EXECUTE ON FUNCTION delete_own_data(UUID) TO authenticated;

-- サービスロール（Edge Function）も実行可能にする
GRANT EXECUTE ON FUNCTION delete_own_data(UUID) TO service_role;
