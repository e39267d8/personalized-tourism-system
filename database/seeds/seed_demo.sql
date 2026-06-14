SET client_encoding = 'UTF8';

-- =====================================================
-- 个性化旅游系统 - 基础演示数据
-- =====================================================
-- 景点主数据只由 database/imports/amap_pois.sql 管理。
-- 本文件只负责用户、分类、设施、路线、游记、评论、成就等演示关系数据。
-- 需要关联景点时，按景点名称从 scenic_spots 动态查找 id，避免和高德导入数据重复。
-- =====================================================

BEGIN;

-- 演示用户
INSERT INTO users
    (id, username, password_hash, email, phone, nickname, gender, birth_date, preferences, status)
VALUES
    (1, 'demo_user', 'pbkdf2_sha256$20000$746f757270696c6f745f64656d6f5f31$30816d10380edb332c6eeec9f33fb6184319e03cf491a1f89ede57ddd3031183', 'demo@example.com', '13800000001', '演示用户', 0, '2000-01-01', '{"themes":["history","culture"],"budget":"medium","transport":"walk"}', 1),
    (2, 'traveler_li', 'pbkdf2_sha256$20000$746f757270696c6f745f64656d6f5f31$30816d10380edb332c6eeec9f33fb6184319e03cf491a1f89ede57ddd3031183', 'li@example.com', '13800000002', '李同学', 1, '1999-06-12', '{"themes":["museum","citywalk"],"budget":"low","transport":"subway"}', 1),
    (3, 'planner_wang', 'pbkdf2_sha256$20000$746f757270696c6f745f64656d6f5f31$30816d10380edb332c6eeec9f33fb6184319e03cf491a1f89ede57ddd3031183', 'wang@example.com', '13800000003', '王规划', 2, '1998-11-08', '{"themes":["architecture","photo"],"budget":"medium","transport":"bike"}', 1)
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

-- 景点分类。id=1 保留为高德导入使用的通用分类。
INSERT INTO categories
    (id, name, description, icon, parent_id, sort_order)
VALUES
    (1, '旅游景点', '高德 POI 导入时使用的通用景点分类', 'map-pin', NULL, 1),
    (2, '历史古迹', '历史文化遗产与古建筑', 'landmark', NULL, 2),
    (3, '博物馆', '展览、文博与公共文化空间', 'museum', NULL, 3),
    (4, '城市公园', '休闲散步和自然景观', 'trees', NULL, 4),
    (5, '商业街区', '购物、美食与夜游区域', 'shopping-bag', NULL, 5),
    (6, '观景摄影', '适合拍照与城市观景的地点', 'camera', NULL, 6)
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    description = EXCLUDED.description,
    icon = EXCLUDED.icon,
    sort_order = EXCLUDED.sort_order;

INSERT INTO categories (id, name, description, icon, parent_id, sort_order)
VALUES (7, '城市地标', '城市广场、地标建筑与公共空间', 'building-2', NULL, 7)
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    description = EXCLUDED.description,
    icon = EXCLUDED.icon,
    sort_order = EXCLUDED.sort_order;

WITH category_rules(category_id, priority, keywords) AS (
    VALUES
        (3, 10, ARRAY['博物馆','纪念馆','展览','美术馆','科技馆','文化馆']::TEXT[]),
        (7, 20, ARRAY['广场','地标','城楼','电视塔','体育场','中心']::TEXT[]),
        (5, 30, ARRAY['商业','购物','步行街','美食','小吃','夜市','酒吧','餐厅','工体','三里屯','王府井','前门']::TEXT[]),
        (4, 40, ARRAY['公园','森林','湿地','湖','山','自然','园林','植物园','动物园','颐和园','圆明园','北海']::TEXT[]),
        (2, 50, ARRAY['历史','古迹','古建','遗址','故宫','长城','寺','庙','宫','塔','陵','文化遗产','天坛','雍和宫']::TEXT[]),
        (6, 60, ARRAY['摄影','观景','打卡','日落','夜景','俯瞰']::TEXT[])
),
matched_categories AS (
    SELECT DISTINCT ON (s.id)
        s.id,
        r.category_id
    FROM scenic_spots s
    JOIN category_rules r ON EXISTS (
        SELECT 1
        FROM unnest(r.keywords) AS keyword(value)
        WHERE COALESCE(s.name, '') ILIKE '%' || keyword.value || '%'
           OR COALESCE(s.description, '') ILIKE '%' || keyword.value || '%'
           OR COALESCE(array_to_string(s.tags, ' '), '') ILIKE '%' || keyword.value || '%'
    )
    WHERE s.status = 1
      AND (s.category_id IS NULL OR s.category_id = 1)
    ORDER BY s.id, r.priority
)
UPDATE scenic_spots s
SET category_id = matched.category_id
FROM matched_categories matched
WHERE s.id = matched.id;

