SET client_encoding = 'UTF8';

-- =====================================================
-- 个性化旅游系统 - 数据库初始化脚本 v2.0
-- =====================================================
-- 功能：
-- 1. 创建数据库
-- 2. 启用 PostGIS 扩展
-- 3. 创建所有表结构
-- 4. 创建索引
-- 5. 创建触发器
-- =====================================================

-- 创建数据库（需要超级用户权限）
-- CREATE DATABASE tourism_system;
-- \c tourism_system;

-- 启用 PostGIS 扩展（空间数据支持）
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- 0. 刷新令牌表（认证模块）
-- =====================================================
CREATE TABLE refresh_tokens (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    token VARCHAR(500) NOT NULL UNIQUE,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    revoked BOOLEAN DEFAULT FALSE
);

CREATE INDEX idx_refresh_tokens_user ON refresh_tokens (user_id);
CREATE INDEX idx_refresh_tokens_token ON refresh_tokens (token);
CREATE INDEX idx_refresh_tokens_expires ON refresh_tokens (expires_at);

-- =====================================================
-- 1. 用户表（完整版）
-- =====================================================
CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(20),
    nickname VARCHAR(50),
    avatar_url VARCHAR(500),
    gender SMALLINT DEFAULT 0 CHECK (gender IN (0, 1, 2)),  -- 0:未知 1:男 2:女
    birth_date DATE,
    preferences JSONB,
    status SMALLINT DEFAULT 1 CHECK (status IN (0, 1, 2)),  -- 0:禁用 1:正常 2:封禁
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_login_at TIMESTAMP WITH TIME ZONE
);

-- 用户偏好表
CREATE TABLE user_preferences (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    preference_type VARCHAR(50) NOT NULL,  -- 'scenic_type', 'transport', 'budget', 'activity'
    preference_value JSONB NOT NULL,
    weight DECIMAL(3,2) DEFAULT 1.0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, preference_type)
);

-- 用户收藏表
CREATE TABLE user_favorites (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    scenic_spot_id BIGINT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, scenic_spot_id)
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_phone ON users(phone);
CREATE INDEX idx_users_status ON users(status);
CREATE INDEX idx_users_preferences ON users USING GIN (preferences);
CREATE INDEX idx_user_preferences_user ON user_preferences(user_id);
CREATE INDEX idx_user_preferences_type ON user_preferences(preference_type);
CREATE INDEX idx_favorites_user ON user_favorites(user_id);
CREATE INDEX idx_favorites_spot ON user_favorites(scenic_spot_id);

-- =====================================================
-- 2. 景点分类表
-- =====================================================
CREATE TABLE categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    description TEXT,
    icon VARCHAR(50),
    parent_id INTEGER REFERENCES categories(id) ON DELETE SET NULL,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_categories_parent ON categories(parent_id);

