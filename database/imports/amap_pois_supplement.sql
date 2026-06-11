-- =====================================================
-- 高德 POI 补充导入：主 POI 导入未覆盖的北京核心地标
-- =====================================================
-- 数据来源：高德地图开放平台 /v3/place/text（2026-06-12 拉取）。
-- 背景：imports/amap_pois.sql 主导入缺少 中国国家博物馆、
--       中国人民革命军事博物馆、颐和园 三个核心地标，
--       导致站内搜索查无此景点。
-- 幂等：与主导入同款 WHERE NOT EXISTS（名称+城市+100米范围）防重。
-- =====================================================

SET client_encoding = 'UTF8';

BEGIN;

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '中国国家博物馆',
    '中国国家博物馆，位于北京市东长安街16号天安门广场东侧，国家一级博物馆。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.401304, 39.905374), 4326)::geography,
    3,
    4.90,
    0,
    '东长安街16号天安门广场东侧',
    '北京市',
    '周二至周日 09:00-17:00，周一闭馆（法定节假日除外）',
    0,
    180,
    4,
    ARRAY['https://aos-comment.amap.com/B000A83U0P/headerImg/c18b1708f9b307ca92bf78809f7a0220_2048_2048_80.jpg'],
    'https://aos-comment.amap.com/B000A83U0P/headerImg/c18b1708f9b307ca92bf78809f7a0220_2048_2048_80.jpg',
    ARRAY['博物馆', '国家一级博物馆', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE lower(trim(name)) = lower(trim('中国国家博物馆'))
      AND COALESCE(city, '') = '北京市'
      AND ST_DWithin(location, ST_SetSRID(ST_MakePoint(116.401304, 39.905374), 4326)::geography, 100)
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '中国人民革命军事博物馆',
    '中国人民革命军事博物馆，位于北京市复兴路9号，全国唯一的大型综合性军事博物馆。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.323871, 39.909108), 4326)::geography,
    3,
    4.20,
    0,
    '复兴路9号',
    '北京市',
    '周二至周日 09:00-17:00，周一闭馆',
    0,
    150,
    2,
    ARRAY['https://aos-comment.amap.com/B000A7S1GC/comment/b08a6ee7daec8d789881a41c12aabead_2048_2048_80.jpg'],
    'https://aos-comment.amap.com/B000A7S1GC/comment/b08a6ee7daec8d789881a41c12aabead_2048_2048_80.jpg',
    ARRAY['博物馆', '军事', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE lower(trim(name)) = lower(trim('中国人民革命军事博物馆'))
      AND COALESCE(city, '') = '北京市'
      AND ST_DWithin(location, ST_SetSRID(ST_MakePoint(116.323871, 39.909108), 4326)::geography, 100)
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '颐和园',
    '颐和园，位于北京市新建宫门路19号，中国现存规模最大的皇家园林，世界文化遗产。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.275179, 39.999617), 4326)::geography,
    2,
    4.90,
    0,
    '新建宫门路19号',
    '北京市',
    '旺季（4-10月）06:00-20:00，淡季 06:30-19:00',
    30,
    240,
    4,
    ARRAY['http://store.is.autonavi.com/showpic/a4b326f43a84d36b581d7f6e856fe858'],
    'http://store.is.autonavi.com/showpic/a4b326f43a84d36b581d7f6e856fe858',
    ARRAY['世界遗产', '皇家园林', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE lower(trim(name)) = lower(trim('颐和园'))
      AND COALESCE(city, '') = '北京市'
      AND ST_DWithin(location, ST_SetSRID(ST_MakePoint(116.275179, 39.999617), 4326)::geography, 100)
);

COMMIT;
