SET client_encoding = 'UTF8';

-- =====================================================
-- Personalized Tourism System - Demo Seed Data
-- =====================================================
-- Small, deterministic data set for local demos.
-- The records are manually curated around central Beijing landmarks.
-- If AMap/Gaode data is used later, keep the same table order and replace
-- the values below with API-generated INSERT statements.
-- =====================================================

BEGIN;

-- Demo users
INSERT INTO users
    (id, username, password_hash, email, phone, nickname, gender, birth_date, preferences, status)
VALUES
    (1, 'demo_user', 'demo_hash_not_for_production', 'demo@example.com', '13800000001', '演示用户', 0, '2000-01-01', '{"themes":["history","culture"],"budget":"medium","transport":"walk"}', 1),
    (2, 'traveler_li', 'demo_hash_not_for_production', 'li@example.com', '13800000002', '李同学', 1, '1999-06-12', '{"themes":["museum","citywalk"],"budget":"low","transport":"subway"}', 1),
    (3, 'planner_wang', 'demo_hash_not_for_production', 'wang@example.com', '13800000003', '王规划', 2, '1998-11-08', '{"themes":["architecture","photo"],"budget":"medium","transport":"bike"}', 1)
ON CONFLICT (id) DO UPDATE SET
    username = EXCLUDED.username,
    password_hash = EXCLUDED.password_hash,
    email = EXCLUDED.email,
    phone = EXCLUDED.phone,
    nickname = EXCLUDED.nickname,
    gender = EXCLUDED.gender,
    birth_date = EXCLUDED.birth_date,
    preferences = EXCLUDED.preferences,
    status = EXCLUDED.status;

INSERT INTO user_preferences
    (user_id, preference_type, preference_value, weight)
VALUES
    (1, 'scenic_type', '["历史古迹","博物馆"]', 1.00),
    (1, 'transport', '["walk","subway"]', 0.90),
    (2, 'scenic_type', '["博物馆","城市漫步"]', 0.95),
    (3, 'scenic_type', '["建筑","摄影"]', 0.85)
ON CONFLICT (user_id, preference_type) DO UPDATE SET
    preference_value = EXCLUDED.preference_value,
    weight = EXCLUDED.weight;

-- Categories
INSERT INTO categories
    (id, name, description, icon, parent_id, sort_order)
VALUES
    (1, '历史古迹', '历史文化遗产与古建筑', 'landmark', NULL, 1),
    (2, '博物馆', '展览、文博与公共文化空间', 'museum', NULL, 2),
    (3, '城市公园', '休闲散步和自然景观', 'trees', NULL, 3),
    (4, '商业街区', '购物、美食与夜游区域', 'shopping-bag', NULL, 4),
    (5, '观景摄影', '适合拍照与城市观景的地点', 'camera', NULL, 5)
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    description = EXCLUDED.description,
    icon = EXCLUDED.icon,
    sort_order = EXCLUDED.sort_order;

-- Scenic spots
INSERT INTO scenic_spots
    (id, name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url,
     view_count, favorite_count, tags, status)
