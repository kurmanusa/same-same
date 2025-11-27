-- 1. Обновить функции триггеров с SECURITY DEFINER
CREATE OR REPLACE FUNCTION update_profile_rated_count()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE profiles
        SET rated_count = rated_count + 1
        WHERE id = NEW.user_id;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE profiles
        SET rated_count = GREATEST(rated_count - 1, 0)
        WHERE id = OLD.user_id;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_user_category_stats()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_category TEXT;
    v_rated_count INT;
    v_likes_count INT;
    v_dislikes_count INT;
    v_affinity FLOAT;
BEGIN
    SELECT category INTO v_category
    FROM interests
    WHERE id = COALESCE(NEW.interest_id, OLD.interest_id);

    IF v_category IS NULL THEN
        RETURN COALESCE(NEW, OLD);
    END IF;

    SELECT 
        COUNT(*)::INT,
        COUNT(*) FILTER (WHERE value = 1)::INT,
        COUNT(*) FILTER (WHERE value = -1)::INT
    INTO v_rated_count, v_likes_count, v_dislikes_count
    FROM user_interests ui
    JOIN interests i ON ui.interest_id = i.id
    WHERE ui.user_id = COALESCE(NEW.user_id, OLD.user_id)
      AND i.category = v_category;

    IF v_rated_count > 0 THEN
        v_affinity := (v_likes_count::FLOAT - v_dislikes_count::FLOAT) / v_rated_count::FLOAT;
    ELSE
        v_affinity := 0;
    END IF;

    INSERT INTO user_category_stats (user_id, category, rated_count, likes_count, dislikes_count, affinity, updated_at)
    VALUES (COALESCE(NEW.user_id, OLD.user_id), v_category, v_rated_count, v_likes_count, v_dislikes_count, v_affinity, NOW())
    ON CONFLICT (user_id, category)
    DO UPDATE SET
        rated_count = EXCLUDED.rated_count,
        likes_count = EXCLUDED.likes_count,
        dislikes_count = EXCLUDED.dislikes_count,
        affinity = EXCLUDED.affinity,
        updated_at = NOW();

    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- 2. Добавить RLS политики для user_category_stats
-- Сначала удаляем старые политики, если они существуют
DROP POLICY IF EXISTS "Users can insert own category stats" ON user_category_stats;
DROP POLICY IF EXISTS "Users can update own category stats" ON user_category_stats;

-- Создаём новые политики
CREATE POLICY "Users can insert own category stats"
    ON user_category_stats FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own category stats"
    ON user_category_stats FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