-- 从高德导入后的景点表中查找演示关系需要的景点 id。
CREATE TEMP TABLE tmp_demo_spots ON COMMIT DROP AS
WITH wanted(key, aliases, ref_lng, ref_lat) AS (
    VALUES
        ('gugong', ARRAY['故宫博物院','故宫','紫禁城']::TEXT[], 116.397026::DOUBLE PRECISION, 39.918058::DOUBLE PRECISION),
        ('tiananmen', ARRAY['天安门广场','天安门']::TEXT[], 116.397477::DOUBLE PRECISION, 39.908692::DOUBLE PRECISION),
        ('jingshan', ARRAY['景山公园','景山']::TEXT[], 116.396621::DOUBLE PRECISION, 39.925048::DOUBLE PRECISION),
        ('beihai', ARRAY['北海公园','北海']::TEXT[], 116.389535::DOUBLE PRECISION, 39.925455::DOUBLE PRECISION),
        ('guobo', ARRAY['中国国家博物馆','国家博物馆','国博']::TEXT[], 116.401015::DOUBLE PRECISION, 39.905103::DOUBLE PRECISION),
        ('qianmen', ARRAY['前门大街','前门','正阳门']::TEXT[], 116.397957::DOUBLE PRECISION, 39.899318::DOUBLE PRECISION),
        ('tiantan', ARRAY['天坛公园','天坛']::TEXT[], 116.406601::DOUBLE PRECISION, 39.882156::DOUBLE PRECISION),
        ('wangfujing', ARRAY['王府井步行街','王府井']::TEXT[], 116.411013::DOUBLE PRECISION, 39.912657::DOUBLE PRECISION),
        ('gulou', ARRAY['鼓楼','钟楼']::TEXT[], 116.393776::DOUBLE PRECISION, 39.940269::DOUBLE PRECISION)
),
candidates AS (
    SELECT
        w.key,
        s.id,
        s.name,
        CASE WHEN COALESCE(s.city, '') IN ('北京', '北京市') THEN 0 ELSE 1 END AS city_rank,
        CASE
            WHEN lower(trim(s.name)) = lower(trim(w.aliases[1])) THEN 0
            WHEN s.name ILIKE w.aliases[1] || '%' THEN 1
            ELSE 2
        END AS name_rank,
        ST_Distance(
            s.location,
            ST_SetSRID(ST_MakePoint(w.ref_lng, w.ref_lat), 4326)::geography
        ) AS distance_meters
    FROM wanted w
    JOIN scenic_spots s
      ON EXISTS (
          SELECT 1
          FROM unnest(w.aliases) AS alias_item(alias_name)
          WHERE s.name ILIKE '%' || alias_item.alias_name || '%'
      )
)
SELECT DISTINCT ON (key)
    key,
    id AS spot_id,
    name AS matched_name
FROM candidates
ORDER BY key, city_rank, name_rank, distance_meters, length(name), id;

-- 周边设施
INSERT INTO facilities
    (id, name, type, location, address, rating, price_level, opening_hours, phone, scenic_spot_id)