VALUES
    (1, '故宫博物院', '明清皇家宫殿建筑群，适合作为历史文化路线的核心节点。',
     ST_SetSRID(ST_MakePoint(116.397026, 39.918058), 4326)::geography, 1, 4.80, 1250, '北京市东城区景山前街4号', '北京',
     '08:30-17:00', 60.00, 240, 4, ARRAY['https://example.com/images/forbidden-city.jpg'], 'https://example.com/images/forbidden-city-thumb.jpg',
     52000, 8600, ARRAY['历史','宫殿','世界遗产','亲子'], 1),
    (2, '天安门广场', '北京中轴线上的开放式城市广场，可与故宫、前门串联游览。',
     ST_SetSRID(ST_MakePoint(116.397477, 39.908692), 4326)::geography, 1, 4.60, 980, '北京市东城区东长安街', '北京',
     '全天开放', 0.00, 60, 3, ARRAY['https://example.com/images/tiananmen.jpg'], 'https://example.com/images/tiananmen-thumb.jpg',
     43000, 7200, ARRAY['地标','广场','中轴线'], 1),
    (3, '景山公园', '登上万春亭可以俯瞰故宫和北京中轴线。',
     ST_SetSRID(ST_MakePoint(116.396621, 39.925048), 4326)::geography, 3, 4.55, 620, '北京市西城区景山西街44号', '北京',
     '06:00-21:00', 2.00, 90, 2, ARRAY['https://example.com/images/jingshan.jpg'], 'https://example.com/images/jingshan-thumb.jpg',
     21000, 3500, ARRAY['公园','观景','摄影'], 1),
    (4, '北海公园', '皇家园林代表，适合湖边散步和轻松游览。',
     ST_SetSRID(ST_MakePoint(116.389535, 39.925455), 4326)::geography, 3, 4.50, 540, '北京市西城区文津街1号', '北京',
     '06:30-20:00', 10.00, 120, 2, ARRAY['https://example.com/images/beihai.jpg'], 'https://example.com/images/beihai-thumb.jpg',
     18500, 2800, ARRAY['公园','湖景','皇家园林'], 1),
    (5, '国家博物馆', '大型综合博物馆，适合文化主题推荐和室内路线。',
     ST_SetSRID(ST_MakePoint(116.401015, 39.905103), 4326)::geography, 2, 4.70, 860, '北京市东城区东长安街16号', '北京',
     '09:00-17:00', 0.00, 180, 3, ARRAY['https://example.com/images/national-museum.jpg'], 'https://example.com/images/national-museum-thumb.jpg',
     36000, 5100, ARRAY['博物馆','展览','室内'], 1),
    (6, '前门大街', '北京传统商业街区，可作为餐饮和夜游节点。',
     ST_SetSRID(ST_MakePoint(116.397957, 39.899318), 4326)::geography, 4, 4.30, 460, '北京市东城区前门大街', '北京',
     '全天开放', 0.00, 120, 3, ARRAY['https://example.com/images/qianmen.jpg'], 'https://example.com/images/qianmen-thumb.jpg',
     24000, 3300, ARRAY['商业街','美食','夜游'], 1),
    (7, '王府井步行街', '购物、美食与城市夜景体验区域。',
     ST_SetSRID(ST_MakePoint(116.411013, 39.912657), 4326)::geography, 4, 4.20, 520, '北京市东城区王府井大街', '北京',
     '全天开放', 0.00, 120, 3, ARRAY['https://example.com/images/wangfujing.jpg'], 'https://example.com/images/wangfujing-thumb.jpg',
     27500, 3900, ARRAY['购物','美食','步行街'], 1),
    (8, '鼓楼', '老城地标，适合与什刹海、南锣鼓巷形成城市漫步路线。',
     ST_SetSRID(ST_MakePoint(116.393776, 39.940269), 4326)::geography, 5, 4.40, 390, '北京市东城区地安门外大街', '北京',
     '09:30-17:30', 20.00, 90, 2, ARRAY['https://example.com/images/drum-tower.jpg'], 'https://example.com/images/drum-tower-thumb.jpg',
     16800, 2600, ARRAY['地标','摄影','胡同'], 1)
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    description = EXCLUDED.description,
    location = EXCLUDED.location,
    category_id = EXCLUDED.category_id,
    rating = EXCLUDED.rating,
    rating_count = EXCLUDED.rating_count,
    address = EXCLUDED.address,
    city = EXCLUDED.city,
    opening_hours = EXCLUDED.opening_hours,
    ticket_price = EXCLUDED.ticket_price,
    duration_minutes = EXCLUDED.duration_minutes,
    crowd_level = EXCLUDED.crowd_level,
    images = EXCLUDED.images,
    thumbnail_url = EXCLUDED.thumbnail_url,
    view_count = EXCLUDED.view_count,
    favorite_count = EXCLUDED.favorite_count,
    tags = EXCLUDED.tags,
    status = EXCLUDED.status;

-- Nearby facilities
INSERT INTO facilities
    (id, name, type, location, address, rating, price_level, opening_hours, phone)
