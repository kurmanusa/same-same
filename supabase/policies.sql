-- SAME SAME RLS Policies
-- Row Level Security policies for all tables

-- ============================================================================
-- ENABLE RLS ON ALL TABLES
-- ============================================================================
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE interests ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_interests ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_category_stats ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE chats ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- 1. PROFILES POLICIES
-- ============================================================================

-- Anyone can read profiles (for matching)
CREATE POLICY "Profiles are viewable by everyone"
    ON profiles FOR SELECT
    USING (true);

-- Users can only update their own profile
CREATE POLICY "Users can update own profile"
    ON profiles FOR UPDATE
    USING (auth.uid() = id);

-- Users can insert their own profile
CREATE POLICY "Users can insert own profile"
    ON profiles FOR INSERT
    WITH CHECK (auth.uid() = id);

-- ============================================================================
-- 2. INTERESTS POLICIES
-- ============================================================================

-- Anyone can read interests (master list)
CREATE POLICY "Interests are viewable by everyone"
    ON interests FOR SELECT
    USING (true);

-- Only service role can modify interests (admin only)
-- Note: This is typically handled via service role, not RLS

-- ============================================================================
-- 3. USER_INTERESTS POLICIES
-- ============================================================================

-- Users can read their own interests
CREATE POLICY "Users can view own interests"
    ON user_interests FOR SELECT
    USING (auth.uid() = user_id);

-- Users can insert their own interests
CREATE POLICY "Users can insert own interests"
    ON user_interests FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Users can update their own interests
CREATE POLICY "Users can update own interests"
    ON user_interests FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Users can delete their own interests
CREATE POLICY "Users can delete own interests"
    ON user_interests FOR DELETE
    USING (auth.uid() = user_id);

-- ============================================================================
-- 4. USER_CATEGORY_STATS POLICIES
-- ============================================================================

-- Users can read their own stats
CREATE POLICY "Users can view own category stats"
    ON user_category_stats FOR SELECT
    USING (auth.uid() = user_id);

-- Users can insert their own stats (for triggers)
CREATE POLICY "Users can insert own category stats"
    ON user_category_stats FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Users can update their own stats (for triggers)
CREATE POLICY "Users can update own category stats"
    ON user_category_stats FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- ============================================================================
-- 5. USER_PREFERENCES POLICIES
-- ============================================================================

-- Users can read their own preferences
CREATE POLICY "Users can view own preferences"
    ON user_preferences FOR SELECT
    USING (auth.uid() = user_id);

-- Users can insert their own preferences
CREATE POLICY "Users can insert own preferences"
    ON user_preferences FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Users can update their own preferences
CREATE POLICY "Users can update own preferences"
    ON user_preferences FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Users can delete their own preferences
CREATE POLICY "Users can delete own preferences"
    ON user_preferences FOR DELETE
    USING (auth.uid() = user_id);

-- ============================================================================
-- 6. USER_LIKES POLICIES
-- ============================================================================

-- Users can read likes they sent
CREATE POLICY "Users can view own sent likes"
    ON user_likes FOR SELECT
    USING (auth.uid() = from_user);

-- Users can insert likes (only from themselves)
CREATE POLICY "Users can insert own likes"
    ON user_likes FOR INSERT
    WITH CHECK (auth.uid() = from_user);

-- Users can delete their own likes
CREATE POLICY "Users can delete own likes"
    ON user_likes FOR DELETE
    USING (auth.uid() = from_user);

-- ============================================================================
-- 7. CHATS POLICIES
-- ============================================================================

-- Users can only see chats they are part of
CREATE POLICY "Users can view own chats"
    ON chats FOR SELECT
    USING (auth.uid() = user1 OR auth.uid() = user2);

-- Users can create chats (as user1 or user2)
CREATE POLICY "Users can create chats"
    ON chats FOR INSERT
    WITH CHECK (auth.uid() = user1 OR auth.uid() = user2);

-- Users cannot update chats (immutable)
-- Users cannot delete chats (or add policy if needed)

-- ============================================================================
-- 8. MESSAGES POLICIES
-- ============================================================================

-- Users can only see messages in chats they are part of
CREATE POLICY "Users can view messages in own chats"
    ON messages FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM chats
            WHERE chats.id = messages.chat_id
            AND (chats.user1 = auth.uid() OR chats.user2 = auth.uid())
        )
    );

-- Users can only send messages in chats they are part of
CREATE POLICY "Users can send messages in own chats"
    ON messages FOR INSERT
    WITH CHECK (
        auth.uid() = sender
        AND EXISTS (
            SELECT 1 FROM chats
            WHERE chats.id = messages.chat_id
            AND (chats.user1 = auth.uid() OR chats.user2 = auth.uid())
        )
    );

-- Users can update messages they sent (e.g., mark as read)
CREATE POLICY "Users can update messages in own chats"
    ON messages FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM chats
            WHERE chats.id = messages.chat_id
            AND (chats.user1 = auth.uid() OR chats.user2 = auth.uid())
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM chats
            WHERE chats.id = messages.chat_id
            AND (chats.user1 = auth.uid() OR chats.user2 = auth.uid())
        )
    );

-- Users can delete messages they sent
CREATE POLICY "Users can delete own messages"
    ON messages FOR DELETE
    USING (auth.uid() = sender);

