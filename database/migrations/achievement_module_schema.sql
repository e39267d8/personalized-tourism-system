SET client_encoding = 'UTF8';

BEGIN;

CREATE TABLE IF NOT EXISTS achievements (
    id SERIAL PRIMARY KEY,
    code VARCHAR(80) UNIQUE,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    icon_url VARCHAR(500),
    level INTEGER DEFAULT 1,
    type VARCHAR(50) NOT NULL,
    tier INTEGER DEFAULT 1,
    display_order INTEGER DEFAULT 0,
    requirement JSONB NOT NULL,
    reward JSONB,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS user_achievements (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    achievement_id INTEGER NOT NULL REFERENCES achievements(id) ON DELETE CASCADE,
    progress JSONB,
    status VARCHAR(20) DEFAULT 'locked' CHECK (status IN ('locked', 'in_progress', 'unlocked')),
    unlocked_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, achievement_id)
);

CREATE TABLE IF NOT EXISTS digital_collectibles (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    achievement_id INTEGER REFERENCES achievements(id) ON DELETE SET NULL,
    diary_id INTEGER REFERENCES travel_diaries(id) ON DELETE SET NULL,
    token_id VARCHAR(100),
    name VARCHAR(200) NOT NULL,
    description TEXT,
    image_url VARCHAR(500),
    metadata JSONB,
    blockchain_hash VARCHAR(200),
    minted_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE achievements ADD COLUMN IF NOT EXISTS code VARCHAR(80);
ALTER TABLE achievements ADD COLUMN IF NOT EXISTS tier INTEGER DEFAULT 1;
ALTER TABLE achievements ADD COLUMN IF NOT EXISTS display_order INTEGER DEFAULT 0;
ALTER TABLE achievements ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT TRUE;

UPDATE achievements
SET code = 'legacy-' || id::text
WHERE code IS NULL OR code = '';

CREATE TABLE IF NOT EXISTS user_scenic_checkins (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    scenic_spot_id INTEGER NOT NULL REFERENCES scenic_spots(id) ON DELETE CASCADE,
    latitude DECIMAL(10, 7),
    longitude DECIMAL(10, 7),
    verification VARCHAR(20) DEFAULT 'self' CHECK (verification IN ('gps', 'self')),
    distance_meters DECIMAL(10, 2),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, scenic_spot_id)
);

CREATE TABLE IF NOT EXISTS achievement_review_submissions (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    diary_id INTEGER NOT NULL REFERENCES travel_diaries(id) ON DELETE CASCADE,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    reviewer_note TEXT,
    submitted_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    reviewed_at TIMESTAMP WITH TIME ZONE,
    UNIQUE(user_id, diary_id)
);

CREATE TABLE IF NOT EXISTS physical_badge_redemptions (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    achievement_id INTEGER NOT NULL REFERENCES achievements(id) ON DELETE CASCADE,
    recipient_name VARCHAR(80) NOT NULL,
    phone VARCHAR(40) NOT NULL,
    address TEXT NOT NULL,
    note TEXT,
    status VARCHAR(20) DEFAULT 'pending',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, achievement_id)
);

UPDATE physical_badge_redemptions
SET status = CASE
    WHEN status IN ('processing', 'completed') THEN 'approved'
    WHEN status = 'cancelled' THEN 'rejected'
    WHEN status IS NULL OR status = '' THEN 'pending'
    ELSE status
END;

ALTER TABLE physical_badge_redemptions
DROP CONSTRAINT IF EXISTS physical_badge_redemptions_status_check;

ALTER TABLE physical_badge_redemptions
ADD CONSTRAINT physical_badge_redemptions_status_check
CHECK (status IN ('pending', 'approved', 'rejected', 'shipped'));

CREATE UNIQUE INDEX IF NOT EXISTS idx_achievements_code ON achievements(code);
CREATE INDEX IF NOT EXISTS idx_user_achievements_user ON user_achievements(user_id);
CREATE INDEX IF NOT EXISTS idx_user_achievements_status ON user_achievements(status);
CREATE INDEX IF NOT EXISTS idx_checkins_user ON user_scenic_checkins(user_id);
CREATE INDEX IF NOT EXISTS idx_checkins_spot ON user_scenic_checkins(scenic_spot_id);
CREATE INDEX IF NOT EXISTS idx_review_submissions_user ON achievement_review_submissions(user_id);
CREATE INDEX IF NOT EXISTS idx_review_submissions_status ON achievement_review_submissions(status);
CREATE INDEX IF NOT EXISTS idx_badge_redemptions_user ON physical_badge_redemptions(user_id);
CREATE INDEX IF NOT EXISTS idx_badge_redemptions_status ON physical_badge_redemptions(status);
CREATE INDEX IF NOT EXISTS idx_collectibles_user ON digital_collectibles(user_id);
CREATE INDEX IF NOT EXISTS idx_collectibles_token ON digital_collectibles(token_id);

COMMIT;
