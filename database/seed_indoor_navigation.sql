SET client_encoding = 'UTF8';

-- =====================================================
-- TourPilot 室内导航种子数据
-- =====================================================
-- 范围：
--   1. 只使用 tourism_system 数据库，并绑定到高德 POI 离线导入的 scenic_spots。
--   2. 为北大红楼补充一小份正式室内导航图数据。
--   3. 当前 provider 为 local_indoor_graph；后续如接入高德室内图，可补充
--      indoor_buildings.amap_cpid。

BEGIN;

CREATE TEMP TABLE tmp_indoor_spots (
    spot_key TEXT PRIMARY KEY,
    scenic_spot_id INTEGER NOT NULL
) ON COMMIT DROP;

INSERT INTO tmp_indoor_spots (spot_key, scenic_spot_id)
SELECT 'red_building', s.id
FROM scenic_spots s
WHERE s.status = 1
  AND (
      s.name ILIKE '%Beida Red Building%'
      OR s.name ILIKE '%Red Building%'
      OR s.name ILIKE '%北大红楼%'
      OR s.name ILIKE '%北京大学红楼%'
      OR ST_DWithin(
          s.location,
          ST_SetSRID(ST_MakePoint(116.405361, 39.924710), 4326)::geography,
          120
      )
  )
ORDER BY
    CASE
        WHEN s.name ILIKE '%北大红楼%' OR s.name ILIKE '%北京大学红楼%' THEN 0
        ELSE 1
    END,
    ST_Distance(s.location, ST_SetSRID(ST_MakePoint(116.405361, 39.924710), 4326)::geography),
    s.id
LIMIT 1;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM tmp_indoor_spots WHERE spot_key = 'red_building') THEN
        RAISE EXCEPTION '无法绑定室内导航种子数据：未找到北大红楼对应的高德 POI';
    END IF;
END $$;

INSERT INTO indoor_buildings
    (scenic_spot_id, name, provider, source, source_ref, amap_cpid,
     has_indoor_map, description, default_floor_code)
SELECT
    scenic_spot_id,
    '北大红楼主楼',
    'local_indoor_graph',
    'manual-curated',
    'red-building:indoor-building:main',
    '',
    FALSE,
    '北大红楼参观动线的本地室内图数据；当高德官方室内路线不可用时使用本地图计算。',
    'F1'
FROM tmp_indoor_spots
WHERE spot_key = 'red_building'
ON CONFLICT (source, source_ref) DO UPDATE SET
    scenic_spot_id = EXCLUDED.scenic_spot_id,
    name = EXCLUDED.name,
    provider = EXCLUDED.provider,
    amap_cpid = EXCLUDED.amap_cpid,
    has_indoor_map = EXCLUDED.has_indoor_map,
    description = EXCLUDED.description,
    default_floor_code = EXCLUDED.default_floor_code;

CREATE TEMP TABLE tmp_indoor_floors (
    building_ref TEXT NOT NULL,
    floor_code TEXT NOT NULL,
    floor_name TEXT NOT NULL,
    floor_index INTEGER NOT NULL,
    source_ref TEXT NOT NULL
) ON COMMIT DROP;

INSERT INTO tmp_indoor_floors VALUES
    ('red-building:indoor-building:main', 'F1', '一层', 1, 'red-building:floor:F1'),
    ('red-building:indoor-building:main', 'F2', '二层', 2, 'red-building:floor:F2');

INSERT INTO indoor_floors
    (building_id, floor_code, floor_name, floor_index, provider, source, source_ref)
SELECT
    b.id,
    f.floor_code,
    f.floor_name,
    f.floor_index,
    'local_indoor_graph',
    'manual-curated',
    f.source_ref
FROM tmp_indoor_floors f
JOIN indoor_buildings b ON b.source = 'manual-curated' AND b.source_ref = f.building_ref
ON CONFLICT (source, source_ref) DO UPDATE SET
    building_id = EXCLUDED.building_id,
    floor_code = EXCLUDED.floor_code,
    floor_name = EXCLUDED.floor_name,
    floor_index = EXCLUDED.floor_index,
    provider = EXCLUDED.provider;

CREATE TEMP TABLE tmp_indoor_features (
    building_ref TEXT NOT NULL,
    floor_ref TEXT NOT NULL,
    name TEXT NOT NULL,
    type TEXT NOT NULL,
    x NUMERIC(10,2) NOT NULL,
    y NUMERIC(10,2) NOT NULL,
    source_ref TEXT NOT NULL,
    sort_order INTEGER NOT NULL
) ON COMMIT DROP;

