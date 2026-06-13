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

    -- 5. 步行路径边（双向，source='osm' 标记为可导航真实道路）
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 63.5, 'walk', 52, 0.64, 2, 'osm', 'yiheyuan-demo:edge'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:e_dong' AND nb.source_ref='yiheyuan-demo:node:w1';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 63.5, 'walk', 52, 0.64, 2, 'osm', 'yiheyuan-demo:edge'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w1' AND nb.source_ref='yiheyuan-demo:node:e_dong';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 75.7, 'walk', 63, 0.76, 2, 'osm', 'yiheyuan-demo:edge'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w1' AND nb.source_ref='yiheyuan-demo:node:w2';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 75.7, 'walk', 63, 0.76, 2, 'osm', 'yiheyuan-demo:edge'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w2' AND nb.source_ref='yiheyuan-demo:node:w1';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 83.5, 'walk', 69, 0.83, 2, 'osm', 'yiheyuan-demo:edge'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w2' AND nb.source_ref='yiheyuan-demo:node:w3';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 83.5, 'walk', 69, 0.83, 2, 'osm', 'yiheyuan-demo:edge'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w3' AND nb.source_ref='yiheyuan-demo:node:w2';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 95.9, 'walk', 79, 0.96, 2, 'osm', 'yiheyuan-demo:edge'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w3' AND nb.source_ref='yiheyuan-demo:node:w4';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 95.9, 'walk', 79, 0.96, 2, 'osm', 'yiheyuan-demo:edge'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w4' AND nb.source_ref='yiheyuan-demo:node:w3';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 115.4, 'walk', 96, 1.15, 2, 'osm', 'yiheyuan-demo:edge'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w4' AND nb.source_ref='yiheyuan-demo:node:w5';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 115.4, 'walk', 96, 1.15, 2, 'osm', 'yiheyuan-demo:edge'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w5' AND nb.source_ref='yiheyuan-demo:node:w4';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 206.8, 'walk', 172, 2.07, 2, 'osm', 'yiheyuan-demo:edge'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w5' AND nb.source_ref='yiheyuan-demo:node:w6';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 206.8, 'walk', 172, 2.07, 2, 'osm', 'yiheyuan-demo:edge'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w6' AND nb.source_ref='yiheyuan-demo:node:w5';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 278.2, 'walk', 231, 2.78, 2, 'osm', 'yiheyuan-demo:edge'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w6' AND nb.source_ref='yiheyuan-demo:node:w7';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 278.2, 'walk', 231, 2.78, 2, 'osm', 'yiheyuan-demo:edge'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w7' AND nb.source_ref='yiheyuan-demo:node:w6';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 101.3, 'walk', 84, 1.01, 2, 'osm', 'yiheyuan-demo:edge'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w6' AND nb.source_ref='yiheyuan-demo:node:w8';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 101.3, 'walk', 84, 1.01, 2, 'osm', 'yiheyuan-demo:edge'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w8' AND nb.source_ref='yiheyuan-demo:node:w6';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 180.8, 'walk', 150, 1.81, 2, 'osm', 'yiheyuan-demo:edge'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w8' AND nb.source_ref='yiheyuan-demo:node:w9';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 180.8, 'walk', 150, 1.81, 2, 'osm', 'yiheyuan-demo:edge'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w9' AND nb.source_ref='yiheyuan-demo:node:w8';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 145.9, 'walk', 121, 1.46, 2, 'osm', 'yiheyuan-demo:edge'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w9' AND nb.source_ref='yiheyuan-demo:node:w10';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 145.9, 'walk', 121, 1.46, 2, 'osm', 'yiheyuan-demo:edge'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w10' AND nb.source_ref='yiheyuan-demo:node:w9';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 113.9, 'walk', 94, 1.14, 2, 'osm', 'yiheyuan-demo:edge'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w10' AND nb.source_ref='yiheyuan-demo:node:e_bei';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 113.9, 'walk', 94, 1.14, 2, 'osm', 'yiheyuan-demo:edge'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:e_bei' AND nb.source_ref='yiheyuan-demo:node:w10';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 244.1, 'walk', 203, 2.44, 2, 'osm', 'yiheyuan-demo:edge'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w1' AND nb.source_ref='yiheyuan-demo:node:w11';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 244.1, 'walk', 203, 2.44, 2, 'osm', 'yiheyuan-demo:edge'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w11' AND nb.source_ref='yiheyuan-demo:node:w1';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 122.4, 'walk', 101, 1.22, 2, 'osm', 'yiheyuan-demo:edge'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w11' AND nb.source_ref='yiheyuan-demo:node:w12';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 122.4, 'walk', 101, 1.22, 2, 'osm', 'yiheyuan-demo:edge'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w12' AND nb.source_ref='yiheyuan-demo:node:w11';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 115.2, 'walk', 95, 1.15, 2, 'osm', 'yiheyuan-demo:edge'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w11' AND nb.source_ref='yiheyuan-demo:node:w15';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 115.2, 'walk', 95, 1.15, 2, 'osm', 'yiheyuan-demo:edge'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w15' AND nb.source_ref='yiheyuan-demo:node:w11';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 126.7, 'walk', 105, 1.27, 2, 'osm', 'yiheyuan-demo:edge'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w15' AND nb.source_ref='yiheyuan-demo:node:w13';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 126.7, 'walk', 105, 1.27, 2, 'osm', 'yiheyuan-demo:edge'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w13' AND nb.source_ref='yiheyuan-demo:node:w15';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 139.1, 'walk', 115, 1.39, 2, 'osm', 'yiheyuan-demo:edge'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w13' AND nb.source_ref='yiheyuan-demo:node:w14';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 139.1, 'walk', 115, 1.39, 2, 'osm', 'yiheyuan-demo:edge'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w14' AND nb.source_ref='yiheyuan-demo:node:w13';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 494.0, 'walk', 411, 4.94, 2, 'osm', 'yiheyuan-demo:edge'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w7' AND nb.source_ref='yiheyuan-demo:node:w16';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 494.0, 'walk', 411, 4.94, 2, 'osm', 'yiheyuan-demo:edge'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w16' AND nb.source_ref='yiheyuan-demo:node:w7';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 343.9, 'walk', 286, 3.44, 2, 'osm', 'yiheyuan-demo:edge'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w13' AND nb.source_ref='yiheyuan-demo:node:w17';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 343.9, 'walk', 286, 3.44, 2, 'osm', 'yiheyuan-demo:edge'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w17' AND nb.source_ref='yiheyuan-demo:node:w13';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 90.4, 'walk', 75, 0.90, 2, 'osm', 'yiheyuan-demo:edge'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w17' AND nb.source_ref='yiheyuan-demo:node:e_xin';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 90.4, 'walk', 75, 0.90, 2, 'osm', 'yiheyuan-demo:edge'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:e_xin' AND nb.source_ref='yiheyuan-demo:node:w17';

    -- 5b. 电瓶车线（双向，travel_mode='shuttle'，速度快、拥挤度低，验收 4c）
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 432.9, 'shuttle', 86, 4.33, 1, 'osm', 'yiheyuan-demo:shuttle'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:e_dong' AND nb.source_ref='yiheyuan-demo:node:w5';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 432.9, 'shuttle', 86, 4.33, 1, 'osm', 'yiheyuan-demo:shuttle'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w5' AND nb.source_ref='yiheyuan-demo:node:e_dong';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 481.3, 'shuttle', 96, 4.81, 1, 'osm', 'yiheyuan-demo:shuttle'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w5' AND nb.source_ref='yiheyuan-demo:node:w7';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 481.3, 'shuttle', 96, 4.81, 1, 'osm', 'yiheyuan-demo:shuttle'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w7' AND nb.source_ref='yiheyuan-demo:node:w5';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 272.3, 'shuttle', 54, 2.72, 1, 'osm', 'yiheyuan-demo:shuttle'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w7' AND nb.source_ref='yiheyuan-demo:node:w8';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 272.3, 'shuttle', 54, 2.72, 1, 'osm', 'yiheyuan-demo:shuttle'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w8' AND nb.source_ref='yiheyuan-demo:node:w7';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 324.6, 'shuttle', 64, 3.25, 1, 'osm', 'yiheyuan-demo:shuttle'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w8' AND nb.source_ref='yiheyuan-demo:node:w10';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 324.6, 'shuttle', 64, 3.25, 1, 'osm', 'yiheyuan-demo:shuttle'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w10' AND nb.source_ref='yiheyuan-demo:node:w8';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 113.9, 'shuttle', 22, 1.14, 1, 'osm', 'yiheyuan-demo:shuttle'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w10' AND nb.source_ref='yiheyuan-demo:node:e_bei';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 113.9, 'shuttle', 22, 1.14, 1, 'osm', 'yiheyuan-demo:shuttle'
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
