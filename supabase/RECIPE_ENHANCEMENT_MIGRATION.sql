-- このファイルの内容をSupabase SQL Editorにコピペして実行してください
-- レシピ機能拡張のためのデータベースマイグレーション

-- 1. 新しいカラムを追加
ALTER TABLE espresso_recipes
ADD COLUMN IF NOT EXISTS notes TEXT,
ADD COLUMN IF NOT EXISTS appearance_rating INT CHECK (appearance_rating >= 1 AND appearance_rating <= 5),
ADD COLUMN IF NOT EXISTS taste_rating INT CHECK (taste_rating >= 1 AND taste_rating <= 5);

-- 2. 既存データのマイグレーション（既存のratingをappearance_ratingとtaste_ratingにコピー）
UPDATE espresso_recipes
SET
  appearance_rating = COALESCE(appearance_rating, rating),
  taste_rating = COALESCE(taste_rating, rating),
  notes = COALESCE(notes, '')
WHERE appearance_rating IS NULL OR taste_rating IS NULL;

-- 3. RLSポリシー: 自分のレシピのみ更新可能
DROP POLICY IF EXISTS "Users can update own recipes" ON espresso_recipes;

CREATE POLICY "Users can update own recipes"
ON espresso_recipes
FOR UPDATE
TO authenticated
USING (auth.uid() = created_by)
WITH CHECK (auth.uid() = created_by);

-- 4. get_recipes_with_usernames関数を更新
DROP FUNCTION IF EXISTS get_recipes_with_usernames(uuid);

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
  appearance_rating INT,
  taste_rating INT,
  notes TEXT,
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
    r.appearance_rating,
    r.taste_rating,
    r.notes,
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

-- 5. 既存のratingカラムはそのまま残す（後方互換性のため）
-- 将来的に削除する場合は: ALTER TABLE espresso_recipes DROP COLUMN rating;
