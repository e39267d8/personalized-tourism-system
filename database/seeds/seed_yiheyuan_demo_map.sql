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
    VALUES ('东宫门公共卫生间', 'toilet', ST_SetSRID(ST_MakePoint(116.281357, 39.999491), 4326)::geography, '颐和园内', 4.3, NULL, '08:00-17:00', v_spot, 'demo', 'yiheyuan-demo:fac:0');
    INSERT INTO facilities (name, type, location, address, rating, price_level, opening_hours, scenic_spot_id, source, source_ref)
    VALUES ('仁寿殿游客服务点', 'service', ST_SetSRID(ST_MakePoint(116.279578, 39.999871), 4326)::geography, '颐和园内', 4.5, NULL, '08:00-17:00', v_spot, 'demo', 'yiheyuan-demo:fac:1');
    INSERT INTO facilities (name, type, location, address, rating, price_level, opening_hours, scenic_spot_id, source, source_ref)
    VALUES ('听鹂馆饭庄', 'restaurant', ST_SetSRID(ST_MakePoint(116.277518, 39.999690), 4326)::geography, '颐和园内', 4.6, 3, '08:00-17:00', v_spot, 'demo', 'yiheyuan-demo:fac:2');
    INSERT INTO facilities (name, type, location, address, rating, price_level, opening_hours, scenic_spot_id, source, source_ref)
    VALUES ('长廊东口卫生间', 'toilet', ST_SetSRID(ST_MakePoint(116.276334, 39.999710), 4326)::geography, '颐和园内', 4.2, NULL, '08:00-17:00', v_spot, 'demo', 'yiheyuan-demo:fac:3');
    INSERT INTO facilities (name, type, location, address, rating, price_level, opening_hours, scenic_spot_id, source, source_ref)
    VALUES ('排云殿文创商店', 'shop', ST_SetSRID(ST_MakePoint(116.273880, 39.999823), 4326)::geography, '颐和园内', 4.4, 2, '08:00-17:00', v_spot, 'demo', 'yiheyuan-demo:fac:4');
    INSERT INTO facilities (name, type, location, address, rating, price_level, opening_hours, scenic_spot_id, source, source_ref)
    VALUES ('石舫咖啡厅', 'restaurant', ST_SetSRID(ST_MakePoint(116.271680, 39.999494), 4326)::geography, '颐和园内', 4.3, 2, '08:00-17:00', v_spot, 'demo', 'yiheyuan-demo:fac:5');
    INSERT INTO facilities (name, type, location, address, rating, price_level, opening_hours, scenic_spot_id, source, source_ref)
    VALUES ('佛香阁观景平台', 'service', ST_SetSRID(ST_MakePoint(116.274034, 40.001269), 4326)::geography, '颐和园内', 4.8, NULL, '08:00-17:00', v_spot, 'demo', 'yiheyuan-demo:fac:6');
    INSERT INTO facilities (name, type, location, address, rating, price_level, opening_hours, scenic_spot_id, source, source_ref)
    VALUES ('苏州街小吃店', 'restaurant', ST_SetSRID(ST_MakePoint(116.273991, 40.002230), 4326)::geography, '颐和园内', 4.1, 1, '08:00-17:00', v_spot, 'demo', 'yiheyuan-demo:fac:7');
    INSERT INTO facilities (name, type, location, address, rating, price_level, opening_hours, scenic_spot_id, source, source_ref)
    VALUES ('北宫门综合超市', 'shop', ST_SetSRID(ST_MakePoint(116.275228, 40.003240), 4326)::geography, '颐和园内', 4.2, 1, '08:00-17:00', v_spot, 'demo', 'yiheyuan-demo:fac:8');
    INSERT INTO facilities (name, type, location, address, rating, price_level, opening_hours, scenic_spot_id, source, source_ref)
    VALUES ('北宫门公共卫生间', 'toilet', ST_SetSRID(ST_MakePoint(116.274834, 40.003247), 4326)::geography, '颐和园内', 4.0, NULL, '08:00-17:00', v_spot, 'demo', 'yiheyuan-demo:fac:9');
    INSERT INTO facilities (name, type, location, address, rating, price_level, opening_hours, scenic_spot_id, source, source_ref)
    VALUES ('知春亭茶室', 'restaurant', ST_SetSRID(ST_MakePoint(116.279118, 39.996551), 4326)::geography, '颐和园内', 4.5, 2, '08:00-17:00', v_spot, 'demo', 'yiheyuan-demo:fac:10');
    INSERT INTO facilities (name, type, location, address, rating, price_level, opening_hours, scenic_spot_id, source, source_ref)
    VALUES ('十七孔桥服务驿站', 'service', ST_SetSRID(ST_MakePoint(116.277680, 39.995411), 4326)::geography, '颐和园内', 4.3, NULL, '08:00-17:00', v_spot, 'demo', 'yiheyuan-demo:fac:11');
    INSERT INTO facilities (name, type, location, address, rating, price_level, opening_hours, scenic_spot_id, source, source_ref)
    VALUES ('南湖岛公共卫生间', 'toilet', ST_SetSRID(ST_MakePoint(116.276022, 39.994184), 4326)::geography, '颐和园内', 3.9, NULL, '08:00-17:00', v_spot, 'demo', 'yiheyuan-demo:fac:12');
    INSERT INTO facilities (name, type, location, address, rating, price_level, opening_hours, scenic_spot_id, source, source_ref)
    VALUES ('西堤自助售卖机', 'atm', ST_SetSRID(ST_MakePoint(116.271473, 39.996123), 4326)::geography, '颐和园内', 4.0, 1, '08:00-17:00', v_spot, 'demo', 'yiheyuan-demo:fac:13');
    INSERT INTO facilities (name, type, location, address, rating, price_level, opening_hours, scenic_spot_id, source, source_ref)
    VALUES ('新建宫门卫生间', 'toilet', ST_SetSRID(ST_MakePoint(116.270321, 39.997552), 4326)::geography, '颐和园内', 4.1, NULL, '08:00-17:00', v_spot, 'demo', 'yiheyuan-demo:fac:14');
    INSERT INTO facilities (name, type, location, address, rating, price_level, opening_hours, scenic_spot_id, source, source_ref)
    VALUES ('东堤便利店', 'shop', ST_SetSRID(ST_MakePoint(116.280530, 39.997258), 4326)::geography, '颐和园内', 4.2, 1, '08:00-17:00', v_spot, 'demo', 'yiheyuan-demo:fac:15');

    -- 3. 路网节点（graph_nodes）：路径/景点/入口
    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, source, source_ref)
    VALUES ('东宫门', ST_SetSRID(ST_MakePoint(116.282791, 39.999581), 4326)::geography, 'entrance', v_spot, 'demo', 'yiheyuan-demo:node:e_dong');
    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, source, source_ref)
    VALUES ('东宫门广场', ST_SetSRID(ST_MakePoint(116.281145, 39.999491), 4326)::geography, 'scenic', v_spot, 'demo', 'yiheyuan-demo:node:w1');
    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, source, source_ref)
    VALUES ('仁寿殿', ST_SetSRID(ST_MakePoint(116.279734, 39.999761), 4326)::geography, 'scenic', v_spot, 'demo', 'yiheyuan-demo:node:w2');
    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, source, source_ref)
    VALUES ('玉澜堂', ST_SetSRID(ST_MakePoint(116.278440, 39.999041), 4326)::geography, 'scenic', v_spot, 'demo', 'yiheyuan-demo:node:w3');
    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, source, source_ref)
    VALUES ('乐寿堂', ST_SetSRID(ST_MakePoint(116.277499, 39.999851), 4326)::geography, 'scenic', v_spot, 'demo', 'yiheyuan-demo:node:w4');
    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, source, source_ref)
    VALUES ('长廊东口', ST_SetSRID(ST_MakePoint(116.276206, 39.999581), 4326)::geography, 'scenic', v_spot, 'demo', 'yiheyuan-demo:node:w5');
    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, source, source_ref)
    VALUES ('排云殿前', ST_SetSRID(ST_MakePoint(116.274089, 39.999851), 4326)::geography, 'scenic', v_spot, 'demo', 'yiheyuan-demo:node:w6');
    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, source, source_ref)
    VALUES ('石舫', ST_SetSRID(ST_MakePoint(116.271502, 39.999581), 4326)::geography, 'scenic', v_spot, 'demo', 'yiheyuan-demo:node:w7');
    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, source, source_ref)
    VALUES ('佛香阁下', ST_SetSRID(ST_MakePoint(116.274089, 40.001113), 4326)::geography, 'scenic', v_spot, 'demo', 'yiheyuan-demo:node:w8');
    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, source, source_ref)
    VALUES ('苏州街', ST_SetSRID(ST_MakePoint(116.274089, 40.002374), 4326)::geography, 'scenic', v_spot, 'demo', 'yiheyuan-demo:node:w9');
    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, source, source_ref)
    VALUES ('北宫门内', ST_SetSRID(ST_MakePoint(116.275030, 40.003185), 4326)::geography, 'scenic', v_spot, 'demo', 'yiheyuan-demo:node:w10');
    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, source, source_ref)
    VALUES ('北宫门', ST_SetSRID(ST_MakePoint(116.275735, 40.003905), 4326)::geography, 'entrance', v_spot, 'demo', 'yiheyuan-demo:node:e_bei');
    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, source, source_ref)
    VALUES ('昆明湖东堤', ST_SetSRID(ST_MakePoint(116.280557, 39.997419), 4326)::geography, 'scenic', v_spot, 'demo', 'yiheyuan-demo:node:w11');
    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, source, source_ref)
    VALUES ('知春亭', ST_SetSRID(ST_MakePoint(116.279028, 39.996698), 4326)::geography, 'scenic', v_spot, 'demo', 'yiheyuan-demo:node:w12');
    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, source, source_ref)
    VALUES ('十七孔桥北', ST_SetSRID(ST_MakePoint(116.277617, 39.995257), 4326)::geography, 'scenic', v_spot, 'demo', 'yiheyuan-demo:node:w13');
    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, source, source_ref)
    VALUES ('南湖岛', ST_SetSRID(ST_MakePoint(116.276206, 39.994266), 4326)::geography, 'scenic', v_spot, 'demo', 'yiheyuan-demo:node:w14');
    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, source, source_ref)
    VALUES ('铜牛', ST_SetSRID(ST_MakePoint(116.279381, 39.995797), 4326)::geography, 'scenic', v_spot, 'demo', 'yiheyuan-demo:node:w15');
    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, source, source_ref)
    VALUES ('西堤玉带桥', ST_SetSRID(ST_MakePoint(116.271266, 39.996158), 4326)::geography, 'scenic', v_spot, 'demo', 'yiheyuan-demo:node:w16');
    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, source, source_ref)
    VALUES ('新建宫门内', ST_SetSRID(ST_MakePoint(116.270443, 39.997419), 4326)::geography, 'scenic', v_spot, 'demo', 'yiheyuan-demo:node:w17');
    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, source, source_ref)
    VALUES ('新建宫门', ST_SetSRID(ST_MakePoint(116.269150, 39.997149), 4326)::geography, 'entrance', v_spot, 'demo', 'yiheyuan-demo:node:e_xin');

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
    SELECT na.id, nb.id, 140.4, 'walk', 116, 1.40, 2, 'osm', 'yiheyuan-demo:edge'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:e_dong' AND nb.source_ref='yiheyuan-demo:node:w1';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 140.4, 'walk', 116, 1.40, 2, 'osm', 'yiheyuan-demo:edge'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w1' AND nb.source_ref='yiheyuan-demo:node:e_dong';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 123.7, 'walk', 103, 1.24, 2, 'osm', 'yiheyuan-demo:edge'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w1' AND nb.source_ref='yiheyuan-demo:node:w2';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 123.7, 'walk', 103, 1.24, 2, 'osm', 'yiheyuan-demo:edge'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w2' AND nb.source_ref='yiheyuan-demo:node:w1';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 136.0, 'walk', 113, 1.36, 2, 'osm', 'yiheyuan-demo:edge'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w2' AND nb.source_ref='yiheyuan-demo:node:w3';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 136.0, 'walk', 113, 1.36, 2, 'osm', 'yiheyuan-demo:edge'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w3' AND nb.source_ref='yiheyuan-demo:node:w2';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 120.4, 'walk', 100, 1.20, 2, 'osm', 'yiheyuan-demo:edge'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w3' AND nb.source_ref='yiheyuan-demo:node:w4';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 120.4, 'walk', 100, 1.20, 2, 'osm', 'yiheyuan-demo:edge'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w4' AND nb.source_ref='yiheyuan-demo:node:w3';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 114.0, 'walk', 95, 1.14, 2, 'osm', 'yiheyuan-demo:edge'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w4' AND nb.source_ref='yiheyuan-demo:node:w5';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 114.0, 'walk', 95, 1.14, 2, 'osm', 'yiheyuan-demo:edge'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w5' AND nb.source_ref='yiheyuan-demo:node:w4';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 182.5, 'walk', 152, 1.82, 2, 'osm', 'yiheyuan-demo:edge'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w5' AND nb.source_ref='yiheyuan-demo:node:w6';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 182.5, 'walk', 152, 1.82, 2, 'osm', 'yiheyuan-demo:edge'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w6' AND nb.source_ref='yiheyuan-demo:node:w5';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 222.0, 'walk', 185, 2.22, 2, 'osm', 'yiheyuan-demo:edge'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w6' AND nb.source_ref='yiheyuan-demo:node:w7';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 222.0, 'walk', 185, 2.22, 2, 'osm', 'yiheyuan-demo:edge'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w7' AND nb.source_ref='yiheyuan-demo:node:w6';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 140.0, 'walk', 116, 1.40, 2, 'osm', 'yiheyuan-demo:edge'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w6' AND nb.source_ref='yiheyuan-demo:node:w8';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 140.0, 'walk', 116, 1.40, 2, 'osm', 'yiheyuan-demo:edge'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w8' AND nb.source_ref='yiheyuan-demo:node:w6';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 140.0, 'walk', 116, 1.40, 2, 'osm', 'yiheyuan-demo:edge'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w8' AND nb.source_ref='yiheyuan-demo:node:w9';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 140.0, 'walk', 116, 1.40, 2, 'osm', 'yiheyuan-demo:edge'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w9' AND nb.source_ref='yiheyuan-demo:node:w8';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 120.4, 'walk', 100, 1.20, 2, 'osm', 'yiheyuan-demo:edge'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w9' AND nb.source_ref='yiheyuan-demo:node:w10';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 120.4, 'walk', 100, 1.20, 2, 'osm', 'yiheyuan-demo:edge'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w10' AND nb.source_ref='yiheyuan-demo:node:w9';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 100.0, 'walk', 83, 1.00, 2, 'osm', 'yiheyuan-demo:edge'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w10' AND nb.source_ref='yiheyuan-demo:node:e_bei';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 100.0, 'walk', 83, 1.00, 2, 'osm', 'yiheyuan-demo:edge'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:e_bei' AND nb.source_ref='yiheyuan-demo:node:w10';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 235.4, 'walk', 196, 2.35, 2, 'osm', 'yiheyuan-demo:edge'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w1' AND nb.source_ref='yiheyuan-demo:node:w11';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 235.4, 'walk', 196, 2.35, 2, 'osm', 'yiheyuan-demo:edge'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w11' AND nb.source_ref='yiheyuan-demo:node:w1';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 152.6, 'walk', 127, 1.53, 2, 'osm', 'yiheyuan-demo:edge'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w11' AND nb.source_ref='yiheyuan-demo:node:w12';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 152.6, 'walk', 127, 1.53, 2, 'osm', 'yiheyuan-demo:edge'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w12' AND nb.source_ref='yiheyuan-demo:node:w11';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 200.0, 'walk', 166, 2.00, 2, 'osm', 'yiheyuan-demo:edge'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w12' AND nb.source_ref='yiheyuan-demo:node:w13';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 200.0, 'walk', 166, 2.00, 2, 'osm', 'yiheyuan-demo:edge'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w13' AND nb.source_ref='yiheyuan-demo:node:w12';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 162.8, 'walk', 135, 1.63, 2, 'osm', 'yiheyuan-demo:edge'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w13' AND nb.source_ref='yiheyuan-demo:node:w14';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 162.8, 'walk', 135, 1.63, 2, 'osm', 'yiheyuan-demo:edge'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w14' AND nb.source_ref='yiheyuan-demo:node:w13';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 205.9, 'walk', 171, 2.06, 2, 'osm', 'yiheyuan-demo:edge'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w11' AND nb.source_ref='yiheyuan-demo:node:w15';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 205.9, 'walk', 171, 2.06, 2, 'osm', 'yiheyuan-demo:edge'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w15' AND nb.source_ref='yiheyuan-demo:node:w11';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 161.6, 'walk', 134, 1.62, 2, 'osm', 'yiheyuan-demo:edge'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w15' AND nb.source_ref='yiheyuan-demo:node:w13';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 161.6, 'walk', 134, 1.62, 2, 'osm', 'yiheyuan-demo:edge'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w13' AND nb.source_ref='yiheyuan-demo:node:w15';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 380.5, 'walk', 317, 3.81, 2, 'osm', 'yiheyuan-demo:edge'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w7' AND nb.source_ref='yiheyuan-demo:node:w16';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 380.5, 'walk', 317, 3.81, 2, 'osm', 'yiheyuan-demo:edge'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w16' AND nb.source_ref='yiheyuan-demo:node:w7';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 156.5, 'walk', 130, 1.57, 2, 'osm', 'yiheyuan-demo:edge'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w16' AND nb.source_ref='yiheyuan-demo:node:w17';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 156.5, 'walk', 130, 1.57, 2, 'osm', 'yiheyuan-demo:edge'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w17' AND nb.source_ref='yiheyuan-demo:node:w16';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 114.0, 'walk', 95, 1.14, 2, 'osm', 'yiheyuan-demo:edge'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w17' AND nb.source_ref='yiheyuan-demo:node:e_xin';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 114.0, 'walk', 95, 1.14, 2, 'osm', 'yiheyuan-demo:edge'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:e_xin' AND nb.source_ref='yiheyuan-demo:node:w17';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 469.6, 'walk', 391, 4.70, 2, 'osm', 'yiheyuan-demo:edge'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w14' AND nb.source_ref='yiheyuan-demo:node:w16';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, source, source_ref)
    SELECT na.id, nb.id, 469.6, 'walk', 391, 4.70, 2, 'osm', 'yiheyuan-demo:edge'
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref='yiheyuan-demo:node:w16' AND nb.source_ref='yiheyuan-demo:node:w14';

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
