-- 个性化旅游系统数据库 Schema
-- PostgreSQL 15 + PostGIS 3.3
-- 版本：v1.0
-- 创建日期：2026-03-31

-- ============================================
-- 1. 启用 PostGIS 扩展
-- ============================================
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS postgis_topology;

-- ============================================
-- 2. 用户系统
-- ============================================

-- 用户表
CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    avatar_url VARCHAR(500),
    nickname VARCHAR(50),
    gender SMALLINT DEFAULT 0, -- 0:未知 1:男 2:女
    birth_date DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_login_at TIMESTAMP WITH TIME ZONE,
    status SMALLINT DEFAULT 1 -- 0:禁用 1:正常 2:封禁
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_phone ON users(phone);

-- 用户偏好表
CREATE TABLE user_preferences (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    preference_type VARCHAR(50) NOT NULL, -- 'scenic_type', 'transport', 'budget', 'activity'
    preference_value JSONB NOT NULL, -- 存储具体偏好值
    weight DECIMAL(3,2) DEFAULT 1.0, -- 偏好权重
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, preference_type)
);

CREATE INDEX idx_user_preferences_user ON user_preferences(user_id);

-- 用户收藏表
CREATE TABLE user_favorites (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    scenic_spot_id BIGINT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, scenic_spot_id)
);

CREATE INDEX idx_favorites_user ON user_favorites(user_id);
CREATE INDEX idx_favorites_scenic ON user_favorites(scenic_spot_id);

-- ============================================
-- 3. 景点数据（含 PostGIS 地理空间）
-- ============================================

-- 景点分类表
CREATE TABLE scenic_categories (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    parent_id BIGINT REFERENCES scenic_categories(id),
    icon_url VARCHAR(500),
    sort_order INTEGER DEFAULT 0
);

CREATE INDEX idx_categories_parent ON scenic_categories(parent_id);