VALUES
    (1, '故宫游客服务中心', 'service', ST_SetSRID(ST_MakePoint(116.397400, 39.916900), 4326)::geography, '故宫午门附近', 4.60, 1, '08:30-17:00', '010-85000001'),
    (2, '角楼咖啡', 'restaurant', ST_SetSRID(ST_MakePoint(116.399064, 39.924178), 4326)::geography, '故宫神武门附近', 4.50, 2, '09:00-18:00', '010-85000002'),
    (3, '天安门东地铁站', 'subway', ST_SetSRID(ST_MakePoint(116.401216, 39.908780), 4326)::geography, '地铁1号线天安门东站', 4.20, 1, '05:00-23:30', NULL),
    (4, '前门地铁站', 'subway', ST_SetSRID(ST_MakePoint(116.397937, 39.900192), 4326)::geography, '地铁2号线前门站', 4.20, 1, '05:00-23:30', NULL),
    (5, '四季民福前门店', 'restaurant', ST_SetSRID(ST_MakePoint(116.397371, 39.899049), 4326)::geography, '前门商业区', 4.70, 3, '10:30-22:00', '010-85000005'),
    (6, '北京饭店', 'hotel', ST_SetSRID(ST_MakePoint(116.405031, 39.909705), 4326)::geography, '东长安街33号', 4.60, 4, '全天', '010-85000006'),
    (7, '景山公园东门停车场', 'parking', ST_SetSRID(ST_MakePoint(116.398786, 39.925053), 4326)::geography, '景山东街', 4.00, 2, '07:00-21:00', NULL),
    (8, '北海北地铁站', 'subway', ST_SetSRID(ST_MakePoint(116.386829, 39.933247), 4326)::geography, '地铁6号线北海北站', 4.20, 1, '05:00-23:30', NULL),
    (9, '王府井小吃街', 'restaurant', ST_SetSRID(ST_MakePoint(116.410946, 39.914742), 4326)::geography, '王府井商业区', 4.10, 2, '10:00-22:00', NULL),
    (10, '东华门公共卫生间', 'toilet', ST_SetSRID(ST_MakePoint(116.404061, 39.918965), 4326)::geography, '东华门附近', 4.00, 1, '07:00-22:00', NULL),
    (11, '什刹海游客中心', 'service', ST_SetSRID(ST_MakePoint(116.390855, 39.937661), 4326)::geography, '什刹海景区', 4.30, 1, '09:00-18:00', '010-85000011'),
    (12, '鼓楼西侧停车场', 'parking', ST_SetSRID(ST_MakePoint(116.391540, 39.939830), 4326)::geography, '鼓楼西大街', 3.90, 2, '08:00-22:00', NULL)
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    type = EXCLUDED.type,
    location = EXCLUDED.location,
    address = EXCLUDED.address,
    rating = EXCLUDED.rating,
    price_level = EXCLUDED.price_level,
    opening_hours = EXCLUDED.opening_hours,
    phone = EXCLUDED.phone;

-- Graph nodes: scenic spots, facilities, and transfer points
INSERT INTO graph_nodes
    (id, name, location, node_type, scenic_spot_id, facility_id, congestion_level)
VALUES
    (1, '故宫博物院节点', ST_SetSRID(ST_MakePoint(116.397026, 39.918058), 4326)::geography, 'scenic', 1, NULL, 4),
    (2, '天安门广场节点', ST_SetSRID(ST_MakePoint(116.397477, 39.908692), 4326)::geography, 'scenic', 2, NULL, 3),
    (3, '景山公园节点', ST_SetSRID(ST_MakePoint(116.396621, 39.925048), 4326)::geography, 'scenic', 3, NULL, 2),
    (4, '北海公园节点', ST_SetSRID(ST_MakePoint(116.389535, 39.925455), 4326)::geography, 'scenic', 4, NULL, 2),
    (5, '国家博物馆节点', ST_SetSRID(ST_MakePoint(116.401015, 39.905103), 4326)::geography, 'scenic', 5, NULL, 3),
    (6, '前门大街节点', ST_SetSRID(ST_MakePoint(116.397957, 39.899318), 4326)::geography, 'scenic', 6, NULL, 3),
    (7, '王府井步行街节点', ST_SetSRID(ST_MakePoint(116.411013, 39.912657), 4326)::geography, 'scenic', 7, NULL, 3),
    (8, '鼓楼节点', ST_SetSRID(ST_MakePoint(116.393776, 39.940269), 4326)::geography, 'scenic', 8, NULL, 2),
    (101, '天安门东地铁节点', ST_SetSRID(ST_MakePoint(116.401216, 39.908780), 4326)::geography, 'facility', NULL, 3, 2),
    (102, '前门地铁节点', ST_SetSRID(ST_MakePoint(116.397937, 39.900192), 4326)::geography, 'facility', NULL, 4, 2),
    (103, '北海北地铁节点', ST_SetSRID(ST_MakePoint(116.386829, 39.933247), 4326)::geography, 'facility', NULL, 8, 2),
    (104, '故宫北门换乘点', ST_SetSRID(ST_MakePoint(116.397712, 39.923724), 4326)::geography, 'entrance', NULL, NULL, 3),
    (105, '前门餐饮节点', ST_SetSRID(ST_MakePoint(116.397371, 39.899049), 4326)::geography, 'facility', NULL, 5, 3),
    (106, '王府井餐饮节点', ST_SetSRID(ST_MakePoint(116.410946, 39.914742), 4326)::geography, 'facility', NULL, 9, 3),
    (107, '什刹海游客节点', ST_SetSRID(ST_MakePoint(116.390855, 39.937661), 4326)::geography, 'facility', NULL, 11, 2)
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    location = EXCLUDED.location,
    node_type = EXCLUDED.node_type,
    scenic_spot_id = EXCLUDED.scenic_spot_id,
    facility_id = EXCLUDED.facility_id,
    congestion_level = EXCLUDED.congestion_level;