INSERT INTO tmp_indoor_features VALUES
    ('red-building:indoor-building:main', 'red-building:floor:F1', '主入口', 'entrance', 10, 50, 'red-building:feature:main-entrance', 10),
    ('red-building:indoor-building:main', 'red-building:floor:F1', '一层大厅', 'hallway', 28, 50, 'red-building:feature:f1-lobby', 20),
    ('red-building:indoor-building:main', 'red-building:floor:F1', '票务服务台', 'service', 42, 42, 'red-building:feature:service-desk', 30),
    ('red-building:indoor-building:main', 'red-building:floor:F1', '基本陈列展厅', 'exhibition', 68, 54, 'red-building:feature:permanent-exhibition', 40),
    ('red-building:indoor-building:main', 'red-building:floor:F1', '一层卫生间', 'toilet', 70, 32, 'red-building:feature:f1-restroom', 50),
    ('red-building:indoor-building:main', 'red-building:floor:F1', '一层楼梯', 'stairs', 32, 66, 'red-building:feature:f1-stairs', 60),
    ('red-building:indoor-building:main', 'red-building:floor:F2', '二层楼梯', 'stairs', 32, 66, 'red-building:feature:f2-stairs', 70),
    ('red-building:indoor-building:main', 'red-building:floor:F2', '历史展室', 'exhibition', 62, 55, 'red-building:feature:history-room', 80),
    ('red-building:indoor-building:main', 'red-building:floor:F2', '阅览室', 'room', 48, 38, 'red-building:feature:reading-room', 90),
    ('red-building:indoor-building:main', 'red-building:floor:F2', '二层卫生间', 'toilet', 72, 34, 'red-building:feature:f2-restroom', 100);

INSERT INTO indoor_features
    (building_id, floor_id, name, type, x, y, provider, source, source_ref, is_public, sort_order)
SELECT
    b.id,
    fl.id,
    feat.name,
    feat.type,
    feat.x,
    feat.y,
    'local_indoor_graph',
    'manual-curated',
    feat.source_ref,
    TRUE,
    feat.sort_order
FROM tmp_indoor_features feat
JOIN indoor_buildings b ON b.source = 'manual-curated' AND b.source_ref = feat.building_ref
JOIN indoor_floors fl ON fl.source = 'manual-curated' AND fl.source_ref = feat.floor_ref
ON CONFLICT (source, source_ref) DO UPDATE SET
    building_id = EXCLUDED.building_id,
    floor_id = EXCLUDED.floor_id,
    name = EXCLUDED.name,
    type = EXCLUDED.type,
    x = EXCLUDED.x,
    y = EXCLUDED.y,
    provider = EXCLUDED.provider,
    is_public = EXCLUDED.is_public,
    sort_order = EXCLUDED.sort_order;

CREATE TEMP TABLE tmp_indoor_edges (
    building_ref TEXT NOT NULL,
    from_ref TEXT NOT NULL,
    to_ref TEXT NOT NULL,
    distance NUMERIC(10,2) NOT NULL,
    travel_time INTEGER NOT NULL,
    edge_type TEXT NOT NULL,
    source_ref TEXT NOT NULL
) ON COMMIT DROP;

