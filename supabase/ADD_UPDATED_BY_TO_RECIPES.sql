-- ============================================================================
-- Add updated_by column to espresso_recipes
-- ============================================================================
-- This migration adds updated_by to track who last updated the recipe

-- Add updated_by column
ALTER TABLE public.espresso_recipes
ADD COLUMN IF NOT EXISTS updated_by UUID REFERENCES auth.users(id) ON DELETE CASCADE;

-- Set initial value to created_by for existing records
UPDATE public.espresso_recipes
SET updated_by = created_by
WHERE updated_by IS NULL;

-- Make it NOT NULL after setting initial values
ALTER TABLE public.espresso_recipes
ALTER COLUMN updated_by SET NOT NULL;

-- Create index for performance
CREATE INDEX IF NOT EXISTS idx_espresso_recipes_updated_by ON public.espresso_recipes(updated_by);

-- Update the RPC function to include updated_by_username
DROP FUNCTION IF EXISTS get_recipes_with_usernames(UUID);

CREATE OR REPLACE FUNCTION get_recipes_with_usernames(p_group_id UUID)
RETURNS TABLE (
    id UUID,
    group_id UUID,
    created_by UUID,
    created_by_username TEXT,
    updated_by UUID,
    updated_by_username TEXT,
    source_shot_id UUID,
    coffee_weight DECIMAL,
    grinder_setting TEXT,
    extraction_time INTEGER,
    roast_level DECIMAL,
    rating INTEGER,
    extraction_speed TEXT,
    is_favorite BOOLEAN,
    notes TEXT,
    photo_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        r.id,
        r.group_id,
        r.created_by,
        COALESCE(p1.username, 'Unknown') as created_by_username,
        r.updated_by,
        COALESCE(p2.username, 'Unknown') as updated_by_username,
        r.source_shot_id,
        r.coffee_weight,
        r.grinder_setting,
        r.extraction_time,
        r.roast_level,
        r.rating,
        r.extraction_speed,
        r.is_favorite,
        r.notes,
        r.photo_url,
        r.created_at,
        r.updated_at
    FROM public.espresso_recipes r
    LEFT JOIN public.profiles p1 ON r.created_by = p1.id
    LEFT JOIN public.profiles p2 ON r.updated_by = p2.id
    WHERE r.group_id = p_group_id
    ORDER BY r.updated_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update the single recipe function too
DROP FUNCTION IF EXISTS get_recipe_with_username(UUID);

CREATE OR REPLACE FUNCTION get_recipe_with_username(p_recipe_id UUID)
RETURNS TABLE (
    id UUID,
    group_id UUID,
    created_by UUID,
    created_by_username TEXT,
    updated_by UUID,
    updated_by_username TEXT,
    source_shot_id UUID,
    coffee_weight DECIMAL,
    grinder_setting TEXT,
    extraction_time INTEGER,
    roast_level DECIMAL,
    rating INTEGER,
    extraction_speed TEXT,
    is_favorite BOOLEAN,
    notes TEXT,
    photo_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        r.id,
        r.group_id,
        r.created_by,
        COALESCE(p1.username, 'Unknown') as created_by_username,
        r.updated_by,
        COALESCE(p2.username, 'Unknown') as updated_by_username,
        r.source_shot_id,
        r.coffee_weight,
        r.grinder_setting,
        r.extraction_time,
        r.roast_level,
        r.rating,
        r.extraction_speed,
        r.is_favorite,
        r.notes,
        r.photo_url,
        r.created_at,
        r.updated_at
    FROM public.espresso_recipes r
    LEFT JOIN public.profiles p1 ON r.created_by = p1.id
    LEFT JOIN public.profiles p2 ON r.updated_by = p2.id
    WHERE r.id = p_recipe_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