-- Graph edges for route planning demo
INSERT INTO graph_edges
    (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level)
VALUES
    (2, 1, 1050, 'walk', 900, 10.50, 3),
    (1, 2, 1050, 'walk', 900, 10.50, 3),
    (1, 104, 650, 'walk', 560, 6.50, 3),
    (104, 1, 650, 'walk', 560, 6.50, 3),
    (104, 3, 520, 'walk', 450, 5.20, 2),
    (3, 104, 520, 'walk', 450, 5.20, 2),
    (3, 4, 900, 'walk', 780, 9.00, 2),
    (4, 3, 900, 'walk', 780, 9.00, 2),
    (4, 103, 980, 'walk', 840, 9.80, 2),
    (103, 4, 980, 'walk', 840, 9.80, 2),
    (103, 8, 1150, 'bike', 420, 8.00, 2),
    (8, 103, 1150, 'bike', 420, 8.00, 2),
    (2, 5, 620, 'walk', 530, 6.20, 3),
    (5, 2, 620, 'walk', 530, 6.20, 3),
    (5, 101, 380, 'walk', 320, 3.80, 2),
    (101, 5, 380, 'walk', 320, 3.80, 2),
    (2, 102, 980, 'walk', 820, 9.80, 3),
    (102, 2, 980, 'walk', 820, 9.80, 3),
    (102, 6, 240, 'walk', 210, 2.40, 2),
    (6, 102, 240, 'walk', 210, 2.40, 2),
    (6, 105, 120, 'walk', 120, 1.20, 2),
    (105, 6, 120, 'walk', 120, 1.20, 2),
    (1, 7, 1700, 'bike', 620, 11.00, 3),
    (7, 1, 1700, 'bike', 620, 11.00, 3),
    (7, 106, 300, 'walk', 260, 3.00, 3),
    (106, 7, 300, 'walk', 260, 3.00, 3),
    (8, 107, 450, 'walk', 390, 4.50, 2),
    (107, 8, 450, 'walk', 390, 4.50, 2),
    (101, 102, 1200, 'subway', 180, 4.50, 2),
    (102, 101, 1200, 'subway', 180, 4.50, 2),
    (101, 7, 1250, 'bike', 460, 8.50, 3),
    (7, 101, 1250, 'bike', 460, 8.50, 3)
ON CONFLICT (from_node, to_node, travel_mode) DO UPDATE SET
    distance = EXCLUDED.distance,
    travel_time = EXCLUDED.travel_time,
    base_weight = EXCLUDED.base_weight,
    congestion_level = EXCLUDED.congestion_level;

-- Favorites, reviews, and diaries
INSERT INTO user_favorites (user_id, scenic_spot_id)
VALUES
    (1, 1),
    (1, 3),
    (1, 5),
    (2, 5),
    (2, 6),
    (3, 3),
    (3, 8)
ON CONFLICT (user_id, scenic_spot_id) DO NOTHING;

INSERT INTO reviews
    (id, user_id, scenic_spot_id, rating, content, images, helpful_count, status)
VALUES
    (1, 1, 1, 5, '故宫适合安排半天以上，建议提前预约并从中轴线慢慢走。', ARRAY[]::TEXT[], 12, 1),
    (2, 2, 5, 5, '国家博物馆很适合雨天或高温天气，展览信息密度很高。', ARRAY[]::TEXT[], 8, 1),
    (3, 3, 3, 4, '景山视角很好，傍晚拍故宫非常出片。', ARRAY[]::TEXT[], 6, 1),
    (4, 1, 6, 4, '前门大街餐饮选择多，适合放在路线结尾。', ARRAY[]::TEXT[], 5, 1),
    (5, 2, 8, 4, '鼓楼和什刹海可以串联成轻松 citywalk。', ARRAY[]::TEXT[], 4, 1)