INSERT INTO tmp_indoor_edges VALUES
    ('red-building:indoor-building:main', 'red-building:feature:main-entrance', 'red-building:feature:f1-lobby', 16, 20, 'corridor', 'red-building:edge:main-entrance:f1-lobby'),
    ('red-building:indoor-building:main', 'red-building:feature:f1-lobby', 'red-building:feature:main-entrance', 16, 20, 'corridor', 'red-building:edge:f1-lobby:main-entrance'),
    ('red-building:indoor-building:main', 'red-building:feature:f1-lobby', 'red-building:feature:service-desk', 14, 18, 'corridor', 'red-building:edge:f1-lobby:service-desk'),
    ('red-building:indoor-building:main', 'red-building:feature:service-desk', 'red-building:feature:f1-lobby', 14, 18, 'corridor', 'red-building:edge:service-desk:f1-lobby'),
    ('red-building:indoor-building:main', 'red-building:feature:f1-lobby', 'red-building:feature:permanent-exhibition', 36, 42, 'corridor', 'red-building:edge:f1-lobby:permanent-exhibition'),
    ('red-building:indoor-building:main', 'red-building:feature:permanent-exhibition', 'red-building:feature:f1-lobby', 36, 42, 'corridor', 'red-building:edge:permanent-exhibition:f1-lobby'),
    ('red-building:indoor-building:main', 'red-building:feature:permanent-exhibition', 'red-building:feature:f1-restroom', 18, 24, 'corridor', 'red-building:edge:permanent-exhibition:f1-restroom'),
    ('red-building:indoor-building:main', 'red-building:feature:f1-restroom', 'red-building:feature:permanent-exhibition', 18, 24, 'corridor', 'red-building:edge:f1-restroom:permanent-exhibition'),
    ('red-building:indoor-building:main', 'red-building:feature:f1-lobby', 'red-building:feature:f1-stairs', 20, 25, 'corridor', 'red-building:edge:f1-lobby:f1-stairs'),
    ('red-building:indoor-building:main', 'red-building:feature:f1-stairs', 'red-building:feature:f1-lobby', 20, 25, 'corridor', 'red-building:edge:f1-stairs:f1-lobby'),
    ('red-building:indoor-building:main', 'red-building:feature:f1-stairs', 'red-building:feature:f2-stairs', 18, 80, 'stairs', 'red-building:edge:f1-stairs:f2-stairs'),
    ('red-building:indoor-building:main', 'red-building:feature:f2-stairs', 'red-building:feature:f1-stairs', 18, 80, 'stairs', 'red-building:edge:f2-stairs:f1-stairs'),
    ('red-building:indoor-building:main', 'red-building:feature:f2-stairs', 'red-building:feature:history-room', 32, 38, 'corridor', 'red-building:edge:f2-stairs:history-room'),
    ('red-building:indoor-building:main', 'red-building:feature:history-room', 'red-building:feature:f2-stairs', 32, 38, 'corridor', 'red-building:edge:history-room:f2-stairs'),
    ('red-building:indoor-building:main', 'red-building:feature:f2-stairs', 'red-building:feature:reading-room', 22, 28, 'corridor', 'red-building:edge:f2-stairs:reading-room'),
    ('red-building:indoor-building:main', 'red-building:feature:reading-room', 'red-building:feature:f2-stairs', 22, 28, 'corridor', 'red-building:edge:reading-room:f2-stairs'),
    ('red-building:indoor-building:main', 'red-building:feature:history-room', 'red-building:feature:f2-restroom', 16, 22, 'corridor', 'red-building:edge:history-room:f2-restroom'),
    ('red-building:indoor-building:main', 'red-building:feature:f2-restroom', 'red-building:feature:history-room', 16, 22, 'corridor', 'red-building:edge:f2-restroom:history-room');

INSERT INTO indoor_edges
    (building_id, from_feature_id, to_feature_id, distance, travel_time,
     edge_type, provider, source, source_ref)
SELECT
    b.id,
    from_feat.id,
    to_feat.id,
    e.distance,
    e.travel_time,
    e.edge_type,
    'local_indoor_graph',
    'manual-curated',
    e.source_ref
FROM tmp_indoor_edges e
JOIN indoor_buildings b ON b.source = 'manual-curated' AND b.source_ref = e.building_ref
JOIN indoor_features from_feat ON from_feat.source = 'manual-curated' AND from_feat.source_ref = e.from_ref
JOIN indoor_features to_feat ON to_feat.source = 'manual-curated' AND to_feat.source_ref = e.to_ref
ON CONFLICT (source, source_ref) DO UPDATE SET
    building_id = EXCLUDED.building_id,
    from_feature_id = EXCLUDED.from_feature_id,
    to_feature_id = EXCLUDED.to_feature_id,
    distance = EXCLUDED.distance,
    travel_time = EXCLUDED.travel_time,
    edge_type = EXCLUDED.edge_type,
    provider = EXCLUDED.provider;

SELECT setval('indoor_buildings_id_seq', COALESCE((SELECT MAX(id) FROM indoor_buildings), 1), TRUE);
SELECT setval('indoor_floors_id_seq', COALESCE((SELECT MAX(id) FROM indoor_floors), 1), TRUE);
SELECT setval('indoor_features_id_seq', COALESCE((SELECT MAX(id) FROM indoor_features), 1), TRUE);
SELECT setval('indoor_edges_id_seq', COALESCE((SELECT MAX(id) FROM indoor_edges), 1), TRUE);

COMMIT;