VALUES
    (1, '故宫游客服务中心', 'service', ST_SetSRID(ST_MakePoint(116.397400, 39.916900), 4326)::geography, '故宫午门附近', 4.60, 1, '08:30-17:00', '010-85000001', (SELECT spot_id FROM tmp_demo_spots WHERE key = 'gugong')),
    (2, '角楼咖啡', 'restaurant', ST_SetSRID(ST_MakePoint(116.399064, 39.924178), 4326)::geography, '故宫神武门附近', 4.50, 2, '09:00-18:00', '010-85000002', (SELECT spot_id FROM tmp_demo_spots WHERE key = 'gugong')),
    (3, '天安门东地铁站', 'subway', ST_SetSRID(ST_MakePoint(116.401216, 39.908780), 4326)::geography, '地铁1号线天安门东站', 4.20, 1, '05:00-23:30', NULL, (SELECT spot_id FROM tmp_demo_spots WHERE key = 'tiananmen')),
    (4, '前门地铁站', 'subway', ST_SetSRID(ST_MakePoint(116.397937, 39.900192), 4326)::geography, '地铁2号线前门站', 4.20, 1, '05:00-23:30', NULL, (SELECT spot_id FROM tmp_demo_spots WHERE key = 'qianmen')),
    (5, '四季民福前门店', 'restaurant', ST_SetSRID(ST_MakePoint(116.397371, 39.899049), 4326)::geography, '前门商业区', 4.70, 3, '10:30-22:00', '010-85000005', (SELECT spot_id FROM tmp_demo_spots WHERE key = 'qianmen')),
    (6, '北京饭店', 'hotel', ST_SetSRID(ST_MakePoint(116.405031, 39.909705), 4326)::geography, '东长安街33号', 4.60, 4, '全天', '010-85000006', (SELECT spot_id FROM tmp_demo_spots WHERE key = 'wangfujing')),
    (7, '景山公园东门停车场', 'parking', ST_SetSRID(ST_MakePoint(116.398786, 39.925053), 4326)::geography, '景山东街', 4.00, 2, '07:00-21:00', NULL, (SELECT spot_id FROM tmp_demo_spots WHERE key = 'jingshan')),
    (8, '北海北地铁站', 'subway', ST_SetSRID(ST_MakePoint(116.386829, 39.933247), 4326)::geography, '地铁6号线北海北站', 4.20, 1, '05:00-23:30', NULL, (SELECT spot_id FROM tmp_demo_spots WHERE key = 'beihai')),
    (9, '王府井小吃街', 'restaurant', ST_SetSRID(ST_MakePoint(116.410946, 39.914742), 4326)::geography, '王府井商业区', 4.10, 2, '10:00-22:00', NULL, (SELECT spot_id FROM tmp_demo_spots WHERE key = 'wangfujing')),
    (10, '东华门公共卫生间', 'toilet', ST_SetSRID(ST_MakePoint(116.404061, 39.918965), 4326)::geography, '东华门附近', 4.00, 1, '07:00-22:00', NULL, (SELECT spot_id FROM tmp_demo_spots WHERE key = 'gugong')),
    (11, '什刹海游客中心', 'service', ST_SetSRID(ST_MakePoint(116.390855, 39.937661), 4326)::geography, '什刹海景区', 4.30, 1, '09:00-18:00', '010-85000011', (SELECT spot_id FROM tmp_demo_spots WHERE key = 'gulou')),
    (12, '鼓楼西侧停车场', 'parking', ST_SetSRID(ST_MakePoint(116.391540, 39.939830), 4326)::geography, '鼓楼西大街', 3.90, 2, '08:00-22:00', NULL, (SELECT spot_id FROM tmp_demo_spots WHERE key = 'gulou'))
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    type = EXCLUDED.type,
    location = EXCLUDED.location,
    address = EXCLUDED.address,
    rating = EXCLUDED.rating,
    price_level = EXCLUDED.price_level,
    opening_hours = EXCLUDED.opening_hours,
    phone = EXCLUDED.phone,
    scenic_spot_id = EXCLUDED.scenic_spot_id;

-- 图节点：景点节点通过 tmp_demo_spots 关联真实导入景点。
INSERT INTO graph_nodes
    (id, name, location, node_type, scenic_spot_id, facility_id, congestion_level)