ON CONFLICT (id) DO UPDATE SET
    user_id = EXCLUDED.user_id,
    scenic_spot_id = EXCLUDED.scenic_spot_id,
    rating = EXCLUDED.rating,
    content = EXCLUDED.content,
    images = EXCLUDED.images,
    helpful_count = EXCLUDED.helpful_count,
    status = EXCLUDED.status;

INSERT INTO travel_diaries
    (id, user_id, title, summary, content, status, scenic_spot_ids, start_date, end_date,
     total_distance_km, images, tags, view_count, like_count, comment_count, aigc_summary, aigc_title)
VALUES
    (1, 1, '中轴线一日游：从前门到景山',
     '一条适合初次来北京的经典历史路线。',
     '上午从前门出发，经过天安门广场进入故宫，下午登上景山看中轴线。整体步行强度中等，适合文化主题推荐演示。',
     1, ARRAY[6,2,1,3], '2026-04-12', '2026-04-12', 5.20, ARRAY['https://example.com/images/diary-axis.jpg'],
     ARRAY['中轴线','历史','一日游'], 430, 38, 6, '前门、天安门、故宫、景山串联的一日游路线。', '北京中轴线一日游'),
    (2, 2, '博物馆和商业街的轻松路线',
     '国家博物馆加王府井，适合室内展览与晚间餐饮。',
     '白天参观国家博物馆，傍晚骑行到王府井吃饭购物。路线较短，适合低预算学生出行。',
     1, ARRAY[5,7], '2026-04-18', '2026-04-18', 2.10, ARRAY['https://example.com/images/diary-museum.jpg'],
     ARRAY['博物馆','王府井','低预算'], 360, 31, 4, '国家博物馆与王府井组合，适合轻松城市游。', '展览与夜游半日路线'),
    (3, 3, '鼓楼到北海的 citywalk',
     '老城摄影与公园散步路线。',
     '从鼓楼出发，经什刹海到北海公园，最后可以去景山看日落。适合摄影偏好用户。',
     1, ARRAY[8,4,3], '2026-04-26', '2026-04-26', 3.80, ARRAY['https://example.com/images/diary-citywalk.jpg'],
     ARRAY['摄影','公园','citywalk'], 290, 24, 3, '鼓楼、什刹海、北海、景山构成轻量 citywalk。', '老城摄影漫步')
ON CONFLICT (id) DO UPDATE SET
    user_id = EXCLUDED.user_id,
    title = EXCLUDED.title,
    summary = EXCLUDED.summary,
    content = EXCLUDED.content,
    status = EXCLUDED.status,
    scenic_spot_ids = EXCLUDED.scenic_spot_ids,
    start_date = EXCLUDED.start_date,
    end_date = EXCLUDED.end_date,
    total_distance_km = EXCLUDED.total_distance_km,
    images = EXCLUDED.images,
    tags = EXCLUDED.tags,
    view_count = EXCLUDED.view_count,
    like_count = EXCLUDED.like_count,
    comment_count = EXCLUDED.comment_count,
    aigc_summary = EXCLUDED.aigc_summary,
    aigc_title = EXCLUDED.aigc_title;

INSERT INTO route_plans
    (id, user_id, title, start_node_id, end_node_id, waypoint_node_ids, travel_mode,
     total_distance, total_duration, route_geometry, optimization_type)
VALUES
    (1, 1, '前门-天安门-故宫-景山路线', 6, 3, ARRAY[2,1], 'walk',
     3200, 2700, '{"coordinates":[[116.397957,39.899318],[116.397477,39.908692],[116.397026,39.918058],[116.396621,39.925048]]}', 'balanced'),
    (2, 2, '国家博物馆到王府井骑行', 5, 7, ARRAY[101], 'bike',
     2100, 900, '{"coordinates":[[116.401015,39.905103],[116.401216,39.908780],[116.411013,39.912657]]}', 'time'),
    (3, 3, '鼓楼-北海-景山摄影路线', 8, 3, ARRAY[107,4], 'walk',
     3800, 3300, '{"coordinates":[[116.393776,39.940269],[116.390855,39.937661],[116.389535,39.925455],[116.396621,39.925048]]}', 'distance')
