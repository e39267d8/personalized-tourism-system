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
    SELECT na.id, nb.id, 206.8, 'walk', 172, 2.07, 2, 'osm', 'yiheyuan-demo:edge', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.272700 39.993400, 116.270300 39.993700)')
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w5' AND nb.source_ref='yiheyuan-demo:node:w6';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref, geometry)
    SELECT na.id, nb.id, 206.8, 'walk', 172, 2.07, 2, 'osm', 'yiheyuan-demo:edge', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.270300 39.993700, 116.272700 39.993400)')
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w6' AND nb.source_ref='yiheyuan-demo:node:w5';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref, geometry)
    SELECT na.id, nb.id, 338.8, 'walk', 282, 3.39, 2, 'osm', 'yiheyuan-demo:edge', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.268273 39.992261, 116.268203 39.992326, 116.267630 39.992682, 116.267066 39.992995, 116.266901 39.993138, 116.266897 39.993138, 116.267044 39.993329, 116.267296 39.993694, 116.267352 39.993811, 116.267548 39.994479, 116.267569 39.994588, 116.267565 39.994709)')
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w6' AND nb.source_ref='yiheyuan-demo:node:w7';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref, geometry)
    SELECT na.id, nb.id, 338.8, 'walk', 282, 3.39, 2, 'osm', 'yiheyuan-demo:edge', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.267565 39.994709, 116.267569 39.994588, 116.267548 39.994479, 116.267352 39.993811, 116.267296 39.993694, 116.267044 39.993329, 116.266897 39.993138, 116.266901 39.993138, 116.267066 39.992995, 116.267630 39.992682, 116.268203 39.992326, 116.268273 39.992261)')
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w7' AND nb.source_ref='yiheyuan-demo:node:w6';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref, geometry)
    SELECT na.id, nb.id, 101.3, 'walk', 84, 1.01, 2, 'osm', 'yiheyuan-demo:edge', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.270300 39.993700, 116.270500 39.994600)')
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w6' AND nb.source_ref='yiheyuan-demo:node:w8';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref, geometry)
    SELECT na.id, nb.id, 101.3, 'walk', 84, 1.01, 2, 'osm', 'yiheyuan-demo:edge', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.270500 39.994600, 116.270300 39.993700)')
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w8' AND nb.source_ref='yiheyuan-demo:node:w6';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref, geometry)
    SELECT na.id, nb.id, 180.8, 'walk', 150, 1.81, 2, 'osm', 'yiheyuan-demo:edge', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.270500 39.994600, 116.270900 39.996200)')
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w8' AND nb.source_ref='yiheyuan-demo:node:w9';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref, geometry)
    SELECT na.id, nb.id, 180.8, 'walk', 150, 1.81, 2, 'osm', 'yiheyuan-demo:edge', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.270900 39.996200, 116.270500 39.994600)')
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
    SELECT na.id, nb.id, 115.2, 'walk', 95, 1.15, 2, 'osm', 'yiheyuan-demo:edge', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.274600 39.990600, 116.275600 39.989900)')
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w11' AND nb.source_ref='yiheyuan-demo:node:w15';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref, geometry)
    SELECT na.id, nb.id, 115.2, 'walk', 95, 1.15, 2, 'osm', 'yiheyuan-demo:edge', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.275600 39.989900, 116.274600 39.990600)')
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w15' AND nb.source_ref='yiheyuan-demo:node:w11';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref, geometry)
    SELECT na.id, nb.id, 126.0, 'walk', 104, 1.26, 2, 'osm', 'yiheyuan-demo:edge', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.275599 39.989896, 116.275204 39.988802)')
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w15' AND nb.source_ref='yiheyuan-demo:node:w13';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref, geometry)
    SELECT na.id, nb.id, 126.0, 'walk', 104, 1.26, 2, 'osm', 'yiheyuan-demo:edge', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.275204 39.988802, 116.275599 39.989896)')
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w13' AND nb.source_ref='yiheyuan-demo:node:w15';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref, geometry)
    SELECT na.id, nb.id, 139.1, 'walk', 115, 1.39, 2, 'osm', 'yiheyuan-demo:edge', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.275200 39.988800, 116.273700 39.988300)')
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w13' AND nb.source_ref='yiheyuan-demo:node:w14';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref, geometry)
    SELECT na.id, nb.id, 139.1, 'walk', 115, 1.39, 2, 'osm', 'yiheyuan-demo:edge', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.273700 39.988300, 116.275200 39.988800)')
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w14' AND nb.source_ref='yiheyuan-demo:node:w13';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref, geometry)
    SELECT na.id, nb.id, 619.5, 'walk', 516, 6.19, 2, 'osm', 'yiheyuan-demo:edge', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.267561 39.994709, 116.267569 39.994592, 116.267552 39.994484, 116.267357 39.993815, 116.267300 39.993698, 116.267049 39.993333, 116.266901 39.993142, 116.266897 39.993138, 116.267062 39.992999, 116.267626 39.992687, 116.268199 39.992326, 116.267964 39.991940, 116.267826 39.991710, 116.267760 39.991506, 116.267721 39.991089, 116.267687 39.990951, 116.267543 39.990573, 116.267396 39.990234, 116.267374 39.990187, 116.267300 39.990048, 116.267166 39.989857)')
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w7' AND nb.source_ref='yiheyuan-demo:node:w16';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref, geometry)
    SELECT na.id, nb.id, 619.5, 'walk', 516, 6.19, 2, 'osm', 'yiheyuan-demo:edge', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.267166 39.989857, 116.267300 39.990048, 116.267374 39.990187, 116.267396 39.990234, 116.267543 39.990573, 116.267687 39.990951, 116.267721 39.991089, 116.267760 39.991506, 116.267826 39.991710, 116.267964 39.991940, 116.268199 39.992326, 116.267626 39.992687, 116.267062 39.992999, 116.266897 39.993138, 116.266901 39.993142, 116.267049 39.993333, 116.267300 39.993698, 116.267357 39.993815, 116.267552 39.994484, 116.267569 39.994592, 116.267561 39.994709)')
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w16' AND nb.source_ref='yiheyuan-demo:node:w7';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref, geometry)
    SELECT na.id, nb.id, 343.9, 'walk', 286, 3.44, 2, 'osm', 'yiheyuan-demo:edge', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.275200 39.988800, 116.273000 39.986200)')
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w13' AND nb.source_ref='yiheyuan-demo:node:w17';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref, geometry)
    SELECT na.id, nb.id, 343.9, 'walk', 286, 3.44, 2, 'osm', 'yiheyuan-demo:edge', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.273000 39.986200, 116.275200 39.988800)')
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w17' AND nb.source_ref='yiheyuan-demo:node:w13';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref, geometry)
    SELECT na.id, nb.id, 110.8, 'walk', 92, 1.11, 2, 'osm', 'yiheyuan-demo:edge', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.273668 39.986280, 116.273672 39.986263, 116.273702 39.986050, 116.273733 39.985842, 116.273741 39.985825, 116.273767 39.985812, 116.273789 39.985807, 116.273859 39.985807, 116.273885 39.985599, 116.273906 39.985451, 116.273902 39.985365)')
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w17' AND nb.source_ref='yiheyuan-demo:node:e_xin';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref, geometry)
    SELECT na.id, nb.id, 110.8, 'walk', 92, 1.11, 2, 'osm', 'yiheyuan-demo:edge', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.273902 39.985365, 116.273906 39.985451, 116.273885 39.985599, 116.273859 39.985807, 116.273789 39.985807, 116.273767 39.985812, 116.273741 39.985825, 116.273733 39.985842, 116.273702 39.986050, 116.273672 39.986263, 116.273668 39.986280)')
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:e_xin' AND nb.source_ref='yiheyuan-demo:node:w17';

    -- 5a. 自行车道（双向，与步行同几何，速度更快，验收 4c）
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref, geometry)
    SELECT na.id, nb.id, 27.5, 'bike', 6, 0.28, 2, 'osm', 'yiheyuan-demo:bike', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.276641 39.991606, 116.276589 39.991697, 116.276432 39.991784)')
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:e_dong' AND nb.source_ref='yiheyuan-demo:node:w1';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref, geometry)
    SELECT na.id, nb.id, 27.5, 'bike', 6, 0.28, 2, 'osm', 'yiheyuan-demo:bike', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.276432 39.991784, 116.276589 39.991697, 116.276641 39.991606)')
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w1' AND nb.source_ref='yiheyuan-demo:node:e_dong';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref, geometry)
    SELECT na.id, nb.id, 45.7, 'bike', 11, 0.46, 2, 'osm', 'yiheyuan-demo:bike', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.276428 39.991784, 116.276150 39.991862, 116.276098 39.991875, 116.275981 39.991875, 116.275911 39.991875)')
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w1' AND nb.source_ref='yiheyuan-demo:node:w2';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref, geometry)
    SELECT na.id, nb.id, 45.7, 'bike', 11, 0.46, 2, 'osm', 'yiheyuan-demo:bike', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.275911 39.991875, 116.275981 39.991875, 116.276098 39.991875, 116.276150 39.991862, 116.276428 39.991784)')
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w2' AND nb.source_ref='yiheyuan-demo:node:w1';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref, geometry)
    SELECT na.id, nb.id, 27.3, 'bike', 6, 0.27, 2, 'osm', 'yiheyuan-demo:bike', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.275907 39.991875, 116.275885 39.991875, 116.275742 39.991858, 116.275595 39.991823)')
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w2' AND nb.source_ref='yiheyuan-demo:node:w3';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref, geometry)
    SELECT na.id, nb.id, 27.3, 'bike', 6, 0.27, 2, 'osm', 'yiheyuan-demo:bike', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.275595 39.991823, 116.275742 39.991858, 116.275885 39.991875, 116.275907 39.991875)')
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w3' AND nb.source_ref='yiheyuan-demo:node:w2';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref, geometry)
    SELECT na.id, nb.id, 11.0, 'bike', 2, 0.11, 2, 'osm', 'yiheyuan-demo:bike', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.275590 39.991819, 116.275477 39.991771)')
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w3' AND nb.source_ref='yiheyuan-demo:node:w4';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref, geometry)
    SELECT na.id, nb.id, 11.0, 'bike', 2, 0.11, 2, 'osm', 'yiheyuan-demo:bike', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.275477 39.991771, 116.275590 39.991819)')
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w4' AND nb.source_ref='yiheyuan-demo:node:w3';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref, geometry)
    SELECT na.id, nb.id, 114.8, 'bike', 28, 1.15, 2, 'osm', 'yiheyuan-demo:bike', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.273997 39.993099, 116.272704 39.993398)')
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w4' AND nb.source_ref='yiheyuan-demo:node:w5';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref, geometry)
    SELECT na.id, nb.id, 114.8, 'bike', 28, 1.15, 2, 'osm', 'yiheyuan-demo:bike', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.272704 39.993398, 116.273997 39.993099)')
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w5' AND nb.source_ref='yiheyuan-demo:node:w4';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref, geometry)
    SELECT na.id, nb.id, 206.8, 'bike', 51, 2.07, 2, 'osm', 'yiheyuan-demo:bike', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.272700 39.993400, 116.270300 39.993700)')
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w5' AND nb.source_ref='yiheyuan-demo:node:w6';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref, geometry)
    SELECT na.id, nb.id, 206.8, 'bike', 51, 2.07, 2, 'osm', 'yiheyuan-demo:bike', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.270300 39.993700, 116.272700 39.993400)')
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w6' AND nb.source_ref='yiheyuan-demo:node:w5';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref, geometry)
    SELECT na.id, nb.id, 338.8, 'bike', 84, 3.39, 2, 'osm', 'yiheyuan-demo:bike', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.268273 39.992261, 116.268203 39.992326, 116.267630 39.992682, 116.267066 39.992995, 116.266901 39.993138, 116.266897 39.993138, 116.267044 39.993329, 116.267296 39.993694, 116.267352 39.993811, 116.267548 39.994479, 116.267569 39.994588, 116.267565 39.994709)')
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w6' AND nb.source_ref='yiheyuan-demo:node:w7';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref, geometry)
    SELECT na.id, nb.id, 338.8, 'bike', 84, 3.39, 2, 'osm', 'yiheyuan-demo:bike', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.267565 39.994709, 116.267569 39.994588, 116.267548 39.994479, 116.267352 39.993811, 116.267296 39.993694, 116.267044 39.993329, 116.266897 39.993138, 116.266901 39.993138, 116.267066 39.992995, 116.267630 39.992682, 116.268203 39.992326, 116.268273 39.992261)')
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w7' AND nb.source_ref='yiheyuan-demo:node:w6';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref, geometry)
    SELECT na.id, nb.id, 101.3, 'bike', 25, 1.01, 2, 'osm', 'yiheyuan-demo:bike', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.270300 39.993700, 116.270500 39.994600)')
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w6' AND nb.source_ref='yiheyuan-demo:node:w8';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref, geometry)
    SELECT na.id, nb.id, 101.3, 'bike', 25, 1.01, 2, 'osm', 'yiheyuan-demo:bike', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.270500 39.994600, 116.270300 39.993700)')
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w8' AND nb.source_ref='yiheyuan-demo:node:w6';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref, geometry)
    SELECT na.id, nb.id, 180.8, 'bike', 45, 1.81, 2, 'osm', 'yiheyuan-demo:bike', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.270500 39.994600, 116.270900 39.996200)')
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w8' AND nb.source_ref='yiheyuan-demo:node:w9';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref, geometry)
    SELECT na.id, nb.id, 180.8, 'bike', 45, 1.81, 2, 'osm', 'yiheyuan-demo:bike', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.270900 39.996200, 116.270500 39.994600)')
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w9' AND nb.source_ref='yiheyuan-demo:node:w8';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref, geometry)
    SELECT na.id, nb.id, 74.7, 'bike', 18, 0.75, 2, 'osm', 'yiheyuan-demo:bike', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.270664 39.997678, 116.271055 39.997717, 116.271536 39.997760)')
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w9' AND nb.source_ref='yiheyuan-demo:node:w10';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref, geometry)
    SELECT na.id, nb.id, 74.7, 'bike', 18, 0.75, 2, 'osm', 'yiheyuan-demo:bike', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.271536 39.997760, 116.271055 39.997717, 116.270664 39.997678)')
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w10' AND nb.source_ref='yiheyuan-demo:node:w9';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref, geometry)
    SELECT na.id, nb.id, 178.4, 'bike', 44, 1.78, 2, 'osm', 'yiheyuan-demo:bike', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.271536 39.997760, 116.272444 39.997852, 116.272444 39.997847, 116.272448 39.997925, 116.272448 39.997977, 116.272287 39.997977, 116.272044 39.997964, 116.272010 39.997960, 116.272005 39.997956, 116.271970 39.998064, 116.271918 39.998203, 116.271879 39.998247, 116.271836 39.998255, 116.271771 39.998325)')
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w10' AND nb.source_ref='yiheyuan-demo:node:e_bei';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref, geometry)
    SELECT na.id, nb.id, 178.4, 'bike', 44, 1.78, 2, 'osm', 'yiheyuan-demo:bike', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.271771 39.998325, 116.271836 39.998255, 116.271879 39.998247, 116.271918 39.998203, 116.271970 39.998064, 116.272005 39.997956, 116.272010 39.997960, 116.272044 39.997964, 116.272287 39.997977, 116.272448 39.997977, 116.272448 39.997925, 116.272444 39.997847, 116.272444 39.997852, 116.271536 39.997760)')
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:e_bei' AND nb.source_ref='yiheyuan-demo:node:w10';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref, geometry)
    SELECT na.id, nb.id, 160.4, 'bike', 40, 1.60, 2, 'osm', 'yiheyuan-demo:bike', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.276428 39.991784, 116.276150 39.991862, 116.276098 39.991875, 116.275981 39.991875, 116.275885 39.991875, 116.275742 39.991858, 116.275595 39.991823, 116.275477 39.991771, 116.275425 39.991706, 116.275412 39.991654, 116.275404 39.991554, 116.275382 39.991406, 116.275382 39.991363, 116.275430 39.991298, 116.275573 39.991150)')
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w1' AND nb.source_ref='yiheyuan-demo:node:w11';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref, geometry)
    SELECT na.id, nb.id, 160.4, 'bike', 40, 1.60, 2, 'osm', 'yiheyuan-demo:bike', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.275573 39.991150, 116.275430 39.991298, 116.275382 39.991363, 116.275382 39.991406, 116.275404 39.991554, 116.275412 39.991654, 116.275425 39.991706, 116.275477 39.991771, 116.275595 39.991823, 116.275742 39.991858, 116.275885 39.991875, 116.275981 39.991875, 116.276098 39.991875, 116.276150 39.991862, 116.276428 39.991784)')
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w11' AND nb.source_ref='yiheyuan-demo:node:w1';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref, geometry)
    SELECT na.id, nb.id, 60.5, 'bike', 15, 0.61, 2, 'osm', 'yiheyuan-demo:bike', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.275573 39.991146, 116.275434 39.991293, 116.275382 39.991359, 116.275382 39.991402, 116.275399 39.991549, 116.275408 39.991645)')
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w11' AND nb.source_ref='yiheyuan-demo:node:w12';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref, geometry)
    SELECT na.id, nb.id, 60.5, 'bike', 15, 0.61, 2, 'osm', 'yiheyuan-demo:bike', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.275408 39.991645, 116.275399 39.991549, 116.275382 39.991402, 116.275382 39.991359, 116.275434 39.991293, 116.275573 39.991146)')
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w12' AND nb.source_ref='yiheyuan-demo:node:w11';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref, geometry)
    SELECT na.id, nb.id, 115.2, 'bike', 28, 1.15, 2, 'osm', 'yiheyuan-demo:bike', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.274600 39.990600, 116.275600 39.989900)')
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w11' AND nb.source_ref='yiheyuan-demo:node:w15';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref, geometry)
    SELECT na.id, nb.id, 115.2, 'bike', 28, 1.15, 2, 'osm', 'yiheyuan-demo:bike', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.275600 39.989900, 116.274600 39.990600)')
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w15' AND nb.source_ref='yiheyuan-demo:node:w11';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref, geometry)
    SELECT na.id, nb.id, 126.0, 'bike', 31, 1.26, 2, 'osm', 'yiheyuan-demo:bike', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.275599 39.989896, 116.275204 39.988802)')
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w15' AND nb.source_ref='yiheyuan-demo:node:w13';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref, geometry)
    SELECT na.id, nb.id, 126.0, 'bike', 31, 1.26, 2, 'osm', 'yiheyuan-demo:bike', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.275204 39.988802, 116.275599 39.989896)')
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w13' AND nb.source_ref='yiheyuan-demo:node:w15';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref, geometry)
    SELECT na.id, nb.id, 139.1, 'bike', 34, 1.39, 2, 'osm', 'yiheyuan-demo:bike', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.275200 39.988800, 116.273700 39.988300)')
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w13' AND nb.source_ref='yiheyuan-demo:node:w14';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref, geometry)
    SELECT na.id, nb.id, 139.1, 'bike', 34, 1.39, 2, 'osm', 'yiheyuan-demo:bike', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.273700 39.988300, 116.275200 39.988800)')
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w14' AND nb.source_ref='yiheyuan-demo:node:w13';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref, geometry)
    SELECT na.id, nb.id, 619.5, 'bike', 154, 6.19, 2, 'osm', 'yiheyuan-demo:bike', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.267561 39.994709, 116.267569 39.994592, 116.267552 39.994484, 116.267357 39.993815, 116.267300 39.993698, 116.267049 39.993333, 116.266901 39.993142, 116.266897 39.993138, 116.267062 39.992999, 116.267626 39.992687, 116.268199 39.992326, 116.267964 39.991940, 116.267826 39.991710, 116.267760 39.991506, 116.267721 39.991089, 116.267687 39.990951, 116.267543 39.990573, 116.267396 39.990234, 116.267374 39.990187, 116.267300 39.990048, 116.267166 39.989857)')
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w7' AND nb.source_ref='yiheyuan-demo:node:w16';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref, geometry)
    SELECT na.id, nb.id, 619.5, 'bike', 154, 6.19, 2, 'osm', 'yiheyuan-demo:bike', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.267166 39.989857, 116.267300 39.990048, 116.267374 39.990187, 116.267396 39.990234, 116.267543 39.990573, 116.267687 39.990951, 116.267721 39.991089, 116.267760 39.991506, 116.267826 39.991710, 116.267964 39.991940, 116.268199 39.992326, 116.267626 39.992687, 116.267062 39.992999, 116.266897 39.993138, 116.266901 39.993142, 116.267049 39.993333, 116.267300 39.993698, 116.267357 39.993815, 116.267552 39.994484, 116.267569 39.994592, 116.267561 39.994709)')
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w16' AND nb.source_ref='yiheyuan-demo:node:w7';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref, geometry)
    SELECT na.id, nb.id, 343.9, 'bike', 85, 3.44, 2, 'osm', 'yiheyuan-demo:bike', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.275200 39.988800, 116.273000 39.986200)')
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w13' AND nb.source_ref='yiheyuan-demo:node:w17';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref, geometry)
    SELECT na.id, nb.id, 343.9, 'bike', 85, 3.44, 2, 'osm', 'yiheyuan-demo:bike', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.273000 39.986200, 116.275200 39.988800)')
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w17' AND nb.source_ref='yiheyuan-demo:node:w13';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref, geometry)
    SELECT na.id, nb.id, 110.8, 'bike', 27, 1.11, 2, 'osm', 'yiheyuan-demo:bike', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.273668 39.986280, 116.273672 39.986263, 116.273702 39.986050, 116.273733 39.985842, 116.273741 39.985825, 116.273767 39.985812, 116.273789 39.985807, 116.273859 39.985807, 116.273885 39.985599, 116.273906 39.985451, 116.273902 39.985365)')
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w17' AND nb.source_ref='yiheyuan-demo:node:e_xin';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref, geometry)
    SELECT na.id, nb.id, 110.8, 'bike', 27, 1.11, 2, 'osm', 'yiheyuan-demo:bike', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.273902 39.985365, 116.273906 39.985451, 116.273885 39.985599, 116.273859 39.985807, 116.273789 39.985807, 116.273767 39.985812, 116.273741 39.985825, 116.273733 39.985842, 116.273702 39.986050, 116.273672 39.986263, 116.273668 39.986280)')
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:e_xin' AND nb.source_ref='yiheyuan-demo:node:w17';

    -- 5b. 电瓶车线（双向，travel_mode='shuttle'，速度快、拥挤度低，验收 4c）
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref, geometry)
    SELECT na.id, nb.id, 112.7, 'shuttle', 22, 1.13, 1, 'osm', 'yiheyuan-demo:shuttle', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.276641 39.991606, 116.276589 39.991697, 116.276432 39.991784, 116.276150 39.991862, 116.276098 39.991875, 116.275981 39.991875, 116.275885 39.991875, 116.275742 39.991858, 116.275595 39.991823, 116.275477 39.991771)')
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:e_dong' AND nb.source_ref='yiheyuan-demo:node:w5';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref, geometry)
    SELECT na.id, nb.id, 112.7, 'shuttle', 22, 1.13, 1, 'osm', 'yiheyuan-demo:shuttle', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.275477 39.991771, 116.275595 39.991823, 116.275742 39.991858, 116.275885 39.991875, 116.275981 39.991875, 116.276098 39.991875, 116.276150 39.991862, 116.276432 39.991784, 116.276589 39.991697, 116.276641 39.991606)')
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w5' AND nb.source_ref='yiheyuan-demo:node:e_dong';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref, geometry)
    SELECT na.id, nb.id, 481.3, 'shuttle', 96, 4.81, 1, 'osm', 'yiheyuan-demo:shuttle', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.272700 39.993400, 116.267300 39.994700)')
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w5' AND nb.source_ref='yiheyuan-demo:node:w7';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref, geometry)
    SELECT na.id, nb.id, 481.3, 'shuttle', 96, 4.81, 1, 'osm', 'yiheyuan-demo:shuttle', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.267300 39.994700, 116.272700 39.993400)')
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w7' AND nb.source_ref='yiheyuan-demo:node:w5';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref, geometry)
    SELECT na.id, nb.id, 13.0, 'shuttle', 2, 0.13, 1, 'osm', 'yiheyuan-demo:shuttle', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.267561 39.994709, 116.267569 39.994592)')
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w7' AND nb.source_ref='yiheyuan-demo:node:w8';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref, geometry)
    SELECT na.id, nb.id, 13.0, 'shuttle', 2, 0.13, 1, 'osm', 'yiheyuan-demo:shuttle', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.267569 39.994592, 116.267561 39.994709)')
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w8' AND nb.source_ref='yiheyuan-demo:node:w7';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref, geometry)
    SELECT na.id, nb.id, 324.6, 'shuttle', 64, 3.25, 1, 'osm', 'yiheyuan-demo:shuttle', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.270500 39.994600, 116.271600 39.997400)')
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w8' AND nb.source_ref='yiheyuan-demo:node:w10';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref, geometry)
    SELECT na.id, nb.id, 324.6, 'shuttle', 64, 3.25, 1, 'osm', 'yiheyuan-demo:shuttle', ST_GeomFromEWKT('SRID=4326;LINESTRING(116.271600 39.997400, 116.270500 39.994600)')
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