VALUES
    (1, '故宫博物院节点', ST_SetSRID(ST_MakePoint(116.397026, 39.918058), 4326)::geography, 'scenic', (SELECT spot_id FROM tmp_demo_spots WHERE key = 'gugong'), NULL, 4),
    (2, '天安门广场节点', ST_SetSRID(ST_MakePoint(116.397477, 39.908692), 4326)::geography, 'scenic', (SELECT spot_id FROM tmp_demo_spots WHERE key = 'tiananmen'), NULL, 3),
    (3, '景山公园节点', ST_SetSRID(ST_MakePoint(116.396621, 39.925048), 4326)::geography, 'scenic', (SELECT spot_id FROM tmp_demo_spots WHERE key = 'jingshan'), NULL, 2),
    (4, '北海公园节点', ST_SetSRID(ST_MakePoint(116.389535, 39.925455), 4326)::geography, 'scenic', (SELECT spot_id FROM tmp_demo_spots WHERE key = 'beihai'), NULL, 2),
    (5, '国家博物馆节点', ST_SetSRID(ST_MakePoint(116.401015, 39.905103), 4326)::geography, 'scenic', (SELECT spot_id FROM tmp_demo_spots WHERE key = 'guobo'), NULL, 3),
    (6, '前门大街节点', ST_SetSRID(ST_MakePoint(116.397957, 39.899318), 4326)::geography, 'scenic', (SELECT spot_id FROM tmp_demo_spots WHERE key = 'qianmen'), NULL, 3),
    (7, '王府井步行街节点', ST_SetSRID(ST_MakePoint(116.411013, 39.912657), 4326)::geography, 'scenic', (SELECT spot_id FROM tmp_demo_spots WHERE key = 'wangfujing'), NULL, 3),
    (8, '鼓楼节点', ST_SetSRID(ST_MakePoint(116.393776, 39.940269), 4326)::geography, 'scenic', (SELECT spot_id FROM tmp_demo_spots WHERE key = 'gulou'), NULL, 2),
    (9, '天坛公园节点', ST_SetSRID(ST_MakePoint(116.406601, 39.882156), 4326)::geography, 'scenic', (SELECT spot_id FROM tmp_demo_spots WHERE key = 'tiantan'), NULL, 3),
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

UPDATE graph_nodes AS gn
SET scenic_spot_id = f.scenic_spot_id
FROM facilities AS f
WHERE gn.facility_id = f.id
  AND gn.scenic_spot_id IS DISTINCT FROM f.scenic_spot_id;

-- 路线规划演示用图边
INSERT INTO graph_edges
    (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry)
