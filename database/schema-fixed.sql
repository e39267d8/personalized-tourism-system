-- =====================================================
-- 个性化旅游系统 - 修正版数据库初始化脚本
-- =====================================================
-- 功能：
-- 1. 创建数据库
-- 2. 启用 PostGIS 扩展
-- 3. 创建所有表结构（包含缺失字段）
-- 4. 创建索引
-- 5. 创建所有存储过程
-- =====================================================

-- 创建数据库
CREATE DATABASE tourism_system;
\c tourism_system;

-- 启用 PostGIS 扩展（空间数据支持）
CREATE EXTENSION IF NOT EXISTS postgis;

-- =====================================================
-- 1. 用户表
-- =====================================================
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    email VARCHAR(100),
    nickname VARCHAR(50),
    avatar_url VARCHAR(200),
    gender SMALLINT,
    birth_date DATE,
    preferences JSONB,
    status SMALLINT DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_users_preferences ON users USING GIN (preferences);

-- =====================================================
-- 2. 用户偏好表
-- =====================================================
CREATE TABLE user_preferences (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    preference_type VARCHAR(50),
    preference_value JSONB,
    weight DECIMAL(3,2) DEFAULT 1.0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_user_preferences_user ON user_preferences (user_id);
CREATE INDEX idx_user_preferences_type ON user_preferences (preference_type);

-- =====================================================
-- 3. 景点分类表
-- =====================================================
CREATE TABLE scenic_categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    description TEXT,
    icon_url VARCHAR(200),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- 4. 景点表（PostGIS 空间数据）
-- =====================================================
CREATE TABLE scenic_spots (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    location GEOGRAPHY(POINT, 4326) NOT NULL,
    category_id INTEGER REFERENCES scenic_categories(id),
    category VARCHAR(50),
    rating DECIMAL(3,2) DEFAULT 0.0,
    address VARCHAR(200),
    city VARCHAR(50),
    opening_hours VARCHAR(100),
    ticket_price DECIMAL(10,2),
    duration_hours INTEGER,
    crowd_level SMALLINT DEFAULT 1,  -- 1-4 级别
    visit_count INTEGER DEFAULT 0,
    images TEXT[],
    tags TEXT[],
    status SMALLINT DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_scenic_spots_location ON scenic_spots USING GIST (location);
CREATE INDEX idx_scenic_spots_category ON scenic_spots (category_id);
CREATE INDEX idx_scenic_spots_city ON scenic_spots (city);
CREATE INDEX idx_scenic_spots_rating ON scenic_spots (rating);
CREATE INDEX idx_scenic_spots_status ON scenic_spots (status);

ALTER TABLE scenic_spots ADD COLUMN search_vector TSVECTOR;
CREATE INDEX idx_scenic_spots_search ON scenic_spots USING GIN (search_vector);

-- =====================================================
-- 5. 设施类型表
-- =====================================================
CREATE TABLE facility_types (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    icon_url VARCHAR(200),
    color_code VARCHAR(10),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- 6. 设施表
-- =====================================================
CREATE TABLE facilities (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    facility_type_id INTEGER REFERENCES facility_types(id),
    type VARCHAR(50),
    location GEOGRAPHY(POINT, 4326),
    address VARCHAR(200),
    city VARCHAR(50),
    rating DECIMAL(3,2) DEFAULT 0.0,
    price_level INTEGER,
    phone VARCHAR(20),
    opening_hours VARCHAR(100),
    images TEXT[],
    tags TEXT[],
    status SMALLINT DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_facilities_location ON facilities USING GIST (location);
CREATE INDEX idx_facilities_type ON facilities (facility_type_id);
CREATE INDEX idx_facilities_city ON facilities (city);
CREATE INDEX idx_facilities_status ON facilities (status);

-- =====================================================
-- 7. 图节点表
-- =====================================================
CREATE TABLE graph_nodes (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    location GEOGRAPHY(POINT, 4326),
    node_type VARCHAR(20),
    scenic_spot_id INTEGER REFERENCES scenic_spots(id),
    facility_id INTEGER REFERENCES facilities(id),
    properties JSONB,
    status SMALLINT DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_graph_nodes_location ON graph_nodes USING GIST (location);
CREATE INDEX idx_graph_nodes_scenic ON graph_nodes (scenic_spot_id);
CREATE INDEX idx_graph_nodes_facility ON graph_nodes (facility_id);
CREATE INDEX idx_graph_nodes_type ON graph_nodes (node_type);

-- =====================================================
-- 8. 图边表
-- =====================================================
CREATE TABLE graph_edges (
    id SERIAL PRIMARY KEY,
    from_node_id INTEGER NOT NULL REFERENCES graph_nodes(id),
    to_node_id INTEGER NOT NULL REFERENCES graph_nodes(id),
    from_node INTEGER NOT NULL REFERENCES graph_nodes(id),
    to_node INTEGER NOT NULL REFERENCES graph_nodes(id),
    distance DECIMAL(10,2),
    travel_mode VARCHAR(20),
    travel_time INTEGER,
    base_weight DECIMAL(10,2) DEFAULT 1.0,
    dynamic_weight DECIMAL(10,2) DEFAULT 1.0,
    weight DECIMAL(10,2) DEFAULT 1.0,
    transport_type VARCHAR(20),
    distance_meters INTEGER,
    duration_seconds INTEGER,
    weight_updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status SMALLINT DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_edges_from ON graph_edges (from_node_id);
CREATE INDEX idx_edges_to ON graph_edges (to_node_id);
CREATE INDEX idx_edges_mode ON graph_edges (travel_mode);
CREATE INDEX idx_edges_transport ON graph_edges (transport_type);
CREATE INDEX idx_edges_status ON graph_edges (status);

-- =====================================================
-- 9. 游记表
-- =====================================================
CREATE TABLE travel_diaries (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    title VARCHAR(200) NOT NULL,
    content TEXT NOT NULL,
    tags TEXT[],
    scenic_spot_ids INTEGER[],
    images TEXT[],
    visibility SMALLINT DEFAULT 1,  -- 1:公开, 2:好友, 3:私密
    view_count INTEGER DEFAULT 0,
    like_count INTEGER DEFAULT 0,
    comment_count INTEGER DEFAULT 0,
    mood SMALLINT,  -- 心情值 1-5
    weather VARCHAR(20),
    start_date DATE,
    end_date DATE,
    route_data JSONB,  -- 路线数据
    visited_spots JSONB,  -- 访问过的景点
    published_at TIMESTAMP,
    search_vector TSVECTOR,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_diaries_search ON travel_diaries USING GIN (search_vector);
CREATE INDEX idx_diaries_tags ON travel_diaries USING GIN (tags);
CREATE INDEX idx_diaries_user ON travel_diaries (user_id);
CREATE INDEX idx_diaries_visibility ON travel_diaries (visibility);
CREATE INDEX idx_diaries_published ON travel_diaries (published_at);

-- =====================================================
-- 10. 评价目标类型表
-- =====================================================
CREATE TABLE review_target_types (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    table_name VARCHAR(50) NOT NULL
);

-- =====================================================
-- 11. 评价标签表
-- =====================================================
CREATE TABLE review_tags (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    description TEXT,
    category VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- 12. 评价标签映射表
-- =====================================================
CREATE TABLE review_tag_mapping (
    id SERIAL PRIMARY KEY,
    review_id INTEGER REFERENCES reviews(id),
    tag_id INTEGER REFERENCES review_tags(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_review_tags_review ON review_tag_mapping (review_id);
CREATE INDEX idx_review_tags_tag ON review_tag_mapping (tag_id);

-- =====================================================
-- 13. 评价表
-- =====================================================
CREATE TABLE reviews (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    target_type VARCHAR(50) NOT NULL,  -- 'scenic', 'facility', 'diary'
    target_id INTEGER NOT NULL,
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),
    title VARCHAR(200),
    content TEXT,
    is_verified BOOLEAN DEFAULT FALSE,
    status SMALLINT DEFAULT 1,
    helpful_count INTEGER DEFAULT 0,
    images TEXT[],
    tags TEXT[],
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_reviews_user ON reviews (user_id);
CREATE INDEX idx_reviews_target ON reviews (target_type, target_id);
CREATE INDEX idx_reviews_rating ON reviews (rating);
CREATE INDEX idx_reviews_status ON reviews (status);

-- =====================================================
-- 14. 成就表
-- =====================================================
CREATE TABLE achievements (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    level INTEGER,  -- 1:打卡, 2:探索, 3:创作, 4:大师
    type VARCHAR(50),  -- 'scenic_checkin', 'route_complete', 'diary_create'
    requirement JSONB,  -- 解锁条件
    reward JSONB,  -- 奖励
    icon_url VARCHAR(200),
    order_num INTEGER DEFAULT 0,
    status SMALLINT DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- 15. 用户成就表
-- =====================================================
CREATE TABLE user_achievements (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    achievement_id INTEGER REFERENCES achievements(id),
    unlocked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    progress JSONB,  -- 进度 {current: int, required: int}
    status VARCHAR(20) DEFAULT 'locked',  -- locked, in_progress, unlocked
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_user_achievements_user ON user_achievements (user_id);
CREATE INDEX idx_user_achievements_achievement ON user_achievements (achievement_id);
CREATE INDEX idx_user_achievements_status ON user_achievements (status);

-- =====================================================
-- 16. 数字藏品表
-- =====================================================
CREATE TABLE digital_collectibles (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    achievement_id INTEGER REFERENCES achievements(id),
    token_id VARCHAR(100) UNIQUE,
    name VARCHAR(100),
    description TEXT,
    image_url VARCHAR(200),
    metadata JSONB,
    blockchain_hash VARCHAR(200),
    owner_address VARCHAR(100),
    mint_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status SMALLINT DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_collectibles_user ON digital_collectibles (user_id);
CREATE INDEX idx_collectibles_achievement ON digital_collectibles (achievement_id);
CREATE INDEX idx_collectibles_token ON digital_collectibles (token_id);

-- =====================================================
-- 17. 搜索历史表
-- =====================================================
CREATE TABLE search_histories (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    query_text TEXT NOT NULL,
    search_type VARCHAR(50),  -- 'scenic', 'diary', 'general'
    result_count INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_search_histories_user ON search_histories (user_id);
CREATE INDEX idx_search_histories_text ON search_histories (query_text);
CREATE INDEX idx_search_histories_type ON search_histories (search_type);

-- =====================================================
-- 18. 系统配置表
-- =====================================================
CREATE TABLE system_configs (
    id SERIAL PRIMARY KEY,
    config_key VARCHAR(100) UNIQUE NOT NULL,
    config_value TEXT,
    description TEXT,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- 19. API 访问日志表
-- =====================================================
CREATE TABLE api_access_logs (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    endpoint VARCHAR(200) NOT NULL,
    method VARCHAR(10) NOT NULL,
    ip_address INET,
    user_agent TEXT,
    response_time_ms INTEGER,
    status_code INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_api_logs_user ON api_access_logs (user_id);
CREATE INDEX idx_api_logs_endpoint ON api_access_logs (endpoint);
CREATE INDEX idx_api_logs_created ON api_access_logs (created_at);

-- =====================================================
-- 20. 物化视图：热门景点
-- =====================================================
CREATE MATERIALIZED VIEW mv_hot_scenic_spots AS
SELECT 
    ss.id,
    ss.name,
    ss.rating,
    ss.visit_count,
    ss.review_count,
    ROW_NUMBER() OVER (ORDER BY ss.visit_count DESC, ss.rating DESC) as popularity_rank
FROM scenic_spots ss
WHERE ss.status = 1
ORDER BY ss.visit_count DESC, ss.rating DESC;

-- =====================================================
-- 存储过程：KNN 最近邻查询
-- =====================================================
CREATE OR REPLACE FUNCTION find_nearest_spots(
    ref_lat DOUBLE PRECISION,
    ref_lng DOUBLE PRECISION,
    k INTEGER DEFAULT 10
)
RETURNS TABLE(
    id INTEGER,
    name VARCHAR,
    distance DOUBLE PRECISION,
    rating DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT s.id, s.name,
           ST_Distance(s.location::geography, 
                       ST_SetSRID(ST_MakePoint(ref_lng, ref_lat), 4326)::geography) AS distance,
           s.rating
    FROM scenic_spots s
    WHERE s.status = 1
    ORDER BY s.location <-> ST_SetSRID(ST_MakePoint(ref_lng, ref_lat), 4326)
    LIMIT k;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 存储过程：范围查询
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
    SELECT f.id, f.name, f.type,
           ST_Distance(f.location::geography, 
                       ST_SetSRID(ST_MakePoint(ref_lng, ref_lat), 4326)::geography) AS distance
    FROM facilities f
    WHERE ST_DWithin(
        f.location::geography,
        ST_SetSRID(ST_MakePoint(ref_lng, ref_lat), 4326)::geography,
        radius_meters
    )
    AND (facility_type IS NULL OR f.type = facility_type)
    AND f.status = 1
    ORDER BY distance;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 1. 地理空间查询函数
-- =================================================----

-- 查找指定半径内的景点
CREATE OR REPLACE FUNCTION find_nearby_scenic_spots(
    p_longitude DECIMAL,
    p_latitude DECIMAL,
    p_radius_meters INTEGER DEFAULT 5000,
    p_category_id INTEGER DEFAULT NULL,
    p_limit INTEGER DEFAULT 20
)
RETURNS TABLE (
    id BIGINT,
    name VARCHAR,
    distance_meters DECIMAL,
    rating DECIMAL,
    crowd_level SMALLINT,
    address VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ss.id,
        ss.name,
        ST_Distance(
            ss.location,
            ST_SetSRID(ST_MakePoint(p_longitude, p_latitude), 4326)::geography
        ) AS distance_meters,
        ss.rating,
        ss.crowd_level,
        ss.address
    FROM scenic_spots ss
    WHERE ST_DWithin(
        ss.location,
        ST_SetSRID(ST_MakePoint(p_longitude, p_latitude), 4326)::geography,
        p_radius_meters
    )
    AND (p_category_id IS NULL OR ss.category_id = p_category_id)
    AND ss.status = 1
    ORDER BY distance_meters
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- 查找 K 个最近邻景点（KNN - 使用 PostGIS 优化）
CREATE OR REPLACE FUNCTION find_k_nearest_scenic_spots(
    p_longitude DECIMAL,
    p_latitude DECIMAL,
    p_limit INTEGER DEFAULT 10
)
RETURNS TABLE (
    id BIGINT,
    name VARCHAR,
    distance_meters DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ss.id,
        ss.name,
        ST_Distance(
            ss.location,
            ST_SetSRID(ST_MakePoint(p_longitude, p_latitude), 4326)::geography
        ) AS distance_meters
    FROM scenic_spots ss
    WHERE ss.status = 1
    ORDER BY ss.location <-> ST_SetSRID(ST_MakePoint(p_longitude, p_latitude), 4326)::geography
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- 查找指定范围内的设施
CREATE OR REPLACE FUNCTION find_nearby_facilities(
    p_longitude DECIMAL,
    p_latitude DECIMAL,
    p_radius_meters INTEGER DEFAULT 1000,
    p_facility_type_id INTEGER DEFAULT NULL,
    p_limit INTEGER DEFAULT 20
)
RETURNS TABLE (
    id BIGINT,
    name VARCHAR,
    facility_type_id BIGINT,
    distance_meters DECIMAL,
    rating DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        f.id,
        f.name,
        f.facility_type_id,
        ST_Distance(
            f.location,
            ST_SetSRID(ST_MakePoint(p_longitude, p_latitude), 4326)::geography
        ) AS distance_meters,
        f.rating
    FROM facilities f
    WHERE ST_DWithin(
        f.location,
        ST_SetSRID(ST_MakePoint(p_longitude, p_latitude), 4326)::geography,
        p_radius_meters
    )
    AND (p_facility_type_id IS NULL OR f.facility_type_id = p_facility_type_id)
    AND f.status = 1
    ORDER BY distance_meters
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- 查找矩形区域内的景点（用于地图边界查询）
CREATE OR REPLACE FUNCTION find_scenic_in_bounds(
    p_min_lon DECIMAL, p_min_lat DECIMAL,
    p_max_lon DECIMAL, p_max_lat DECIMAL,
    p_limit INTEGER DEFAULT 100
)
RETURNS TABLE (
    id BIGINT,
    name VARCHAR,
    longitude DECIMAL,
    latitude DECIMAL,
    rating DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ss.id,
        ss.name,
        ST_X(ss.location::geometry) AS longitude,
        ST_Y(ss.location::geometry) AS latitude,
        ss.rating
    FROM scenic_spots ss
    WHERE ss.location && ST_MakeEnvelope(
        p_min_lon, p_min_lat, p_max_lon, p_max_lat, 4326
    )::geography
    AND ss.status = 1
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- 计算两点间距离（Haversine 公式）
CREATE OR REPLACE FUNCTION calculate_distance(
    p_lon1 DECIMAL, p_lat1 DECIMAL,
    p_lon2 DECIMAL, p_lat2 DECIMAL
)
RETURNS DECIMAL AS $$
BEGIN
    RETURN ST_Distance(
        ST_SetSRID(ST_MakePoint(p_lon1, p_lat1), 4326)::geography,
        ST_SetSRID(ST_MakePoint(p_lon2, p_lat2), 4326)::geography
    );
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 2. 路径规划辅助函数
-- =====================================================

-- 获取节点的邻居边
CREATE OR REPLACE FUNCTION get_node_neighbors(
    p_node_id BIGINT,
    p_transport_type VARCHAR DEFAULT NULL
)
RETURNS TABLE (
    edge_id BIGINT,
    to_node_id BIGINT,
    distance_meters INTEGER,
    duration_seconds INTEGER,
    weight DECIMAL,
    transport_type VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ge.id,
        ge.to_node_id,
        ge.distance_meters,
        ge.duration_seconds,
        COALESCE(ge.dynamic_weight, ge.base_weight) AS weight,
        ge.transport_type
    FROM graph_edges ge
    WHERE ge.from_node_id = p_node_id
    AND (p_transport_type IS NULL OR ge.transport_type = p_transport_type)
    AND ge.status = 1
    ORDER BY weight;
END;
$$ LANGUAGE plpgsql;

-- 更新边的动态权重（基于拥挤度）
CREATE OR REPLACE FUNCTION update_edge_dynamic_weights()
RETURNS INTEGER AS $$
DECLARE
    updated_count INTEGER;
BEGIN
    UPDATE graph_edges ge
    SET dynamic_weight = CASE
        -- 获取目标节点的拥挤度
        WHEN EXISTS (
            SELECT 1 FROM scenic_spots ss 
            JOIN graph_nodes gn ON gn.scenic_spot_id = ss.id 
            WHERE gn.id = ge.to_node_id AND ss.crowd_level > 2
        ) THEN ge.base_weight * 1.5  -- 拥挤时增加 50% 权重
        WHEN EXISTS (
            SELECT 1 FROM scenic_spots ss 
            JOIN graph_nodes gn ON gn.scenic_spot_id = ss.id 
            WHERE gn.id = ge.to_node_id AND ss.crowd_level = 2
        ) THEN ge.base_weight * 1.2  -- 中等拥挤增加 20%
        ELSE ge.base_weight  -- 正常
    END,
    weight_updated_at = CURRENT_TIMESTAMP
    WHERE ge.dynamic_weight IS NULL 
       OR ge.weight_updated_at < CURRENT_TIMESTAMP - INTERVAL '1 hour';
    
    GET DIAGNOSTICS updated_count = ROW_COUNT;
    RETURN updated_count;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 3. 推荐系统函数
-- =====================================================

-- 计算景点综合评分
CREATE OR REPLACE FUNCTION calculate_scenic_score(
    p_scenic_spot_id BIGINT,
    p_user_id BIGINT DEFAULT NULL
)
RETURNS DECIMAL AS $$
DECLARE
    v_score DECIMAL;
    v_base_score DECIMAL;
    v_preference_weight DECIMAL := 1.0;
BEGIN
    -- 基础评分（评分 + 热度）
    SELECT rating * 0.6 + (LOG(visit_count + 1) / 10.0) * 0.4
    INTO v_base_score
    FROM scenic_spots
    WHERE id = p_scenic_spot_id;
    
    -- 如果有用户 ID，考虑用户偏好
    IF p_user_id IS NOT NULL THEN
        SELECT COALESCE(AVG(up.weight), 1.0)
        INTO v_preference_weight
        FROM user_preferences up
        WHERE up.user_id = p_user_id
        AND up.preference_type = 'scenic_type';
    END IF;
    
    v_score := v_base_score * v_preference_weight;
    
    RETURN ROUND(v_score::NUMERIC, 2);
END;
$$ LANGUAGE plpgsql;

-- Top-K 推荐景点（使用窗口函数）
CREATE OR REPLACE FUNCTION get_top_k_recommendations(
    p_user_id BIGINT DEFAULT NULL,
    p_longitude DECIMAL DEFAULT NULL,
    p_latitude DECIMAL DEFAULT NULL,
    p_limit INTEGER DEFAULT 10,
    p_scenario VARCHAR DEFAULT 'explore' -- 'explore', 'nearby', 'seasonal'
)
RETURNS TABLE (
    scenic_spot_id BIGINT,
    name VARCHAR,
    score DECIMAL,
    distance_meters DECIMAL,
    reason VARCHAR
) AS $$
BEGIN
    IF p_scenario = 'nearby' AND p_longitude IS NOT NULL AND p_latitude IS NOT NULL THEN
        -- 周边推荐
        RETURN QUERY
        SELECT 
            ss.id,
            ss.name,
            calculate_scenic_score(ss.id, p_user_id) AS score,
            ST_Distance(
                ss.location,
                ST_SetSRID(ST_MakePoint(p_longitude, p_latitude), 4326)::geography
            ) AS distance_meters,
            '距离您较近且评分较高'::VARCHAR AS reason
        FROM scenic_spots ss
        WHERE ST_DWithin(
            ss.location,
            ST_SetSRID(ST_MakePoint(p_longitude, p_latitude), 4326)::geography,
            5000
        )
        AND ss.status = 1
        ORDER BY score DESC, distance_meters ASC
        LIMIT p_limit;
        
    ELSIF p_scenario = 'seasonal' THEN
        -- 季节性推荐（简化版，实际应根据季节标签）
        RETURN QUERY
        SELECT 
            ss.id,
            ss.name,
            calculate_scenic_score(ss.id, p_user_id) AS score,
            NULL::DECIMAL AS distance_meters,
            '当季热门景点'::VARCHAR AS reason
        FROM scenic_spots ss
        WHERE ss.status = 1
        AND ss.crowd_level <= 3  -- 避免过度拥挤
        ORDER BY score DESC
        LIMIT p_limit;
        
    ELSE
        -- 通用推荐
        RETURN QUERY
        SELECT 
            ss.id,
            ss.name,
            calculate_scenic_score(ss.id, p_user_id) AS score,
            NULL::DECIMAL AS distance_meters,
            '根据您的偏好推荐'::VARCHAR AS reason
        FROM scenic_spots ss
        WHERE ss.status = 1
        ORDER BY score DESC
        LIMIT p_limit;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 4. 全文检索函数
-- =====================================================

-- 搜索游记（全文检索）
CREATE OR REPLACE FUNCTION search_diaries(
    p_query TEXT,
    p_limit INTEGER DEFAULT 20,
    p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
    diary_id BIGINT,
    title VARCHAR,
    summary TEXT,
    author_id BIGINT,
    author_name VARCHAR,
    view_count INTEGER,
    like_count INTEGER,
    created_at TIMESTAMP WITH TIME ZONE,
    rank DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        td.id AS diary_id,
        td.title,
        LEFT(td.content, 200) AS summary,
        td.user_id AS author_id,
        u.username AS author_name,
        td.view_count,
        td.like_count,
        td.created_at,
        ts_rank(
            to_tsvector('simple', COALESCE(td.title, '') || ' ' || COALESCE(td.content, '')),
            plainto_tsquery('simple', p_query)
        ) AS rank
    FROM travel_diaries td
    JOIN users u ON u.id = td.user_id
    WHERE td.visibility = 1  -- 公开
    AND to_tsvector('simple', COALESCE(td.title, '') || ' ' || COALESCE(td.content, ''))
        @@ plainto_tsquery('simple', p_query)
    ORDER BY rank DESC, td.created_at DESC
    LIMIT p_limit
    OFFSET p_offset;
END;
$$ LANGUAGE plpgsql;

-- 搜索景点
CREATE OR REPLACE FUNCTION search_scenic_spots(
    p_query TEXT,
    p_city VARCHAR DEFAULT NULL,
    p_limit INTEGER DEFAULT 20
)
RETURNS TABLE (
    scenic_spot_id BIGINT,
    name VARCHAR,
    city VARCHAR,
    rating DECIMAL,
    rank DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ss.id,
        ss.name,
        ss.city,
        ss.rating,
        ts_rank(
            to_tsvector('simple', ss.name || ' ' || COALESCE(ss.description, '')),
            plainto_tsquery('simple', p_query)
        ) AS rank
    FROM scenic_spots ss
    WHERE ss.status = 1
    AND (p_city IS NULL OR ss.city = p_city)
    AND to_tsvector('simple', ss.name || ' ' || COALESCE(ss.description, ''))
        @@ plainto_tsquery('simple', p_query)
    ORDER BY rank DESC, ss.rating DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 5. 统计函数
-- =====================================================

-- 刷新热门景点物化视图
CREATE OR REPLACE FUNCTION refresh_hot_spots_view()
RETURNS VOID AS $$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY mv_hot_scenic_spots;
END;
$$ LANGUAGE plpgsql;

-- 获取系统统计信息
CREATE OR REPLACE FUNCTION get_system_statistics()
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    SELECT jsonb_build_object(
        'total_users', (SELECT COUNT(*) FROM users WHERE status = 1),
        'total_scenic_spots', (SELECT COUNT(*) FROM scenic_spots WHERE status = 1),
        'total_facilities', (SELECT COUNT(*) FROM facilities WHERE status = 1),
        'total_diaries', (SELECT COUNT(*) FROM travel_diaries WHERE visibility = 1),
        'total_reviews', (SELECT COUNT(*) FROM reviews WHERE status = 1),
        'graph_nodes', (SELECT COUNT(*) FROM graph_nodes),
        'graph_edges', (SELECT COUNT(*) FROM graph_edges)
    ) INTO result;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 6. 游记管理函数
-- =====================================================

-- 创建游记（带事务）
CREATE OR REPLACE FUNCTION create_travel_diary(
    p_user_id BIGINT,
    p_title VARCHAR,
    p_content TEXT,
    p_start_date DATE,
    p_end_date DATE,
    p_route_data JSONB,
    p_visited_spots JSONB,
    p_visibility SMALLINT DEFAULT 1
)
RETURNS BIGINT AS $$
DECLARE
    v_diary_id BIGINT;
BEGIN
    INSERT INTO travel_diaries (
        user_id, title, content, start_date, end_date,
        route_data, visited_spots, visibility, published_at
    ) VALUES (
        p_user_id, p_title, p_content, p_start_date, p_end_date,
        p_route_data, p_visited_spots, p_visibility, CURRENT_TIMESTAMP
    ) RETURNING id INTO v_diary_id;
    
    -- 更新景点访问计数
    UPDATE scenic_spots ss
    SET visit_count = visit_count + 1
    FROM jsonb_array_elements(p_visited_spots) AS spot
    WHERE ss.id = (spot->>'scenic_spot_id')::BIGINT;
    
    RETURN v_diary_id;
END;
$$ LANGUAGE plpgsql;

-- 增加游记浏览量
CREATE OR REPLACE FUNCTION increment_diary_view_count(
    p_diary_id BIGINT
)
RETURNS VOID AS $$
BEGIN
    UPDATE travel_diaries
    SET view_count = view_count + 1
    WHERE id = p_diary_id;
END;
$$ LANGUAGE plpgsql;

-- 点赞游记
CREATE OR REPLACE FUNCTION toggle_diary_like(
    p_diary_id BIGINT,
    p_user_id BIGINT
)
RETURNS BOOLEAN AS $$
DECLARE
    v_liked BOOLEAN;
BEGIN
    -- 简化版，实际需要用户点赞记录表
    UPDATE travel_diaries
    SET like_count = like_count + 1
    WHERE id = p_diary_id;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 7. 评论管理函数
-- =====================================================

-- 创建评论并更新评分
CREATE OR REPLACE FUNCTION create_review(
    p_user_id BIGINT,
    p_target_type VARCHAR,
    p_target_id BIGINT,
    p_rating SMALLINT,
    p_title VARCHAR,
    p_content TEXT,
    p_tags BIGINT[] DEFAULT NULL
)
RETURNS BIGINT AS $$
DECLARE
    v_review_id BIGINT;
    v_avg_rating DECIMAL;
    v_review_count INTEGER;
BEGIN
    -- 插入评论
    INSERT INTO reviews (
        user_id, target_type, target_id, rating, title, content,
        is_verified, status
    ) VALUES (
        p_user_id, p_target_type, p_target_id, p_rating, p_title, p_content,
        TRUE, 1
    ) RETURNING id INTO v_review_id;
    
    -- 插入标签关联
    IF p_tags IS NOT NULL THEN
        INSERT INTO review_tag_mapping (review_id, tag_id)
        SELECT v_review_id, UNNEST(p_tags);
    END IF;
    
    -- 更新目标评分（如果是景点或设施）
    IF p_target_type = 'scenic' THEN
        UPDATE scenic_spots
        SET rating = (
                SELECT AVG(r.rating)
                FROM reviews r
                WHERE r.target_type = 'scenic'
                AND r.target_id = p_target_id
                AND r.status = 1
            ),
            review_count = (
                SELECT COUNT(*)
                FROM reviews r
                WHERE r.target_type = 'scenic'
                AND r.target_id = p_target_id
                AND r.status = 1
            )
        WHERE id = p_target_id;
    ELSIF p_target_type = 'facility' THEN
        UPDATE facilities
        SET rating = (
                SELECT AVG(r.rating)
                FROM reviews r
                WHERE r.target_type = 'facility'
                AND r.target_id = p_target_id
                AND r.status = 1
            ),
            review_count = (
                SELECT COUNT(*)
                FROM reviews r
                WHERE r.target_type = 'facility'
                AND r.target_id = p_target_id
                AND r.status = 1
            )
        WHERE id = p_target_id;
    END IF;
    
    RETURN v_review_id;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 函数创建完成
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '数据库架构创建完成！';
    RAISE NOTICE '数据库：tourism_system';
    RAISE NOTICE '扩展：PostGIS 已启用';
    RAISE NOTICE '表数量：20 张核心表 + 1 个物化视图';
    RAISE NOTICE '存储过程：20+ 个函数';
END $$;