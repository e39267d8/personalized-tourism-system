-- =====================================================
-- 个性化旅游系统 - 数据库迁移脚本 v1 -> v2
-- =====================================================
-- 用途：将 v1 schema 升级到 v2
-- 使用前请备份数据库！
-- =====================================================

BEGIN;

-- =====================================================
-- 0. 确保扩展已启用
-- =====================================================
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- 1. 刷新令牌表
-- =====================================================
CREATE TABLE IF NOT EXISTS refresh_tokens (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    token VARCHAR(500) NOT NULL UNIQUE,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    revoked BOOLEAN DEFAULT FALSE
);

CREATE INDEX IF NOT EXISTS idx_refresh_tokens_user ON refresh_tokens (user_id);
CREATE INDEX IF NOT EXISTS idx_refresh_tokens_token ON refresh_tokens (token);
CREATE INDEX IF NOT EXISTS idx_refresh_tokens_expires ON refresh_tokens (expires_at);

-- =====================================================
-- 2. 用户表升级
-- =====================================================
-- 添加缺失字段
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'phone') THEN
        ALTER TABLE users ADD COLUMN phone VARCHAR(20);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'nickname') THEN
        ALTER TABLE users ADD COLUMN nickname VARCHAR(50);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'avatar_url') THEN
        ALTER TABLE users ADD COLUMN avatar_url VARCHAR(500);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'gender') THEN
        ALTER TABLE users ADD COLUMN gender SMALLINT DEFAULT 0;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'birth_date') THEN
        ALTER TABLE users ADD COLUMN birth_date DATE;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'status') THEN
        ALTER TABLE users ADD COLUMN status SMALLINT DEFAULT 1;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'last_login_at') THEN
        ALTER TABLE users ADD COLUMN last_login_at TIMESTAMP WITH TIME ZONE;
    END IF;
END $$;

-- 添加约束
ALTER TABLE users ALTER COLUMN email SET NOT NULL;
ALTER TABLE users ADD CONSTRAINT users_email_unique UNIQUE (email);
ALTER TABLE users ADD CONSTRAINT users_gender_check CHECK (gender IN (0, 1, 2));
ALTER TABLE users ADD CONSTRAINT users_status_check CHECK (status IN (0, 1, 2));

-- 添加索引
CREATE INDEX IF NOT EXISTS idx_users_phone ON users(phone);
CREATE INDEX IF NOT EXISTS idx_users_status ON users(status);

-- =====================================================
-- 3. 景点分类表
-- =====================================================
CREATE TABLE IF NOT EXISTS categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    description TEXT,
    icon VARCHAR(50),
    parent_id INTEGER REFERENCES categories(id) ON DELETE SET NULL,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_categories_parent ON categories(parent_id);

-- =====================================================
-- 4. 景点表升级
-- =====================================================
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'scenic_spots' AND column_name = 'category_id') THEN
        ALTER TABLE scenic_spots ADD COLUMN category_id INTEGER REFERENCES categories(id) ON DELETE SET NULL;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'scenic_spots' AND column_name = 'rating_count') THEN
        ALTER TABLE scenic_spots ADD COLUMN rating_count INTEGER DEFAULT 0;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'scenic_spots' AND column_name = 'city') THEN
        ALTER TABLE scenic_spots ADD COLUMN city VARCHAR(50);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'scenic_spots' AND column_name = 'duration_minutes') THEN
        ALTER TABLE scenic_spots ADD COLUMN duration_minutes INTEGER;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'scenic_spots' AND column_name = 'crowd_level') THEN
        ALTER TABLE scenic_spots ADD COLUMN crowd_level SMALLINT DEFAULT 2;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'scenic_spots' AND column_name = 'images') THEN
        ALTER TABLE scenic_spots ADD COLUMN images TEXT[];
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'scenic_spots' AND column_name = 'thumbnail_url') THEN
        ALTER TABLE scenic_spots ADD COLUMN thumbnail_url VARCHAR(500);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'scenic_spots' AND column_name = 'view_count') THEN
        ALTER TABLE scenic_spots ADD COLUMN view_count INTEGER DEFAULT 0;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'scenic_spots' AND column_name = 'favorite_count') THEN
        ALTER TABLE scenic_spots ADD COLUMN favorite_count INTEGER DEFAULT 0;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'scenic_spots' AND column_name = 'tags') THEN
        ALTER TABLE scenic_spots ADD COLUMN tags TEXT[];
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'scenic_spots' AND column_name = 'status') THEN
        ALTER TABLE scenic_spots ADD COLUMN status SMALLINT DEFAULT 1;
    END IF;
END $$;