-- 景点表
CREATE TABLE scenic_spots (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    category_id BIGINT REFERENCES scenic_categories(id),
    location GEOGRAPHY(POINT, 4326) NOT NULL, -- WGS84 坐标
    address VARCHAR(500),
    province VARCHAR(50),
    city VARCHAR(50),
    district VARCHAR(50),
    opening_hours JSONB, -- {"monday": "09:00-18:00", ...}
    ticket_price DECIMAL(10,2),
    duration_hours INTEGER, -- 建议游玩时长（分钟）
    crowd_level SMALLINT DEFAULT 1, -- 1:低 2:中 3:高 4:极高
    crowd_updated_at TIMESTAMP WITH TIME ZONE,
    rating DECIMAL(3,2) DEFAULT 0.0, -- 平均评分
    review_count INTEGER DEFAULT 0,
    visit_count INTEGER DEFAULT 0,
    images JSONB, -- 图片 URL 数组
    tags TEXT[], -- 标签数组
    status SMALLINT DEFAULT 1, -- 0:关闭 1:开放 2:维护
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- PostGIS 空间索引（关键！）
CREATE INDEX idx_scenic_location ON scenic_spots USING GIST (location);
CREATE INDEX idx_scenic_category ON scenic_spots(category_id);
CREATE INDEX idx_scenic_city ON scenic_spots(city);
CREATE INDEX idx_scenic_rating ON scenic_spots(rating DESC);
CREATE INDEX idx_scenic_crowd ON scenic_spots(crowd_level);

-- 景点属性表
CREATE TABLE scenic_attributes (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    type VARCHAR(50) DEFAULT 'boolean', -- boolean, enum, range
    values JSONB -- 可选值列表
);

CREATE INDEX idx_attributes_name ON scenic_attributes(name);

CREATE TABLE scenic_spot_attributes (
    scenic_spot_id BIGINT NOT NULL REFERENCES scenic_spots(id) ON DELETE CASCADE,
    attribute_id BIGINT NOT NULL REFERENCES scenic_attributes(id) ON DELETE CASCADE,
    value JSONB NOT NULL, -- 属性值
    PRIMARY KEY (scenic_spot_id, attribute_id)
);

CREATE INDEX idx_spot_attr_scenic ON scenic_spot_attributes(scenic_spot_id);
CREATE INDEX idx_spot_attr_attr ON scenic_spot_attributes(attribute_id);

-- ============================================
-- 4. 图结构（路径规划）
-- ============================================

-- 图节点表（可以是景点、路口、交通枢纽等）
CREATE TABLE graph_nodes (
    id BIGSERIAL PRIMARY KEY,
    node_type VARCHAR(50) NOT NULL, -- 'scenic', 'junction', 'transport', 'facility'
    name VARCHAR(200),
    location GEOGRAPHY(POINT, 4326) NOT NULL,
    scenic_spot_id BIGINT REFERENCES scenic_spots(id),
    facility_id BIGINT, -- 暂不设置外键，避免循环依赖
    properties JSONB, -- 节点属性
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_nodes_type ON graph_nodes(node_type);
CREATE INDEX idx_nodes_scenic ON graph_nodes(scenic_spot_id);
CREATE INDEX idx_nodes_location ON graph_nodes(location) USING GIST;

-- 图边表
CREATE TABLE graph_edges (
    id BIGSERIAL PRIMARY KEY,
    from_node_id BIGINT NOT NULL REFERENCES graph_nodes(id) ON DELETE CASCADE,
    to_node_id BIGINT NOT NULL REFERENCES graph_nodes(id) ON DELETE CASCADE,
    transport_type VARCHAR(50) NOT NULL, -- 'walk', 'bike', 'car', 'bus', 'subway'
    distance_meters INTEGER NOT NULL, -- 实际距离
    duration_seconds INTEGER NOT NULL, -- 预计耗时
    base_weight DECIMAL(10,4) NOT NULL, -- 基础权重
    dynamic_weight DECIMAL(10,4), -- 动态权重（考虑拥堵等）
    weight_updated_at TIMESTAMP WITH TIME ZONE,
    properties JSONB, -- 边属性（如：是否有电梯、坡度等）
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_edges_from ON graph_edges(from_node_id);
CREATE INDEX idx_edges_to ON graph_edges(to_node_id);
CREATE INDEX idx_edges_transport ON graph_edges(transport_type);
CREATE INDEX idx_edges_weight ON graph_edges(base_weight);
CREATE UNIQUE INDEX idx_edges_unique ON graph_edges(from_node_id, to_node_id, transport_type);

-- 交通方式配置表
CREATE TABLE transport_modes (
    id BIGSERIAL PRIMARY KEY,
    code VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    speed_factor DECIMAL(5,2) DEFAULT 1.0, -- 速度系数
    cost_per_km DECIMAL(10,2) DEFAULT 0.0, -- 每公里成本
    co2_per_km DECIMAL(10,2) DEFAULT 0.0, -- 碳排放
    enabled BOOLEAN DEFAULT true
);

-- 插入默认交通方式
INSERT INTO transport_modes (code, name, speed_factor, cost_per_km) VALUES
('walk', '步行', 1.0, 0.0),
('bike', '自行车', 3.0, 0.0),
('car', '自驾车', 8.0, 1.5),
('bus', '公交车', 5.0, 0.5),
('subway', '地铁', 10.0, 0.8);

-- ============================================
-- 5. 服务设施
-- ============================================

-- 设施分类表
CREATE TABLE facility_types (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    parent_id BIGINT REFERENCES facility_types(id),
    icon_url VARCHAR(500),
    color_code VARCHAR(20) -- 地图显示颜色
);

CREATE INDEX idx_facility_types_parent ON facility_types(parent_id);

-- 设施表
CREATE TABLE facilities (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    facility_type_id BIGINT NOT NULL REFERENCES facility_types(id),
    location GEOGRAPHY(POINT, 4326) NOT NULL,
    address VARCHAR(500),
    description TEXT,
    opening_hours JSONB,
    contact_phone VARCHAR(20),
    contact_website VARCHAR(200),
    rating DECIMAL(3,2) DEFAULT 0.0,
    review_count INTEGER DEFAULT 0,
    price_level SMALLINT, -- 1:便宜 2:适中 3:贵 4:很贵
    images JSONB,
    tags TEXT[],
    properties JSONB, -- 扩展属性
    status SMALLINT DEFAULT 1,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_facilities_type ON facilities(facility_type_id);
CREATE INDEX idx_facilities_rating ON facilities(rating DESC);
CREATE INDEX idx_facilities_location ON facilities(location) USING GIST;

-- ============================================
-- 6. 游记/日记
-- ============================================

-- 游记表
CREATE TABLE travel_diaries (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(300) NOT NULL,
    content TEXT, -- 富文本内容
    summary TEXT, -- 摘要
    cover_image_url VARCHAR(500),
    start_date DATE,
    end_date DATE,
    route_data JSONB, -- 路线数据（节点序列）
    visited_spots JSONB, -- 访问的景点列表
    total_distance_km DECIMAL(10,2),
    total_duration_hours INTEGER, -- 总时长（分钟）
    budget DECIMAL(10,2), -- 预算
    actual_cost DECIMAL(10,2), -- 实际花费
    mood SMALLINT, -- 1-5 心情评分
    visibility SMALLINT DEFAULT 1, -- 0:私密 1:公开 2:好友可见
    like_count INTEGER DEFAULT 0,
    comment_count INTEGER DEFAULT 0,
    share_count INTEGER DEFAULT 0,
    view_count INTEGER DEFAULT 0,
    is_featured BOOLEAN DEFAULT false, -- 是否精选
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    published_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_diaries_user ON travel_diaries(user_id);
CREATE INDEX idx_diaries_date ON travel_diaries(start_date DESC);
CREATE INDEX idx_diaries_visibility ON travel_diaries(visibility);
CREATE INDEX idx_diaries_featured ON travel_diaries(is_featured) WHERE is_featured = true;

-- 全文检索索引（PostgreSQL 内置）
CREATE INDEX idx_diaries_search ON travel_diaries 
    USING GIN (to_tsvector('simple', COALESCE(title, '') || ' ' || COALESCE(content, '')));

-- 游记图片表
CREATE TABLE diary_images (
    id BIGSERIAL PRIMARY KEY,
    diary_id BIGINT NOT NULL REFERENCES travel_diaries(id) ON DELETE CASCADE,
    image_url VARCHAR(500) NOT NULL,
    thumbnail_url VARCHAR(500),
    caption TEXT,
    location GEOGRAPHY(POINT, 4326), -- 拍摄地点
    taken_at TIMESTAMP WITH TIME ZONE,
    sort_order INTEGER DEFAULT 0
);

CREATE INDEX idx_images_diary ON diary_images(diary_id);
CREATE INDEX idx_images_location ON diary_images(location) USING GIST;

-- 游记景点关联表
CREATE TABLE diary_scenic_spots (
    id BIGSERIAL PRIMARY KEY,
    diary_id BIGINT NOT NULL REFERENCES travel_diaries(id) ON DELETE CASCADE,
    scenic_spot_id BIGINT NOT NULL REFERENCES scenic_spots(id),
    visit_order INTEGER, -- 访问顺序
    arrived_at TIMESTAMP WITH TIME ZONE,
    departed_at TIMESTAMP WITH TIME ZONE,
    duration_minutes INTEGER,
    user_rating DECIMAL(3,2), -- 用户对该景点的评分
    notes TEXT
);

CREATE INDEX idx_diary_spots_diary ON diary_scenic_spots(diary_id);
CREATE INDEX idx_diary_spots_scenic ON diary_scenic_spots(scenic_spot_id);
CREATE UNIQUE INDEX idx_diary_spots_unique ON diary_scenic_spots(diary_id, scenic_spot_id);

-- ============================================
-- 7. 评价体系
-- ============================================

-- 评论表
CREATE TABLE reviews (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    target_type VARCHAR(50) NOT NULL, -- 'scenic', 'facility', 'diary'
    target_id BIGINT NOT NULL, -- 关联目标 ID
    rating SMALLINT NOT NULL CHECK (rating >= 1 AND rating <= 5),
    title VARCHAR(200),
    content TEXT,
    images JSONB, -- 图片数组
    visit_date DATE,
    helpful_count INTEGER DEFAULT 0,
    not_helpful_count INTEGER DEFAULT 0,
    reply_count INTEGER DEFAULT 0,
    is_verified BOOLEAN DEFAULT false, -- 是否真实游玩后评价
    status SMALLINT DEFAULT 1, -- 0:隐藏 1:显示 2:审核中
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_reviews_target ON reviews(target_type, target_id);
CREATE INDEX idx_reviews_user ON reviews(user_id);
CREATE INDEX idx_reviews_rating ON reviews(rating);
CREATE INDEX idx_reviews_date ON reviews(visit_date DESC);

-- 全文检索索引
CREATE INDEX idx_reviews_search ON reviews 
    USING GIN (to_tsvector('simple', COALESCE(title, '') || ' ' || COALESCE(content, '')));

-- 评论标签表
CREATE TABLE review_tags (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL,
    category VARCHAR(50), -- 'positive', 'negative', 'neutral'
    color_code VARCHAR(20),
    usage_count INTEGER DEFAULT 0
);

CREATE INDEX idx_tags_category ON review_tags(category);

-- 评论 - 标签关联表
CREATE TABLE review_tag_mapping (
    review_id BIGINT NOT NULL REFERENCES reviews(id) ON DELETE CASCADE,
    tag_id BIGINT NOT NULL REFERENCES review_tags(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (review_id, tag_id)
);

CREATE INDEX idx_review_tags_review ON review_tag_mapping(review_id);
CREATE INDEX idx_review_tags_tag ON review_tag_mapping(tag_id);

-- 评论回复表
CREATE TABLE review_replies (
    id BIGSERIAL PRIMARY KEY,
    review_id BIGINT NOT NULL REFERENCES reviews(id) ON DELETE CASCADE,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    parent_reply_id BIGINT REFERENCES review_replies(id),
    like_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_replies_review ON review_replies(review_id);
CREATE INDEX idx_replies_parent ON review_replies(parent_reply_id);

-- ============================================
-- 8. 辅助表
-- ============================================

-- 搜索历史表
CREATE TABLE search_histories (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT REFERENCES users(id) ON DELETE SET NULL,
    search_query TEXT NOT NULL,
    search_type VARCHAR(50), -- 'scenic', 'facility', 'diary'
    filters JSONB, -- 搜索过滤条件
    result_count INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_search_user ON search_histories(user_id);
CREATE INDEX idx_search_created ON search_histories(created_at);

-- 系统配置表
CREATE TABLE system_configs (
    key VARCHAR(100) PRIMARY KEY,
    value JSONB NOT NULL,
    description TEXT,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- API 访问日志表
CREATE TABLE api_access_logs (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT REFERENCES users(id),
    endpoint VARCHAR(200) NOT NULL,
    method VARCHAR(10) NOT NULL,
    request_params JSONB,
    response_status INTEGER,
    response_time_ms INTEGER,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_logs_user ON api_access_logs(user_id);
CREATE INDEX idx_logs_endpoint ON api_access_logs(endpoint);
CREATE INDEX idx_logs_created ON api_access_logs(created_at);

-- ============================================
-- 9. 插入基础数据
-- ============================================

-- 插入基础景点分类
INSERT INTO scenic_categories (name, parent_id, sort_order) VALUES
('自然景观', NULL, 1),
('人文景观', NULL, 2),
('主题乐园', NULL, 3),
('博物馆', NULL, 4),
('山水风光', 1, 1),
('海滨海岛', 1, 2),
('森林草原', 1, 3),
('历史古迹', 2, 1),
('宗教建筑', 2, 2),
('现代建筑', 2, 3);

-- 插入基础设施分类
INSERT INTO facility_types (name, parent_id, color_code) VALUES
('餐饮', NULL, '#FF6B6B'),
('住宿', NULL, '#4ECDC4'),
('交通', NULL, '#45B7D1'),
('购物', NULL, '#FFA07A'),
('医疗', NULL, '#98D8C8'),
('卫生间', NULL, '#F7DC6F'),
('停车场', NULL, '#BB8FCE'),
('餐厅', 1, '#FF6B6B'),
('咖啡厅', 1, '#FF8C8C'),
('酒店', 2, '#4ECDC4'),
('地铁站', 3, '#45B7D1'),
('公交站', 3, '#5BC0DE');

-- 插入基础评论标签
INSERT INTO review_tags (name, category, color_code) VALUES
('风景优美', 'positive', '#2ECC71'),
('服务好', 'positive', '#2ECC71'),
('值得推荐', 'positive', '#2ECC71'),
('交通便利', 'positive', '#2ECC71'),
('性价比高', 'positive', '#2ECC71'),
('人多拥挤', 'negative', '#E74C3C'),
('价格贵', 'negative', '#E74C3C'),
('设施旧', 'negative', '#E74C3C'),
('一般般', 'neutral', '#95A5A6'),
('有改进空间', 'neutral', '#95A5A6');

-- ============================================
-- 10. 创建触发器（自动更新时间）
-- ============================================

-- 创建更新时间触发器函数
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 为需要自动更新时间的表添加触发器
CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_preferences_updated_at
    BEFORE UPDATE ON user_preferences
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_scenic_spots_updated_at
    BEFORE UPDATE ON scenic_spots
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_facilities_updated_at
    BEFORE UPDATE ON facilities
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_travel_diaries_updated_at
    BEFORE UPDATE ON travel_diaries
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_reviews_updated_at
    BEFORE UPDATE ON reviews
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- 11. 创建物化视图（性能优化）
-- ============================================

-- 热门景点统计视图
CREATE MATERIALIZED VIEW mv_hot_scenic_spots AS
SELECT 
    ss.id,
    ss.name,
    ss.rating,
    ss.review_count,
    ss.visit_count,
    COUNT(uf.id) AS favorite_count,
    (ss.rating * 0.4 + LOG(ss.visit_count + 1) * 0.3 + ss.review_count * 0.3) AS hot_score
FROM scenic_spots ss
LEFT JOIN user_favorites uf ON uf.scenic_spot_id = ss.id
WHERE ss.status = 1
GROUP BY ss.id
WITH DATA;

-- 创建物化视图索引
CREATE INDEX idx_mv_hot_spots_score ON mv_hot_scenic_spots(hot_score DESC);
CREATE INDEX idx_mv_hot_spots_rating ON mv_hot_scenic_spots(rating DESC);

-- ============================================
-- Schema 创建完成
-- ============================================

COMMENT ON SCHEMA public IS '个性化旅游系统数据库 - v1.0 (2026-03-31)';
