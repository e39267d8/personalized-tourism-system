-- =====================================================
-- 北京大学校园自行车道（travel_mode='bike'，验收 4c：校区自行车最短时间）
-- =====================================================
-- 在 seed_pku_curated_map.sql 已建的连通主路网之上，沿主干道补一层自行车道。
-- 自行车理想速度 4 m/s（步行 1.2），"默认自行车在校区任何地点都有"，所以
-- 规划时可步行+自行车自由混合，由后端按时间最短的多模式 Dijkstra 求解。
-- 依赖：先执行 seed_pku_curated_map.sql（本脚本按 source_ref 关联其节点）。
-- 幂等：按 source_ref='pku-curated:bike' 清理后重建。
-- =====================================================
SET client_encoding = 'UTF8';
BEGIN;

DELETE FROM graph_edges WHERE source_ref = 'pku-curated:bike';

-- 主干道自行车段（无向；下方 UNION 自动补反向）。
WITH seg(f, t) AS (
    VALUES
        ('west_gate', 'sackler'), ('sackler', 'jingchun'), ('jingchun', 'weiming_west'),
        ('weiming_west', 'admin'), ('admin', 'library'), ('library', 'first_teaching'),
        ('first_teaching', 'weiming_south'), ('weiming_south', 'boya'),
        ('library', 'science'), ('science', 'second_teaching'),
        ('second_teaching', 'fourth_teaching'), ('fourth_teaching', 'gym'), ('gym', 'south_gate'),
        ('admin', 'shao_yuan'), ('shao_yuan', 'west_gate'),
        ('weiming_east', 'guanghua'), ('guanghua', 'government'), ('government', 'east_gate'),
        ('government', 'lakeview'), ('lakeview', 'north_gate'),
        ('second_teaching', 'hall'), ('hall', 'nongyuan'), ('nongyuan', 'south_gate')
),
bidir(f, t) AS (
    SELECT f, t FROM seg
    UNION ALL
    SELECT t, f FROM seg
)
INSERT INTO graph_edges
    (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
SELECT a.id, b.id,
       ST_Distance(a.location, b.location),
       'bike',
       CEIL(ST_Distance(a.location, b.location) / 4.0)::int,   -- 自行车 4 m/s
       (ST_Distance(a.location, b.location) / 100.0),
       2,
       'osm',                                                   -- 可导航真实道路
       'pku-curated:bike'
FROM bidir
JOIN graph_nodes a ON a.source_ref = 'pku-curated:node:' || bidir.f
JOIN graph_nodes b ON b.source_ref = 'pku-curated:node:' || bidir.t;

COMMIT;