-- 添加约束
ALTER TABLE scenic_spots ADD CONSTRAINT scenic_spots_rating_check CHECK (rating >= 0 AND rating <= 5);
ALTER TABLE scenic_spots ADD CONSTRAINT scenic_spots_crowd_check CHECK (crowd_level BETWEEN 1 AND 4);

-- 添加索引
CREATE INDEX IF NOT EXISTS idx_scenic_spots_category ON scenic_spots(category_id);
CREATE INDEX IF NOT EXISTS idx_scenic_spots_rating ON scenic_spots(rating DESC);
CREATE INDEX IF NOT EXISTS idx_scenic_spots_city ON scenic_spots(city);
CREATE INDEX IF NOT EXISTS idx_scenic_spots_crowd ON scenic_spots(crowd_level);
CREATE INDEX IF NOT EXISTS idx_scenic_spots_status ON scenic_spots(status);
CREATE INDEX IF NOT EXISTS idx_scenic_spots_tags ON scenic_spots USING GIN(tags);

-- =====================================================
-- 5. 图节点表升级
-- =====================================================
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'graph_nodes' AND column_name = 'facility_id') THEN
        ALTER TABLE graph_nodes ADD COLUMN facility_id INTEGER REFERENCES facilities(id) ON DELETE SET NULL;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'graph_nodes' AND column_name = 'congestion_level') THEN
        ALTER TABLE graph_nodes ADD COLUMN congestion_level SMALLINT DEFAULT 2;
    END IF;
END $$;

ALTER TABLE graph_nodes ADD CONSTRAINT graph_nodes_congestion_check CHECK (congestion_level BETWEEN 1 AND 4);
CREATE INDEX IF NOT EXISTS idx_graph_nodes_congestion ON graph_nodes(congestion_level);

-- =====================================================
-- 6. 图边表升级
-- =====================================================
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'graph_edges' AND column_name = 'congestion_level') THEN
        ALTER TABLE graph_edges ADD COLUMN congestion_level SMALLINT DEFAULT 2;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'graph_edges' AND column_name = 'updated_at') THEN
        ALTER TABLE graph_edges ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP;
    END IF;
END $$;

ALTER TABLE graph_edges ADD CONSTRAINT graph_edges_congestion_check CHECK (congestion_level BETWEEN 1 AND 4);
CREATE INDEX IF NOT EXISTS idx_edges_congestion ON graph_edges(congestion_level);

-- =====================================================
-- 7. 游记表升级
-- =====================================================
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'travel_diaries' AND column_name = 'summary') THEN
        ALTER TABLE travel_diaries ADD COLUMN summary TEXT;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'travel_diaries' AND column_name = 'status') THEN
        ALTER TABLE travel_diaries ADD COLUMN status SMALLINT DEFAULT 1;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'travel_diaries' AND column_name = 'start_date') THEN
        ALTER TABLE travel_diaries ADD COLUMN start_date DATE;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'travel_diaries' AND column_name = 'end_date') THEN
        ALTER TABLE travel_diaries ADD COLUMN end_date DATE;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'travel_diaries' AND column_name = 'total_distance_km') THEN
        ALTER TABLE travel_diaries ADD COLUMN total_distance_km DECIMAL(10,2);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'travel_diaries' AND column_name = 'view_count') THEN
        ALTER TABLE travel_diaries ADD COLUMN view_count INTEGER DEFAULT 0;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'travel_diaries' AND column_name = 'like_count') THEN
        ALTER TABLE travel_diaries ADD COLUMN like_count INTEGER DEFAULT 0;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'travel_diaries' AND column_name = 'comment_count') THEN
        ALTER TABLE travel_diaries ADD COLUMN comment_count INTEGER DEFAULT 0;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'travel_diaries' AND column_name = 'aigc_summary') THEN
        ALTER TABLE travel_diaries ADD COLUMN aigc_summary TEXT;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'travel_diaries' AND column_name = 'aigc_title') THEN
        ALTER TABLE travel_diaries ADD COLUMN aigc_title TEXT;
    END IF;
END $$;

