-- =====================================================
-- 个性化旅游系统 - 数据库初始化脚本
-- =====================================================
-- 功能：
-- 1. 创建数据库
-- 2. 启用 PostGIS 扩展
-- 3. 创建所有表结构
-- 4. 创建索引
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
    preferences JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_users_preferences ON users USING GIN (preferences);

-- =====================================================
-- 2. 景点表（PostGIS 空间数据）
-- =====================================================
CREATE TABLE scenic_spots (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    location GEOGRAPHY(POINT, 4326) NOT NULL,
    category VARCHAR(50),
    rating DECIMAL(3,2),
    address VARCHAR(200),
    opening_hours VARCHAR(100),
    ticket_price DECIMAL(10,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_scenic_spots_location ON scenic_spots USING GIST (location);

ALTER TABLE scenic_spots ADD COLUMN search_vector TSVECTOR;
CREATE INDEX idx_scenic_spots_search ON scenic_spots USING GIN (search_vector);

-- =====================================================
-- 3. 图节点表
-- =====================================================
CREATE TABLE graph_nodes (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    location GEOGRAPHY(POINT, 4326),
    node_type VARCHAR(20),
    scenic_spot_id INTEGER REFERENCES scenic_spots(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_graph_nodes_location ON graph_nodes USING GIST (location);

-- =====================================================
-- 4. 图边表
-- =====================================================
CREATE TABLE graph_edges (
    id SERIAL PRIMARY KEY,
    from_node INTEGER NOT NULL REFERENCES graph_nodes(id),
    to_node INTEGER NOT NULL REFERENCES graph_nodes(id),
    distance DECIMAL(10,2),
    travel_mode VARCHAR(20),
    travel_time INTEGER,
    weight DECIMAL(10,2) DEFAULT 1.0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_edges_from ON graph_edges (from_node);
CREATE INDEX idx_edges_to ON graph_edges (to_node);
CREATE INDEX idx_edges_mode ON graph_edges (travel_mode);

-- =====================================================
-- 5. 设施表
-- =====================================================
CREATE TABLE facilities (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    type VARCHAR(50),
    location GEOGRAPHY(POINT, 4326),
    address VARCHAR(200),
    rating DECIMAL(3,2),
    price_level INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_facilities_location ON facilities USING GIST (location);

-- =====================================================
-- 6. 游记表
-- =====================================================
CREATE TABLE travel_diaries (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    title VARCHAR(200) NOT NULL,
    content TEXT NOT NULL,
    tags TEXT[],
    scenic_spot_ids INTEGER[],
    images TEXT[],
    search_vector TSVECTOR,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_diaries_search ON travel_diaries USING GIN (search_vector);
CREATE INDEX idx_diaries_tags ON travel_diaries USING GIN (tags);
CREATE INDEX idx_diaries_user ON travel_diaries (user_id);

-- =====================================================
-- 7. 评价表
-- =====================================================
CREATE TABLE reviews (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    scenic_spot_id INTEGER REFERENCES scenic_spots(id),
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),
    content TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_reviews_user ON reviews (user_id);
CREATE INDEX idx_reviews_spot ON reviews (scenic_spot_id);

-- =====================================================
-- 8. 成就表
-- =====================================================
CREATE TABLE achievements (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    level INTEGER,
    type VARCHAR(50),
    requirement JSONB,
    reward JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- 9. 用户成就表
-- =====================================================
CREATE TABLE user_achievements (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    achievement_id INTEGER REFERENCES achievements(id),
    unlocked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    progress JSONB,
    status VARCHAR(20) DEFAULT 'locked'
);

CREATE INDEX idx_user_achievements_user ON user_achievements (user_id);
CREATE INDEX idx_user_achievements_status ON user_achievements (status);

-- =====================================================
-- 10. 数字藏品表
-- =====================================================
CREATE TABLE digital_collectibles (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    achievement_id INTEGER REFERENCES achievements(id),
    token_id VARCHAR(100),
    metadata JSONB,
    blockchain_hash VARCHAR(200),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_collectibles_user ON digital_collectibles (user_id);
CREATE INDEX idx_collectibles_token ON digital_collectibles (token_id);

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
    ORDER BY distance;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 完成提示
-- =====================================================
DO $$
BEGIN
    RAISE NOTICE '数据库架构创建完成！';
    RAISE NOTICE '数据库：tourism_system';
    RAISE NOTICE '扩展：PostGIS 已启用';
    RAISE NOTICE '表数量：10 张核心表';
END $$;
