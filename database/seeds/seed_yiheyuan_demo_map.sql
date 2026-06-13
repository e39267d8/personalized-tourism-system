-- =====================================================
-- 颐和园内部步行演示图（人工构造的连通路网 + 分类设施）
-- 由 scripts/gen_yiheyuan_demo_map.py 生成，请勿手工编辑。
-- 用途：场所查询/内部导航验收演示。真实 OSM 路网碎片化无法用，
--       本图保证连通，算法（Dijkstra 路网距离/类别过滤/关键词）真实。
-- 幂等：按 source_ref 前缀 'yiheyuan-demo:%' 清理后重建。
-- =====================================================
SET client_encoding = 'UTF8';
BEGIN;

DO $$
DECLARE
    v_spot INTEGER;
BEGIN
    SELECT id INTO v_spot FROM scenic_spots WHERE name = '颐和园' AND city = '北京市' LIMIT 1;
    IF v_spot IS NULL THEN
        RAISE EXCEPTION '未找到景点 颐和园，请先执行 imports/amap_pois_supplement.sql';
    END IF;

    -- 1. 清理本脚本旧数据（边→节点→设施，按 source_ref 前缀）
    DELETE FROM graph_edges WHERE source_ref LIKE 'yiheyuan-demo:%';
    DELETE FROM graph_nodes WHERE source_ref LIKE 'yiheyuan-demo:%';
    DELETE FROM facilities  WHERE source_ref LIKE 'yiheyuan-demo:%';

    -- 2. 设施（facilities）
    INSERT INTO facilities (name, type, location, address, rating, price_level, opening_hours, scenic_spot_id, source, source_ref)
    VALUES ('东宫门公共卫生间', 'toilet', ST_SetSRID(ST_MakePoint(116.276912, 39.992100), 4326)::geography, '颐和园内', 4.3, NULL, '08:00-17:00', v_spot, 'demo', 'yiheyuan-demo:fac:0');
    INSERT INTO facilities (name, type, location, address, rating, price_level, opening_hours, scenic_spot_id, source, source_ref)
    VALUES ('仁寿殿游客服务点', 'service', ST_SetSRID(ST_MakePoint(116.275744, 39.992510), 4326)::geography, '颐和园内', 4.5, NULL, '08:00-17:00', v_spot, 'demo', 'yiheyuan-demo:fac:1');
    INSERT INTO facilities (name, type, location, address, rating, price_level, opening_hours, scenic_spot_id, source, source_ref)
    VALUES ('听鹂馆饭庄', 'restaurant', ST_SetSRID(ST_MakePoint(116.274019, 39.992938), 4326)::geography, '颐和园内', 4.6, 3, '08:00-17:00', v_spot, 'demo', 'yiheyuan-demo:fac:2');
    INSERT INTO facilities (name, type, location, address, rating, price_level, opening_hours, scenic_spot_id, source, source_ref)
    VALUES ('长廊东口卫生间', 'toilet', ST_SetSRID(ST_MakePoint(116.272829, 39.993529), 4326)::geography, '颐和园内', 4.2, NULL, '08:00-17:00', v_spot, 'demo', 'yiheyuan-demo:fac:3');
    INSERT INTO facilities (name, type, location, address, rating, price_level, opening_hours, scenic_spot_id, source, source_ref)
    VALUES ('排云殿文创商店', 'shop', ST_SetSRID(ST_MakePoint(116.270092, 39.993672), 4326)::geography, '颐和园内', 4.4, 2, '08:00-17:00', v_spot, 'demo', 'yiheyuan-demo:fac:4');
    INSERT INTO facilities (name, type, location, address, rating, price_level, opening_hours, scenic_spot_id, source, source_ref)
    VALUES ('石舫咖啡厅', 'restaurant', ST_SetSRID(ST_MakePoint(116.267479, 39.994613), 4326)::geography, '颐和园内', 4.3, 2, '08:00-17:00', v_spot, 'demo', 'yiheyuan-demo:fac:5');
    INSERT INTO facilities (name, type, location, address, rating, price_level, opening_hours, scenic_spot_id, source, source_ref)
    VALUES ('佛香阁观景平台', 'service', ST_SetSRID(ST_MakePoint(116.270445, 39.994757), 4326)::geography, '颐和园内', 4.8, NULL, '08:00-17:00', v_spot, 'demo', 'yiheyuan-demo:fac:6');
    INSERT INTO facilities (name, type, location, address, rating, price_level, opening_hours, scenic_spot_id, source, source_ref)
    VALUES ('苏州街小吃店', 'restaurant', ST_SetSRID(ST_MakePoint(116.270802, 39.996056), 4326)::geography, '颐和园内', 4.1, 1, '08:00-17:00', v_spot, 'demo', 'yiheyuan-demo:fac:7');
    INSERT INTO facilities (name, type, location, address, rating, price_level, opening_hours, scenic_spot_id, source, source_ref)
    VALUES ('北宫门综合超市', 'shop', ST_SetSRID(ST_MakePoint(116.271799, 39.997456), 4326)::geography, '颐和园内', 4.2, 1, '08:00-17:00', v_spot, 'demo', 'yiheyuan-demo:fac:8');
    INSERT INTO facilities (name, type, location, address, rating, price_level, opening_hours, scenic_spot_id, source, source_ref)
    VALUES ('北宫门公共卫生间', 'toilet', ST_SetSRID(ST_MakePoint(116.271404, 39.997462), 4326)::geography, '颐和园内', 4.0, NULL, '08:00-17:00', v_spot, 'demo', 'yiheyuan-demo:fac:9');
    INSERT INTO facilities (name, type, location, address, rating, price_level, opening_hours, scenic_spot_id, source, source_ref)
    VALUES ('知春亭茶室', 'restaurant', ST_SetSRID(ST_MakePoint(116.274590, 39.991553), 4326)::geography, '颐和园内', 4.5, 2, '08:00-17:00', v_spot, 'demo', 'yiheyuan-demo:fac:10');
    INSERT INTO facilities (name, type, location, address, rating, price_level, opening_hours, scenic_spot_id, source, source_ref)
    VALUES ('十七孔桥服务驿站', 'service', ST_SetSRID(ST_MakePoint(116.275263, 39.988955), 4326)::geography, '颐和园内', 4.3, NULL, '08:00-17:00', v_spot, 'demo', 'yiheyuan-demo:fac:11');
    INSERT INTO facilities (name, type, location, address, rating, price_level, opening_hours, scenic_spot_id, source, source_ref)
    VALUES ('南湖岛公共卫生间', 'toilet', ST_SetSRID(ST_MakePoint(116.273517, 39.988219), 4326)::geography, '颐和园内', 3.9, NULL, '08:00-17:00', v_spot, 'demo', 'yiheyuan-demo:fac:12');
    INSERT INTO facilities (name, type, location, address, rating, price_level, opening_hours, scenic_spot_id, source, source_ref)
    VALUES ('西堤自助售卖机', 'atm', ST_SetSRID(ST_MakePoint(116.266007, 39.990365), 4326)::geography, '颐和园内', 4.0, 1, '08:00-17:00', v_spot, 'demo', 'yiheyuan-demo:fac:13');
    INSERT INTO facilities (name, type, location, address, rating, price_level, opening_hours, scenic_spot_id, source, source_ref)
    VALUES ('新建宫门卫生间', 'toilet', ST_SetSRID(ST_MakePoint(116.272878, 39.986333), 4326)::geography, '颐和园内', 4.1, NULL, '08:00-17:00', v_spot, 'demo', 'yiheyuan-demo:fac:14');
    INSERT INTO facilities (name, type, location, address, rating, price_level, opening_hours, scenic_spot_id, source, source_ref)
    VALUES ('东堤便利店', 'shop', ST_SetSRID(ST_MakePoint(116.274573, 39.990439), 4326)::geography, '颐和园内', 4.2, 1, '08:00-17:00', v_spot, 'demo', 'yiheyuan-demo:fac:15');

    -- 3. 路网节点（graph_nodes）：路径/景点/入口
    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, source, source_ref)
    VALUES ('东宫门', ST_SetSRID(ST_MakePoint(116.277400, 39.991900), 4326)::geography, 'entrance', v_spot, 'demo', 'yiheyuan-demo:node:e_dong');
    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, source, source_ref)
    VALUES ('东宫门广场', ST_SetSRID(ST_MakePoint(116.276700, 39.992100), 4326)::geography, 'scenic', v_spot, 'demo', 'yiheyuan-demo:node:w1');
    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, source, source_ref)
    VALUES ('仁寿殿', ST_SetSRID(ST_MakePoint(116.275900, 39.992400), 4326)::geography, 'scenic', v_spot, 'demo', 'yiheyuan-demo:node:w2');
    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, source, source_ref)
    VALUES ('玉澜堂', ST_SetSRID(ST_MakePoint(116.275000, 39.992700), 4326)::geography, 'scenic', v_spot, 'demo', 'yiheyuan-demo:node:w3');
    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, source, source_ref)
    VALUES ('乐寿堂', ST_SetSRID(ST_MakePoint(116.274000, 39.993100), 4326)::geography, 'scenic', v_spot, 'demo', 'yiheyuan-demo:node:w4');
    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, source, source_ref)
    VALUES ('长廊东口', ST_SetSRID(ST_MakePoint(116.272700, 39.993400), 4326)::geography, 'scenic', v_spot, 'demo', 'yiheyuan-demo:node:w5');
    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, source, source_ref)
    VALUES ('排云殿前', ST_SetSRID(ST_MakePoint(116.270300, 39.993700), 4326)::geography, 'scenic', v_spot, 'demo', 'yiheyuan-demo:node:w6');
    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, source, source_ref)
    VALUES ('石舫', ST_SetSRID(ST_MakePoint(116.267300, 39.994700), 4326)::geography, 'scenic', v_spot, 'demo', 'yiheyuan-demo:node:w7');
    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, source, source_ref)
    VALUES ('佛香阁下', ST_SetSRID(ST_MakePoint(116.270500, 39.994600), 4326)::geography, 'scenic', v_spot, 'demo', 'yiheyuan-demo:node:w8');
    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, source, source_ref)
    VALUES ('苏州街', ST_SetSRID(ST_MakePoint(116.270900, 39.996200), 4326)::geography, 'scenic', v_spot, 'demo', 'yiheyuan-demo:node:w9');
    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, source, source_ref)
    VALUES ('北宫门内', ST_SetSRID(ST_MakePoint(116.271600, 39.997400), 4326)::geography, 'scenic', v_spot, 'demo', 'yiheyuan-demo:node:w10');
    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, source, source_ref)
    VALUES ('北宫门', ST_SetSRID(ST_MakePoint(116.271900, 39.998400), 4326)::geography, 'entrance', v_spot, 'demo', 'yiheyuan-demo:node:e_bei');
    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, source, source_ref)
    VALUES ('昆明湖东堤', ST_SetSRID(ST_MakePoint(116.274600, 39.990600), 4326)::geography, 'scenic', v_spot, 'demo', 'yiheyuan-demo:node:w11');
    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, source, source_ref)
    VALUES ('知春亭', ST_SetSRID(ST_MakePoint(116.274500, 39.991700), 4326)::geography, 'scenic', v_spot, 'demo', 'yiheyuan-demo:node:w12');
    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, source, source_ref)
    VALUES ('十七孔桥北', ST_SetSRID(ST_MakePoint(116.275200, 39.988800), 4326)::geography, 'scenic', v_spot, 'demo', 'yiheyuan-demo:node:w13');
    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, source, source_ref)
    VALUES ('南湖岛', ST_SetSRID(ST_MakePoint(116.273700, 39.988300), 4326)::geography, 'scenic', v_spot, 'demo', 'yiheyuan-demo:node:w14');
    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, source, source_ref)
    VALUES ('铜牛', ST_SetSRID(ST_MakePoint(116.275600, 39.989900), 4326)::geography, 'scenic', v_spot, 'demo', 'yiheyuan-demo:node:w15');
    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, source, source_ref)
    VALUES ('西堤玉带桥', ST_SetSRID(ST_MakePoint(116.265800, 39.990400), 4326)::geography, 'scenic', v_spot, 'demo', 'yiheyuan-demo:node:w16');
    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, source, source_ref)
    VALUES ('新建宫门内', ST_SetSRID(ST_MakePoint(116.273000, 39.986200), 4326)::geography, 'scenic', v_spot, 'demo', 'yiheyuan-demo:node:w17');
    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, source, source_ref)
    VALUES ('新建宫门', ST_SetSRID(ST_MakePoint(116.273200, 39.985400), 4326)::geography, 'entrance', v_spot, 'demo', 'yiheyuan-demo:node:e_xin');

    -- 4. 设施对应的路网节点（node_type='facility'，绑定 facility_id）
    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, facility_id, source, source_ref)
    SELECT f.name, f.location, 'facility', v_spot, f.id, 'demo', 'yiheyuan-demo:facnode:0'
    FROM facilities f WHERE f.source_ref = 'yiheyuan-demo:fac:0';
    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, facility_id, source, source_ref)
    SELECT f.name, f.location, 'facility', v_spot, f.id, 'demo', 'yiheyuan-demo:facnode:1'
    FROM facilities f WHERE f.source_ref = 'yiheyuan-demo:fac:1';
    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, facility_id, source, source_ref)
    SELECT f.name, f.location, 'facility', v_spot, f.id, 'demo', 'yiheyuan-demo:facnode:2'
    FROM facilities f WHERE f.source_ref = 'yiheyuan-demo:fac:2';
    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, facility_id, source, source_ref)
    SELECT f.name, f.location, 'facility', v_spot, f.id, 'demo', 'yiheyuan-demo:facnode:3'
    FROM facilities f WHERE f.source_ref = 'yiheyuan-demo:fac:3';
    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, facility_id, source, source_ref)
    SELECT f.name, f.location, 'facility', v_spot, f.id, 'demo', 'yiheyuan-demo:facnode:4'
    FROM facilities f WHERE f.source_ref = 'yiheyuan-demo:fac:4';
    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, facility_id, source, source_ref)
    SELECT f.name, f.location, 'facility', v_spot, f.id, 'demo', 'yiheyuan-demo:facnode:5'
    FROM facilities f WHERE f.source_ref = 'yiheyuan-demo:fac:5';
    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, facility_id, source, source_ref)
    SELECT f.name, f.location, 'facility', v_spot, f.id, 'demo', 'yiheyuan-demo:facnode:6'
    FROM facilities f WHERE f.source_ref = 'yiheyuan-demo:fac:6';
    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, facility_id, source, source_ref)
    SELECT f.name, f.location, 'facility', v_spot, f.id, 'demo', 'yiheyuan-demo:facnode:7'
    FROM facilities f WHERE f.source_ref = 'yiheyuan-demo:fac:7';
    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, facility_id, source, source_ref)
    SELECT f.name, f.location, 'facility', v_spot, f.id, 'demo', 'yiheyuan-demo:facnode:8'
    FROM facilities f WHERE f.source_ref = 'yiheyuan-demo:fac:8';
    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, facility_id, source, source_ref)
    SELECT f.name, f.location, 'facility', v_spot, f.id, 'demo', 'yiheyuan-demo:facnode:9'
    FROM facilities f WHERE f.source_ref = 'yiheyuan-demo:fac:9';
    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, facility_id, source, source_ref)
    SELECT f.name, f.location, 'facility', v_spot, f.id, 'demo', 'yiheyuan-demo:facnode:10'
    FROM facilities f WHERE f.source_ref = 'yiheyuan-demo:fac:10';
    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, facility_id, source, source_ref)
    SELECT f.name, f.location, 'facility', v_spot, f.id, 'demo', 'yiheyuan-demo:facnode:11'
    FROM facilities f WHERE f.source_ref = 'yiheyuan-demo:fac:11';
    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, facility_id, source, source_ref)
    SELECT f.name, f.location, 'facility', v_spot, f.id, 'demo', 'yiheyuan-demo:facnode:12'
    FROM facilities f WHERE f.source_ref = 'yiheyuan-demo:fac:12';
    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, facility_id, source, source_ref)
    SELECT f.name, f.location, 'facility', v_spot, f.id, 'demo', 'yiheyuan-demo:facnode:13'
    FROM facilities f WHERE f.source_ref = 'yiheyuan-demo:fac:13';
    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, facility_id, source, source_ref)
    SELECT f.name, f.location, 'facility', v_spot, f.id, 'demo', 'yiheyuan-demo:facnode:14'
    FROM facilities f WHERE f.source_ref = 'yiheyuan-demo:fac:14';
    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, facility_id, source, source_ref)
    SELECT f.name, f.location, 'facility', v_spot, f.id, 'demo', 'yiheyuan-demo:facnode:15'
    FROM facilities f WHERE f.source_ref = 'yiheyuan-demo:fac:15';

    -- 5. 步行路径边（双向，几何来自高德步行折线，沿真实道路）
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref, geometry)
    SELECT na.id, nb.id, 27.5, 'walk', 22, 0.28, 2, 'osm', 'yiheyuan-demo:edge', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.276641 39.991606, 116.276589 39.991697, 116.276432 39.991784)')
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:e_dong' AND nb.source_ref='yiheyuan-demo:node:w1';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref, geometry)
    SELECT na.id, nb.id, 27.5, 'walk', 22, 0.28, 2, 'osm', 'yiheyuan-demo:edge', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.276432 39.991784, 116.276589 39.991697, 116.276641 39.991606)')
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w1' AND nb.source_ref='yiheyuan-demo:node:e_dong';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref, geometry)
    SELECT na.id, nb.id, 45.7, 'walk', 38, 0.46, 2, 'osm', 'yiheyuan-demo:edge', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.276428 39.991784, 116.276150 39.991862, 116.276098 39.991875, 116.275981 39.991875, 116.275911 39.991875)')
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w1' AND nb.source_ref='yiheyuan-demo:node:w2';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref, geometry)
    SELECT na.id, nb.id, 45.7, 'walk', 38, 0.46, 2, 'osm', 'yiheyuan-demo:edge', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.275911 39.991875, 116.275981 39.991875, 116.276098 39.991875, 116.276150 39.991862, 116.276428 39.991784)')
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w2' AND nb.source_ref='yiheyuan-demo:node:w1';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref, geometry)
    SELECT na.id, nb.id, 27.3, 'walk', 22, 0.27, 2, 'osm', 'yiheyuan-demo:edge', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.275907 39.991875, 116.275885 39.991875, 116.275742 39.991858, 116.275595 39.991823)')
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w2' AND nb.source_ref='yiheyuan-demo:node:w3';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref, geometry)
    SELECT na.id, nb.id, 27.3, 'walk', 22, 0.27, 2, 'osm', 'yiheyuan-demo:edge', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.275595 39.991823, 116.275742 39.991858, 116.275885 39.991875, 116.275907 39.991875)')
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w3' AND nb.source_ref='yiheyuan-demo:node:w2';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref, geometry)
    SELECT na.id, nb.id, 11.0, 'walk', 9, 0.11, 2, 'osm', 'yiheyuan-demo:edge', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.275590 39.991819, 116.275477 39.991771)')
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w3' AND nb.source_ref='yiheyuan-demo:node:w4';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref, geometry)
    SELECT na.id, nb.id, 11.0, 'walk', 9, 0.11, 2, 'osm', 'yiheyuan-demo:edge', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.275477 39.991771, 116.275590 39.991819)')
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w4' AND nb.source_ref='yiheyuan-demo:node:w3';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref, geometry)
    SELECT na.id, nb.id, 114.8, 'walk', 95, 1.15, 2, 'osm', 'yiheyuan-demo:edge', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.273997 39.993099, 116.272704 39.993398)')
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w4' AND nb.source_ref='yiheyuan-demo:node:w5';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref, geometry)
    SELECT na.id, nb.id, 114.8, 'walk', 95, 1.15, 2, 'osm', 'yiheyuan-demo:edge', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.272704 39.993398, 116.273997 39.993099)')
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w5' AND nb.source_ref='yiheyuan-demo:node:w4';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref, geometry)
    SELECT na.id, nb.id, 3705.6, 'walk', 3088, 37.06, 2, 'osm', 'yiheyuan-demo:edge', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.275473 39.991766, 116.275590 39.991819, 116.275738 39.991853, 116.275881 39.991875, 116.275977 39.991875, 116.276094 39.991875, 116.276146 39.991866, 116.276428 39.991788, 116.276584 39.991701, 116.276667 39.991576, 116.276680 39.991536, 116.276680 39.991502, 116.276667 39.991432, 116.276602 39.991250, 116.276584 39.991059, 116.276580 39.991055, 116.276680 39.991029, 116.276675 39.991024, 116.277847 39.990642, 116.278333 39.990503, 116.278333 39.990499, 116.278676 39.990477, 116.279058 39.990425, 116.279058 39.990421, 116.279293 39.990556, 116.279375 39.990595, 116.279583 39.990751, 116.279631 39.990799, 116.279692 39.990920, 116.279766 39.991137, 116.279896 39.991480, 116.280148 39.991827, 116.280278 39.992148, 116.280360 39.992921, 116.280516 39.993832, 116.280495 39.994310, 116.280421 39.995022, 116.280408 39.995139, 116.280382 39.995447, 116.280373 39.995573, 116.280330 39.995924, 116.280039 39.996458, 116.279887 39.996788, 116.279887 39.996784, 116.279787 39.996884, 116.279705 39.996970, 116.279644 39.997014, 116.279562 39.997096, 116.279488 39.997144, 116.279401 39.997192, 116.279332 39.997253, 116.279240 39.997357, 116.279206 39.997405, 116.279141 39.997517, 116.279097 39.997656, 116.279019 39.998294, 116.278997 39.998403, 116.278993 39.998403, 116.278945 39.998403, 116.278824 39.998403, 116.278685 39.998403, 116.278615 39.998398, 116.278268 39.998355, 116.278142 39.998338, 116.278025 39.998329, 116.277947 39.998329, 116.277925 39.998333, 116.277917 39.998351, 116.277908 39.998433, 116.277904 39.998433, 116.277565 39.998407, 116.276953 39.998359, 116.276519 39.998320, 116.275920 39.998260, 116.275747 39.998234, 116.275464 39.998168, 116.274727 39.997652, 116.274653 39.997617, 116.274262 39.997591, 116.274167 39.997578, 116.273746 39.997543, 116.273424 39.997543, 116.272947 39.997704, 116.272669 39.997821, 116.272582 39.997843, 116.272448 39.997852, 116.271059 39.997721, 116.270135 39.997635, 116.270130 39.997630, 116.270095 39.997652, 116.270074 39.997678, 116.270039 39.997969, 116.270004 39.998207, 116.269974 39.998290, 116.269944 39.998316, 116.269766 39.998455, 116.269540 39.998767, 116.269444 39.998997, 116.269414 39.999106, 116.269397 39.999201, 116.269397 39.999470, 116.269392 39.999648, 116.269362 39.999944, 116.269314 40.000256, 116.269219 40.000707, 116.269193 40.000751, 116.269188 40.000751, 116.268737 40.000720, 116.268733 40.000716, 116.268220 40.000937, 116.267960 40.000968, 116.267630 40.000955, 116.267626 40.000951, 116.267713 40.000547, 116.267786 40.000200, 116.267817 40.000122, 116.267856 40.000030, 116.268051 39.999748, 116.268060 39.999544, 116.268016 39.999297, 116.267951 39.999136, 116.267726 39.998776, 116.267535 39.998242, 116.267452 39.997938, 116.267504 39.997144, 116.267556 39.996749, 116.267569 39.996519, 116.267535 39.996385, 116.267552 39.996259, 116.267569 39.995699, 116.267543 39.995365, 116.267543 39.995030, 116.267569 39.994592, 116.267552 39.994484, 116.267357 39.993815, 116.267300 39.993698, 116.267049 39.993333, 116.266901 39.993142, 116.266897 39.993138, 116.267062 39.992999, 116.267626 39.992687, 116.268199 39.992326, 116.268273 39.992266)')
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w5' AND nb.source_ref='yiheyuan-demo:node:w6';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref, geometry)
    SELECT na.id, nb.id, 3705.6, 'walk', 3088, 37.06, 2, 'osm', 'yiheyuan-demo:edge', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.268273 39.992266, 116.268199 39.992326, 116.267626 39.992687, 116.267062 39.992999, 116.266897 39.993138, 116.266901 39.993142, 116.267049 39.993333, 116.267300 39.993698, 116.267357 39.993815, 116.267552 39.994484, 116.267569 39.994592, 116.267543 39.995030, 116.267543 39.995365, 116.267569 39.995699, 116.267552 39.996259, 116.267535 39.996385, 116.267569 39.996519, 116.267556 39.996749, 116.267504 39.997144, 116.267452 39.997938, 116.267535 39.998242, 116.267726 39.998776, 116.267951 39.999136, 116.268016 39.999297, 116.268060 39.999544, 116.268051 39.999748, 116.267856 40.000030, 116.267817 40.000122, 116.267786 40.000200, 116.267713 40.000547, 116.267626 40.000951, 116.267630 40.000955, 116.267960 40.000968, 116.268220 40.000937, 116.268733 40.000716, 116.268737 40.000720, 116.269188 40.000751, 116.269193 40.000751, 116.269219 40.000707, 116.269314 40.000256, 116.269362 39.999944, 116.269392 39.999648, 116.269397 39.999470, 116.269397 39.999201, 116.269414 39.999106, 116.269444 39.998997, 116.269540 39.998767, 116.269766 39.998455, 116.269944 39.998316, 116.269974 39.998290, 116.270004 39.998207, 116.270039 39.997969, 116.270074 39.997678, 116.270095 39.997652, 116.270130 39.997630, 116.270135 39.997635, 116.271059 39.997721, 116.272448 39.997852, 116.272582 39.997843, 116.272669 39.997821, 116.272947 39.997704, 116.273424 39.997543, 116.273746 39.997543, 116.274167 39.997578, 116.274262 39.997591, 116.274653 39.997617, 116.274727 39.997652, 116.275464 39.998168, 116.275747 39.998234, 116.275920 39.998260, 116.276519 39.998320, 116.276953 39.998359, 116.277565 39.998407, 116.277904 39.998433, 116.277908 39.998433, 116.277917 39.998351, 116.277925 39.998333, 116.277947 39.998329, 116.278025 39.998329, 116.278142 39.998338, 116.278268 39.998355, 116.278615 39.998398, 116.278685 39.998403, 116.278824 39.998403, 116.278945 39.998403, 116.278993 39.998403, 116.278997 39.998403, 116.279019 39.998294, 116.279097 39.997656, 116.279141 39.997517, 116.279206 39.997405, 116.279240 39.997357, 116.279332 39.997253, 116.279401 39.997192, 116.279488 39.997144, 116.279562 39.997096, 116.279644 39.997014, 116.279705 39.996970, 116.279787 39.996884, 116.279887 39.996784, 116.279887 39.996788, 116.280039 39.996458, 116.280330 39.995924, 116.280373 39.995573, 116.280382 39.995447, 116.280408 39.995139, 116.280421 39.995022, 116.280495 39.994310, 116.280516 39.993832, 116.280360 39.992921, 116.280278 39.992148, 116.280148 39.991827, 116.279896 39.991480, 116.279766 39.991137, 116.279692 39.990920, 116.279631 39.990799, 116.279583 39.990751, 116.279375 39.990595, 116.279293 39.990556, 116.279058 39.990421, 116.279058 39.990425, 116.278676 39.990477, 116.278333 39.990499, 116.278333 39.990503, 116.277847 39.990642, 116.276675 39.991024, 116.276680 39.991029, 116.276580 39.991055, 116.276584 39.991059, 116.276602 39.991250, 116.276667 39.991432, 116.276680 39.991502, 116.276680 39.991536, 116.276667 39.991576, 116.276584 39.991701, 116.276428 39.991788, 116.276146 39.991866, 116.276094 39.991875, 116.275977 39.991875, 116.275881 39.991875, 116.275738 39.991853, 116.275590 39.991819, 116.275473 39.991766)')
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w6' AND nb.source_ref='yiheyuan-demo:node:w5';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref, geometry)
    SELECT na.id, nb.id, 338.8, 'walk', 282, 3.39, 2, 'osm', 'yiheyuan-demo:edge', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.268273 39.992261, 116.268203 39.992326, 116.267630 39.992682, 116.267066 39.992995, 116.266901 39.993138, 116.266897 39.993138, 116.267044 39.993329, 116.267296 39.993694, 116.267352 39.993811, 116.267548 39.994479, 116.267569 39.994588, 116.267565 39.994709)')
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w6' AND nb.source_ref='yiheyuan-demo:node:w7';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref, geometry)
    SELECT na.id, nb.id, 338.8, 'walk', 282, 3.39, 2, 'osm', 'yiheyuan-demo:edge', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.267565 39.994709, 116.267569 39.994588, 116.267548 39.994479, 116.267352 39.993811, 116.267296 39.993694, 116.267044 39.993329, 116.266897 39.993138, 116.266901 39.993138, 116.267066 39.992995, 116.267630 39.992682, 116.268203 39.992326, 116.268273 39.992261)')
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w7' AND nb.source_ref='yiheyuan-demo:node:w6';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref, geometry)
    SELECT na.id, nb.id, 325.3, 'walk', 271, 3.25, 2, 'osm', 'yiheyuan-demo:edge', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.268273 39.992261, 116.268203 39.992326, 116.267630 39.992682, 116.267066 39.992995, 116.266901 39.993138, 116.266897 39.993138, 116.267044 39.993329, 116.267296 39.993694, 116.267352 39.993811, 116.267548 39.994479, 116.267569 39.994588)')
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w6' AND nb.source_ref='yiheyuan-demo:node:w8';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref, geometry)
    SELECT na.id, nb.id, 325.3, 'walk', 271, 3.25, 2, 'osm', 'yiheyuan-demo:edge', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.267569 39.994588, 116.267548 39.994479, 116.267352 39.993811, 116.267296 39.993694, 116.267044 39.993329, 116.266897 39.993138, 116.266901 39.993138, 116.267066 39.992995, 116.267630 39.992682, 116.268203 39.992326, 116.268273 39.992261)')
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w8' AND nb.source_ref='yiheyuan-demo:node:w6';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref, geometry)
    SELECT na.id, nb.id, 1272.6, 'walk', 1060, 12.73, 2, 'osm', 'yiheyuan-demo:edge', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.267569 39.994588, 116.267543 39.995026, 116.267543 39.995360, 116.267569 39.995694, 116.267556 39.996254, 116.267535 39.996380, 116.267569 39.996515, 116.267561 39.996745, 116.267509 39.997140, 116.267452 39.997934, 116.267530 39.998238, 116.267721 39.998772, 116.267947 39.999132, 116.268012 39.999293, 116.268060 39.999540, 116.268056 39.999744, 116.267860 40.000026, 116.267821 40.000117, 116.267791 40.000195, 116.267717 40.000543, 116.267630 40.000951, 116.267626 40.000951, 116.267956 40.000968, 116.268216 40.000942, 116.268733 40.000720, 116.268733 40.000716, 116.269188 40.000751, 116.269214 40.000712, 116.269310 40.000260, 116.269358 39.999948, 116.269388 39.999653, 116.269392 39.999475, 116.269392 39.999206, 116.269410 39.999110, 116.269440 39.999002, 116.269536 39.998772, 116.269761 39.998459, 116.269939 39.998320, 116.269970 39.998294, 116.270000 39.998212, 116.270035 39.997973, 116.270069 39.997682, 116.270091 39.997656, 116.270130 39.997635, 116.270130 39.997630, 116.270664 39.997678)')
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w8' AND nb.source_ref='yiheyuan-demo:node:w9';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref, geometry)
    SELECT na.id, nb.id, 1272.6, 'walk', 1060, 12.73, 2, 'osm', 'yiheyuan-demo:edge', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.270664 39.997678, 116.270130 39.997630, 116.270130 39.997635, 116.270091 39.997656, 116.270069 39.997682, 116.270035 39.997973, 116.270000 39.998212, 116.269970 39.998294, 116.269939 39.998320, 116.269761 39.998459, 116.269536 39.998772, 116.269440 39.999002, 116.269410 39.999110, 116.269392 39.999206, 116.269392 39.999475, 116.269388 39.999653, 116.269358 39.999948, 116.269310 40.000260, 116.269214 40.000712, 116.269188 40.000751, 116.268733 40.000716, 116.268733 40.000720, 116.268216 40.000942, 116.267956 40.000968, 116.267626 40.000951, 116.267630 40.000951, 116.267717 40.000543, 116.267791 40.000195, 116.267821 40.000117, 116.267860 40.000026, 116.268056 39.999744, 116.268060 39.999540, 116.268012 39.999293, 116.267947 39.999132, 116.267721 39.998772, 116.267530 39.998238, 116.267452 39.997934, 116.267509 39.997140, 116.267561 39.996745, 116.267569 39.996515, 116.267535 39.996380, 116.267556 39.996254, 116.267569 39.995694, 116.267543 39.995360, 116.267543 39.995026, 116.267569 39.994588)')
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w9' AND nb.source_ref='yiheyuan-demo:node:w8';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref, geometry)
    SELECT na.id, nb.id, 74.7, 'walk', 62, 0.75, 2, 'osm', 'yiheyuan-demo:edge', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.270664 39.997678, 116.271055 39.997717, 116.271536 39.997760)')
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w9' AND nb.source_ref='yiheyuan-demo:node:w10';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref, geometry)
    SELECT na.id, nb.id, 74.7, 'walk', 62, 0.75, 2, 'osm', 'yiheyuan-demo:edge', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.271536 39.997760, 116.271055 39.997717, 116.270664 39.997678)')
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w10' AND nb.source_ref='yiheyuan-demo:node:w9';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref, geometry)
    SELECT na.id, nb.id, 178.4, 'walk', 148, 1.78, 2, 'osm', 'yiheyuan-demo:edge', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.271536 39.997760, 116.272444 39.997852, 116.272444 39.997847, 116.272448 39.997925, 116.272448 39.997977, 116.272287 39.997977, 116.272044 39.997964, 116.272010 39.997960, 116.272005 39.997956, 116.271970 39.998064, 116.271918 39.998203, 116.271879 39.998247, 116.271836 39.998255, 116.271771 39.998325)')
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w10' AND nb.source_ref='yiheyuan-demo:node:e_bei';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref, geometry)
    SELECT na.id, nb.id, 178.4, 'walk', 148, 1.78, 2, 'osm', 'yiheyuan-demo:edge', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.271771 39.998325, 116.271836 39.998255, 116.271879 39.998247, 116.271918 39.998203, 116.271970 39.998064, 116.272005 39.997956, 116.272010 39.997960, 116.272044 39.997964, 116.272287 39.997977, 116.272448 39.997977, 116.272448 39.997925, 116.272444 39.997847, 116.272444 39.997852, 116.271536 39.997760)')
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:e_bei' AND nb.source_ref='yiheyuan-demo:node:w10';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref, geometry)
    SELECT na.id, nb.id, 160.4, 'walk', 133, 1.60, 2, 'osm', 'yiheyuan-demo:edge', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.276428 39.991784, 116.276150 39.991862, 116.276098 39.991875, 116.275981 39.991875, 116.275885 39.991875, 116.275742 39.991858, 116.275595 39.991823, 116.275477 39.991771, 116.275425 39.991706, 116.275412 39.991654, 116.275404 39.991554, 116.275382 39.991406, 116.275382 39.991363, 116.275430 39.991298, 116.275573 39.991150)')
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w1' AND nb.source_ref='yiheyuan-demo:node:w11';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref, geometry)
    SELECT na.id, nb.id, 160.4, 'walk', 133, 1.60, 2, 'osm', 'yiheyuan-demo:edge', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.275573 39.991150, 116.275430 39.991298, 116.275382 39.991363, 116.275382 39.991406, 116.275404 39.991554, 116.275412 39.991654, 116.275425 39.991706, 116.275477 39.991771, 116.275595 39.991823, 116.275742 39.991858, 116.275885 39.991875, 116.275981 39.991875, 116.276098 39.991875, 116.276150 39.991862, 116.276428 39.991784)')
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w11' AND nb.source_ref='yiheyuan-demo:node:w1';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref, geometry)
    SELECT na.id, nb.id, 60.5, 'walk', 50, 0.61, 2, 'osm', 'yiheyuan-demo:edge', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.275573 39.991146, 116.275434 39.991293, 116.275382 39.991359, 116.275382 39.991402, 116.275399 39.991549, 116.275408 39.991645)')
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w11' AND nb.source_ref='yiheyuan-demo:node:w12';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref, geometry)
    SELECT na.id, nb.id, 60.5, 'walk', 50, 0.61, 2, 'osm', 'yiheyuan-demo:edge', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.275408 39.991645, 116.275399 39.991549, 116.275382 39.991402, 116.275382 39.991359, 116.275434 39.991293, 116.275573 39.991146)')
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w12' AND nb.source_ref='yiheyuan-demo:node:w11';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref, geometry)
    SELECT na.id, nb.id, 288.9, 'walk', 240, 2.89, 2, 'osm', 'yiheyuan-demo:edge', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.275573 39.991146, 116.275434 39.991293, 116.275382 39.991359, 116.275382 39.991402, 116.275399 39.991549, 116.275734 39.991671, 116.275812 39.991671, 116.275885 39.991675, 116.276033 39.991680, 116.276172 39.991680, 116.276328 39.991667, 116.276380 39.991654, 116.276458 39.991610, 116.276593 39.991497, 116.276662 39.991432, 116.276736 39.991385, 116.276719 39.991228, 116.276706 39.991137, 116.276684 39.991029, 116.276680 39.991024, 116.276584 39.991055, 116.276254 39.991076, 116.276141 39.991081, 116.276128 39.991081, 116.276120 39.990916, 116.276094 39.990898)')
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w11' AND nb.source_ref='yiheyuan-demo:node:w15';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref, geometry)
    SELECT na.id, nb.id, 288.9, 'walk', 240, 2.89, 2, 'osm', 'yiheyuan-demo:edge', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.276094 39.990898, 116.276120 39.990916, 116.276128 39.991081, 116.276141 39.991081, 116.276254 39.991076, 116.276584 39.991055, 116.276680 39.991024, 116.276684 39.991029, 116.276706 39.991137, 116.276719 39.991228, 116.276736 39.991385, 116.276662 39.991432, 116.276593 39.991497, 116.276458 39.991610, 116.276380 39.991654, 116.276328 39.991667, 116.276172 39.991680, 116.276033 39.991680, 116.275885 39.991675, 116.275812 39.991671, 116.275734 39.991671, 116.275399 39.991549, 116.275382 39.991402, 116.275382 39.991359, 116.275434 39.991293, 116.275573 39.991146)')
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w15' AND nb.source_ref='yiheyuan-demo:node:w11';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref, geometry)
    SELECT na.id, nb.id, 126.0, 'walk', 104, 1.26, 2, 'osm', 'yiheyuan-demo:edge', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.275599 39.989896, 116.275204 39.988802)')
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w15' AND nb.source_ref='yiheyuan-demo:node:w13';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref, geometry)
    SELECT na.id, nb.id, 126.0, 'walk', 104, 1.26, 2, 'osm', 'yiheyuan-demo:edge', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.275204 39.988802, 116.275599 39.989896)')
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w13' AND nb.source_ref='yiheyuan-demo:node:w15';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref, geometry)
    SELECT na.id, nb.id, 2498.2, 'walk', 2081, 24.98, 2, 'osm', 'yiheyuan-demo:edge', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.276089 39.990894, 116.276115 39.990911, 116.276124 39.991076, 116.276137 39.991081, 116.276250 39.991081, 116.276580 39.991059, 116.276680 39.991029, 116.276675 39.991024, 116.277847 39.990642, 116.278333 39.990503, 116.278333 39.990499, 116.278537 39.990234, 116.278650 39.990087, 116.278650 39.990082, 116.278620 39.989861, 116.278355 39.988993, 116.278220 39.988451, 116.278069 39.987604, 116.277734 39.986094, 116.277622 39.985812, 116.277483 39.985569, 116.277439 39.985438, 116.277448 39.985278, 116.277470 39.985152, 116.277539 39.984983, 116.277622 39.984883, 116.277791 39.984727, 116.278229 39.984262, 116.278663 39.983746, 116.279071 39.983220, 116.279293 39.982886, 116.279670 39.982339, 116.280013 39.981714, 116.280074 39.981571, 116.280082 39.981545, 116.280082 39.981541, 116.279861 39.981428, 116.279557 39.981398, 116.279553 39.981393, 116.279340 39.981332, 116.279076 39.981337, 116.278576 39.981345, 116.277665 39.981432, 116.277661 39.981432, 116.277517 39.981597, 116.277283 39.981879, 116.277144 39.982049, 116.276745 39.982370, 116.276740 39.982370, 116.276437 39.982426, 116.276215 39.982457, 116.276146 39.982465, 116.275760 39.982500, 116.275612 39.982487, 116.275547 39.982487, 116.275486 39.982491, 116.275378 39.982517, 116.275065 39.982539, 116.275004 39.982522, 116.274852 39.982496, 116.274809 39.982496, 116.274670 39.982496, 116.274062 39.982622, 116.274058 39.982622, 116.274032 39.982704, 116.273954 39.982899, 116.273767 39.983264, 116.273689 39.983424, 116.273672 39.983503, 116.273672 39.983832, 116.273676 39.984227, 116.273720 39.984627, 116.273798 39.984965, 116.273872 39.985174, 116.273889 39.985282, 116.273906 39.985447, 116.273889 39.985595, 116.273863 39.985807, 116.273859 39.985807, 116.273945 39.985825, 116.273902 39.986076, 116.273893 39.986159, 116.273867 39.986263, 116.273850 39.986385, 116.273802 39.986632, 116.273789 39.986641, 116.273702 39.986636, 116.273698 39.986632, 116.273668 39.986701, 116.273490 39.986797, 116.273225 39.987023, 116.272687 39.987635, 116.272587 39.987752)')
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w13' AND nb.source_ref='yiheyuan-demo:node:w14';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref, geometry)
    SELECT na.id, nb.id, 2498.2, 'walk', 2081, 24.98, 2, 'osm', 'yiheyuan-demo:edge', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.272587 39.987752, 116.272687 39.987635, 116.273225 39.987023, 116.273490 39.986797, 116.273668 39.986701, 116.273698 39.986632, 116.273702 39.986636, 116.273789 39.986641, 116.273802 39.986632, 116.273850 39.986385, 116.273867 39.986263, 116.273893 39.986159, 116.273902 39.986076, 116.273945 39.985825, 116.273859 39.985807, 116.273863 39.985807, 116.273889 39.985595, 116.273906 39.985447, 116.273889 39.985282, 116.273872 39.985174, 116.273798 39.984965, 116.273720 39.984627, 116.273676 39.984227, 116.273672 39.983832, 116.273672 39.983503, 116.273689 39.983424, 116.273767 39.983264, 116.273954 39.982899, 116.274032 39.982704, 116.274058 39.982622, 116.274062 39.982622, 116.274670 39.982496, 116.274809 39.982496, 116.274852 39.982496, 116.275004 39.982522, 116.275065 39.982539, 116.275378 39.982517, 116.275486 39.982491, 116.275547 39.982487, 116.275612 39.982487, 116.275760 39.982500, 116.276146 39.982465, 116.276215 39.982457, 116.276437 39.982426, 116.276740 39.982370, 116.276745 39.982370, 116.277144 39.982049, 116.277283 39.981879, 116.277517 39.981597, 116.277661 39.981432, 116.277665 39.981432, 116.278576 39.981345, 116.279076 39.981337, 116.279340 39.981332, 116.279553 39.981393, 116.279557 39.981398, 116.279861 39.981428, 116.280082 39.981541, 116.280082 39.981545, 116.280074 39.981571, 116.280013 39.981714, 116.279670 39.982339, 116.279293 39.982886, 116.279071 39.983220, 116.278663 39.983746, 116.278229 39.984262, 116.277791 39.984727, 116.277622 39.984883, 116.277539 39.984983, 116.277470 39.985152, 116.277448 39.985278, 116.277439 39.985438, 116.277483 39.985569, 116.277622 39.985812, 116.277734 39.986094, 116.278069 39.987604, 116.278220 39.988451, 116.278355 39.988993, 116.278620 39.989861, 116.278650 39.990082, 116.278650 39.990087, 116.278537 39.990234, 116.278333 39.990499, 116.278333 39.990503, 116.277847 39.990642, 116.276675 39.991024, 116.276680 39.991029, 116.276580 39.991059, 116.276250 39.991081, 116.276137 39.991081, 116.276124 39.991076, 116.276115 39.990911, 116.276089 39.990894)')
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w14' AND nb.source_ref='yiheyuan-demo:node:w13';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref, geometry)
    SELECT na.id, nb.id, 619.5, 'walk', 516, 6.19, 2, 'osm', 'yiheyuan-demo:edge', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.267561 39.994709, 116.267569 39.994592, 116.267552 39.994484, 116.267357 39.993815, 116.267300 39.993698, 116.267049 39.993333, 116.266901 39.993142, 116.266897 39.993138, 116.267062 39.992999, 116.267626 39.992687, 116.268199 39.992326, 116.267964 39.991940, 116.267826 39.991710, 116.267760 39.991506, 116.267721 39.991089, 116.267687 39.990951, 116.267543 39.990573, 116.267396 39.990234, 116.267374 39.990187, 116.267300 39.990048, 116.267166 39.989857)')
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w7' AND nb.source_ref='yiheyuan-demo:node:w16';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref, geometry)
    SELECT na.id, nb.id, 619.5, 'walk', 516, 6.19, 2, 'osm', 'yiheyuan-demo:edge', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.267166 39.989857, 116.267300 39.990048, 116.267374 39.990187, 116.267396 39.990234, 116.267543 39.990573, 116.267687 39.990951, 116.267721 39.991089, 116.267760 39.991506, 116.267826 39.991710, 116.267964 39.991940, 116.268199 39.992326, 116.267626 39.992687, 116.267062 39.992999, 116.266897 39.993138, 116.266901 39.993142, 116.267049 39.993333, 116.267300 39.993698, 116.267357 39.993815, 116.267552 39.994484, 116.267569 39.994592, 116.267561 39.994709)')
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w16' AND nb.source_ref='yiheyuan-demo:node:w7';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref, geometry)
    SELECT na.id, nb.id, 2294.6, 'walk', 1912, 22.95, 2, 'osm', 'yiheyuan-demo:edge', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.276089 39.990894, 116.276115 39.990911, 116.276124 39.991076, 116.276137 39.991081, 116.276250 39.991081, 116.276580 39.991059, 116.276680 39.991029, 116.276675 39.991024, 116.277847 39.990642, 116.278333 39.990503, 116.278333 39.990499, 116.278537 39.990234, 116.278650 39.990087, 116.278650 39.990082, 116.278620 39.989861, 116.278355 39.988993, 116.278220 39.988451, 116.278069 39.987604, 116.277734 39.986094, 116.277622 39.985812, 116.277483 39.985569, 116.277439 39.985438, 116.277448 39.985278, 116.277470 39.985152, 116.277539 39.984983, 116.277622 39.984883, 116.277791 39.984727, 116.278229 39.984262, 116.278663 39.983746, 116.279071 39.983220, 116.279293 39.982886, 116.279670 39.982339, 116.280013 39.981714, 116.280074 39.981571, 116.280082 39.981545, 116.280082 39.981541, 116.279861 39.981428, 116.279557 39.981398, 116.279553 39.981393, 116.279340 39.981332, 116.279076 39.981337, 116.278576 39.981345, 116.277665 39.981432, 116.277661 39.981432, 116.277517 39.981597, 116.277283 39.981879, 116.277144 39.982049, 116.276745 39.982370, 116.276740 39.982370, 116.276437 39.982426, 116.276215 39.982457, 116.276146 39.982465, 116.275760 39.982500, 116.275612 39.982487, 116.275547 39.982487, 116.275486 39.982491, 116.275378 39.982517, 116.275065 39.982539, 116.275004 39.982522, 116.274852 39.982496, 116.274809 39.982496, 116.274670 39.982496, 116.274062 39.982622, 116.274058 39.982622, 116.274032 39.982704, 116.273954 39.982899, 116.273767 39.983264, 116.273689 39.983424, 116.273672 39.983503, 116.273672 39.983832, 116.273676 39.984227, 116.273720 39.984627, 116.273798 39.984965, 116.273872 39.985174, 116.273889 39.985282, 116.273906 39.985447, 116.273889 39.985595, 116.273863 39.985807, 116.273859 39.985807, 116.273793 39.985807, 116.273772 39.985807, 116.273746 39.985820, 116.273737 39.985838, 116.273707 39.986046, 116.273676 39.986259, 116.273672 39.986280)')
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w13' AND nb.source_ref='yiheyuan-demo:node:w17';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref, geometry)
    SELECT na.id, nb.id, 2294.6, 'walk', 1912, 22.95, 2, 'osm', 'yiheyuan-demo:edge', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.273672 39.986280, 116.273676 39.986259, 116.273707 39.986046, 116.273737 39.985838, 116.273746 39.985820, 116.273772 39.985807, 116.273793 39.985807, 116.273859 39.985807, 116.273863 39.985807, 116.273889 39.985595, 116.273906 39.985447, 116.273889 39.985282, 116.273872 39.985174, 116.273798 39.984965, 116.273720 39.984627, 116.273676 39.984227, 116.273672 39.983832, 116.273672 39.983503, 116.273689 39.983424, 116.273767 39.983264, 116.273954 39.982899, 116.274032 39.982704, 116.274058 39.982622, 116.274062 39.982622, 116.274670 39.982496, 116.274809 39.982496, 116.274852 39.982496, 116.275004 39.982522, 116.275065 39.982539, 116.275378 39.982517, 116.275486 39.982491, 116.275547 39.982487, 116.275612 39.982487, 116.275760 39.982500, 116.276146 39.982465, 116.276215 39.982457, 116.276437 39.982426, 116.276740 39.982370, 116.276745 39.982370, 116.277144 39.982049, 116.277283 39.981879, 116.277517 39.981597, 116.277661 39.981432, 116.277665 39.981432, 116.278576 39.981345, 116.279076 39.981337, 116.279340 39.981332, 116.279553 39.981393, 116.279557 39.981398, 116.279861 39.981428, 116.280082 39.981541, 116.280082 39.981545, 116.280074 39.981571, 116.280013 39.981714, 116.279670 39.982339, 116.279293 39.982886, 116.279071 39.983220, 116.278663 39.983746, 116.278229 39.984262, 116.277791 39.984727, 116.277622 39.984883, 116.277539 39.984983, 116.277470 39.985152, 116.277448 39.985278, 116.277439 39.985438, 116.277483 39.985569, 116.277622 39.985812, 116.277734 39.986094, 116.278069 39.987604, 116.278220 39.988451, 116.278355 39.988993, 116.278620 39.989861, 116.278650 39.990082, 116.278650 39.990087, 116.278537 39.990234, 116.278333 39.990499, 116.278333 39.990503, 116.277847 39.990642, 116.276675 39.991024, 116.276680 39.991029, 116.276580 39.991059, 116.276250 39.991081, 116.276137 39.991081, 116.276124 39.991076, 116.276115 39.990911, 116.276089 39.990894)')
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w17' AND nb.source_ref='yiheyuan-demo:node:w13';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref, geometry)
    SELECT na.id, nb.id, 110.8, 'walk', 92, 1.11, 2, 'osm', 'yiheyuan-demo:edge', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.273668 39.986280, 116.273672 39.986263, 116.273702 39.986050, 116.273733 39.985842, 116.273741 39.985825, 116.273767 39.985812, 116.273789 39.985807, 116.273859 39.985807, 116.273885 39.985599, 116.273906 39.985451, 116.273902 39.985365)')
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w17' AND nb.source_ref='yiheyuan-demo:node:e_xin';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref, geometry)
    SELECT na.id, nb.id, 110.8, 'walk', 92, 1.11, 2, 'osm', 'yiheyuan-demo:edge', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.273902 39.985365, 116.273906 39.985451, 116.273885 39.985599, 116.273859 39.985807, 116.273789 39.985807, 116.273767 39.985812, 116.273741 39.985825, 116.273733 39.985842, 116.273702 39.986050, 116.273672 39.986263, 116.273668 39.986280)')
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:e_xin' AND nb.source_ref='yiheyuan-demo:node:w17';

    -- 5b. 电瓶车线（双向，travel_mode='shuttle'，速度快、拥挤度低，验收 4c）
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref, geometry)
    SELECT na.id, nb.id, 112.7, 'shuttle', 22, 1.13, 1, 'osm', 'yiheyuan-demo:shuttle', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.276641 39.991606, 116.276589 39.991697, 116.276432 39.991784, 116.276150 39.991862, 116.276098 39.991875, 116.275981 39.991875, 116.275885 39.991875, 116.275742 39.991858, 116.275595 39.991823, 116.275477 39.991771)')
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:e_dong' AND nb.source_ref='yiheyuan-demo:node:w5';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref, geometry)
    SELECT na.id, nb.id, 112.7, 'shuttle', 22, 1.13, 1, 'osm', 'yiheyuan-demo:shuttle', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.275477 39.991771, 116.275595 39.991823, 116.275742 39.991858, 116.275885 39.991875, 116.275981 39.991875, 116.276098 39.991875, 116.276150 39.991862, 116.276432 39.991784, 116.276589 39.991697, 116.276641 39.991606)')
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w5' AND nb.source_ref='yiheyuan-demo:node:e_dong';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref, geometry)
    SELECT na.id, nb.id, 3366.8, 'shuttle', 673, 33.67, 1, 'osm', 'yiheyuan-demo:shuttle', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.275473 39.991766, 116.275590 39.991819, 116.275738 39.991853, 116.275881 39.991875, 116.275977 39.991875, 116.276094 39.991875, 116.276146 39.991866, 116.276428 39.991788, 116.276584 39.991701, 116.276667 39.991576, 116.276680 39.991536, 116.276680 39.991502, 116.276667 39.991432, 116.276602 39.991250, 116.276584 39.991059, 116.276580 39.991055, 116.276680 39.991029, 116.276675 39.991024, 116.277847 39.990642, 116.278333 39.990503, 116.278333 39.990499, 116.278676 39.990477, 116.279058 39.990425, 116.279058 39.990421, 116.279293 39.990556, 116.279375 39.990595, 116.279583 39.990751, 116.279631 39.990799, 116.279692 39.990920, 116.279766 39.991137, 116.279896 39.991480, 116.280148 39.991827, 116.280278 39.992148, 116.280360 39.992921, 116.280516 39.993832, 116.280495 39.994310, 116.280421 39.995022, 116.280408 39.995139, 116.280382 39.995447, 116.280373 39.995573, 116.280330 39.995924, 116.280039 39.996458, 116.279887 39.996788, 116.279887 39.996784, 116.279787 39.996884, 116.279705 39.996970, 116.279644 39.997014, 116.279562 39.997096, 116.279488 39.997144, 116.279401 39.997192, 116.279332 39.997253, 116.279240 39.997357, 116.279206 39.997405, 116.279141 39.997517, 116.279097 39.997656, 116.279019 39.998294, 116.278997 39.998403, 116.278993 39.998403, 116.278945 39.998403, 116.278824 39.998403, 116.278685 39.998403, 116.278615 39.998398, 116.278268 39.998355, 116.278142 39.998338, 116.278025 39.998329, 116.277947 39.998329, 116.277925 39.998333, 116.277917 39.998351, 116.277908 39.998433, 116.277904 39.998433, 116.277565 39.998407, 116.276953 39.998359, 116.276519 39.998320, 116.275920 39.998260, 116.275747 39.998234, 116.275464 39.998168, 116.274727 39.997652, 116.274653 39.997617, 116.274262 39.997591, 116.274167 39.997578, 116.273746 39.997543, 116.273424 39.997543, 116.272947 39.997704, 116.272669 39.997821, 116.272582 39.997843, 116.272448 39.997852, 116.271059 39.997721, 116.270135 39.997635, 116.270130 39.997630, 116.270095 39.997652, 116.270074 39.997678, 116.270039 39.997969, 116.270004 39.998207, 116.269974 39.998290, 116.269944 39.998316, 116.269766 39.998455, 116.269540 39.998767, 116.269444 39.998997, 116.269414 39.999106, 116.269397 39.999201, 116.269397 39.999470, 116.269392 39.999648, 116.269362 39.999944, 116.269314 40.000256, 116.269219 40.000707, 116.269193 40.000751, 116.269188 40.000751, 116.268737 40.000720, 116.268733 40.000716, 116.268220 40.000937, 116.267960 40.000968, 116.267630 40.000955, 116.267626 40.000951, 116.267713 40.000547, 116.267786 40.000200, 116.267817 40.000122, 116.267856 40.000030, 116.268051 39.999748, 116.268060 39.999544, 116.268016 39.999297, 116.267951 39.999136, 116.267726 39.998776, 116.267535 39.998242, 116.267452 39.997938, 116.267504 39.997144, 116.267556 39.996749, 116.267569 39.996519, 116.267535 39.996385, 116.267552 39.996259, 116.267569 39.995699, 116.267543 39.995365, 116.267543 39.995030, 116.267561 39.994714)')
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w5' AND nb.source_ref='yiheyuan-demo:node:w7';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref, geometry)
    SELECT na.id, nb.id, 3366.8, 'shuttle', 673, 33.67, 1, 'osm', 'yiheyuan-demo:shuttle', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.267561 39.994714, 116.267543 39.995030, 116.267543 39.995365, 116.267569 39.995699, 116.267552 39.996259, 116.267535 39.996385, 116.267569 39.996519, 116.267556 39.996749, 116.267504 39.997144, 116.267452 39.997938, 116.267535 39.998242, 116.267726 39.998776, 116.267951 39.999136, 116.268016 39.999297, 116.268060 39.999544, 116.268051 39.999748, 116.267856 40.000030, 116.267817 40.000122, 116.267786 40.000200, 116.267713 40.000547, 116.267626 40.000951, 116.267630 40.000955, 116.267960 40.000968, 116.268220 40.000937, 116.268733 40.000716, 116.268737 40.000720, 116.269188 40.000751, 116.269193 40.000751, 116.269219 40.000707, 116.269314 40.000256, 116.269362 39.999944, 116.269392 39.999648, 116.269397 39.999470, 116.269397 39.999201, 116.269414 39.999106, 116.269444 39.998997, 116.269540 39.998767, 116.269766 39.998455, 116.269944 39.998316, 116.269974 39.998290, 116.270004 39.998207, 116.270039 39.997969, 116.270074 39.997678, 116.270095 39.997652, 116.270130 39.997630, 116.270135 39.997635, 116.271059 39.997721, 116.272448 39.997852, 116.272582 39.997843, 116.272669 39.997821, 116.272947 39.997704, 116.273424 39.997543, 116.273746 39.997543, 116.274167 39.997578, 116.274262 39.997591, 116.274653 39.997617, 116.274727 39.997652, 116.275464 39.998168, 116.275747 39.998234, 116.275920 39.998260, 116.276519 39.998320, 116.276953 39.998359, 116.277565 39.998407, 116.277904 39.998433, 116.277908 39.998433, 116.277917 39.998351, 116.277925 39.998333, 116.277947 39.998329, 116.278025 39.998329, 116.278142 39.998338, 116.278268 39.998355, 116.278615 39.998398, 116.278685 39.998403, 116.278824 39.998403, 116.278945 39.998403, 116.278993 39.998403, 116.278997 39.998403, 116.279019 39.998294, 116.279097 39.997656, 116.279141 39.997517, 116.279206 39.997405, 116.279240 39.997357, 116.279332 39.997253, 116.279401 39.997192, 116.279488 39.997144, 116.279562 39.997096, 116.279644 39.997014, 116.279705 39.996970, 116.279787 39.996884, 116.279887 39.996784, 116.279887 39.996788, 116.280039 39.996458, 116.280330 39.995924, 116.280373 39.995573, 116.280382 39.995447, 116.280408 39.995139, 116.280421 39.995022, 116.280495 39.994310, 116.280516 39.993832, 116.280360 39.992921, 116.280278 39.992148, 116.280148 39.991827, 116.279896 39.991480, 116.279766 39.991137, 116.279692 39.990920, 116.279631 39.990799, 116.279583 39.990751, 116.279375 39.990595, 116.279293 39.990556, 116.279058 39.990421, 116.279058 39.990425, 116.278676 39.990477, 116.278333 39.990499, 116.278333 39.990503, 116.277847 39.990642, 116.276675 39.991024, 116.276680 39.991029, 116.276580 39.991055, 116.276584 39.991059, 116.276602 39.991250, 116.276667 39.991432, 116.276680 39.991502, 116.276680 39.991536, 116.276667 39.991576, 116.276584 39.991701, 116.276428 39.991788, 116.276146 39.991866, 116.276094 39.991875, 116.275977 39.991875, 116.275881 39.991875, 116.275738 39.991853, 116.275590 39.991819, 116.275473 39.991766)')
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w7' AND nb.source_ref='yiheyuan-demo:node:w5';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref, geometry)
    SELECT na.id, nb.id, 13.0, 'shuttle', 2, 0.13, 1, 'osm', 'yiheyuan-demo:shuttle', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.267561 39.994709, 116.267569 39.994592)')
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w7' AND nb.source_ref='yiheyuan-demo:node:w8';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref, geometry)
    SELECT na.id, nb.id, 13.0, 'shuttle', 2, 0.13, 1, 'osm', 'yiheyuan-demo:shuttle', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.267569 39.994592, 116.267561 39.994709)')
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w8' AND nb.source_ref='yiheyuan-demo:node:w7';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref, geometry)
    SELECT na.id, nb.id, 1347.3, 'shuttle', 269, 13.47, 1, 'osm', 'yiheyuan-demo:shuttle', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.267569 39.994588, 116.267543 39.995026, 116.267543 39.995360, 116.267569 39.995694, 116.267556 39.996254, 116.267535 39.996380, 116.267569 39.996515, 116.267561 39.996745, 116.267509 39.997140, 116.267452 39.997934, 116.267530 39.998238, 116.267721 39.998772, 116.267947 39.999132, 116.268012 39.999293, 116.268060 39.999540, 116.268056 39.999744, 116.267860 40.000026, 116.267821 40.000117, 116.267791 40.000195, 116.267717 40.000543, 116.267630 40.000951, 116.267626 40.000951, 116.267956 40.000968, 116.268216 40.000942, 116.268733 40.000720, 116.268733 40.000716, 116.269188 40.000751, 116.269214 40.000712, 116.269310 40.000260, 116.269358 39.999948, 116.269388 39.999653, 116.269392 39.999475, 116.269392 39.999206, 116.269410 39.999110, 116.269440 39.999002, 116.269536 39.998772, 116.269761 39.998459, 116.269939 39.998320, 116.269970 39.998294, 116.270000 39.998212, 116.270035 39.997973, 116.270069 39.997682, 116.270091 39.997656, 116.270130 39.997635, 116.270130 39.997630, 116.271055 39.997717, 116.271536 39.997760)')
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w8' AND nb.source_ref='yiheyuan-demo:node:w10';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref, geometry)
    SELECT na.id, nb.id, 1347.3, 'shuttle', 269, 13.47, 1, 'osm', 'yiheyuan-demo:shuttle', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.271536 39.997760, 116.271055 39.997717, 116.270130 39.997630, 116.270130 39.997635, 116.270091 39.997656, 116.270069 39.997682, 116.270035 39.997973, 116.270000 39.998212, 116.269970 39.998294, 116.269939 39.998320, 116.269761 39.998459, 116.269536 39.998772, 116.269440 39.999002, 116.269410 39.999110, 116.269392 39.999206, 116.269392 39.999475, 116.269388 39.999653, 116.269358 39.999948, 116.269310 40.000260, 116.269214 40.000712, 116.269188 40.000751, 116.268733 40.000716, 116.268733 40.000720, 116.268216 40.000942, 116.267956 40.000968, 116.267626 40.000951, 116.267630 40.000951, 116.267717 40.000543, 116.267791 40.000195, 116.267821 40.000117, 116.267860 40.000026, 116.268056 39.999744, 116.268060 39.999540, 116.268012 39.999293, 116.267947 39.999132, 116.267721 39.998772, 116.267530 39.998238, 116.267452 39.997934, 116.267509 39.997140, 116.267561 39.996745, 116.267569 39.996515, 116.267535 39.996380, 116.267556 39.996254, 116.267569 39.995694, 116.267543 39.995360, 116.267543 39.995026, 116.267569 39.994588)')
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w10' AND nb.source_ref='yiheyuan-demo:node:w8';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref, geometry)
    SELECT na.id, nb.id, 178.4, 'shuttle', 35, 1.78, 1, 'osm', 'yiheyuan-demo:shuttle', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.271536 39.997760, 116.272444 39.997852, 116.272444 39.997847, 116.272448 39.997925, 116.272448 39.997977, 116.272287 39.997977, 116.272044 39.997964, 116.272010 39.997960, 116.272005 39.997956, 116.271970 39.998064, 116.271918 39.998203, 116.271879 39.998247, 116.271836 39.998255, 116.271771 39.998325)')
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w10' AND nb.source_ref='yiheyuan-demo:node:e_bei';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref, geometry)
    SELECT na.id, nb.id, 178.4, 'shuttle', 35, 1.78, 1, 'osm', 'yiheyuan-demo:shuttle', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.271771 39.998325, 116.271836 39.998255, 116.271879 39.998247, 116.271918 39.998203, 116.271970 39.998064, 116.272005 39.997956, 116.272010 39.997960, 116.272044 39.997964, 116.272287 39.997977, 116.272448 39.997977, 116.272448 39.997925, 116.272444 39.997847, 116.272444 39.997852, 116.271536 39.997760)')
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:e_bei' AND nb.source_ref='yiheyuan-demo:node:w10';

    -- 6. 设施接入边（双向，source='generated' 表示接入连接边）
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 18.0, 'walk', 15, 0.18, 2, 'generated', 'yiheyuan-demo:connector'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:facnode:0' AND nb.source_ref='yiheyuan-demo:node:w1';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 18.0, 'walk', 15, 0.18, 2, 'generated', 'yiheyuan-demo:connector'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w1' AND nb.source_ref='yiheyuan-demo:facnode:0';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 18.0, 'walk', 15, 0.18, 2, 'generated', 'yiheyuan-demo:connector'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:facnode:1' AND nb.source_ref='yiheyuan-demo:node:w2';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 18.0, 'walk', 15, 0.18, 2, 'generated', 'yiheyuan-demo:connector'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w2' AND nb.source_ref='yiheyuan-demo:facnode:1';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 18.0, 'walk', 15, 0.18, 2, 'generated', 'yiheyuan-demo:connector'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:facnode:2' AND nb.source_ref='yiheyuan-demo:node:w4';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 18.0, 'walk', 15, 0.18, 2, 'generated', 'yiheyuan-demo:connector'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w4' AND nb.source_ref='yiheyuan-demo:facnode:2';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 18.0, 'walk', 15, 0.18, 2, 'generated', 'yiheyuan-demo:connector'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:facnode:3' AND nb.source_ref='yiheyuan-demo:node:w5';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 18.0, 'walk', 15, 0.18, 2, 'generated', 'yiheyuan-demo:connector'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w5' AND nb.source_ref='yiheyuan-demo:facnode:3';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 18.0, 'walk', 15, 0.18, 2, 'generated', 'yiheyuan-demo:connector'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:facnode:4' AND nb.source_ref='yiheyuan-demo:node:w6';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 18.0, 'walk', 15, 0.18, 2, 'generated', 'yiheyuan-demo:connector'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w6' AND nb.source_ref='yiheyuan-demo:facnode:4';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 18.0, 'walk', 15, 0.18, 2, 'generated', 'yiheyuan-demo:connector'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:facnode:5' AND nb.source_ref='yiheyuan-demo:node:w7';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 18.0, 'walk', 15, 0.18, 2, 'generated', 'yiheyuan-demo:connector'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w7' AND nb.source_ref='yiheyuan-demo:facnode:5';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 18.0, 'walk', 15, 0.18, 2, 'generated', 'yiheyuan-demo:connector'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:facnode:6' AND nb.source_ref='yiheyuan-demo:node:w8';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 18.0, 'walk', 15, 0.18, 2, 'generated', 'yiheyuan-demo:connector'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w8' AND nb.source_ref='yiheyuan-demo:facnode:6';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 18.0, 'walk', 15, 0.18, 2, 'generated', 'yiheyuan-demo:connector'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:facnode:7' AND nb.source_ref='yiheyuan-demo:node:w9';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 18.0, 'walk', 15, 0.18, 2, 'generated', 'yiheyuan-demo:connector'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w9' AND nb.source_ref='yiheyuan-demo:facnode:7';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 18.0, 'walk', 15, 0.18, 2, 'generated', 'yiheyuan-demo:connector'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:facnode:8' AND nb.source_ref='yiheyuan-demo:node:w10';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 18.0, 'walk', 15, 0.18, 2, 'generated', 'yiheyuan-demo:connector'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w10' AND nb.source_ref='yiheyuan-demo:facnode:8';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 18.0, 'walk', 15, 0.18, 2, 'generated', 'yiheyuan-demo:connector'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:facnode:9' AND nb.source_ref='yiheyuan-demo:node:w10';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 18.0, 'walk', 15, 0.18, 2, 'generated', 'yiheyuan-demo:connector'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w10' AND nb.source_ref='yiheyuan-demo:facnode:9';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 18.0, 'walk', 15, 0.18, 2, 'generated', 'yiheyuan-demo:connector'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:facnode:10' AND nb.source_ref='yiheyuan-demo:node:w12';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 18.0, 'walk', 15, 0.18, 2, 'generated', 'yiheyuan-demo:connector'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w12' AND nb.source_ref='yiheyuan-demo:facnode:10';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 18.0, 'walk', 15, 0.18, 2, 'generated', 'yiheyuan-demo:connector'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:facnode:11' AND nb.source_ref='yiheyuan-demo:node:w13';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 18.0, 'walk', 15, 0.18, 2, 'generated', 'yiheyuan-demo:connector'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w13' AND nb.source_ref='yiheyuan-demo:facnode:11';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 18.0, 'walk', 15, 0.18, 2, 'generated', 'yiheyuan-demo:connector'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:facnode:12' AND nb.source_ref='yiheyuan-demo:node:w14';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 18.0, 'walk', 15, 0.18, 2, 'generated', 'yiheyuan-demo:connector'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w14' AND nb.source_ref='yiheyuan-demo:facnode:12';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 18.0, 'walk', 15, 0.18, 2, 'generated', 'yiheyuan-demo:connector'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:facnode:13' AND nb.source_ref='yiheyuan-demo:node:w16';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 18.0, 'walk', 15, 0.18, 2, 'generated', 'yiheyuan-demo:connector'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w16' AND nb.source_ref='yiheyuan-demo:facnode:13';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 18.0, 'walk', 15, 0.18, 2, 'generated', 'yiheyuan-demo:connector'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:facnode:14' AND nb.source_ref='yiheyuan-demo:node:w17';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 18.0, 'walk', 15, 0.18, 2, 'generated', 'yiheyuan-demo:connector'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w17' AND nb.source_ref='yiheyuan-demo:facnode:14';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 18.0, 'walk', 15, 0.18, 2, 'generated', 'yiheyuan-demo:connector'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:facnode:15' AND nb.source_ref='yiheyuan-demo:node:w11';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 18.0, 'walk', 15, 0.18, 2, 'generated', 'yiheyuan-demo:connector'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w11' AND nb.source_ref='yiheyuan-demo:facnode:15';

    RAISE NOTICE '颐和园演示图已重建: % 路网节点, % 设施', 20, 16;
END $$;

COMMIT;
