-- =============================================
-- Favorite Functionality Migration
-- =============================================
-- Add favorite functionality to recipes
-- This is a shared favorite system where any group member can mark a recipe as favorite
--
-- IMPORTANT: Run PROFILES_TABLE_MIGRATION.sql first!
-- This migration depends on the profiles table existing.

-- 1. Add is_favorite column
ALTER TABLE espresso_recipes
ADD COLUMN IF NOT EXISTS is_favorite BOOLEAN DEFAULT FALSE;

-- 2. Drop existing policy if it exists, then create new one
DROP POLICY IF EXISTS "Group members can update recipe favorites" ON espresso_recipes;

CREATE POLICY "Group members can update recipe favorites"
ON espresso_recipes FOR UPDATE TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM group_members
    WHERE group_members.group_id = espresso_recipes.group_id
    AND group_members.user_id = auth.uid()
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM group_members
    WHERE group_members.group_id = espresso_recipes.group_id
    AND group_members.user_id = auth.uid()
  )
);

-- 3. Drop existing function first to avoid return type conflict
DROP FUNCTION IF EXISTS get_recipes_with_usernames(uuid);

-- 4. Update get_recipes_with_usernames function to include is_favorite and order by it
CREATE OR REPLACE FUNCTION get_recipes_with_usernames(p_group_id UUID)
RETURNS TABLE (
  id UUID,
  group_id UUID,
  created_by UUID,
  coffee_weight NUMERIC,
  grinder_setting TEXT,
  extraction_time INT,
  roast_level NUMERIC,
  rating INT,
  appearance_rating INT,
  taste_rating INT,
  notes TEXT,
  photo_url TEXT,
  is_favorite BOOLEAN,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ,
  created_by_username TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    r.id,
    r.group_id,
    r.created_by,
    r.coffee_weight,
    r.grinder_setting,
    r.extraction_time,
    r.roast_level,
    r.rating,
    r.appearance_rating,
    r.taste_rating,
    r.notes,
    r.photo_url,
    r.is_favorite,
    r.created_at,
    r.updated_at,
    p.username as created_by_username
  FROM espresso_recipes r
  LEFT JOIN profiles p ON r.created_by = p.id
  WHERE r.group_id = p_group_id
  ORDER BY r.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
