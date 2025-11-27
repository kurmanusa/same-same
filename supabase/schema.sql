-- SAME SAME Database Schema
-- Supabase/PostgreSQL schema for matching system

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";

-- ============================================================================
-- 1. PROFILES TABLE
-- ============================================================================
CREATE TABLE profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    display_name TEXT NOT NULL,
    age INT CHECK (age >= 13 AND age <= 120),
    gender TEXT,
    bio TEXT,
    location_country TEXT,
    location_city TEXT,
    lat DOUBLE PRECISION,
    lng DOUBLE PRECISION,
    languages TEXT[] DEFAULT '{}',
    rated_count INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for profiles
CREATE INDEX idx_profiles_languages ON profiles USING GIN(languages);
CREATE INDEX idx_profiles_location ON profiles(location_country, location_city);
CREATE INDEX idx_profiles_coordinates ON profiles(lat, lng) WHERE lat IS NOT NULL AND lng IS NOT NULL;

-- ============================================================================
-- 2. INTERESTS TABLE
-- ============================================================================
CREATE TABLE interests (
    id BIGSERIAL PRIMARY KEY,
    category TEXT NOT NULL,
    label TEXT NOT NULL,
    popularity FLOAT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(category, label)
);

CREATE INDEX idx_interests_category ON interests(category);
CREATE INDEX idx_interests_popularity ON interests(popularity DESC);

-- ============================================================================
-- 3. USER_INTERESTS TABLE
-- ============================================================================
CREATE TABLE user_interests (
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    interest_id BIGINT NOT NULL REFERENCES interests(id) ON DELETE CASCADE,
    value SMALLINT NOT NULL CHECK (value IN (-1, 1)), -- -1 = dislike, +1 = like
    rated_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (user_id, interest_id)
);

CREATE INDEX idx_user_interests_user ON user_interests(user_id);
CREATE INDEX idx_user_interests_interest ON user_interests(interest_id);
CREATE INDEX idx_user_interests_value ON user_interests(user_id, value);

-- ============================================================================
-- 4. USER_CATEGORY_STATS TABLE
-- ============================================================================
CREATE TABLE user_category_stats (
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    category TEXT NOT NULL,
    rated_count INT DEFAULT 0,
    likes_count INT DEFAULT 0,
    dislikes_count INT DEFAULT 0,
    affinity FLOAT DEFAULT 0, -- (likes - dislikes) / rated_count
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (user_id, category)
);

CREATE INDEX idx_user_category_stats_user ON user_category_stats(user_id);
CREATE INDEX idx_user_category_stats_category ON user_category_stats(category);

-- ============================================================================
-- 5. USER_PREFERENCES TABLE
-- ============================================================================
CREATE TABLE user_preferences (
    user_id UUID PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
    preferred_genders TEXT[] DEFAULT '{}',
    age_min INT CHECK (age_min >= 13),
    age_max INT CHECK (age_max <= 120),
    radius_km INT DEFAULT 50 CHECK (radius_km > 0),
    min_match_percent INT DEFAULT 0 CHECK (min_match_percent >= 0 AND min_match_percent <= 100),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- 6. USER_LIKES TABLE
-- ============================================================================
CREATE TABLE user_likes (
    from_user UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    to_user UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (from_user, to_user),
    CHECK (from_user != to_user)
);

CREATE INDEX idx_user_likes_from ON user_likes(from_user);
CREATE INDEX idx_user_likes_to ON user_likes(to_user);

-- ============================================================================
-- 7. CHATS TABLE
-- ============================================================================
CREATE TABLE chats (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user1 UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    user2 UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user1, user2),
    CHECK (user1 != user2)
);

CREATE INDEX idx_chats_user1 ON chats(user1);
CREATE INDEX idx_chats_user2 ON chats(user2);

-- ============================================================================
-- 8. MESSAGES TABLE
-- ============================================================================
CREATE TABLE messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    chat_id UUID NOT NULL REFERENCES chats(id) ON DELETE CASCADE,
    sender UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    text TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    read_at TIMESTAMPTZ
);

CREATE INDEX idx_messages_chat ON messages(chat_id, created_at);
CREATE INDEX idx_messages_sender ON messages(sender);
CREATE INDEX idx_messages_unread ON messages(chat_id, read_at) WHERE read_at IS NULL;

-- ============================================================================
-- TRIGGERS
-- ============================================================================

-- Function to update profiles.rated_count
-- SECURITY DEFINER allows the function to run with the privileges of the function owner
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

CREATE TRIGGER trigger_update_profile_rated_count
    AFTER INSERT OR DELETE ON user_interests
    FOR EACH ROW
    EXECUTE FUNCTION update_profile_rated_count();

-- Function to update user_category_stats
-- SECURITY DEFINER allows the function to run with the privileges of the function owner
-- This bypasses RLS checks, allowing the trigger to update stats automatically
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
    -- Get category from interest
    SELECT category INTO v_category
    FROM interests
    WHERE id = COALESCE(NEW.interest_id, OLD.interest_id);

    IF v_category IS NULL THEN
        RETURN COALESCE(NEW, OLD);
    END IF;

    -- Calculate stats for the category
    SELECT 
        COUNT(*)::INT,
        COUNT(*) FILTER (WHERE value = 1)::INT,
        COUNT(*) FILTER (WHERE value = -1)::INT
    INTO v_rated_count, v_likes_count, v_dislikes_count
    FROM user_interests ui
    JOIN interests i ON ui.interest_id = i.id
    WHERE ui.user_id = COALESCE(NEW.user_id, OLD.user_id)
      AND i.category = v_category;

    -- Calculate affinity
    IF v_rated_count > 0 THEN
        v_affinity := (v_likes_count::FLOAT - v_dislikes_count::FLOAT) / v_rated_count::FLOAT;
    ELSE
        v_affinity := 0;
    END IF;

    -- Insert or update stats
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

CREATE TRIGGER trigger_update_user_category_stats
    AFTER INSERT OR UPDATE OR DELETE ON user_interests
    FOR EACH ROW
    EXECUTE FUNCTION update_user_category_stats();

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_profiles_updated_at
    BEFORE UPDATE ON profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_user_preferences_updated_at
    BEFORE UPDATE ON user_preferences
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