VALUES
    -- 天安门→午门主通道：人流巅峰，拥挤度 4（高峰时段算法应倾向绕行）
    (2, 1, 1050, 'walk', 900, 10.50, 4, 'SRID=4326;LINESTRING(116.397477 39.908692, 116.397420 39.911540, 116.397240 39.914540, 116.397026 39.918058)'),
    (1, 2, 1050, 'walk', 900, 10.50, 4, 'SRID=4326;LINESTRING(116.397026 39.918058, 116.397240 39.914540, 116.397420 39.911540, 116.397477 39.908692)'),
    -- 故宫北门换乘点↔故宫：北门人流稀少，拥挤度 1
    (1, 104, 650, 'walk', 560, 6.50, 1, 'SRID=4326;LINESTRING(116.397026 39.918058, 116.397090 39.919640, 116.397210 39.921520, 116.397712 39.923724)'),
    (104, 1, 650, 'walk', 560, 6.50, 1, 'SRID=4326;LINESTRING(116.397712 39.923724, 116.397210 39.921520, 116.397090 39.919640, 116.397026 39.918058)'),
    -- 天安门↔故宫北门换乘点：沿筒子河绕行，距离长但畅通（高峰绕行备选）
    (2, 104, 1600, 'walk', 950, 16.00, 1, 'SRID=4326;LINESTRING(116.397477 39.908692, 116.401216 39.909120, 116.401560 39.915860, 116.399880 39.921820, 116.397712 39.923724)'),
    (104, 2, 1600, 'walk', 950, 16.00, 1, 'SRID=4326;LINESTRING(116.397712 39.923724, 116.399880 39.921820, 116.401560 39.915860, 116.401216 39.909120, 116.397477 39.908692)'),
    (104, 3, 520, 'walk', 450, 5.20, 2, 'SRID=4326;LINESTRING(116.397712 39.923724, 116.397580 39.924320, 116.397180 39.924760, 116.396621 39.925048)'),
    (3, 104, 520, 'walk', 450, 5.20, 2, 'SRID=4326;LINESTRING(116.396621 39.925048, 116.397180 39.924760, 116.397580 39.924320, 116.397712 39.923724)'),
    (3, 4, 900, 'walk', 780, 9.00, 2, 'SRID=4326;LINESTRING(116.396621 39.925048, 116.394780 39.925180, 116.392260 39.925300, 116.389535 39.925455)'),
    (4, 3, 900, 'walk', 780, 9.00, 2, 'SRID=4326;LINESTRING(116.389535 39.925455, 116.392260 39.925300, 116.394780 39.925180, 116.396621 39.925048)'),
    (4, 103, 980, 'walk', 840, 9.80, 2, 'SRID=4326;LINESTRING(116.389535 39.925455, 116.388260 39.927860, 116.387520 39.930520, 116.386829 39.933247)'),
    (103, 4, 980, 'walk', 840, 9.80, 2, 'SRID=4326;LINESTRING(116.386829 39.933247, 116.387520 39.930520, 116.388260 39.927860, 116.389535 39.925455)'),
    (103, 8, 1150, 'bike', 420, 8.00, 2, 'SRID=4326;LINESTRING(116.386829 39.933247, 116.388640 39.936020, 116.391120 39.938460, 116.393776 39.940269)'),
    (8, 103, 1150, 'bike', 420, 8.00, 2, 'SRID=4326;LINESTRING(116.393776 39.940269, 116.391120 39.938460, 116.388640 39.936020, 116.386829 39.933247)'),
    (2, 5, 620, 'walk', 530, 6.20, 3, 'SRID=4326;LINESTRING(116.397477 39.908692, 116.398600 39.907760, 116.399760 39.906220, 116.401015 39.905103)'),
    (5, 2, 620, 'walk', 530, 6.20, 3, 'SRID=4326;LINESTRING(116.401015 39.905103, 116.399760 39.906220, 116.398600 39.907760, 116.397477 39.908692)'),
    (5, 101, 380, 'walk', 320, 3.80, 2, 'SRID=4326;LINESTRING(116.401015 39.905103, 116.401120 39.906120, 116.401180 39.907360, 116.401216 39.908780)'),
    (101, 5, 380, 'walk', 320, 3.80, 2, 'SRID=4326;LINESTRING(116.401216 39.908780, 116.401180 39.907360, 116.401120 39.906120, 116.401015 39.905103)'),
    (2, 102, 980, 'walk', 820, 9.80, 3, 'SRID=4326;LINESTRING(116.397477 39.908692, 116.397620 39.906160, 116.397780 39.903320, 116.397937 39.900192)'),
    (102, 2, 980, 'walk', 820, 9.80, 3, 'SRID=4326;LINESTRING(116.397937 39.900192, 116.397780 39.903320, 116.397620 39.906160, 116.397477 39.908692)'),
    (102, 6, 240, 'walk', 210, 2.40, 2, 'SRID=4326;LINESTRING(116.397937 39.900192, 116.397948 39.899860, 116.397957 39.899318)'),
    (6, 102, 240, 'walk', 210, 2.40, 2, 'SRID=4326;LINESTRING(116.397957 39.899318, 116.397948 39.899860, 116.397937 39.900192)'),
    (6, 105, 120, 'walk', 120, 1.20, 2, 'SRID=4326;LINESTRING(116.397957 39.899318, 116.397720 39.899180, 116.397371 39.899049)'),
    (105, 6, 120, 'walk', 120, 1.20, 2, 'SRID=4326;LINESTRING(116.397371 39.899049, 116.397720 39.899180, 116.397957 39.899318)'),
    (6, 9, 2300, 'walk', 1900, 23.00, 3, 'SRID=4326;LINESTRING(116.397957 39.899318, 116.398400 39.895900, 116.400900 39.891400, 116.404200 39.886800, 116.406601 39.882156)'),
    (9, 6, 2300, 'walk', 1900, 23.00, 3, 'SRID=4326;LINESTRING(116.406601 39.882156, 116.404200 39.886800, 116.400900 39.891400, 116.398400 39.895900, 116.397957 39.899318)'),
    (5, 9, 2800, 'walk', 2300, 28.00, 3, 'SRID=4326;LINESTRING(116.401015 39.905103, 116.402200 39.899600, 116.403700 39.893400, 116.405100 39.887900, 116.406601 39.882156)'),
    (9, 5, 2800, 'walk', 2300, 28.00, 3, 'SRID=4326;LINESTRING(116.406601 39.882156, 116.405100 39.887900, 116.403700 39.893400, 116.402200 39.899600, 116.401015 39.905103)'),
    (2, 9, 3200, 'walk', 2600, 32.00, 3, 'SRID=4326;LINESTRING(116.397477 39.908692, 116.399100 39.901600, 116.402300 39.894200, 116.404900 39.887700, 116.406601 39.882156)'),
    (9, 2, 3200, 'walk', 2600, 32.00, 3, 'SRID=4326;LINESTRING(116.406601 39.882156, 116.404900 39.887700, 116.402300 39.894200, 116.399100 39.901600, 116.397477 39.908692)'),
    (1, 7, 1700, 'bike', 620, 11.00, 3, 'SRID=4326;LINESTRING(116.397026 39.918058, 116.401180 39.917420, 116.406280 39.915980, 116.411013 39.912657)'),
    (7, 1, 1700, 'bike', 620, 11.00, 3, 'SRID=4326;LINESTRING(116.411013 39.912657, 116.406280 39.915980, 116.401180 39.917420, 116.397026 39.918058)'),
    (7, 106, 300, 'walk', 260, 3.00, 3, 'SRID=4326;LINESTRING(116.411013 39.912657, 116.410980 39.913520, 116.410946 39.914742)'),
    (106, 7, 300, 'walk', 260, 3.00, 3, 'SRID=4326;LINESTRING(116.410946 39.914742, 116.410980 39.913520, 116.411013 39.912657)'),
    (8, 107, 450, 'walk', 390, 4.50, 2, 'SRID=4326;LINESTRING(116.393776 39.940269, 116.392860 39.939360, 116.391920 39.938420, 116.390855 39.937661)'),
    (107, 8, 450, 'walk', 390, 4.50, 2, 'SRID=4326;LINESTRING(116.390855 39.937661, 116.391920 39.938420, 116.392860 39.939360, 116.393776 39.940269)'),
    (101, 102, 1200, 'subway', 180, 4.50, 2, 'SRID=4326;LINESTRING(116.401216 39.908780, 116.400100 39.906320, 116.399200 39.903520, 116.397937 39.900192)'),
    (102, 101, 1200, 'subway', 180, 4.50, 2, 'SRID=4326;LINESTRING(116.397937 39.900192, 116.399200 39.903520, 116.400100 39.906320, 116.401216 39.908780)'),
    (101, 7, 1250, 'bike', 460, 8.50, 3, 'SRID=4326;LINESTRING(116.401216 39.908780, 116.404240 39.910680, 116.407720 39.911860, 116.411013 39.912657)'),
    (7, 101, 1250, 'bike', 460, 8.50, 3, 'SRID=4326;LINESTRING(116.411013 39.912657, 116.407720 39.911860, 116.404240 39.910680, 116.401216 39.908780)')