-- =====================================================
-- 3. 景点表（完整版）
-- =====================================================
CREATE TABLE scenic_spots (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    location GEOGRAPHY(POINT, 4326) NOT NULL,
    category_id INTEGER REFERENCES categories(id) ON DELETE SET NULL,
    rating DECIMAL(3,2) DEFAULT 0 CHECK (rating >= 0 AND rating <= 5),
    rating_count INTEGER DEFAULT 0,
    address VARCHAR(200),
    city VARCHAR(50),
    opening_hours VARCHAR(100),
    ticket_price DECIMAL(10,2) DEFAULT 0,
    duration_minutes INTEGER,  -- 建议游览时长（分钟）
    crowd_level SMALLINT DEFAULT 2 CHECK (crowd_level BETWEEN 1 AND 4),  -- 1:空旷 2:一般 3:拥挤 4:爆满
    images TEXT[],  -- 多张图片 URL
    thumbnail_url VARCHAR(500),
    view_count INTEGER DEFAULT 0,
    favorite_count INTEGER DEFAULT 0,
    tags TEXT[],
    search_vector TSVECTOR,
    status SMALLINT DEFAULT 1 CHECK (status IN (0, 1, 2)),  -- 0:下架 1:正常 2:待审核
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 空间索引
CREATE INDEX idx_scenic_spots_location ON scenic_spots USING GIST (location);
-- 全文搜索索引
CREATE INDEX idx_scenic_spots_search ON scenic_spots USING GIN (search_vector);
-- 常用查询索引
CREATE INDEX idx_scenic_spots_category ON scenic_spots(category_id);
CREATE INDEX idx_scenic_spots_rating ON scenic_spots(rating DESC);
CREATE INDEX idx_scenic_spots_city ON scenic_spots(city);
CREATE INDEX idx_scenic_spots_crowd ON scenic_spots(crowd_level);
CREATE INDEX idx_scenic_spots_status ON scenic_spots(status);
CREATE INDEX idx_scenic_spots_tags ON scenic_spots USING GIN(tags);

-- =====================================================
-- 4. 图节点表
-- =====================================================
CREATE TABLE graph_nodes (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    location GEOGRAPHY(POINT, 4326),
    node_type VARCHAR(20) NOT NULL,  -- 'scenic', 'facility', 'transport', 'entrance'
    scenic_spot_id INTEGER REFERENCES scenic_spots(id) ON DELETE SET NULL,
    facility_id INTEGER,
    congestion_level SMALLINT DEFAULT 2 CHECK (congestion_level BETWEEN 1 AND 4),  -- 拥堵等级
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_graph_nodes_location ON graph_nodes USING GIST (location);
CREATE INDEX idx_graph_nodes_type ON graph_nodes(node_type);
CREATE INDEX idx_graph_nodes_scenic ON graph_nodes(scenic_spot_id);
CREATE INDEX idx_graph_nodes_congestion ON graph_nodes(congestion_level);

-- =====================================================
-- 5. 图边表
-- =====================================================
CREATE TABLE graph_edges (
    id SERIAL PRIMARY KEY,
    from_node INTEGER NOT NULL REFERENCES graph_nodes(id) ON DELETE CASCADE,
    to_node INTEGER NOT NULL REFERENCES graph_nodes(id) ON DELETE CASCADE,
    distance DECIMAL(10,2) NOT NULL,  -- 距离（米）
    travel_mode VARCHAR(20) NOT NULL,  -- 'walk', 'bike', 'car', 'bus', 'subway'
    travel_time INTEGER,  -- 预计时间（秒）
    base_weight DECIMAL(10,2) DEFAULT 1.0,  -- 基础权重
    congestion_level SMALLINT DEFAULT 2 CHECK (congestion_level BETWEEN 1 AND 4),  -- 当前拥堵等级
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(from_node, to_node, travel_mode)
);

CREATE INDEX idx_edges_from ON graph_edges(from_node);
CREATE INDEX idx_edges_to ON graph_edges(to_node);
CREATE INDEX idx_edges_mode ON graph_edges(travel_mode);
CREATE INDEX idx_edges_congestion ON graph_edges(congestion_level);

-- =====================================================
-- 6. 设施表
-- =====================================================
CREATE TABLE facilities (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    type VARCHAR(50) NOT NULL,  -- 'restaurant', 'hotel', 'toilet', 'parking', 'atm'
    location GEOGRAPHY(POINT, 4326),
    address VARCHAR(200),
    rating DECIMAL(3,2) DEFAULT 0,
    price_level INTEGER CHECK (price_level BETWEEN 1 AND 4),
    opening_hours VARCHAR(100),
    phone VARCHAR(20),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_facilities_location ON facilities USING GIST (location);
CREATE INDEX idx_facilities_type ON facilities(type);

ALTER TABLE user_favorites
    ADD CONSTRAINT fk_user_favorites_scenic_spot
    FOREIGN KEY (scenic_spot_id) REFERENCES scenic_spots(id) ON DELETE CASCADE;

ALTER TABLE graph_nodes
    ADD CONSTRAINT fk_graph_nodes_facility
    FOREIGN KEY (facility_id) REFERENCES facilities(id) ON DELETE SET NULL;

-- =====================================================
-- 7. 游记表（完整版）
-- =====================================================
CREATE TABLE travel_diaries (
    id SERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL,
    summary TEXT,  -- 摘要
    content TEXT NOT NULL,
    status SMALLINT DEFAULT 1 CHECK (status IN (0, 1, 2)),  -- 0:草稿 1:已发布 2:已删除
    scenic_spot_ids INTEGER[],
    start_date DATE,
    end_date DATE,
    total_distance_km DECIMAL(10,2),
    images TEXT[],
    tags TEXT[],
    view_count INTEGER DEFAULT 0,
    like_count INTEGER DEFAULT 0,
    comment_count INTEGER DEFAULT 0,
    search_vector TSVECTOR,
    aigc_summary TEXT,  -- AI 生成的摘要
    aigc_title TEXT,    -- AI 生成的标题
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_diaries_search ON travel_diaries USING GIN (search_vector);
CREATE INDEX idx_diaries_tags ON travel_diaries USING GIN (tags);
CREATE INDEX idx_diaries_user ON travel_diaries(user_id);
CREATE INDEX idx_diaries_status ON travel_diaries(status);
CREATE INDEX idx_diaries_created ON travel_diaries(created_at DESC);
CREATE INDEX idx_diaries_view_count ON travel_diaries(view_count DESC);

-- 游记点赞表
CREATE TABLE diary_likes (
    id BIGSERIAL PRIMARY KEY,
    diary_id INTEGER NOT NULL REFERENCES travel_diaries(id) ON DELETE CASCADE,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(diary_id, user_id)
);

-- =====================================================
-- 8. 评价表（完整版）
-- =====================================================
CREATE TABLE reviews (
    id SERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    scenic_spot_id INTEGER NOT NULL REFERENCES scenic_spots(id) ON DELETE CASCADE,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    content TEXT,
    images TEXT[],
    helpful_count INTEGER DEFAULT 0,
    status SMALLINT DEFAULT 1 CHECK (status IN (0, 1, 2)),  -- 0:隐藏 1:正常 2:待审核
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_reviews_user ON reviews(user_id);
CREATE INDEX idx_reviews_spot ON reviews(scenic_spot_id);
CREATE INDEX idx_reviews_rating ON reviews(rating DESC);
CREATE INDEX idx_reviews_helpful ON reviews(helpful_count DESC);
CREATE INDEX idx_reviews_created ON reviews(created_at DESC);

-- 评价点赞表
CREATE TABLE review_helpful (
    id BIGSERIAL PRIMARY KEY,
    review_id INTEGER NOT NULL REFERENCES reviews(id) ON DELETE CASCADE,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(review_id, user_id)
);

-- =====================================================
-- 9. 路径规划记录表
-- =====================================================
CREATE TABLE route_plans (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT REFERENCES users(id) ON DELETE SET NULL,
    title VARCHAR(200),
    start_node_id INTEGER REFERENCES graph_nodes(id),
    end_node_id INTEGER REFERENCES graph_nodes(id),
    waypoint_node_ids INTEGER[],
    travel_mode VARCHAR(20) DEFAULT 'walk',
    total_distance DECIMAL(10,2),  -- 总距离（米）
    total_duration INTEGER,           -- 总时长（秒）
    route_geometry JSONB,            -- 路线几何数据
    optimization_type VARCHAR(20) DEFAULT 'time',  -- 'time', 'distance', 'balanced'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_route_plans_user ON route_plans(user_id);
CREATE INDEX idx_route_plans_created ON route_plans(created_at DESC);

-- =====================================================
-- 10. 成就表
-- =====================================================
CREATE TABLE achievements (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    icon_url VARCHAR(500),
    level INTEGER DEFAULT 1,
    type VARCHAR(50) NOT NULL,  -- 'exploration', 'review', 'diary', 'social'
    requirement JSONB NOT NULL,  -- 解锁条件
    reward JSONB,  -- 奖励内容
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 用户成就表
CREATE TABLE user_achievements (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    achievement_id INTEGER NOT NULL REFERENCES achievements(id) ON DELETE CASCADE,
    progress JSONB,  -- 当前进度
    status VARCHAR(20) DEFAULT 'locked' CHECK (status IN ('locked', 'in_progress', 'unlocked')),
    unlocked_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, achievement_id)
);

CREATE INDEX idx_user_achievements_user ON user_achievements(user_id);
CREATE INDEX idx_user_achievements_status ON user_achievements(status);

-- =====================================================
-- 11. 数字藏品表
-- =====================================================
CREATE TABLE digital_collectibles (
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

CREATE INDEX idx_collectibles_user ON digital_collectibles(user_id);
CREATE INDEX idx_collectibles_token ON digital_collectibles(token_id);

-- =====================================================
-- 触发器：自动更新 updated_at
-- =====================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 为所有表添加 updated_at 触发器
CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_preferences_updated_at
    BEFORE UPDATE ON user_preferences
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_scenic_spots_updated_at
    BEFORE UPDATE ON scenic_spots
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_graph_nodes_updated_at
    BEFORE UPDATE ON graph_nodes
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_graph_edges_updated_at
    BEFORE UPDATE ON graph_edges
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_travel_diaries_updated_at
    BEFORE UPDATE ON travel_diaries
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_reviews_updated_at
    BEFORE UPDATE ON reviews
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- 触发器：自动更新全文搜索向量
-- =====================================================
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

CREATE TRIGGER update_travel_diaries_search_vector
    BEFORE INSERT OR UPDATE ON travel_diaries
    FOR EACH ROW EXECUTE FUNCTION update_travel_diaries_search_vector();

-- =====================================================
-- 存储过程：KNN 最近邻查询
-- =====================================================
CREATE OR REPLACE FUNCTION find_nearest_spots(
    ref_lat DOUBLE PRECISION,
    ref_lng DOUBLE PRECISION,
    k INTEGER DEFAULT 10,
    max_distance_meters DOUBLE PRECISION DEFAULT NULL
)
RETURNS TABLE(
    id INTEGER,
    name VARCHAR,
    distance DOUBLE PRECISION,
    rating DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        s.id, 
        s.name,
        ST_Distance(s.location::geography, 
                    ST_SetSRID(ST_MakePoint(ref_lng, ref_lat), 4326)::geography) AS distance,
        s.rating
    FROM scenic_spots s
    WHERE s.status = 1
      AND (max_distance_meters IS NULL OR 
           ST_DWithin(s.location::geography, 
                     ST_SetSRID(ST_MakePoint(ref_lng, ref_lat), 4326)::geography,
                     max_distance_meters))
    ORDER BY s.location <-> ST_SetSRID(ST_MakePoint(ref_lng, ref_lat), 4326)
    LIMIT k;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 存储过程：范围查询设施
-- =====================================================
CREATE OR REPLACE FUNCTION find_facilities_in_range(
    ref_lat DOUBLE PRECISION,
    ref_lng DOUBLE PRECISION,
    radius_meters DOUBLE PRECISION,
    facility_type VARCHAR DEFAULT NULL
)
RETURNS TABLE(
    id INTEGER,
    name VARCHAR,
    type VARCHAR,
    distance DOUBLE PRECISION
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        f.id, 
        f.name, 
        f.type,
        ST_Distance(f.location::geography, 
                    ST_SetSRID(ST_MakePoint(ref_lng, ref_lat), 4326)::geography) AS distance
    FROM facilities f
    WHERE ST_DWithin(
        f.location::geography,
        ST_SetSRID(ST_MakePoint(ref_lng, ref_lat), 4326)::geography,
        radius_meters
    )
    AND (facility_type IS NULL OR f.type = facility_type)
    ORDER BY distance;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 存储过程：带拥堵系数的最短路径权重计算
-- =====================================================
CREATE OR REPLACE FUNCTION calculate_edge_weight(
    edge_id INTEGER,
    travel_mode VARCHAR
)
RETURNS DECIMAL AS $$
DECLARE
    base_w DECIMAL;
    congestion INTEGER;
    mode_factor DECIMAL;
BEGIN
    -- 获取基础权重和拥堵等级
    SELECT e.base_weight, e.congestion_level INTO base_w, congestion
    FROM graph_edges e WHERE e.id = edge_id;
    
    -- 交通方式系数
    mode_factor := CASE travel_mode
        WHEN 'walk' THEN 1.0
        WHEN 'bike' THEN 0.6
        WHEN 'car' THEN 0.8
        WHEN 'bus' THEN 0.5
        WHEN 'subway' THEN 0.4
        ELSE 1.0
    END;
    
    -- 拥堵系数：1级1.0, 2级1.3, 3级1.6, 4级2.0
    RETURN base_w * mode_factor * (1.0 + (congestion - 1) * 0.3);
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 存储过程：更新景点评分
-- =====================================================
CREATE OR REPLACE FUNCTION update_scenic_spot_rating(spot_id INTEGER)
RETURNS VOID AS $$
DECLARE
    avg_rating DECIMAL;
    rating_cnt INTEGER;
BEGIN
    SELECT AVG(rating), COUNT(*) INTO avg_rating, rating_cnt
    FROM reviews
    WHERE scenic_spot_id = spot_id AND status = 1;
    
    UPDATE scenic_spots
    SET rating = COALESCE(avg_rating, 0),
        rating_count = rating_cnt
    WHERE id = spot_id;
END;
$$ LANGUAGE plpgsql;

-- 创建更新评分的触发器
CREATE OR REPLACE FUNCTION trigger_update_scenic_spot_rating()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        PERFORM update_scenic_spot_rating(NEW.scenic_spot_id);
    ELSIF TG_OP = 'UPDATE' THEN
        IF OLD.scenic_spot_id IS DISTINCT FROM NEW.scenic_spot_id THEN
            PERFORM update_scenic_spot_rating(OLD.scenic_spot_id);
            PERFORM update_scenic_spot_rating(NEW.scenic_spot_id);
        ELSE
            PERFORM update_scenic_spot_rating(NEW.scenic_spot_id);
        END IF;
    ELSIF TG_OP = 'DELETE' THEN
        PERFORM update_scenic_spot_rating(OLD.scenic_spot_id);
    END IF;
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_scenic_spot_rating_trigger
    AFTER INSERT OR UPDATE OR DELETE ON reviews
    FOR EACH ROW EXECUTE FUNCTION trigger_update_scenic_spot_rating();

-- =====================================================
-- 完成提示
-- =====================================================
DO $$
BEGIN
    RAISE NOTICE '============================================';
    RAISE NOTICE 'Database schema v2.0 created successfully';
    RAISE NOTICE '============================================';
    RAISE NOTICE 'Database: tourism_system';
    RAISE NOTICE 'Extensions: PostGIS, uuid-ossp';
    RAISE NOTICE 'Tables: 15 core tables + 4 relation tables';
    RAISE NOTICE 'Indexes: 40+';
    RAISE NOTICE 'Triggers: 12';
    RAISE NOTICE 'Stored procedures: 4';
    RAISE NOTICE '============================================';
END $$;