ALTER TABLE travel_diaries ADD CONSTRAINT diaries_status_check CHECK (status IN (0, 1, 2));
CREATE INDEX IF NOT EXISTS idx_diaries_status ON travel_diaries(status);
CREATE INDEX IF NOT EXISTS idx_diaries_created ON travel_diaries(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_diaries_view_count ON travel_diaries(view_count DESC);

-- 游记点赞表
CREATE TABLE IF NOT EXISTS diary_likes (
    id BIGSERIAL PRIMARY KEY,
    diary_id INTEGER NOT NULL REFERENCES travel_diaries(id) ON DELETE CASCADE,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(diary_id, user_id)
);

-- =====================================================
-- 8. 评价表升级
-- =====================================================
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'reviews' AND column_name = 'images') THEN
        ALTER TABLE reviews ADD COLUMN images TEXT[];
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'reviews' AND column_name = 'helpful_count') THEN
        ALTER TABLE reviews ADD COLUMN helpful_count INTEGER DEFAULT 0;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'reviews' AND column_name = 'status') THEN
        ALTER TABLE reviews ADD COLUMN status SMALLINT DEFAULT 1;
    END IF;
END $$;

ALTER TABLE reviews ADD CONSTRAINT reviews_status_check CHECK (status IN (0, 1, 2));
CREATE INDEX IF NOT EXISTS idx_reviews_rating ON reviews(rating DESC);
CREATE INDEX IF NOT EXISTS idx_reviews_helpful ON reviews(helpful_count DESC);
CREATE INDEX IF NOT EXISTS idx_reviews_created ON reviews(created_at DESC);

-- 评价点赞表
CREATE TABLE IF NOT EXISTS review_helpful (
    id BIGSERIAL PRIMARY KEY,
    review_id INTEGER NOT NULL REFERENCES reviews(id) ON DELETE CASCADE,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(review_id, user_id)
);

-- =====================================================
-- 9. 用户偏好表
-- =====================================================
CREATE TABLE IF NOT EXISTS user_preferences (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    preference_type VARCHAR(50) NOT NULL,
    preference_value JSONB NOT NULL,
    weight DECIMAL(3,2) DEFAULT 1.0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, preference_type)
);

CREATE INDEX IF NOT EXISTS idx_user_preferences_user ON user_preferences(user_id);
CREATE INDEX IF NOT EXISTS idx_user_preferences_type ON user_preferences(preference_type);

-- =====================================================
-- 10. 用户收藏表
-- =====================================================
CREATE TABLE IF NOT EXISTS user_favorites (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    scenic_spot_id BIGINT NOT NULL REFERENCES scenic_spots(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, scenic_spot_id)
);

CREATE INDEX IF NOT EXISTS idx_favorites_user ON user_favorites(user_id);
CREATE INDEX IF NOT EXISTS idx_favorites_spot ON user_favorites(scenic_spot_id);

-- =====================================================
-- 11. 路径规划记录表
-- =====================================================
CREATE TABLE IF NOT EXISTS route_plans (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT REFERENCES users(id) ON DELETE SET NULL,
    title VARCHAR(200),
    start_node_id INTEGER REFERENCES graph_nodes(id),
    end_node_id INTEGER REFERENCES graph_nodes(id),
    waypoint_node_ids INTEGER[],
    travel_mode VARCHAR(20) DEFAULT 'walk',
    total_distance DECIMAL(10,2),
    total_duration INTEGER,
    route_geometry JSONB,
    optimization_type VARCHAR(20) DEFAULT 'time',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_route_plans_user ON route_plans(user_id);
CREATE INDEX IF NOT EXISTS idx_route_plans_created ON route_plans(created_at DESC);

-- =====================================================
-- 12. 成就表和用户成就表（如果不存在）
-- =====================================================
CREATE TABLE IF NOT EXISTS achievements (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    icon_url VARCHAR(500),
    level INTEGER DEFAULT 1,
    type VARCHAR(50) NOT NULL,
    requirement JSONB NOT NULL,
    reward JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS user_achievements (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    achievement_id INTEGER NOT NULL REFERENCES achievements(id) ON DELETE CASCADE,
    progress JSONB,
    status VARCHAR(20) DEFAULT 'locked',
    unlocked_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, achievement_id)
);

CREATE INDEX IF NOT EXISTS idx_user_achievements_user ON user_achievements(user_id);
CREATE INDEX IF NOT EXISTS idx_user_achievements_status ON user_achievements(status);

-- =====================================================
-- 13. 数字藏品表（如果不存在）
-- =====================================================
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

CREATE INDEX IF NOT EXISTS idx_collectibles_user ON digital_collectibles(user_id);
CREATE INDEX IF NOT EXISTS idx_collectibles_token ON digital_collectibles(token_id);

-- =====================================================
-- 14. 设施表升级
-- =====================================================
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'facilities' AND column_name = 'opening_hours') THEN
        ALTER TABLE facilities ADD COLUMN opening_hours VARCHAR(100);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'facilities' AND column_name = 'phone') THEN
        ALTER TABLE facilities ADD COLUMN phone VARCHAR(20);
    END IF;
END $$;