ON CONFLICT (from_node, to_node, travel_mode) DO UPDATE SET
    distance = EXCLUDED.distance,
    travel_time = EXCLUDED.travel_time,
    base_weight = EXCLUDED.base_weight,
    congestion_level = EXCLUDED.congestion_level,
    geometry = EXCLUDED.geometry;

-- 收藏和评价：按景点 key 动态关联导入后的真实景点 id。
INSERT INTO user_favorites (user_id, scenic_spot_id)
SELECT item.user_id, spot.spot_id
FROM (VALUES
    (1, 'gugong'),
    (1, 'jingshan'),
    (1, 'guobo'),
    (2, 'guobo'),
    (2, 'qianmen'),
    (3, 'jingshan'),
    (3, 'gulou')
) AS item(user_id, spot_key)
JOIN tmp_demo_spots spot ON spot.key = item.spot_key
WHERE spot.spot_id IS NOT NULL
ON CONFLICT (user_id, scenic_spot_id) DO NOTHING;

INSERT INTO reviews
    (id, user_id, scenic_spot_id, rating, content, images, helpful_count, status)
SELECT item.id, item.user_id, spot.spot_id, item.rating, item.content, ARRAY[]::TEXT[], item.helpful_count, 1
FROM (VALUES
    (1, 1, 'gugong', 5, '故宫适合安排半天以上，建议提前预约并从中轴线慢慢走。', 12),
    (2, 2, 'guobo', 5, '国家博物馆很适合雨天或高温天气，展览信息密度很高。', 8),
    (3, 3, 'jingshan', 4, '景山视角很好，傍晚拍故宫非常出片。', 6),
    (4, 1, 'qianmen', 4, '前门大街餐饮选择多，适合放在路线结尾。', 5),
    (5, 2, 'gulou', 4, '鼓楼和什刹海可以串联成轻松 citywalk。', 4)
) AS item(id, user_id, spot_key, rating, content, helpful_count)
JOIN tmp_demo_spots spot ON spot.key = item.spot_key
WHERE spot.spot_id IS NOT NULL
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
     1,
     array_remove(ARRAY[
        (SELECT spot_id FROM tmp_demo_spots WHERE key = 'qianmen'),
        (SELECT spot_id FROM tmp_demo_spots WHERE key = 'tiananmen'),
        (SELECT spot_id FROM tmp_demo_spots WHERE key = 'gugong'),
        (SELECT spot_id FROM tmp_demo_spots WHERE key = 'jingshan')
     ]::INTEGER[], NULL),
     '2026-04-12', '2026-04-12', 5.20, ARRAY['/images/diary/gugong_0.jpg'],
     ARRAY['中轴线','历史','一日游'], 430, 38, 6, '前门、天安门、故宫、景山串联的一日游路线。', '北京中轴线一日游'),
    (2, 2, '博物馆和商业街的轻松路线',
     '国家博物馆加王府井，适合室内展览与晚间餐饮。',
     '白天参观国家博物馆，傍晚骑行到王府井吃饭购物。路线较短，适合低预算学生出行。',
     1,
     array_remove(ARRAY[
        (SELECT spot_id FROM tmp_demo_spots WHERE key = 'guobo'),
        (SELECT spot_id FROM tmp_demo_spots WHERE key = 'wangfujing')
     ]::INTEGER[], NULL),
     '2026-04-18', '2026-04-18', 2.10, ARRAY['/images/diary/guojiabowuguan_0.jpeg'],
     ARRAY['博物馆','王府井','低预算'], 360, 31, 4, '国家博物馆与王府井组合，适合轻松城市游。', '展览与夜游半日路线'),
    (3, 3, '鼓楼到北海的 citywalk',
     '老城摄影与公园散步路线。',
     '从鼓楼出发，经什刹海到北海公园，最后可以去景山看日落。适合摄影偏好用户。',
     1,
     array_remove(ARRAY[
        (SELECT spot_id FROM tmp_demo_spots WHERE key = 'gulou'),
        (SELECT spot_id FROM tmp_demo_spots WHERE key = 'beihai'),
        (SELECT spot_id FROM tmp_demo_spots WHERE key = 'jingshan')
     ]::INTEGER[], NULL),
     '2026-04-26', '2026-04-26', 3.80, ARRAY['/images/diary/shichahai_0.jpg'],
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

-- 补充个性化推荐标签。
UPDATE scenic_spots
SET tags = ARRAY['历史古迹', '博物馆', '世界遗产', '历史', '摄影', '亲子', '室内']
WHERE name ILIKE '%故宫%' OR name ILIKE '%紫禁城%';

UPDATE scenic_spots
SET tags = ARRAY['城市地标', '历史', '摄影', '步行', '低预算', '城市漫步']
WHERE name ILIKE '%天安门%';

UPDATE scenic_spots
SET tags = ARRAY['博物馆', '历史', '展览', '室内', '低预算', '亲子']
WHERE name ILIKE '%国家博物馆%' OR name ILIKE '%中国国家博物馆%' OR name ILIKE '%国博%';

UPDATE scenic_spots
SET tags = ARRAY['公园', '自然', '观景', '摄影', '轻徒步', '历史']
WHERE name ILIKE '%景山%';

UPDATE scenic_spots
SET tags = ARRAY['商业街区', '美食', '夜游', '购物', '城市漫步', '低预算']
WHERE name ILIKE '%前门%';

UPDATE scenic_spots
SET tags = ARRAY['城市漫步', '胡同', '摄影', '休闲', '夜游', '美食']
WHERE name ILIKE '%什刹海%' OR name ILIKE '%鼓楼%' OR name ILIKE '%南锣鼓巷%';

UPDATE scenic_spots
SET tags = ARRAY['公园', '自然', '湖景', '摄影', '亲子', '低预算']
WHERE name ILIKE '%北海公园%' OR name ILIKE '%颐和园%' OR name ILIKE '%圆明园%';

UPDATE scenic_spots
SET tags = ARRAY['历史古迹', '世界遗产', '轻徒步', '摄影', '自然']
WHERE name ILIKE '%长城%';

UPDATE scenic_spots
SET tags = ARRAY['商业街区', '购物', '美食', '夜游', '城市地标']
WHERE name ILIKE '%王府井%' OR name ILIKE '%三里屯%' OR name ILIKE '%西单%';

UPDATE scenic_spots
SET tags = ARRAY['美食街区', '美食', '夜游', '城市漫步', '低预算']
WHERE name ILIKE '%簋街%' OR name ILIKE '%小吃%' OR name ILIKE '%美食%';

UPDATE scenic_spots
SET tags = array_remove(ARRAY[
    CASE WHEN COALESCE(array_to_string(tags, ' '), '') ILIKE '%博物馆%' OR COALESCE(description, '') ILIKE '%博物馆%' THEN '博物馆' END,
    CASE WHEN COALESCE(array_to_string(tags, ' '), '') ILIKE '%公园%' OR COALESCE(description, '') ILIKE '%公园%' THEN '公园' END,
    CASE WHEN COALESCE(array_to_string(tags, ' '), '') ILIKE '%风景%' OR COALESCE(description, '') ILIKE '%自然%' THEN '自然' END,
    CASE WHEN COALESCE(array_to_string(tags, ' '), '') ILIKE '%古迹%' OR COALESCE(description, '') ILIKE '%历史%' THEN '历史古迹' END,
    CASE WHEN COALESCE(array_to_string(tags, ' '), '') ILIKE '%广场%' OR COALESCE(description, '') ILIKE '%地标%' THEN '城市地标' END,
    CASE WHEN COALESCE(array_to_string(tags, ' '), '') ILIKE '%商业%' OR COALESCE(array_to_string(tags, ' '), '') ILIKE '%步行街%' THEN '商业街区' END,
    '摄影',
    CASE WHEN COALESCE(ticket_price, 0) <= 30 THEN '低预算' END
], NULL)
WHERE tags IS NULL OR array_length(tags, 1) IS NULL OR tags = ARRAY['']::text[];

-- 让 SERIAL/BIGSERIAL 序列值大于显式写入的演示 id。
SELECT setval('users_id_seq', (SELECT MAX(id) FROM users));
SELECT setval('categories_id_seq', (SELECT MAX(id) FROM categories));
SELECT setval('scenic_spots_id_seq', (SELECT COALESCE(MAX(id), 1) FROM scenic_spots));
SELECT setval('facilities_id_seq', (SELECT MAX(id) FROM facilities));
SELECT setval('graph_nodes_id_seq', (SELECT MAX(id) FROM graph_nodes));
SELECT setval('graph_edges_id_seq', (SELECT COALESCE(MAX(id), 1) FROM graph_edges));
SELECT setval('reviews_id_seq', (SELECT COALESCE(MAX(id), 1) FROM reviews));
SELECT setval('travel_diaries_id_seq', (SELECT COALESCE(MAX(id), 1) FROM travel_diaries));
SELECT setval('route_plans_id_seq', (SELECT COALESCE(MAX(id), 1) FROM route_plans));

COMMIT;
