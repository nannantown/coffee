-- このファイルの内容をSupabase SQL Editorにコピペして実行してください

-- 既存の関数を削除
DROP FUNCTION IF EXISTS get_recipes_with_usernames(uuid);
DROP FUNCTION IF EXISTS get_group_members_with_usernames(uuid);

-- 1. レシピをユーザー名と一緒に取得する関数
CREATE OR REPLACE FUNCTION get_recipes_with_usernames(p_group_id UUID)
RETURNS TABLE (
  id UUID,
  group_id UUID,
  created_by UUID,
  created_by_username TEXT,
  coffee_weight NUMERIC,
  grinder_setting TEXT,
  extraction_time INT,
  roast_level NUMERIC,
  rating INT,
  photo_url TEXT,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ
)
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT
    r.id,
    r.group_id,
    r.created_by,
    COALESCE((au.raw_user_meta_data->>'username')::TEXT, 'Unknown') as created_by_username,
    r.coffee_weight,
    r.grinder_setting,
    r.extraction_time,
    r.roast_level,
    r.rating,
    r.photo_url,
    r.created_at,
    r.updated_at
  FROM espresso_recipes r
  LEFT JOIN auth.users au ON r.created_by = au.id
  WHERE r.group_id = p_group_id
  ORDER BY r.created_at DESC;
END;
$$;

GRANT EXECUTE ON FUNCTION get_recipes_with_usernames(UUID) TO authenticated;

-- 2. グループメンバーをユーザー名と一緒に取得する関数
CREATE OR REPLACE FUNCTION get_group_members_with_usernames(p_group_id UUID)
RETURNS TABLE (
  id UUID,
  group_id UUID,
  user_id UUID,
  username TEXT,
  role TEXT,
  joined_at TIMESTAMPTZ
)
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT
    gm.id,
    gm.group_id,
    gm.user_id,
    COALESCE((au.raw_user_meta_data->>'username')::TEXT, 'Unknown') as username,
    gm.role,
    gm.joined_at
  FROM group_members gm
  LEFT JOIN auth.users au ON gm.user_id = au.id
  WHERE gm.group_id = p_group_id
  ORDER BY
    CASE
      WHEN gm.role = 'owner' THEN 0
      ELSE 1
    END,
    gm.joined_at ASC;
END;
$$;

GRANT EXECUTE ON FUNCTION get_group_members_with_usernames(UUID) TO authenticated;