-- =====================================================
-- 15. 触发器
-- =====================================================
-- updated_at 触发器函数
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 为已有表添加触发器
DROP TRIGGER IF EXISTS update_users_updated_at ON users;
CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_scenic_spots_updated_at ON scenic_spots;
CREATE TRIGGER update_scenic_spots_updated_at
    BEFORE UPDATE ON scenic_spots
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_travel_diaries_updated_at ON travel_diaries;
CREATE TRIGGER update_travel_diaries_updated_at
    BEFORE UPDATE ON travel_diaries
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_reviews_updated_at ON reviews;
CREATE TRIGGER update_reviews_updated_at
    BEFORE UPDATE ON reviews
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 全文搜索触发器
CREATE OR REPLACE FUNCTION update_scenic_spots_search_vector()
RETURNS TRIGGER AS $$
BEGIN
    NEW.search_vector = 
        setweight(to_tsvector('simple', COALESCE(NEW.name, '')), 'A') ||
        setweight(to_tsvector('simple', COALESCE(NEW.description, '')), 'B') ||
        setweight(to_tsvector('simple', COALESCE(NEW.city, '')), 'C') ||
        setweight(to_tsvector('simple', COALESCE(array_to_string(NEW.tags, ' '), '')), 'D');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_scenic_spots_search_vector ON scenic_spots;
CREATE TRIGGER update_scenic_spots_search_vector
    BEFORE INSERT OR UPDATE ON scenic_spots
    FOR EACH ROW EXECUTE FUNCTION update_scenic_spots_search_vector();

CREATE OR REPLACE FUNCTION update_travel_diaries_search_vector()
RETURNS TRIGGER AS $$
BEGIN
    NEW.search_vector = 
        setweight(to_tsvector('simple', COALESCE(NEW.title, '')), 'A') ||
        setweight(to_tsvector('simple', COALESCE(NEW.content, '')), 'B') ||
        setweight(to_tsvector('simple', COALESCE(NEW.summary, '')), 'C') ||
        setweight(to_tsvector('simple', COALESCE(array_to_string(NEW.tags, ' '), '')), 'D');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_travel_diaries_search_vector ON travel_diaries;
CREATE TRIGGER update_travel_diaries_search_vector
    BEFORE INSERT OR UPDATE ON travel_diaries
    FOR EACH ROW EXECUTE FUNCTION update_travel_diaries_search_vector();

-- 更新已有数据的 search_vector
UPDATE scenic_spots SET search_vector = 
    setweight(to_tsvector('simple', COALESCE(name, '')), 'A') ||
    setweight(to_tsvector('simple', COALESCE(description, '')), 'B') ||
    setweight(to_tsvector('simple', COALESCE(city, '')), 'C') ||
    setweight(to_tsvector('simple', COALESCE(array_to_string(tags, ' '), '')), 'D')
WHERE search_vector IS NULL;

UPDATE travel_diaries SET search_vector = 
    setweight(to_tsvector('simple', COALESCE(title, '')), 'A') ||
    setweight(to_tsvector('simple', COALESCE(content, '')), 'B') ||
    setweight(to_tsvector('simple', COALESCE(summary, '')), 'C') ||
    setweight(to_tsvector('simple', COALESCE(array_to_string(tags, ' '), '')), 'D')
WHERE search_vector IS NULL;

COMMIT;

-- =====================================================
-- 完成提示
-- =====================================================
DO $$
BEGIN
    RAISE NOTICE '============================================';
    RAISE NOTICE '数据库迁移完成！';
    RAISE NOTICE '============================================';
    RAISE NOTICE '已完成的升级：';
    RAISE NOTICE '  - users 表：添加 phone, nickname, avatar_url, gender, birth_date, status, last_login_at';
    RAISE NOTICE '  - scenic_spots 表：添加 category_id, rating_count, city, duration_minutes, crowd_level, images, thumbnail_url, view_count, favorite_count, status';
    RAISE NOTICE '  - graph_nodes 表：添加 facility_id, congestion_level';
    RAISE NOTICE '  - graph_edges 表：添加 congestion_level, updated_at';
    RAISE NOTICE '  - travel_diaries 表：添加 summary, status, start_date, end_date, total_distance_km, view_count, like_count, comment_count, aigc_summary, aigc_title';
    RAISE NOTICE '  - reviews 表：添加 images, helpful_count, status';
    RAISE NOTICE '  - 新增表：categories, user_preferences, user_favorites, route_plans, refresh_tokens, diary_likes, review_helpful';
    RAISE NOTICE '  - 新增触发器：updated_at 自动更新、search_vector 自动更新';
    RAISE NOTICE '============================================';
END $$;