ON CONFLICT (id) DO UPDATE SET
    user_id = EXCLUDED.user_id,
    title = EXCLUDED.title,
    start_node_id = EXCLUDED.start_node_id,
    end_node_id = EXCLUDED.end_node_id,
    waypoint_node_ids = EXCLUDED.waypoint_node_ids,
    travel_mode = EXCLUDED.travel_mode,
    total_distance = EXCLUDED.total_distance,
    total_duration = EXCLUDED.total_duration,
    route_geometry = EXCLUDED.route_geometry,
    optimization_type = EXCLUDED.optimization_type;

-- Achievements and collectibles
INSERT INTO achievements
    (id, name, description, icon_url, level, type, requirement, reward)
VALUES
    (1, '中轴线探索者', '完成一条包含前门、天安门、故宫、景山的路线。', 'https://example.com/icons/axis.png', 1, 'exploration', '{"route_contains":[6,2,1,3]}', '{"points":100}'),
    (2, '博物馆爱好者', '收藏或评价博物馆类景点。', 'https://example.com/icons/museum.png', 1, 'review', '{"category_id":2,"action":"review"}', '{"points":60}'),
    (3, '城市漫步达人', '完成一条 3 公里以上 citywalk 路线。', 'https://example.com/icons/walk.png', 2, 'diary', '{"min_distance_km":3}', '{"points":120}')
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    description = EXCLUDED.description,
    icon_url = EXCLUDED.icon_url,
    level = EXCLUDED.level,
    type = EXCLUDED.type,
    requirement = EXCLUDED.requirement,
    reward = EXCLUDED.reward;

INSERT INTO user_achievements
    (user_id, achievement_id, progress, status, unlocked_at)
VALUES
    (1, 1, '{"completed":true}', 'unlocked', CURRENT_TIMESTAMP),
    (2, 2, '{"review_count":1}', 'unlocked', CURRENT_TIMESTAMP),
    (3, 3, '{"distance_km":3.8}', 'unlocked', CURRENT_TIMESTAMP)
ON CONFLICT (user_id, achievement_id) DO UPDATE SET
    progress = EXCLUDED.progress,
    status = EXCLUDED.status,
    unlocked_at = EXCLUDED.unlocked_at;

INSERT INTO digital_collectibles
    (id, user_id, achievement_id, diary_id, token_id, name, description, image_url, metadata, blockchain_hash, minted_at)
VALUES
    (1, 1, 1, 1, 'DEMO-AXIS-001', '中轴线纪念章', '完成北京中轴线演示路线后获得的模拟数字藏品。', 'https://example.com/collectibles/axis.png', '{"demo":true,"city":"Beijing"}', 'demo-hash-axis-001', CURRENT_TIMESTAMP),
    (2, 3, 3, 3, 'DEMO-WALK-001', '老城漫步纪念章', '完成鼓楼到北海 citywalk 后获得的模拟数字藏品。', 'https://example.com/collectibles/walk.png', '{"demo":true,"theme":"citywalk"}', 'demo-hash-walk-001', CURRENT_TIMESTAMP)
ON CONFLICT (id) DO UPDATE SET
    user_id = EXCLUDED.user_id,
    achievement_id = EXCLUDED.achievement_id,
    diary_id = EXCLUDED.diary_id,
    token_id = EXCLUDED.token_id,
    name = EXCLUDED.name,
    description = EXCLUDED.description,
    image_url = EXCLUDED.image_url,
    metadata = EXCLUDED.metadata,
    blockchain_hash = EXCLUDED.blockchain_hash,
    minted_at = EXCLUDED.minted_at;

-- Keep SERIAL/BIGSERIAL counters ahead of explicit demo ids.
SELECT setval('users_id_seq', (SELECT MAX(id) FROM users));
SELECT setval('categories_id_seq', (SELECT MAX(id) FROM categories));
SELECT setval('scenic_spots_id_seq', (SELECT MAX(id) FROM scenic_spots));
SELECT setval('facilities_id_seq', (SELECT MAX(id) FROM facilities));
SELECT setval('graph_nodes_id_seq', (SELECT MAX(id) FROM graph_nodes));
SELECT setval('graph_edges_id_seq', (SELECT MAX(id) FROM graph_edges));
SELECT setval('reviews_id_seq', (SELECT MAX(id) FROM reviews));
SELECT setval('travel_diaries_id_seq', (SELECT MAX(id) FROM travel_diaries));
SELECT setval('route_plans_id_seq', (SELECT MAX(id) FROM route_plans));
SELECT setval('achievements_id_seq', (SELECT MAX(id) FROM achievements));
SELECT setval('digital_collectibles_id_seq', (SELECT MAX(id) FROM digital_collectibles));

COMMIT;
