-- ============================================================
-- Travel Diary Social Features Migration
-- Tables: diary_comments, diary_bookmarks, diary_ratings
-- ALTER: travel_diaries add rating/bookmark columns
-- ============================================================

BEGIN;

-- 1. diary_comments - 评论表
CREATE TABLE IF NOT EXISTS diary_comments (
    id BIGSERIAL PRIMARY KEY,
    diary_id INTEGER NOT NULL REFERENCES travel_diaries(id) ON DELETE CASCADE,
    user_id BIGINT NOT NULL DEFAULT 1,
    content TEXT NOT NULL,
    parent_id BIGINT REFERENCES diary_comments(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_diary_comments_diary_id ON diary_comments(diary_id);
CREATE INDEX IF NOT EXISTS idx_diary_comments_parent_id ON diary_comments(parent_id);
CREATE INDEX IF NOT EXISTS idx_diary_comments_created_at ON diary_comments(created_at DESC);

-- 2. diary_bookmarks - 书签/收藏表
CREATE TABLE IF NOT EXISTS diary_bookmarks (
    id BIGSERIAL PRIMARY KEY,
    diary_id INTEGER NOT NULL REFERENCES travel_diaries(id) ON DELETE CASCADE,
    user_id BIGINT NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(diary_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_diary_bookmarks_diary_id ON diary_bookmarks(diary_id);
CREATE INDEX IF NOT EXISTS idx_diary_bookmarks_user_id ON diary_bookmarks(user_id);

-- 3. diary_ratings - 评分表
CREATE TABLE IF NOT EXISTS diary_ratings (
    id BIGSERIAL PRIMARY KEY,
    diary_id INTEGER NOT NULL REFERENCES travel_diaries(id) ON DELETE CASCADE,
    user_id BIGINT NOT NULL DEFAULT 1,
    score SMALLINT NOT NULL CHECK (score >= 1 AND score <= 5),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(diary_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_diary_ratings_diary_id ON diary_ratings(diary_id);
CREATE INDEX IF NOT EXISTS idx_diary_ratings_user_id ON diary_ratings(user_id);

-- 4. ALTER travel_diaries - 添加评分和收藏计数列
ALTER TABLE travel_diaries ADD COLUMN IF NOT EXISTS rating_score DECIMAL(3,2) DEFAULT 0;
ALTER TABLE travel_diaries ADD COLUMN IF NOT EXISTS rating_count INTEGER DEFAULT 0;
ALTER TABLE travel_diaries ADD COLUMN IF NOT EXISTS bookmark_count INTEGER DEFAULT 0;

CREATE INDEX IF NOT EXISTS idx_diaries_rating_score ON travel_diaries(rating_score DESC);

COMMIT;
