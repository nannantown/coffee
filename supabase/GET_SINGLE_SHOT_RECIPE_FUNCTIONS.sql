-- ============================================================================
-- RPC Functions to get single shot/recipe with username
-- ============================================================================
-- These functions fetch individual shots and recipes with creator usernames
-- by JOINing with the profiles table

-- Drop existing functions if they exist
DROP FUNCTION IF EXISTS get_shot_with_username(UUID);
DROP FUNCTION IF EXISTS get_recipe_with_username(UUID);

-- ============================================================================
-- Get single shot with username
-- ============================================================================

CREATE OR REPLACE FUNCTION get_shot_with_username(p_shot_id UUID)
RETURNS TABLE (
    id UUID,
    group_id UUID,
    created_by UUID,
    created_by_username TEXT,
    coffee_weight DECIMAL,
    grinder_setting TEXT,
    extraction_time INTEGER,
    roast_level DECIMAL,
    rating INTEGER,
    extraction_speed TEXT,
    notes TEXT,
    photo_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        s.id,
        s.group_id,
        s.created_by,
        COALESCE(p.username, 'Unknown') as created_by_username,
        s.coffee_weight,
        s.grinder_setting,
        s.extraction_time,
        s.roast_level,
        s.rating,
        s.extraction_speed,
        s.notes,
        s.photo_url,
        s.created_at,
        s.updated_at
    FROM public.espresso_shots s
    LEFT JOIN public.profiles p ON s.created_by = p.id
    WHERE s.id = p_shot_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- Get single recipe with username
-- ============================================================================

CREATE OR REPLACE FUNCTION get_recipe_with_username(p_recipe_id UUID)
RETURNS TABLE (
    id UUID,
    group_id UUID,
    created_by UUID,
    created_by_username TEXT,
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
        COALESCE(p.username, 'Unknown') as created_by_username,
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
    LEFT JOIN public.profiles p ON r.created_by = p.id
    WHERE r.id = p_recipe_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
