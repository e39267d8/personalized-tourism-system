-- =====================================================
-- 北京大学校园内部连通路网（人工校核主路网 + 分类设施）
-- 由 scripts/gen_pku_curated_map.py 生成，请勿手工编辑。
-- 用途：校园内部导航、附近设施查询、实际步行距离排序。
-- 来源：在 OSM 导入数据基础上补充 campus_curated 连通拓扑；
--       不把人工校核边标记为 OSM。设施接入短边为 generated。
-- 幂等：按 source_ref 前缀 'pku-curated:%' 清理后重建。
-- =====================================================
SET client_encoding = 'UTF8';
BEGIN;

DO $$
DECLARE
    v_spot INTEGER;
BEGIN
    SELECT id INTO v_spot
    FROM scenic_spots
    WHERE status = 1
      AND city = '北京市'
      AND (name = '北京大学' OR name ILIKE '%北京大学%' OR name ILIKE '%北大%')
    ORDER BY ST_Distance(location, ST_SetSRID(ST_MakePoint(116.304, 39.992), 4326)::geography), id
    LIMIT 1;
    IF v_spot IS NULL THEN
        RAISE EXCEPTION '未找到北京大学，请先执行 database/seeds/seed_campus_spots.sql';
    END IF;

    DELETE FROM graph_edges ge
    WHERE ge.source_ref LIKE 'pku-curated:%'
       OR EXISTS (
           SELECT 1 FROM graph_nodes n
           WHERE (n.id = ge.from_node OR n.id = ge.to_node)
             AND n.source_ref LIKE 'pku-curated:%'
       );
    DELETE FROM graph_nodes WHERE source_ref LIKE 'pku-curated:%';
    DELETE FROM facilities WHERE source_ref LIKE 'pku-curated:%';

    -- 1. 分类设施
    INSERT INTO facilities (name, type, location, address, rating, price_level, opening_hours, scenic_spot_id, source, source_ref, source_tags)
    VALUES ('西门公共卫生间', 'toilet', ST_SetSRID(ST_MakePoint(116.2988044, 39.9932960), 4326)::geography, '北京大学校园内', 4.2, NULL, '08:00-22:00', v_spot, 'campus_curated', 'pku-curated:fac:0', '{"kind":"campus-curated-facility","near":"west_gate"}'::jsonb);
    INSERT INTO facilities (name, type, location, address, rating, price_level, opening_hours, scenic_spot_id, source, source_ref, source_tags)
    VALUES ('赛克勒馆服务台', 'service', ST_SetSRID(ST_MakePoint(116.2996160, 39.9945446), 4326)::geography, '北京大学校园内', 4.5, NULL, '08:00-22:00', v_spot, 'campus_curated', 'pku-curated:fac:1', '{"kind":"campus-curated-facility","near":"sackler"}'::jsonb);
    INSERT INTO facilities (name, type, location, address, rating, price_level, opening_hours, scenic_spot_id, source, source_ref, source_tags)
    VALUES ('未名湖公共卫生间', 'toilet', ST_SetSRID(ST_MakePoint(116.3006022, 39.9935046), 4326)::geography, '北京大学校园内', 4.1, NULL, '08:00-22:00', v_spot, 'campus_curated', 'pku-curated:fac:2', '{"kind":"campus-curated-facility","near":"weiming_west"}'::jsonb);
    INSERT INTO facilities (name, type, location, address, rating, price_level, opening_hours, scenic_spot_id, source, source_ref, source_tags)
    VALUES ('博雅塔游客服务点', 'service', ST_SetSRID(ST_MakePoint(116.3059118, 39.9927655), 4326)::geography, '北京大学校园内', 4.6, NULL, '08:00-22:00', v_spot, 'campus_curated', 'pku-curated:fac:3', '{"kind":"campus-curated-facility","near":"boya"}'::jsonb);
    INSERT INTO facilities (name, type, location, address, rating, price_level, opening_hours, scenic_spot_id, source, source_ref, source_tags)
    VALUES ('图书馆咖啡吧', 'cafe', ST_SetSRID(ST_MakePoint(116.3031127, 39.9914946), 4326)::geography, '北京大学校园内', 4.4, 2, '08:00-22:00', v_spot, 'campus_curated', 'pku-curated:fac:4', '{"kind":"campus-curated-facility","near":"library"}'::jsonb);
    INSERT INTO facilities (name, type, location, address, rating, price_level, opening_hours, scenic_spot_id, source, source_ref, source_tags)
    VALUES ('图书馆自助售卖点', 'shop', ST_SetSRID(ST_MakePoint(116.3034997, 39.9914358), 4326)::geography, '北京大学校园内', 4.1, 1, '08:00-22:00', v_spot, 'campus_curated', 'pku-curated:fac:5', '{"kind":"campus-curated-facility","near":"library"}'::jsonb);
    INSERT INTO facilities (name, type, location, address, rating, price_level, opening_hours, scenic_spot_id, source, source_ref, source_tags)
    VALUES ('第一教学楼饮水服务点', 'service', ST_SetSRID(ST_MakePoint(116.3042827, 39.9917036), 4326)::geography, '北京大学校园内', 4.0, NULL, '08:00-22:00', v_spot, 'campus_curated', 'pku-curated:fac:6', '{"kind":"campus-curated-facility","near":"first_teaching"}'::jsonb);
    INSERT INTO facilities (name, type, location, address, rating, price_level, opening_hours, scenic_spot_id, source, source_ref, source_tags)
    VALUES ('理科楼公共卫生间', 'toilet', ST_SetSRID(ST_MakePoint(116.3070091, 39.9901437), 4326)::geography, '北京大学校园内', 4.0, NULL, '08:00-22:00', v_spot, 'campus_curated', 'pku-curated:fac:7', '{"kind":"campus-curated-facility","near":"science"}'::jsonb);
    INSERT INTO facilities (name, type, location, address, rating, price_level, opening_hours, scenic_spot_id, source, source_ref, source_tags)
    VALUES ('第二教学楼便利店', 'shop', ST_SetSRID(ST_MakePoint(116.3075128, 39.9883354), 4326)::geography, '北京大学校园内', 4.2, 1, '08:00-22:00', v_spot, 'campus_curated', 'pku-curated:fac:8', '{"kind":"campus-curated-facility","near":"second_teaching"}'::jsonb);
    INSERT INTO facilities (name, type, location, address, rating, price_level, opening_hours, scenic_spot_id, source, source_ref, source_tags)
    VALUES ('百讲票务服务处', 'shop', ST_SetSRID(ST_MakePoint(116.3042916, 39.9886078), 4326)::geography, '北京大学校园内', 4.3, 1, '08:00-22:00', v_spot, 'campus_curated', 'pku-curated:fac:9', '{"kind":"campus-curated-facility","near":"hall"}'::jsonb);
    INSERT INTO facilities (name, type, location, address, rating, price_level, opening_hours, scenic_spot_id, source, source_ref, source_tags)
    VALUES ('百讲公共卫生间', 'toilet', ST_SetSRID(ST_MakePoint(116.3045769, 39.9883990), 4326)::geography, '北京大学校园内', 4.0, NULL, '08:00-22:00', v_spot, 'campus_curated', 'pku-curated:fac:10', '{"kind":"campus-curated-facility","near":"hall"}'::jsonb);
    INSERT INTO facilities (name, type, location, address, rating, price_level, opening_hours, scenic_spot_id, source, source_ref, source_tags)
    VALUES ('农园餐厅', 'restaurant', ST_SetSRID(ST_MakePoint(116.3061595, 39.9876815), 4326)::geography, '北京大学校园内', 4.5, 2, '08:00-22:00', v_spot, 'campus_curated', 'pku-curated:fac:11', '{"kind":"campus-curated-facility","near":"nongyuan"}'::jsonb);
    INSERT INTO facilities (name, type, location, address, rating, price_level, opening_hours, scenic_spot_id, source, source_ref, source_tags)
    VALUES ('农园小卖部', 'shop', ST_SetSRID(ST_MakePoint(116.3059131, 39.9874455), 4326)::geography, '北京大学校园内', 4.2, 1, '08:00-22:00', v_spot, 'campus_curated', 'pku-curated:fac:12', '{"kind":"campus-curated-facility","near":"nongyuan"}'::jsonb);
    INSERT INTO facilities (name, type, location, address, rating, price_level, opening_hours, scenic_spot_id, source, source_ref, source_tags)
    VALUES ('南门公共卫生间', 'toilet', ST_SetSRID(ST_MakePoint(116.3061567, 39.9860452), 4326)::geography, '北京大学校园内', 4.0, NULL, '08:00-22:00', v_spot, 'campus_curated', 'pku-curated:fac:13', '{"kind":"campus-curated-facility","near":"south_gate"}'::jsonb);
    INSERT INTO facilities (name, type, location, address, rating, price_level, opening_hours, scenic_spot_id, source, source_ref, source_tags)
    VALUES ('校医院服务点', 'service', ST_SetSRID(ST_MakePoint(116.3019859, 39.9894409), 4326)::geography, '北京大学校园内', 4.2, NULL, '08:00-22:00', v_spot, 'campus_curated', 'pku-curated:fac:14', '{"kind":"campus-curated-facility","near":"hospital"}'::jsonb);
    INSERT INTO facilities (name, type, location, address, rating, price_level, opening_hours, scenic_spot_id, source, source_ref, source_tags)
    VALUES ('勺园食堂', 'restaurant', ST_SetSRID(ST_MakePoint(116.2995049, 39.9902581), 4326)::geography, '北京大学校园内', 4.3, 2, '08:00-22:00', v_spot, 'campus_curated', 'pku-curated:fac:15', '{"kind":"campus-curated-facility","near":"shao_yuan"}'::jsonb);
    INSERT INTO facilities (name, type, location, address, rating, price_level, opening_hours, scenic_spot_id, source, source_ref, source_tags)
    VALUES ('勺园公共卫生间', 'toilet', ST_SetSRID(ST_MakePoint(116.2996939, 39.9905234), 4326)::geography, '北京大学校园内', 4.0, NULL, '08:00-22:00', v_spot, 'campus_curated', 'pku-curated:fac:16', '{"kind":"campus-curated-facility","near":"shao_yuan"}'::jsonb);
    INSERT INTO facilities (name, type, location, address, rating, price_level, opening_hours, scenic_spot_id, source, source_ref, source_tags)
    VALUES ('校史馆文创商店', 'shop', ST_SetSRID(ST_MakePoint(116.2998449, 39.9920320), 4326)::geography, '北京大学校园内', 4.4, 2, '08:00-22:00', v_spot, 'campus_curated', 'pku-curated:fac:17', '{"kind":"campus-curated-facility","near":"history"}'::jsonb);
    INSERT INTO facilities (name, type, location, address, rating, price_level, opening_hours, scenic_spot_id, source, source_ref, source_tags)
    VALUES ('办公楼自助银行', 'atm', ST_SetSRID(ST_MakePoint(116.3005575, 39.9932290), 4326)::geography, '北京大学校园内', 4.1, NULL, '08:00-22:00', v_spot, 'campus_curated', 'pku-curated:fac:18', '{"kind":"campus-curated-facility","near":"admin"}'::jsonb);
    INSERT INTO facilities (name, type, location, address, rating, price_level, opening_hours, scenic_spot_id, source, source_ref, source_tags)
    VALUES ('化学楼公共卫生间', 'toilet', ST_SetSRID(ST_MakePoint(116.2997665, 39.9925025), 4326)::geography, '北京大学校园内', 4.0, NULL, '08:00-22:00', v_spot, 'campus_curated', 'pku-curated:fac:19', '{"kind":"campus-curated-facility","near":"chemistry"}'::jsonb);
    INSERT INTO facilities (name, type, location, address, rating, price_level, opening_hours, scenic_spot_id, source, source_ref, source_tags)
    VALUES ('光华咖啡厅', 'cafe', ST_SetSRID(ST_MakePoint(116.3070330, 39.9942070), 4326)::geography, '北京大学校园内', 4.4, 2, '08:00-22:00', v_spot, 'campus_curated', 'pku-curated:fac:20', '{"kind":"campus-curated-facility","near":"guanghua"}'::jsonb);
    INSERT INTO facilities (name, type, location, address, rating, price_level, opening_hours, scenic_spot_id, source, source_ref, source_tags)
    VALUES ('法学院服务点', 'service', ST_SetSRID(ST_MakePoint(116.3076595, 39.9932715), 4326)::geography, '北京大学校园内', 4.2, NULL, '08:00-22:00', v_spot, 'campus_curated', 'pku-curated:fac:21', '{"kind":"campus-curated-facility","near":"law"}'::jsonb);
    INSERT INTO facilities (name, type, location, address, rating, price_level, opening_hours, scenic_spot_id, source, source_ref, source_tags)
    VALUES ('东门便利店', 'shop', ST_SetSRID(ST_MakePoint(116.3120063, 39.9922626), 4326)::geography, '北京大学校园内', 4.1, 1, '08:00-22:00', v_spot, 'campus_curated', 'pku-curated:fac:22', '{"kind":"campus-curated-facility","near":"east_gate"}'::jsonb);
    INSERT INTO facilities (name, type, location, address, rating, price_level, opening_hours, scenic_spot_id, source, source_ref, source_tags)
    VALUES ('北门公共卫生间', 'toilet', ST_SetSRID(ST_MakePoint(116.3107808, 39.9904887), 4326)::geography, '北京大学校园内', 4.0, NULL, '08:00-22:00', v_spot, 'campus_curated', 'pku-curated:fac:23', '{"kind":"campus-curated-facility","near":"north_gate"}'::jsonb);
    INSERT INTO facilities (name, type, location, address, rating, price_level, opening_hours, scenic_spot_id, source, source_ref, source_tags)
    VALUES ('中关新园超市', 'shop', ST_SetSRID(ST_MakePoint(116.3073945, 39.9968688), 4326)::geography, '北京大学校园内', 4.2, 1, '08:00-22:00', v_spot, 'campus_curated', 'pku-curated:fac:24', '{"kind":"campus-curated-facility","near":"lakeview"}'::jsonb);
    INSERT INTO facilities (name, type, location, address, rating, price_level, opening_hours, scenic_spot_id, source, source_ref, source_tags)
    VALUES ('成府园食堂', 'restaurant', ST_SetSRID(ST_MakePoint(116.3068729, 39.9933217), 4326)::geography, '北京大学校园内', 4.1, 2, '08:00-22:00', v_spot, 'campus_curated', 'pku-curated:fac:25', '{"kind":"campus-curated-facility","near":"chengfu"}'::jsonb);
    INSERT INTO facilities (name, type, location, address, rating, price_level, opening_hours, scenic_spot_id, source, source_ref, source_tags)
    VALUES ('体育馆饮料售卖点', 'shop', ST_SetSRID(ST_MakePoint(116.3091396, 39.9872754), 4326)::geography, '北京大学校园内', 4.0, 1, '08:00-22:00', v_spot, 'campus_curated', 'pku-curated:fac:26', '{"kind":"campus-curated-facility","near":"gym"}'::jsonb);

    -- 2. 校园主路网节点
    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, congestion_level, source, source_ref, source_tags)
    VALUES ('西门', ST_SetSRID(ST_MakePoint(116.2985927, 39.9932960), 4326)::geography, 'entrance', v_spot, 2, 'campus_curated', 'pku-curated:node:west_gate', '{"kind":"campus-curated-waypoint","key":"west_gate"}'::jsonb);
    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, congestion_level, source, source_ref, source_tags)
    VALUES ('赛克勒考古与艺术博物馆', ST_SetSRID(ST_MakePoint(116.2997721, 39.9944351), 4326)::geography, 'building', v_spot, 2, 'campus_curated', 'pku-curated:node:sackler', '{"kind":"campus-curated-waypoint","key":"sackler"}'::jsonb);
    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, congestion_level, source, source_ref, source_tags)
    VALUES ('镜春园南路', ST_SetSRID(ST_MakePoint(116.3012961, 39.9946135), 4326)::geography, 'scenic', v_spot, 2, 'campus_curated', 'pku-curated:node:jingchun', '{"kind":"campus-curated-waypoint","key":"jingchun"}'::jsonb);
    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, congestion_level, source, source_ref, source_tags)
    VALUES ('朗润园东路', ST_SetSRID(ST_MakePoint(116.3047211, 39.9947539), 4326)::geography, 'scenic', v_spot, 2, 'campus_curated', 'pku-curated:node:langrun', '{"kind":"campus-curated-waypoint","key":"langrun"}'::jsonb);
    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, congestion_level, source, source_ref, source_tags)
    VALUES ('未名湖西岸', ST_SetSRID(ST_MakePoint(116.3005837, 39.9936661), 4326)::geography, 'scenic', v_spot, 3, 'campus_curated', 'pku-curated:node:weiming_west', '{"kind":"campus-curated-waypoint","key":"weiming_west"}'::jsonb);
    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, congestion_level, source, source_ref, source_tags)
    VALUES ('办公楼（贝公楼）', ST_SetSRID(ST_MakePoint(116.3004075, 39.9933434), 4326)::geography, 'building', v_spot, 2, 'campus_curated', 'pku-curated:node:admin', '{"kind":"campus-curated-waypoint","key":"admin"}'::jsonb);
    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, congestion_level, source, source_ref, source_tags)
    VALUES ('化学楼', ST_SetSRID(ST_MakePoint(116.2997763, 39.9923405), 4326)::geography, 'building', v_spot, 2, 'campus_curated', 'pku-curated:node:chemistry', '{"kind":"campus-curated-waypoint","key":"chemistry"}'::jsonb);
    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, congestion_level, source, source_ref, source_tags)
    VALUES ('校史馆', ST_SetSRID(ST_MakePoint(116.3000564, 39.9920253), 4326)::geography, 'building', v_spot, 2, 'campus_curated', 'pku-curated:node:history', '{"kind":"campus-curated-waypoint","key":"history"}'::jsonb);
    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, congestion_level, source, source_ref, source_tags)
    VALUES ('图书馆', ST_SetSRID(ST_MakePoint(116.3033211, 39.9915228), 4326)::geography, 'building', v_spot, 3, 'campus_curated', 'pku-curated:node:library', '{"kind":"campus-curated-waypoint","key":"library"}'::jsonb);
    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, congestion_level, source, source_ref, source_tags)
    VALUES ('第一教学楼', ST_SetSRID(ST_MakePoint(116.3043376, 39.9915470), 4326)::geography, 'building', v_spot, 3, 'campus_curated', 'pku-curated:node:first_teaching', '{"kind":"campus-curated-waypoint","key":"first_teaching"}'::jsonb);
    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, congestion_level, source, source_ref, source_tags)
    VALUES ('未名湖南路', ST_SetSRID(ST_MakePoint(116.3060249, 39.9918029), 4326)::geography, 'scenic', v_spot, 3, 'campus_curated', 'pku-curated:node:weiming_south', '{"kind":"campus-curated-waypoint","key":"weiming_south"}'::jsonb);
    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, congestion_level, source, source_ref, source_tags)
    VALUES ('博雅塔', ST_SetSRID(ST_MakePoint(116.3057830, 39.9926368), 4326)::geography, 'scenic', v_spot, 2, 'campus_curated', 'pku-curated:node:boya', '{"kind":"campus-curated-waypoint","key":"boya"}'::jsonb);
    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, congestion_level, source, source_ref, source_tags)
    VALUES ('未名湖东路', ST_SetSRID(ST_MakePoint(116.3051885, 39.9942375), 4326)::geography, 'scenic', v_spot, 2, 'campus_curated', 'pku-curated:node:weiming_east', '{"kind":"campus-curated-waypoint","key":"weiming_east"}'::jsonb);
    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, congestion_level, source, source_ref, source_tags)
    VALUES ('法学院（凯原楼）', ST_SetSRID(ST_MakePoint(116.3074497, 39.9932499), 4326)::geography, 'building', v_spot, 3, 'campus_curated', 'pku-curated:node:law', '{"kind":"campus-curated-waypoint","key":"law"}'::jsonb);
    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, congestion_level, source, source_ref, source_tags)
    VALUES ('光华管理学院', ST_SetSRID(ST_MakePoint(116.3071686, 39.9943315), 4326)::geography, 'building', v_spot, 3, 'campus_curated', 'pku-curated:node:guanghua', '{"kind":"campus-curated-waypoint","key":"guanghua"}'::jsonb);
    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, congestion_level, source, source_ref, source_tags)
    VALUES ('政府管理学院（廖凯原楼）', ST_SetSRID(ST_MakePoint(116.3084343, 39.9944704), 4326)::geography, 'building', v_spot, 2, 'campus_curated', 'pku-curated:node:government', '{"kind":"campus-curated-waypoint","key":"government"}'::jsonb);
    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, congestion_level, source, source_ref, source_tags)
    VALUES ('成府园', ST_SetSRID(ST_MakePoint(116.3070746, 39.9933710), 4326)::geography, 'scenic', v_spot, 2, 'campus_curated', 'pku-curated:node:chengfu', '{"kind":"campus-curated-waypoint","key":"chengfu"}'::jsonb);
    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, congestion_level, source, source_ref, source_tags)
    VALUES ('北大博雅国际酒店', ST_SetSRID(ST_MakePoint(116.3072893, 39.9967281), 4326)::geography, 'building', v_spot, 2, 'campus_curated', 'pku-curated:node:lakeview', '{"kind":"campus-curated-waypoint","key":"lakeview"}'::jsonb);
    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, congestion_level, source, source_ref, source_tags)
    VALUES ('北门', ST_SetSRID(ST_MakePoint(116.3107343, 39.9906469), 4326)::geography, 'entrance', v_spot, 2, 'campus_curated', 'pku-curated:node:north_gate', '{"kind":"campus-curated-waypoint","key":"north_gate"}'::jsonb);
    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, congestion_level, source, source_ref, source_tags)
    VALUES ('东门', ST_SetSRID(ST_MakePoint(116.3121800, 39.9921700), 4326)::geography, 'entrance', v_spot, 2, 'campus_curated', 'pku-curated:node:east_gate', '{"kind":"campus-curated-waypoint","key":"east_gate"}'::jsonb);
    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, congestion_level, source, source_ref, source_tags)
    VALUES ('理科教学楼', ST_SetSRID(ST_MakePoint(116.3071067, 39.9902876), 4326)::geography, 'building', v_spot, 4, 'campus_curated', 'pku-curated:node:science', '{"kind":"campus-curated-waypoint","key":"science"}'::jsonb);
    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, congestion_level, source, source_ref, source_tags)
    VALUES ('第二教学楼', ST_SetSRID(ST_MakePoint(116.3073140, 39.9882798), 4326)::geography, 'building', v_spot, 3, 'campus_curated', 'pku-curated:node:second_teaching', '{"kind":"campus-curated-waypoint","key":"second_teaching"}'::jsonb);
    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, congestion_level, source, source_ref, source_tags)
    VALUES ('第四教学楼', ST_SetSRID(ST_MakePoint(116.3080873, 39.9879980), 4326)::geography, 'building', v_spot, 2, 'campus_curated', 'pku-curated:node:fourth_teaching', '{"kind":"campus-curated-waypoint","key":"fourth_teaching"}'::jsonb);
    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, congestion_level, source, source_ref, source_tags)
    VALUES ('邱德拔体育馆', ST_SetSRID(ST_MakePoint(116.3089475, 39.9873434), 4326)::geography, 'building', v_spot, 2, 'campus_curated', 'pku-curated:node:gym', '{"kind":"campus-curated-waypoint","key":"gym"}'::jsonb);
    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, congestion_level, source, source_ref, source_tags)
    VALUES ('百周年纪念讲堂', ST_SetSRID(ST_MakePoint(116.3044872, 39.9885459), 4326)::geography, 'building', v_spot, 3, 'campus_curated', 'pku-curated:node:hall', '{"kind":"campus-curated-waypoint","key":"hall"}'::jsonb);
    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, congestion_level, source, source_ref, source_tags)
    VALUES ('农园餐厅', ST_SetSRID(ST_MakePoint(116.3060962, 39.9875268), 4326)::geography, 'building', v_spot, 4, 'campus_curated', 'pku-curated:node:nongyuan', '{"kind":"campus-curated-waypoint","key":"nongyuan"}'::jsonb);
    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, congestion_level, source, source_ref, source_tags)
    VALUES ('南门', ST_SetSRID(ST_MakePoint(116.3059500, 39.9860800), 4326)::geography, 'entrance', v_spot, 2, 'campus_curated', 'pku-curated:node:south_gate', '{"kind":"campus-curated-waypoint","key":"south_gate"}'::jsonb);
    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, congestion_level, source, source_ref, source_tags)
    VALUES ('校医院', ST_SetSRID(ST_MakePoint(116.3021076, 39.9893082), 4326)::geography, 'building', v_spot, 2, 'campus_curated', 'pku-curated:node:hospital', '{"kind":"campus-curated-waypoint","key":"hospital"}'::jsonb);
    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, congestion_level, source, source_ref, source_tags)
    VALUES ('勺园', ST_SetSRID(ST_MakePoint(116.2995321, 39.9904189), 4326)::geography, 'building', v_spot, 2, 'campus_curated', 'pku-curated:node:shao_yuan', '{"kind":"campus-curated-waypoint","key":"shao_yuan"}'::jsonb);

    -- 3. 设施对应路网节点
    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, facility_id, congestion_level, source, source_ref, source_tags)
    SELECT f.name, f.location, 'facility', v_spot, f.id, 2, 'campus_curated', 'pku-curated:facnode:0', '{"kind":"campus-curated-facility-node","near":"west_gate"}'::jsonb
    FROM facilities f WHERE f.source = 'campus_curated' AND f.source_ref = 'pku-curated:fac:0';
    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, facility_id, congestion_level, source, source_ref, source_tags)
    SELECT f.name, f.location, 'facility', v_spot, f.id, 2, 'campus_curated', 'pku-curated:facnode:1', '{"kind":"campus-curated-facility-node","near":"sackler"}'::jsonb
    FROM facilities f WHERE f.source = 'campus_curated' AND f.source_ref = 'pku-curated:fac:1';
    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, facility_id, congestion_level, source, source_ref, source_tags)
    SELECT f.name, f.location, 'facility', v_spot, f.id, 2, 'campus_curated', 'pku-curated:facnode:2', '{"kind":"campus-curated-facility-node","near":"weiming_west"}'::jsonb
    FROM facilities f WHERE f.source = 'campus_curated' AND f.source_ref = 'pku-curated:fac:2';
    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, facility_id, congestion_level, source, source_ref, source_tags)
    SELECT f.name, f.location, 'facility', v_spot, f.id, 2, 'campus_curated', 'pku-curated:facnode:3', '{"kind":"campus-curated-facility-node","near":"boya"}'::jsonb
    FROM facilities f WHERE f.source = 'campus_curated' AND f.source_ref = 'pku-curated:fac:3';
    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, facility_id, congestion_level, source, source_ref, source_tags)
    SELECT f.name, f.location, 'facility', v_spot, f.id, 2, 'campus_curated', 'pku-curated:facnode:4', '{"kind":"campus-curated-facility-node","near":"library"}'::jsonb
    FROM facilities f WHERE f.source = 'campus_curated' AND f.source_ref = 'pku-curated:fac:4';
    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, facility_id, congestion_level, source, source_ref, source_tags)
    SELECT f.name, f.location, 'facility', v_spot, f.id, 2, 'campus_curated', 'pku-curated:facnode:5', '{"kind":"campus-curated-facility-node","near":"library"}'::jsonb
    FROM facilities f WHERE f.source = 'campus_curated' AND f.source_ref = 'pku-curated:fac:5';
    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, facility_id, congestion_level, source, source_ref, source_tags)
    SELECT f.name, f.location, 'facility', v_spot, f.id, 2, 'campus_curated', 'pku-curated:facnode:6', '{"kind":"campus-curated-facility-node","near":"first_teaching"}'::jsonb
    FROM facilities f WHERE f.source = 'campus_curated' AND f.source_ref = 'pku-curated:fac:6';
    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, facility_id, congestion_level, source, source_ref, source_tags)
    SELECT f.name, f.location, 'facility', v_spot, f.id, 2, 'campus_curated', 'pku-curated:facnode:7', '{"kind":"campus-curated-facility-node","near":"science"}'::jsonb
    FROM facilities f WHERE f.source = 'campus_curated' AND f.source_ref = 'pku-curated:fac:7';
    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, facility_id, congestion_level, source, source_ref, source_tags)
    SELECT f.name, f.location, 'facility', v_spot, f.id, 2, 'campus_curated', 'pku-curated:facnode:8', '{"kind":"campus-curated-facility-node","near":"second_teaching"}'::jsonb
    FROM facilities f WHERE f.source = 'campus_curated' AND f.source_ref = 'pku-curated:fac:8';
    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, facility_id, congestion_level, source, source_ref, source_tags)
    SELECT f.name, f.location, 'facility', v_spot, f.id, 2, 'campus_curated', 'pku-curated:facnode:9', '{"kind":"campus-curated-facility-node","near":"hall"}'::jsonb
    FROM facilities f WHERE f.source = 'campus_curated' AND f.source_ref = 'pku-curated:fac:9';
    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, facility_id, congestion_level, source, source_ref, source_tags)
    SELECT f.name, f.location, 'facility', v_spot, f.id, 2, 'campus_curated', 'pku-curated:facnode:10', '{"kind":"campus-curated-facility-node","near":"hall"}'::jsonb
    FROM facilities f WHERE f.source = 'campus_curated' AND f.source_ref = 'pku-curated:fac:10';
    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, facility_id, congestion_level, source, source_ref, source_tags)
    SELECT f.name, f.location, 'facility', v_spot, f.id, 2, 'campus_curated', 'pku-curated:facnode:11', '{"kind":"campus-curated-facility-node","near":"nongyuan"}'::jsonb
    FROM facilities f WHERE f.source = 'campus_curated' AND f.source_ref = 'pku-curated:fac:11';
    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, facility_id, congestion_level, source, source_ref, source_tags)
    SELECT f.name, f.location, 'facility', v_spot, f.id, 2, 'campus_curated', 'pku-curated:facnode:12', '{"kind":"campus-curated-facility-node","near":"nongyuan"}'::jsonb
    FROM facilities f WHERE f.source = 'campus_curated' AND f.source_ref = 'pku-curated:fac:12';
    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, facility_id, congestion_level, source, source_ref, source_tags)
    SELECT f.name, f.location, 'facility', v_spot, f.id, 2, 'campus_curated', 'pku-curated:facnode:13', '{"kind":"campus-curated-facility-node","near":"south_gate"}'::jsonb
    FROM facilities f WHERE f.source = 'campus_curated' AND f.source_ref = 'pku-curated:fac:13';
    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, facility_id, congestion_level, source, source_ref, source_tags)
    SELECT f.name, f.location, 'facility', v_spot, f.id, 2, 'campus_curated', 'pku-curated:facnode:14', '{"kind":"campus-curated-facility-node","near":"hospital"}'::jsonb
    FROM facilities f WHERE f.source = 'campus_curated' AND f.source_ref = 'pku-curated:fac:14';
    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, facility_id, congestion_level, source, source_ref, source_tags)
    SELECT f.name, f.location, 'facility', v_spot, f.id, 2, 'campus_curated', 'pku-curated:facnode:15', '{"kind":"campus-curated-facility-node","near":"shao_yuan"}'::jsonb
    FROM facilities f WHERE f.source = 'campus_curated' AND f.source_ref = 'pku-curated:fac:15';
    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, facility_id, congestion_level, source, source_ref, source_tags)
    SELECT f.name, f.location, 'facility', v_spot, f.id, 2, 'campus_curated', 'pku-curated:facnode:16', '{"kind":"campus-curated-facility-node","near":"shao_yuan"}'::jsonb
    FROM facilities f WHERE f.source = 'campus_curated' AND f.source_ref = 'pku-curated:fac:16';
    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, facility_id, congestion_level, source, source_ref, source_tags)
    SELECT f.name, f.location, 'facility', v_spot, f.id, 2, 'campus_curated', 'pku-curated:facnode:17', '{"kind":"campus-curated-facility-node","near":"history"}'::jsonb
    FROM facilities f WHERE f.source = 'campus_curated' AND f.source_ref = 'pku-curated:fac:17';
    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, facility_id, congestion_level, source, source_ref, source_tags)
    SELECT f.name, f.location, 'facility', v_spot, f.id, 2, 'campus_curated', 'pku-curated:facnode:18', '{"kind":"campus-curated-facility-node","near":"admin"}'::jsonb
    FROM facilities f WHERE f.source = 'campus_curated' AND f.source_ref = 'pku-curated:fac:18';
    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, facility_id, congestion_level, source, source_ref, source_tags)
    SELECT f.name, f.location, 'facility', v_spot, f.id, 2, 'campus_curated', 'pku-curated:facnode:19', '{"kind":"campus-curated-facility-node","near":"chemistry"}'::jsonb
    FROM facilities f WHERE f.source = 'campus_curated' AND f.source_ref = 'pku-curated:fac:19';
    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, facility_id, congestion_level, source, source_ref, source_tags)
    SELECT f.name, f.location, 'facility', v_spot, f.id, 2, 'campus_curated', 'pku-curated:facnode:20', '{"kind":"campus-curated-facility-node","near":"guanghua"}'::jsonb
    FROM facilities f WHERE f.source = 'campus_curated' AND f.source_ref = 'pku-curated:fac:20';
    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, facility_id, congestion_level, source, source_ref, source_tags)
    SELECT f.name, f.location, 'facility', v_spot, f.id, 2, 'campus_curated', 'pku-curated:facnode:21', '{"kind":"campus-curated-facility-node","near":"law"}'::jsonb
    FROM facilities f WHERE f.source = 'campus_curated' AND f.source_ref = 'pku-curated:fac:21';
    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, facility_id, congestion_level, source, source_ref, source_tags)
    SELECT f.name, f.location, 'facility', v_spot, f.id, 2, 'campus_curated', 'pku-curated:facnode:22', '{"kind":"campus-curated-facility-node","near":"east_gate"}'::jsonb
    FROM facilities f WHERE f.source = 'campus_curated' AND f.source_ref = 'pku-curated:fac:22';
    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, facility_id, congestion_level, source, source_ref, source_tags)
    SELECT f.name, f.location, 'facility', v_spot, f.id, 2, 'campus_curated', 'pku-curated:facnode:23', '{"kind":"campus-curated-facility-node","near":"north_gate"}'::jsonb
    FROM facilities f WHERE f.source = 'campus_curated' AND f.source_ref = 'pku-curated:fac:23';
    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, facility_id, congestion_level, source, source_ref, source_tags)
    SELECT f.name, f.location, 'facility', v_spot, f.id, 2, 'campus_curated', 'pku-curated:facnode:24', '{"kind":"campus-curated-facility-node","near":"lakeview"}'::jsonb
    FROM facilities f WHERE f.source = 'campus_curated' AND f.source_ref = 'pku-curated:fac:24';
    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, facility_id, congestion_level, source, source_ref, source_tags)
    SELECT f.name, f.location, 'facility', v_spot, f.id, 2, 'campus_curated', 'pku-curated:facnode:25', '{"kind":"campus-curated-facility-node","near":"chengfu"}'::jsonb
    FROM facilities f WHERE f.source = 'campus_curated' AND f.source_ref = 'pku-curated:fac:25';
    INSERT INTO graph_nodes (name, location, node_type, scenic_spot_id, facility_id, congestion_level, source, source_ref, source_tags)
    SELECT f.name, f.location, 'facility', v_spot, f.id, 2, 'campus_curated', 'pku-curated:facnode:26', '{"kind":"campus-curated-facility-node","near":"gym"}'::jsonb
    FROM facilities f WHERE f.source = 'campus_curated' AND f.source_ref = 'pku-curated:fac:26';

    -- 4. 校园主路网道路边（双向，source='campus_curated'）
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, 161.39, 'walk', 134, 1.61, 2, ST_GeogFromText('SRID=4326;LINESTRING(116.2985927 39.9932960, 116.2997721 39.9944351)'), 'campus_curated', 'pku-curated:edge:west_gate:sackler', '{"kind":"campus-curated-road","congestionLevel":2}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:node:west_gate' AND nb.source_ref = 'pku-curated:node:sackler';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, 161.39, 'walk', 134, 1.61, 2, ST_GeogFromText('SRID=4326;LINESTRING(116.2997721 39.9944351, 116.2985927 39.9932960)'), 'campus_curated', 'pku-curated:edge:sackler:west_gate:reverse', '{"kind":"campus-curated-road","congestionLevel":2}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:node:sackler' AND nb.source_ref = 'pku-curated:node:west_gate';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, 131.11, 'walk', 109, 1.31, 2, ST_GeogFromText('SRID=4326;LINESTRING(116.2997721 39.9944351, 116.3012961 39.9946135)'), 'campus_curated', 'pku-curated:edge:sackler:jingchun', '{"kind":"campus-curated-road","congestionLevel":2}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:node:sackler' AND nb.source_ref = 'pku-curated:node:jingchun';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, 131.11, 'walk', 109, 1.31, 2, ST_GeogFromText('SRID=4326;LINESTRING(116.3012961 39.9946135, 116.2997721 39.9944351)'), 'campus_curated', 'pku-curated:edge:jingchun:sackler:reverse', '{"kind":"campus-curated-road","congestionLevel":2}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:node:jingchun' AND nb.source_ref = 'pku-curated:node:sackler';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, 291.68, 'walk', 243, 2.92, 2, ST_GeogFromText('SRID=4326;LINESTRING(116.3012961 39.9946135, 116.3047211 39.9947539)'), 'campus_curated', 'pku-curated:edge:jingchun:langrun', '{"kind":"campus-curated-road","congestionLevel":2}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:node:jingchun' AND nb.source_ref = 'pku-curated:node:langrun';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, 291.68, 'walk', 243, 2.92, 2, ST_GeogFromText('SRID=4326;LINESTRING(116.3047211 39.9947539, 116.3012961 39.9946135)'), 'campus_curated', 'pku-curated:edge:langrun:jingchun:reverse', '{"kind":"campus-curated-road","congestionLevel":2}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:node:langrun' AND nb.source_ref = 'pku-curated:node:jingchun';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, 121.36, 'walk', 101, 1.21, 2, ST_GeogFromText('SRID=4326;LINESTRING(116.3012961 39.9946135, 116.3005837 39.9936661)'), 'campus_curated', 'pku-curated:edge:jingchun:weiming_west', '{"kind":"campus-curated-road","congestionLevel":2}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:node:jingchun' AND nb.source_ref = 'pku-curated:node:weiming_west';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, 121.36, 'walk', 101, 1.21, 2, ST_GeogFromText('SRID=4326;LINESTRING(116.3005837 39.9936661, 116.3012961 39.9946135)'), 'campus_curated', 'pku-curated:edge:weiming_west:jingchun:reverse', '{"kind":"campus-curated-road","congestionLevel":2}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:node:weiming_west' AND nb.source_ref = 'pku-curated:node:jingchun';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, 38.83, 'walk', 39, 1.00, 3, ST_GeogFromText('SRID=4326;LINESTRING(116.3005837 39.9936661, 116.3004075 39.9933434)'), 'campus_curated', 'pku-curated:edge:weiming_west:admin', '{"kind":"campus-curated-road","congestionLevel":3}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:node:weiming_west' AND nb.source_ref = 'pku-curated:node:admin';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, 38.83, 'walk', 39, 1.00, 3, ST_GeogFromText('SRID=4326;LINESTRING(116.3004075 39.9933434, 116.3005837 39.9936661)'), 'campus_curated', 'pku-curated:edge:admin:weiming_west:reverse', '{"kind":"campus-curated-road","congestionLevel":3}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:node:admin' AND nb.source_ref = 'pku-curated:node:weiming_west';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, 149.32, 'walk', 124, 1.49, 2, ST_GeogFromText('SRID=4326;LINESTRING(116.3004075 39.9933434, 116.3000564 39.9920253)'), 'campus_curated', 'pku-curated:edge:admin:history', '{"kind":"campus-curated-road","congestionLevel":2}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:node:admin' AND nb.source_ref = 'pku-curated:node:history';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, 149.32, 'walk', 124, 1.49, 2, ST_GeogFromText('SRID=4326;LINESTRING(116.3000564 39.9920253, 116.3004075 39.9933434)'), 'campus_curated', 'pku-curated:edge:history:admin:reverse', '{"kind":"campus-curated-road","congestionLevel":2}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:node:history' AND nb.source_ref = 'pku-curated:node:admin';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, 42.33, 'walk', 35, 1.00, 2, ST_GeogFromText('SRID=4326;LINESTRING(116.3000564 39.9920253, 116.2997763 39.9923405)'), 'campus_curated', 'pku-curated:edge:history:chemistry', '{"kind":"campus-curated-road","congestionLevel":2}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:node:history' AND nb.source_ref = 'pku-curated:node:chemistry';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, 42.33, 'walk', 35, 1.00, 2, ST_GeogFromText('SRID=4326;LINESTRING(116.2997763 39.9923405, 116.3000564 39.9920253)'), 'campus_curated', 'pku-curated:edge:chemistry:history:reverse', '{"kind":"campus-curated-road","congestionLevel":2}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:node:chemistry' AND nb.source_ref = 'pku-curated:node:history';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, 314.82, 'walk', 262, 3.15, 2, ST_GeogFromText('SRID=4326;LINESTRING(116.2997763 39.9923405, 116.3033211 39.9915228)'), 'campus_curated', 'pku-curated:edge:chemistry:library', '{"kind":"campus-curated-road","congestionLevel":2}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:node:chemistry' AND nb.source_ref = 'pku-curated:node:library';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, 314.82, 'walk', 262, 3.15, 2, ST_GeogFromText('SRID=4326;LINESTRING(116.3033211 39.9915228, 116.2997763 39.9923405)'), 'campus_curated', 'pku-curated:edge:library:chemistry:reverse', '{"kind":"campus-curated-road","congestionLevel":2}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:node:library' AND nb.source_ref = 'pku-curated:node:chemistry';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, 86.49, 'walk', 86, 1.00, 3, ST_GeogFromText('SRID=4326;LINESTRING(116.3033211 39.9915228, 116.3043376 39.9915470)'), 'campus_curated', 'pku-curated:edge:library:first_teaching', '{"kind":"campus-curated-road","congestionLevel":3}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:node:library' AND nb.source_ref = 'pku-curated:node:first_teaching';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, 86.49, 'walk', 86, 1.00, 3, ST_GeogFromText('SRID=4326;LINESTRING(116.3043376 39.9915470, 116.3033211 39.9915228)'), 'campus_curated', 'pku-curated:edge:first_teaching:library:reverse', '{"kind":"campus-curated-road","congestionLevel":3}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:node:first_teaching' AND nb.source_ref = 'pku-curated:node:library';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, 146.27, 'walk', 146, 1.46, 3, ST_GeogFromText('SRID=4326;LINESTRING(116.3043376 39.9915470, 116.3060249 39.9918029)'), 'campus_curated', 'pku-curated:edge:first_teaching:weiming_south', '{"kind":"campus-curated-road","congestionLevel":3}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:node:first_teaching' AND nb.source_ref = 'pku-curated:node:weiming_south';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, 146.27, 'walk', 146, 1.46, 3, ST_GeogFromText('SRID=4326;LINESTRING(116.3060249 39.9918029, 116.3043376 39.9915470)'), 'campus_curated', 'pku-curated:edge:weiming_south:first_teaching:reverse', '{"kind":"campus-curated-road","congestionLevel":3}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:node:weiming_south' AND nb.source_ref = 'pku-curated:node:first_teaching';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, 94.82, 'walk', 79, 1.00, 2, ST_GeogFromText('SRID=4326;LINESTRING(116.3060249 39.9918029, 116.3057830 39.9926368)'), 'campus_curated', 'pku-curated:edge:weiming_south:boya', '{"kind":"campus-curated-road","congestionLevel":2}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:node:weiming_south' AND nb.source_ref = 'pku-curated:node:boya';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, 94.82, 'walk', 79, 1.00, 2, ST_GeogFromText('SRID=4326;LINESTRING(116.3057830 39.9926368, 116.3060249 39.9918029)'), 'campus_curated', 'pku-curated:edge:boya:weiming_south:reverse', '{"kind":"campus-curated-road","congestionLevel":2}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:node:boya' AND nb.source_ref = 'pku-curated:node:weiming_south';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, 184.73, 'walk', 154, 1.85, 2, ST_GeogFromText('SRID=4326;LINESTRING(116.3057830 39.9926368, 116.3051885 39.9942375)'), 'campus_curated', 'pku-curated:edge:boya:weiming_east', '{"kind":"campus-curated-road","congestionLevel":2}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:node:boya' AND nb.source_ref = 'pku-curated:node:weiming_east';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, 184.73, 'walk', 154, 1.85, 2, ST_GeogFromText('SRID=4326;LINESTRING(116.3051885 39.9942375, 116.3057830 39.9926368)'), 'campus_curated', 'pku-curated:edge:weiming_east:boya:reverse', '{"kind":"campus-curated-road","congestionLevel":2}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:node:weiming_east' AND nb.source_ref = 'pku-curated:node:boya';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, 69.75, 'walk', 58, 1.00, 2, ST_GeogFromText('SRID=4326;LINESTRING(116.3051885 39.9942375, 116.3047211 39.9947539)'), 'campus_curated', 'pku-curated:edge:weiming_east:langrun', '{"kind":"campus-curated-road","congestionLevel":2}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:node:weiming_east' AND nb.source_ref = 'pku-curated:node:langrun';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, 69.75, 'walk', 58, 1.00, 2, ST_GeogFromText('SRID=4326;LINESTRING(116.3047211 39.9947539, 116.3051885 39.9942375)'), 'campus_curated', 'pku-curated:edge:langrun:weiming_east:reverse', '{"kind":"campus-curated-road","congestionLevel":2}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:node:langrun' AND nb.source_ref = 'pku-curated:node:weiming_east';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, 168.71, 'walk', 169, 1.69, 3, ST_GeogFromText('SRID=4326;LINESTRING(116.3051885 39.9942375, 116.3071686 39.9943315)'), 'campus_curated', 'pku-curated:edge:weiming_east:guanghua', '{"kind":"campus-curated-road","congestionLevel":3}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:node:weiming_east' AND nb.source_ref = 'pku-curated:node:guanghua';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, 168.71, 'walk', 169, 1.69, 3, ST_GeogFromText('SRID=4326;LINESTRING(116.3071686 39.9943315, 116.3051885 39.9942375)'), 'campus_curated', 'pku-curated:edge:guanghua:weiming_east:reverse', '{"kind":"campus-curated-road","congestionLevel":3}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:node:guanghua' AND nb.source_ref = 'pku-curated:node:weiming_east';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, 108.73, 'walk', 109, 1.09, 3, ST_GeogFromText('SRID=4326;LINESTRING(116.3071686 39.9943315, 116.3084343 39.9944704)'), 'campus_curated', 'pku-curated:edge:guanghua:government', '{"kind":"campus-curated-road","congestionLevel":3}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:node:guanghua' AND nb.source_ref = 'pku-curated:node:government';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, 108.73, 'walk', 109, 1.09, 3, ST_GeogFromText('SRID=4326;LINESTRING(116.3084343 39.9944704, 116.3071686 39.9943315)'), 'campus_curated', 'pku-curated:edge:government:guanghua:reverse', '{"kind":"campus-curated-road","congestionLevel":3}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:node:government' AND nb.source_ref = 'pku-curated:node:guanghua';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, 168.11, 'walk', 140, 1.68, 2, ST_GeogFromText('SRID=4326;LINESTRING(116.3084343 39.9944704, 116.3070746 39.9933710)'), 'campus_curated', 'pku-curated:edge:government:chengfu', '{"kind":"campus-curated-road","congestionLevel":2}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:node:government' AND nb.source_ref = 'pku-curated:node:chengfu';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, 168.11, 'walk', 140, 1.68, 2, ST_GeogFromText('SRID=4326;LINESTRING(116.3070746 39.9933710, 116.3084343 39.9944704)'), 'campus_curated', 'pku-curated:edge:chengfu:government:reverse', '{"kind":"campus-curated-road","congestionLevel":2}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:node:chengfu' AND nb.source_ref = 'pku-curated:node:government';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, 454.17, 'walk', 378, 4.54, 2, ST_GeogFromText('SRID=4326;LINESTRING(116.3070746 39.9933710, 116.3121800 39.9921700)'), 'campus_curated', 'pku-curated:edge:chengfu:east_gate', '{"kind":"campus-curated-road","congestionLevel":2}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:node:chengfu' AND nb.source_ref = 'pku-curated:node:east_gate';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, 454.17, 'walk', 378, 4.54, 2, ST_GeogFromText('SRID=4326;LINESTRING(116.3121800 39.9921700, 116.3070746 39.9933710)'), 'campus_curated', 'pku-curated:edge:east_gate:chengfu:reverse', '{"kind":"campus-curated-road","congestionLevel":2}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:node:east_gate' AND nb.source_ref = 'pku-curated:node:chengfu';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, 268.86, 'walk', 224, 2.69, 2, ST_GeogFromText('SRID=4326;LINESTRING(116.3084343 39.9944704, 116.3072893 39.9967281)'), 'campus_curated', 'pku-curated:edge:government:lakeview', '{"kind":"campus-curated-road","congestionLevel":2}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:node:government' AND nb.source_ref = 'pku-curated:node:lakeview';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, 268.86, 'walk', 224, 2.69, 2, ST_GeogFromText('SRID=4326;LINESTRING(116.3072893 39.9967281, 116.3084343 39.9944704)'), 'campus_curated', 'pku-curated:edge:lakeview:government:reverse', '{"kind":"campus-curated-road","congestionLevel":2}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:node:lakeview' AND nb.source_ref = 'pku-curated:node:government';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, 735.85, 'walk', 613, 7.36, 2, ST_GeogFromText('SRID=4326;LINESTRING(116.3072893 39.9967281, 116.3107343 39.9906469)'), 'campus_curated', 'pku-curated:edge:lakeview:north_gate', '{"kind":"campus-curated-road","congestionLevel":2}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:node:lakeview' AND nb.source_ref = 'pku-curated:node:north_gate';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, 735.85, 'walk', 613, 7.36, 2, ST_GeogFromText('SRID=4326;LINESTRING(116.3107343 39.9906469, 116.3072893 39.9967281)'), 'campus_curated', 'pku-curated:edge:north_gate:lakeview:reverse', '{"kind":"campus-curated-road","congestionLevel":2}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:node:north_gate' AND nb.source_ref = 'pku-curated:node:lakeview';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, 221.35, 'walk', 221, 2.21, 3, ST_GeogFromText('SRID=4326;LINESTRING(116.3051885 39.9942375, 116.3074497 39.9932499)'), 'campus_curated', 'pku-curated:edge:weiming_east:law', '{"kind":"campus-curated-road","congestionLevel":3}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:node:weiming_east' AND nb.source_ref = 'pku-curated:node:law';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, 221.35, 'walk', 221, 2.21, 3, ST_GeogFromText('SRID=4326;LINESTRING(116.3074497 39.9932499, 116.3051885 39.9942375)'), 'campus_curated', 'pku-curated:edge:law:weiming_east:reverse', '{"kind":"campus-curated-road","congestionLevel":3}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:node:law' AND nb.source_ref = 'pku-curated:node:weiming_east';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, 34.62, 'walk', 35, 1.00, 3, ST_GeogFromText('SRID=4326;LINESTRING(116.3074497 39.9932499, 116.3070746 39.9933710)'), 'campus_curated', 'pku-curated:edge:law:chengfu', '{"kind":"campus-curated-road","congestionLevel":3}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:node:law' AND nb.source_ref = 'pku-curated:node:chengfu';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, 34.62, 'walk', 35, 1.00, 3, ST_GeogFromText('SRID=4326;LINESTRING(116.3070746 39.9933710, 116.3074497 39.9932499)'), 'campus_curated', 'pku-curated:edge:chengfu:law:reverse', '{"kind":"campus-curated-road","congestionLevel":3}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:node:chengfu' AND nb.source_ref = 'pku-curated:node:law';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, 349.91, 'walk', 449, 3.50, 4, ST_GeogFromText('SRID=4326;LINESTRING(116.3033211 39.9915228, 116.3071067 39.9902876)'), 'campus_curated', 'pku-curated:edge:library:science', '{"kind":"campus-curated-road","congestionLevel":4}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:node:library' AND nb.source_ref = 'pku-curated:node:science';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, 349.91, 'walk', 449, 3.50, 4, ST_GeogFromText('SRID=4326;LINESTRING(116.3071067 39.9902876, 116.3033211 39.9915228)'), 'campus_curated', 'pku-curated:edge:science:library:reverse', '{"kind":"campus-curated-road","congestionLevel":4}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:node:science' AND nb.source_ref = 'pku-curated:node:library';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, 223.56, 'walk', 287, 2.24, 4, ST_GeogFromText('SRID=4326;LINESTRING(116.3071067 39.9902876, 116.3073140 39.9882798)'), 'campus_curated', 'pku-curated:edge:science:second_teaching', '{"kind":"campus-curated-road","congestionLevel":4}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:node:science' AND nb.source_ref = 'pku-curated:node:second_teaching';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, 223.56, 'walk', 287, 2.24, 4, ST_GeogFromText('SRID=4326;LINESTRING(116.3073140 39.9882798, 116.3071067 39.9902876)'), 'campus_curated', 'pku-curated:edge:second_teaching:science:reverse', '{"kind":"campus-curated-road","congestionLevel":4}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:node:second_teaching' AND nb.source_ref = 'pku-curated:node:science';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, 72.82, 'walk', 61, 1.00, 2, ST_GeogFromText('SRID=4326;LINESTRING(116.3073140 39.9882798, 116.3080873 39.9879980)'), 'campus_curated', 'pku-curated:edge:second_teaching:fourth_teaching', '{"kind":"campus-curated-road","congestionLevel":2}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:node:second_teaching' AND nb.source_ref = 'pku-curated:node:fourth_teaching';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, 72.82, 'walk', 61, 1.00, 2, ST_GeogFromText('SRID=4326;LINESTRING(116.3080873 39.9879980, 116.3073140 39.9882798)'), 'campus_curated', 'pku-curated:edge:fourth_teaching:second_teaching:reverse', '{"kind":"campus-curated-road","congestionLevel":2}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:node:fourth_teaching' AND nb.source_ref = 'pku-curated:node:second_teaching';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, 103.11, 'walk', 86, 1.03, 2, ST_GeogFromText('SRID=4326;LINESTRING(116.3080873 39.9879980, 116.3089475 39.9873434)'), 'campus_curated', 'pku-curated:edge:fourth_teaching:gym', '{"kind":"campus-curated-road","congestionLevel":2}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:node:fourth_teaching' AND nb.source_ref = 'pku-curated:node:gym';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, 103.11, 'walk', 86, 1.03, 2, ST_GeogFromText('SRID=4326;LINESTRING(116.3089475 39.9873434, 116.3080873 39.9879980)'), 'campus_curated', 'pku-curated:edge:gym:fourth_teaching:reverse', '{"kind":"campus-curated-road","congestionLevel":2}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:node:gym' AND nb.source_ref = 'pku-curated:node:fourth_teaching';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, 290.94, 'walk', 242, 2.91, 2, ST_GeogFromText('SRID=4326;LINESTRING(116.3089475 39.9873434, 116.3059500 39.9860800)'), 'campus_curated', 'pku-curated:edge:gym:south_gate', '{"kind":"campus-curated-road","congestionLevel":2}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:node:gym' AND nb.source_ref = 'pku-curated:node:south_gate';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, 290.94, 'walk', 242, 2.91, 2, ST_GeogFromText('SRID=4326;LINESTRING(116.3059500 39.9860800, 116.3089475 39.9873434)'), 'campus_curated', 'pku-curated:edge:south_gate:gym:reverse', '{"kind":"campus-curated-road","congestionLevel":2}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:node:south_gate' AND nb.source_ref = 'pku-curated:node:gym';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, 242.20, 'walk', 242, 2.42, 3, ST_GeogFromText('SRID=4326;LINESTRING(116.3073140 39.9882798, 116.3044872 39.9885459)'), 'campus_curated', 'pku-curated:edge:second_teaching:hall', '{"kind":"campus-curated-road","congestionLevel":3}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:node:second_teaching' AND nb.source_ref = 'pku-curated:node:hall';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, 242.20, 'walk', 242, 2.42, 3, ST_GeogFromText('SRID=4326;LINESTRING(116.3044872 39.9885459, 116.3073140 39.9882798)'), 'campus_curated', 'pku-curated:edge:hall:second_teaching:reverse', '{"kind":"campus-curated-road","congestionLevel":3}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:node:hall' AND nb.source_ref = 'pku-curated:node:second_teaching';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, 177.54, 'walk', 228, 1.78, 4, ST_GeogFromText('SRID=4326;LINESTRING(116.3044872 39.9885459, 116.3060962 39.9875268)'), 'campus_curated', 'pku-curated:edge:hall:nongyuan', '{"kind":"campus-curated-road","congestionLevel":4}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:node:hall' AND nb.source_ref = 'pku-curated:node:nongyuan';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, 177.54, 'walk', 228, 1.78, 4, ST_GeogFromText('SRID=4326;LINESTRING(116.3060962 39.9875268, 116.3044872 39.9885459)'), 'campus_curated', 'pku-curated:edge:nongyuan:hall:reverse', '{"kind":"campus-curated-road","congestionLevel":4}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:node:nongyuan' AND nb.source_ref = 'pku-curated:node:hall';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, 161.08, 'walk', 161, 1.61, 3, ST_GeogFromText('SRID=4326;LINESTRING(116.3060962 39.9875268, 116.3059500 39.9860800)'), 'campus_curated', 'pku-curated:edge:nongyuan:south_gate', '{"kind":"campus-curated-road","congestionLevel":3}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:node:nongyuan' AND nb.source_ref = 'pku-curated:node:south_gate';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, 161.08, 'walk', 161, 1.61, 3, ST_GeogFromText('SRID=4326;LINESTRING(116.3059500 39.9860800, 116.3060962 39.9875268)'), 'campus_curated', 'pku-curated:edge:south_gate:nongyuan:reverse', '{"kind":"campus-curated-road","congestionLevel":3}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:node:south_gate' AND nb.source_ref = 'pku-curated:node:nongyuan';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, 219.34, 'walk', 183, 2.19, 2, ST_GeogFromText('SRID=4326;LINESTRING(116.3044872 39.9885459, 116.3021076 39.9893082)'), 'campus_curated', 'pku-curated:edge:hall:hospital', '{"kind":"campus-curated-road","congestionLevel":2}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:node:hall' AND nb.source_ref = 'pku-curated:node:hospital';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, 219.34, 'walk', 183, 2.19, 2, ST_GeogFromText('SRID=4326;LINESTRING(116.3021076 39.9893082, 116.3044872 39.9885459)'), 'campus_curated', 'pku-curated:edge:hospital:hall:reverse', '{"kind":"campus-curated-road","congestionLevel":2}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:node:hospital' AND nb.source_ref = 'pku-curated:node:hall';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, 251.34, 'walk', 209, 2.51, 2, ST_GeogFromText('SRID=4326;LINESTRING(116.3021076 39.9893082, 116.2995321 39.9904189)'), 'campus_curated', 'pku-curated:edge:hospital:shao_yuan', '{"kind":"campus-curated-road","congestionLevel":2}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:node:hospital' AND nb.source_ref = 'pku-curated:node:shao_yuan';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, 251.34, 'walk', 209, 2.51, 2, ST_GeogFromText('SRID=4326;LINESTRING(116.2995321 39.9904189, 116.3021076 39.9893082)'), 'campus_curated', 'pku-curated:edge:shao_yuan:hospital:reverse', '{"kind":"campus-curated-road","congestionLevel":2}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:node:shao_yuan' AND nb.source_ref = 'pku-curated:node:hospital';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, 329.20, 'walk', 274, 3.29, 2, ST_GeogFromText('SRID=4326;LINESTRING(116.2995321 39.9904189, 116.2985927 39.9932960)'), 'campus_curated', 'pku-curated:edge:shao_yuan:west_gate', '{"kind":"campus-curated-road","congestionLevel":2}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:node:shao_yuan' AND nb.source_ref = 'pku-curated:node:west_gate';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, 329.20, 'walk', 274, 3.29, 2, ST_GeogFromText('SRID=4326;LINESTRING(116.2985927 39.9932960, 116.2995321 39.9904189)'), 'campus_curated', 'pku-curated:edge:west_gate:shao_yuan:reverse', '{"kind":"campus-curated-road","congestionLevel":2}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:node:west_gate' AND nb.source_ref = 'pku-curated:node:shao_yuan';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, 333.05, 'walk', 278, 3.33, 2, ST_GeogFromText('SRID=4326;LINESTRING(116.3004075 39.9933434, 116.2995321 39.9904189)'), 'campus_curated', 'pku-curated:edge:admin:shao_yuan', '{"kind":"campus-curated-road","congestionLevel":2}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:node:admin' AND nb.source_ref = 'pku-curated:node:shao_yuan';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, 333.05, 'walk', 278, 3.33, 2, ST_GeogFromText('SRID=4326;LINESTRING(116.2995321 39.9904189, 116.3004075 39.9933434)'), 'campus_curated', 'pku-curated:edge:shao_yuan:admin:reverse', '{"kind":"campus-curated-road","congestionLevel":2}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:node:shao_yuan' AND nb.source_ref = 'pku-curated:node:admin';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, 319.74, 'walk', 320, 3.20, 3, ST_GeogFromText('SRID=4326;LINESTRING(116.3004075 39.9933434, 116.3033211 39.9915228)'), 'campus_curated', 'pku-curated:edge:admin:library', '{"kind":"campus-curated-road","congestionLevel":3}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:node:admin' AND nb.source_ref = 'pku-curated:node:library';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, 319.74, 'walk', 320, 3.20, 3, ST_GeogFromText('SRID=4326;LINESTRING(116.3033211 39.9915228, 116.3004075 39.9933434)'), 'campus_curated', 'pku-curated:edge:library:admin:reverse', '{"kind":"campus-curated-road","congestionLevel":3}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:node:library' AND nb.source_ref = 'pku-curated:node:admin';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, 172.46, 'walk', 172, 1.72, 3, ST_GeogFromText('SRID=4326;LINESTRING(116.3043376 39.9915470, 116.3057830 39.9926368)'), 'campus_curated', 'pku-curated:edge:first_teaching:boya', '{"kind":"campus-curated-road","congestionLevel":3}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:node:first_teaching' AND nb.source_ref = 'pku-curated:node:boya';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, 172.46, 'walk', 172, 1.72, 3, ST_GeogFromText('SRID=4326;LINESTRING(116.3057830 39.9926368, 116.3043376 39.9915470)'), 'campus_curated', 'pku-curated:edge:boya:first_teaching:reverse', '{"kind":"campus-curated-road","congestionLevel":3}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:node:boya' AND nb.source_ref = 'pku-curated:node:first_teaching';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, 479.37, 'walk', 479, 4.79, 3, ST_GeogFromText('SRID=4326;LINESTRING(116.3071067 39.9902876, 116.3121800 39.9921700)'), 'campus_curated', 'pku-curated:edge:science:east_gate', '{"kind":"campus-curated-road","congestionLevel":3}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:node:science' AND nb.source_ref = 'pku-curated:node:east_gate';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, 479.37, 'walk', 479, 4.79, 3, ST_GeogFromText('SRID=4326;LINESTRING(116.3121800 39.9921700, 116.3071067 39.9902876)'), 'campus_curated', 'pku-curated:edge:east_gate:science:reverse', '{"kind":"campus-curated-road","congestionLevel":3}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:node:east_gate' AND nb.source_ref = 'pku-curated:node:science';

    -- 5. 设施接入边（双向短边，source='generated'）
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, GREATEST(ST_Distance(na.location, nb.location), 1), 'walk', GREATEST(CEIL(ST_Distance(na.location, nb.location) / 1.2)::int, 1), GREATEST(ST_Distance(na.location, nb.location) / 100.0, 1), 2, ST_MakeLine(na.location::geometry, nb.location::geometry)::geography, 'generated', 'pku-curated:connector:0:to-road', '{"kind":"facility-road-connector","curatedSource":"pku-curated","maxDistanceMeters":18.0}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:facnode:0' AND nb.source_ref = 'pku-curated:node:west_gate';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, GREATEST(ST_Distance(na.location, nb.location), 1), 'walk', GREATEST(CEIL(ST_Distance(na.location, nb.location) / 1.2)::int, 1), GREATEST(ST_Distance(na.location, nb.location) / 100.0, 1), 2, ST_MakeLine(na.location::geometry, nb.location::geometry)::geography, 'generated', 'pku-curated:connector:0:to-facility', '{"kind":"facility-road-connector","curatedSource":"pku-curated","maxDistanceMeters":18.0}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:node:west_gate' AND nb.source_ref = 'pku-curated:facnode:0';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, GREATEST(ST_Distance(na.location, nb.location), 1), 'walk', GREATEST(CEIL(ST_Distance(na.location, nb.location) / 1.2)::int, 1), GREATEST(ST_Distance(na.location, nb.location) / 100.0, 1), 2, ST_MakeLine(na.location::geometry, nb.location::geometry)::geography, 'generated', 'pku-curated:connector:1:to-road', '{"kind":"facility-road-connector","curatedSource":"pku-curated","maxDistanceMeters":18.0}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:facnode:1' AND nb.source_ref = 'pku-curated:node:sackler';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, GREATEST(ST_Distance(na.location, nb.location), 1), 'walk', GREATEST(CEIL(ST_Distance(na.location, nb.location) / 1.2)::int, 1), GREATEST(ST_Distance(na.location, nb.location) / 100.0, 1), 2, ST_MakeLine(na.location::geometry, nb.location::geometry)::geography, 'generated', 'pku-curated:connector:1:to-facility', '{"kind":"facility-road-connector","curatedSource":"pku-curated","maxDistanceMeters":18.0}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:node:sackler' AND nb.source_ref = 'pku-curated:facnode:1';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, GREATEST(ST_Distance(na.location, nb.location), 1), 'walk', GREATEST(CEIL(ST_Distance(na.location, nb.location) / 1.2)::int, 1), GREATEST(ST_Distance(na.location, nb.location) / 100.0, 1), 2, ST_MakeLine(na.location::geometry, nb.location::geometry)::geography, 'generated', 'pku-curated:connector:2:to-road', '{"kind":"facility-road-connector","curatedSource":"pku-curated","maxDistanceMeters":18.0}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:facnode:2' AND nb.source_ref = 'pku-curated:node:weiming_west';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, GREATEST(ST_Distance(na.location, nb.location), 1), 'walk', GREATEST(CEIL(ST_Distance(na.location, nb.location) / 1.2)::int, 1), GREATEST(ST_Distance(na.location, nb.location) / 100.0, 1), 2, ST_MakeLine(na.location::geometry, nb.location::geometry)::geography, 'generated', 'pku-curated:connector:2:to-facility', '{"kind":"facility-road-connector","curatedSource":"pku-curated","maxDistanceMeters":18.0}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:node:weiming_west' AND nb.source_ref = 'pku-curated:facnode:2';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, GREATEST(ST_Distance(na.location, nb.location), 1), 'walk', GREATEST(CEIL(ST_Distance(na.location, nb.location) / 1.2)::int, 1), GREATEST(ST_Distance(na.location, nb.location) / 100.0, 1), 2, ST_MakeLine(na.location::geometry, nb.location::geometry)::geography, 'generated', 'pku-curated:connector:3:to-road', '{"kind":"facility-road-connector","curatedSource":"pku-curated","maxDistanceMeters":18.0}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:facnode:3' AND nb.source_ref = 'pku-curated:node:boya';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, GREATEST(ST_Distance(na.location, nb.location), 1), 'walk', GREATEST(CEIL(ST_Distance(na.location, nb.location) / 1.2)::int, 1), GREATEST(ST_Distance(na.location, nb.location) / 100.0, 1), 2, ST_MakeLine(na.location::geometry, nb.location::geometry)::geography, 'generated', 'pku-curated:connector:3:to-facility', '{"kind":"facility-road-connector","curatedSource":"pku-curated","maxDistanceMeters":18.0}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:node:boya' AND nb.source_ref = 'pku-curated:facnode:3';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, GREATEST(ST_Distance(na.location, nb.location), 1), 'walk', GREATEST(CEIL(ST_Distance(na.location, nb.location) / 1.2)::int, 1), GREATEST(ST_Distance(na.location, nb.location) / 100.0, 1), 2, ST_MakeLine(na.location::geometry, nb.location::geometry)::geography, 'generated', 'pku-curated:connector:4:to-road', '{"kind":"facility-road-connector","curatedSource":"pku-curated","maxDistanceMeters":18.0}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:facnode:4' AND nb.source_ref = 'pku-curated:node:library';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, GREATEST(ST_Distance(na.location, nb.location), 1), 'walk', GREATEST(CEIL(ST_Distance(na.location, nb.location) / 1.2)::int, 1), GREATEST(ST_Distance(na.location, nb.location) / 100.0, 1), 2, ST_MakeLine(na.location::geometry, nb.location::geometry)::geography, 'generated', 'pku-curated:connector:4:to-facility', '{"kind":"facility-road-connector","curatedSource":"pku-curated","maxDistanceMeters":18.0}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:node:library' AND nb.source_ref = 'pku-curated:facnode:4';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, GREATEST(ST_Distance(na.location, nb.location), 1), 'walk', GREATEST(CEIL(ST_Distance(na.location, nb.location) / 1.2)::int, 1), GREATEST(ST_Distance(na.location, nb.location) / 100.0, 1), 2, ST_MakeLine(na.location::geometry, nb.location::geometry)::geography, 'generated', 'pku-curated:connector:5:to-road', '{"kind":"facility-road-connector","curatedSource":"pku-curated","maxDistanceMeters":18.0}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:facnode:5' AND nb.source_ref = 'pku-curated:node:library';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, GREATEST(ST_Distance(na.location, nb.location), 1), 'walk', GREATEST(CEIL(ST_Distance(na.location, nb.location) / 1.2)::int, 1), GREATEST(ST_Distance(na.location, nb.location) / 100.0, 1), 2, ST_MakeLine(na.location::geometry, nb.location::geometry)::geography, 'generated', 'pku-curated:connector:5:to-facility', '{"kind":"facility-road-connector","curatedSource":"pku-curated","maxDistanceMeters":18.0}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:node:library' AND nb.source_ref = 'pku-curated:facnode:5';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, GREATEST(ST_Distance(na.location, nb.location), 1), 'walk', GREATEST(CEIL(ST_Distance(na.location, nb.location) / 1.2)::int, 1), GREATEST(ST_Distance(na.location, nb.location) / 100.0, 1), 2, ST_MakeLine(na.location::geometry, nb.location::geometry)::geography, 'generated', 'pku-curated:connector:6:to-road', '{"kind":"facility-road-connector","curatedSource":"pku-curated","maxDistanceMeters":18.0}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:facnode:6' AND nb.source_ref = 'pku-curated:node:first_teaching';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, GREATEST(ST_Distance(na.location, nb.location), 1), 'walk', GREATEST(CEIL(ST_Distance(na.location, nb.location) / 1.2)::int, 1), GREATEST(ST_Distance(na.location, nb.location) / 100.0, 1), 2, ST_MakeLine(na.location::geometry, nb.location::geometry)::geography, 'generated', 'pku-curated:connector:6:to-facility', '{"kind":"facility-road-connector","curatedSource":"pku-curated","maxDistanceMeters":18.0}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:node:first_teaching' AND nb.source_ref = 'pku-curated:facnode:6';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, GREATEST(ST_Distance(na.location, nb.location), 1), 'walk', GREATEST(CEIL(ST_Distance(na.location, nb.location) / 1.2)::int, 1), GREATEST(ST_Distance(na.location, nb.location) / 100.0, 1), 2, ST_MakeLine(na.location::geometry, nb.location::geometry)::geography, 'generated', 'pku-curated:connector:7:to-road', '{"kind":"facility-road-connector","curatedSource":"pku-curated","maxDistanceMeters":18.0}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:facnode:7' AND nb.source_ref = 'pku-curated:node:science';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, GREATEST(ST_Distance(na.location, nb.location), 1), 'walk', GREATEST(CEIL(ST_Distance(na.location, nb.location) / 1.2)::int, 1), GREATEST(ST_Distance(na.location, nb.location) / 100.0, 1), 2, ST_MakeLine(na.location::geometry, nb.location::geometry)::geography, 'generated', 'pku-curated:connector:7:to-facility', '{"kind":"facility-road-connector","curatedSource":"pku-curated","maxDistanceMeters":18.0}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:node:science' AND nb.source_ref = 'pku-curated:facnode:7';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, GREATEST(ST_Distance(na.location, nb.location), 1), 'walk', GREATEST(CEIL(ST_Distance(na.location, nb.location) / 1.2)::int, 1), GREATEST(ST_Distance(na.location, nb.location) / 100.0, 1), 2, ST_MakeLine(na.location::geometry, nb.location::geometry)::geography, 'generated', 'pku-curated:connector:8:to-road', '{"kind":"facility-road-connector","curatedSource":"pku-curated","maxDistanceMeters":18.0}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:facnode:8' AND nb.source_ref = 'pku-curated:node:second_teaching';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, GREATEST(ST_Distance(na.location, nb.location), 1), 'walk', GREATEST(CEIL(ST_Distance(na.location, nb.location) / 1.2)::int, 1), GREATEST(ST_Distance(na.location, nb.location) / 100.0, 1), 2, ST_MakeLine(na.location::geometry, nb.location::geometry)::geography, 'generated', 'pku-curated:connector:8:to-facility', '{"kind":"facility-road-connector","curatedSource":"pku-curated","maxDistanceMeters":18.0}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:node:second_teaching' AND nb.source_ref = 'pku-curated:facnode:8';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, GREATEST(ST_Distance(na.location, nb.location), 1), 'walk', GREATEST(CEIL(ST_Distance(na.location, nb.location) / 1.2)::int, 1), GREATEST(ST_Distance(na.location, nb.location) / 100.0, 1), 2, ST_MakeLine(na.location::geometry, nb.location::geometry)::geography, 'generated', 'pku-curated:connector:9:to-road', '{"kind":"facility-road-connector","curatedSource":"pku-curated","maxDistanceMeters":18.0}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:facnode:9' AND nb.source_ref = 'pku-curated:node:hall';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, GREATEST(ST_Distance(na.location, nb.location), 1), 'walk', GREATEST(CEIL(ST_Distance(na.location, nb.location) / 1.2)::int, 1), GREATEST(ST_Distance(na.location, nb.location) / 100.0, 1), 2, ST_MakeLine(na.location::geometry, nb.location::geometry)::geography, 'generated', 'pku-curated:connector:9:to-facility', '{"kind":"facility-road-connector","curatedSource":"pku-curated","maxDistanceMeters":18.0}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:node:hall' AND nb.source_ref = 'pku-curated:facnode:9';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, GREATEST(ST_Distance(na.location, nb.location), 1), 'walk', GREATEST(CEIL(ST_Distance(na.location, nb.location) / 1.2)::int, 1), GREATEST(ST_Distance(na.location, nb.location) / 100.0, 1), 2, ST_MakeLine(na.location::geometry, nb.location::geometry)::geography, 'generated', 'pku-curated:connector:10:to-road', '{"kind":"facility-road-connector","curatedSource":"pku-curated","maxDistanceMeters":18.0}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:facnode:10' AND nb.source_ref = 'pku-curated:node:hall';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, GREATEST(ST_Distance(na.location, nb.location), 1), 'walk', GREATEST(CEIL(ST_Distance(na.location, nb.location) / 1.2)::int, 1), GREATEST(ST_Distance(na.location, nb.location) / 100.0, 1), 2, ST_MakeLine(na.location::geometry, nb.location::geometry)::geography, 'generated', 'pku-curated:connector:10:to-facility', '{"kind":"facility-road-connector","curatedSource":"pku-curated","maxDistanceMeters":18.0}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:node:hall' AND nb.source_ref = 'pku-curated:facnode:10';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, GREATEST(ST_Distance(na.location, nb.location), 1), 'walk', GREATEST(CEIL(ST_Distance(na.location, nb.location) / 1.2)::int, 1), GREATEST(ST_Distance(na.location, nb.location) / 100.0, 1), 2, ST_MakeLine(na.location::geometry, nb.location::geometry)::geography, 'generated', 'pku-curated:connector:11:to-road', '{"kind":"facility-road-connector","curatedSource":"pku-curated","maxDistanceMeters":18.0}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:facnode:11' AND nb.source_ref = 'pku-curated:node:nongyuan';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, GREATEST(ST_Distance(na.location, nb.location), 1), 'walk', GREATEST(CEIL(ST_Distance(na.location, nb.location) / 1.2)::int, 1), GREATEST(ST_Distance(na.location, nb.location) / 100.0, 1), 2, ST_MakeLine(na.location::geometry, nb.location::geometry)::geography, 'generated', 'pku-curated:connector:11:to-facility', '{"kind":"facility-road-connector","curatedSource":"pku-curated","maxDistanceMeters":18.0}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:node:nongyuan' AND nb.source_ref = 'pku-curated:facnode:11';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, GREATEST(ST_Distance(na.location, nb.location), 1), 'walk', GREATEST(CEIL(ST_Distance(na.location, nb.location) / 1.2)::int, 1), GREATEST(ST_Distance(na.location, nb.location) / 100.0, 1), 2, ST_MakeLine(na.location::geometry, nb.location::geometry)::geography, 'generated', 'pku-curated:connector:12:to-road', '{"kind":"facility-road-connector","curatedSource":"pku-curated","maxDistanceMeters":18.0}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:facnode:12' AND nb.source_ref = 'pku-curated:node:nongyuan';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, GREATEST(ST_Distance(na.location, nb.location), 1), 'walk', GREATEST(CEIL(ST_Distance(na.location, nb.location) / 1.2)::int, 1), GREATEST(ST_Distance(na.location, nb.location) / 100.0, 1), 2, ST_MakeLine(na.location::geometry, nb.location::geometry)::geography, 'generated', 'pku-curated:connector:12:to-facility', '{"kind":"facility-road-connector","curatedSource":"pku-curated","maxDistanceMeters":18.0}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:node:nongyuan' AND nb.source_ref = 'pku-curated:facnode:12';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, GREATEST(ST_Distance(na.location, nb.location), 1), 'walk', GREATEST(CEIL(ST_Distance(na.location, nb.location) / 1.2)::int, 1), GREATEST(ST_Distance(na.location, nb.location) / 100.0, 1), 2, ST_MakeLine(na.location::geometry, nb.location::geometry)::geography, 'generated', 'pku-curated:connector:13:to-road', '{"kind":"facility-road-connector","curatedSource":"pku-curated","maxDistanceMeters":18.0}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:facnode:13' AND nb.source_ref = 'pku-curated:node:south_gate';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, GREATEST(ST_Distance(na.location, nb.location), 1), 'walk', GREATEST(CEIL(ST_Distance(na.location, nb.location) / 1.2)::int, 1), GREATEST(ST_Distance(na.location, nb.location) / 100.0, 1), 2, ST_MakeLine(na.location::geometry, nb.location::geometry)::geography, 'generated', 'pku-curated:connector:13:to-facility', '{"kind":"facility-road-connector","curatedSource":"pku-curated","maxDistanceMeters":18.0}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:node:south_gate' AND nb.source_ref = 'pku-curated:facnode:13';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, GREATEST(ST_Distance(na.location, nb.location), 1), 'walk', GREATEST(CEIL(ST_Distance(na.location, nb.location) / 1.2)::int, 1), GREATEST(ST_Distance(na.location, nb.location) / 100.0, 1), 2, ST_MakeLine(na.location::geometry, nb.location::geometry)::geography, 'generated', 'pku-curated:connector:14:to-road', '{"kind":"facility-road-connector","curatedSource":"pku-curated","maxDistanceMeters":18.0}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:facnode:14' AND nb.source_ref = 'pku-curated:node:hospital';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, GREATEST(ST_Distance(na.location, nb.location), 1), 'walk', GREATEST(CEIL(ST_Distance(na.location, nb.location) / 1.2)::int, 1), GREATEST(ST_Distance(na.location, nb.location) / 100.0, 1), 2, ST_MakeLine(na.location::geometry, nb.location::geometry)::geography, 'generated', 'pku-curated:connector:14:to-facility', '{"kind":"facility-road-connector","curatedSource":"pku-curated","maxDistanceMeters":18.0}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:node:hospital' AND nb.source_ref = 'pku-curated:facnode:14';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, GREATEST(ST_Distance(na.location, nb.location), 1), 'walk', GREATEST(CEIL(ST_Distance(na.location, nb.location) / 1.2)::int, 1), GREATEST(ST_Distance(na.location, nb.location) / 100.0, 1), 2, ST_MakeLine(na.location::geometry, nb.location::geometry)::geography, 'generated', 'pku-curated:connector:15:to-road', '{"kind":"facility-road-connector","curatedSource":"pku-curated","maxDistanceMeters":18.0}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:facnode:15' AND nb.source_ref = 'pku-curated:node:shao_yuan';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, GREATEST(ST_Distance(na.location, nb.location), 1), 'walk', GREATEST(CEIL(ST_Distance(na.location, nb.location) / 1.2)::int, 1), GREATEST(ST_Distance(na.location, nb.location) / 100.0, 1), 2, ST_MakeLine(na.location::geometry, nb.location::geometry)::geography, 'generated', 'pku-curated:connector:15:to-facility', '{"kind":"facility-road-connector","curatedSource":"pku-curated","maxDistanceMeters":18.0}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:node:shao_yuan' AND nb.source_ref = 'pku-curated:facnode:15';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, GREATEST(ST_Distance(na.location, nb.location), 1), 'walk', GREATEST(CEIL(ST_Distance(na.location, nb.location) / 1.2)::int, 1), GREATEST(ST_Distance(na.location, nb.location) / 100.0, 1), 2, ST_MakeLine(na.location::geometry, nb.location::geometry)::geography, 'generated', 'pku-curated:connector:16:to-road', '{"kind":"facility-road-connector","curatedSource":"pku-curated","maxDistanceMeters":18.0}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:facnode:16' AND nb.source_ref = 'pku-curated:node:shao_yuan';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, GREATEST(ST_Distance(na.location, nb.location), 1), 'walk', GREATEST(CEIL(ST_Distance(na.location, nb.location) / 1.2)::int, 1), GREATEST(ST_Distance(na.location, nb.location) / 100.0, 1), 2, ST_MakeLine(na.location::geometry, nb.location::geometry)::geography, 'generated', 'pku-curated:connector:16:to-facility', '{"kind":"facility-road-connector","curatedSource":"pku-curated","maxDistanceMeters":18.0}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:node:shao_yuan' AND nb.source_ref = 'pku-curated:facnode:16';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, GREATEST(ST_Distance(na.location, nb.location), 1), 'walk', GREATEST(CEIL(ST_Distance(na.location, nb.location) / 1.2)::int, 1), GREATEST(ST_Distance(na.location, nb.location) / 100.0, 1), 2, ST_MakeLine(na.location::geometry, nb.location::geometry)::geography, 'generated', 'pku-curated:connector:17:to-road', '{"kind":"facility-road-connector","curatedSource":"pku-curated","maxDistanceMeters":18.0}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:facnode:17' AND nb.source_ref = 'pku-curated:node:history';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, GREATEST(ST_Distance(na.location, nb.location), 1), 'walk', GREATEST(CEIL(ST_Distance(na.location, nb.location) / 1.2)::int, 1), GREATEST(ST_Distance(na.location, nb.location) / 100.0, 1), 2, ST_MakeLine(na.location::geometry, nb.location::geometry)::geography, 'generated', 'pku-curated:connector:17:to-facility', '{"kind":"facility-road-connector","curatedSource":"pku-curated","maxDistanceMeters":18.0}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:node:history' AND nb.source_ref = 'pku-curated:facnode:17';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, GREATEST(ST_Distance(na.location, nb.location), 1), 'walk', GREATEST(CEIL(ST_Distance(na.location, nb.location) / 1.2)::int, 1), GREATEST(ST_Distance(na.location, nb.location) / 100.0, 1), 2, ST_MakeLine(na.location::geometry, nb.location::geometry)::geography, 'generated', 'pku-curated:connector:18:to-road', '{"kind":"facility-road-connector","curatedSource":"pku-curated","maxDistanceMeters":18.0}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:facnode:18' AND nb.source_ref = 'pku-curated:node:admin';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, GREATEST(ST_Distance(na.location, nb.location), 1), 'walk', GREATEST(CEIL(ST_Distance(na.location, nb.location) / 1.2)::int, 1), GREATEST(ST_Distance(na.location, nb.location) / 100.0, 1), 2, ST_MakeLine(na.location::geometry, nb.location::geometry)::geography, 'generated', 'pku-curated:connector:18:to-facility', '{"kind":"facility-road-connector","curatedSource":"pku-curated","maxDistanceMeters":18.0}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:node:admin' AND nb.source_ref = 'pku-curated:facnode:18';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, GREATEST(ST_Distance(na.location, nb.location), 1), 'walk', GREATEST(CEIL(ST_Distance(na.location, nb.location) / 1.2)::int, 1), GREATEST(ST_Distance(na.location, nb.location) / 100.0, 1), 2, ST_MakeLine(na.location::geometry, nb.location::geometry)::geography, 'generated', 'pku-curated:connector:19:to-road', '{"kind":"facility-road-connector","curatedSource":"pku-curated","maxDistanceMeters":18.0}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:facnode:19' AND nb.source_ref = 'pku-curated:node:chemistry';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, GREATEST(ST_Distance(na.location, nb.location), 1), 'walk', GREATEST(CEIL(ST_Distance(na.location, nb.location) / 1.2)::int, 1), GREATEST(ST_Distance(na.location, nb.location) / 100.0, 1), 2, ST_MakeLine(na.location::geometry, nb.location::geometry)::geography, 'generated', 'pku-curated:connector:19:to-facility', '{"kind":"facility-road-connector","curatedSource":"pku-curated","maxDistanceMeters":18.0}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:node:chemistry' AND nb.source_ref = 'pku-curated:facnode:19';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, GREATEST(ST_Distance(na.location, nb.location), 1), 'walk', GREATEST(CEIL(ST_Distance(na.location, nb.location) / 1.2)::int, 1), GREATEST(ST_Distance(na.location, nb.location) / 100.0, 1), 2, ST_MakeLine(na.location::geometry, nb.location::geometry)::geography, 'generated', 'pku-curated:connector:20:to-road', '{"kind":"facility-road-connector","curatedSource":"pku-curated","maxDistanceMeters":18.0}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:facnode:20' AND nb.source_ref = 'pku-curated:node:guanghua';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, GREATEST(ST_Distance(na.location, nb.location), 1), 'walk', GREATEST(CEIL(ST_Distance(na.location, nb.location) / 1.2)::int, 1), GREATEST(ST_Distance(na.location, nb.location) / 100.0, 1), 2, ST_MakeLine(na.location::geometry, nb.location::geometry)::geography, 'generated', 'pku-curated:connector:20:to-facility', '{"kind":"facility-road-connector","curatedSource":"pku-curated","maxDistanceMeters":18.0}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:node:guanghua' AND nb.source_ref = 'pku-curated:facnode:20';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, GREATEST(ST_Distance(na.location, nb.location), 1), 'walk', GREATEST(CEIL(ST_Distance(na.location, nb.location) / 1.2)::int, 1), GREATEST(ST_Distance(na.location, nb.location) / 100.0, 1), 2, ST_MakeLine(na.location::geometry, nb.location::geometry)::geography, 'generated', 'pku-curated:connector:21:to-road', '{"kind":"facility-road-connector","curatedSource":"pku-curated","maxDistanceMeters":18.0}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:facnode:21' AND nb.source_ref = 'pku-curated:node:law';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, GREATEST(ST_Distance(na.location, nb.location), 1), 'walk', GREATEST(CEIL(ST_Distance(na.location, nb.location) / 1.2)::int, 1), GREATEST(ST_Distance(na.location, nb.location) / 100.0, 1), 2, ST_MakeLine(na.location::geometry, nb.location::geometry)::geography, 'generated', 'pku-curated:connector:21:to-facility', '{"kind":"facility-road-connector","curatedSource":"pku-curated","maxDistanceMeters":18.0}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:node:law' AND nb.source_ref = 'pku-curated:facnode:21';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, GREATEST(ST_Distance(na.location, nb.location), 1), 'walk', GREATEST(CEIL(ST_Distance(na.location, nb.location) / 1.2)::int, 1), GREATEST(ST_Distance(na.location, nb.location) / 100.0, 1), 2, ST_MakeLine(na.location::geometry, nb.location::geometry)::geography, 'generated', 'pku-curated:connector:22:to-road', '{"kind":"facility-road-connector","curatedSource":"pku-curated","maxDistanceMeters":18.0}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:facnode:22' AND nb.source_ref = 'pku-curated:node:east_gate';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, GREATEST(ST_Distance(na.location, nb.location), 1), 'walk', GREATEST(CEIL(ST_Distance(na.location, nb.location) / 1.2)::int, 1), GREATEST(ST_Distance(na.location, nb.location) / 100.0, 1), 2, ST_MakeLine(na.location::geometry, nb.location::geometry)::geography, 'generated', 'pku-curated:connector:22:to-facility', '{"kind":"facility-road-connector","curatedSource":"pku-curated","maxDistanceMeters":18.0}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:node:east_gate' AND nb.source_ref = 'pku-curated:facnode:22';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, GREATEST(ST_Distance(na.location, nb.location), 1), 'walk', GREATEST(CEIL(ST_Distance(na.location, nb.location) / 1.2)::int, 1), GREATEST(ST_Distance(na.location, nb.location) / 100.0, 1), 2, ST_MakeLine(na.location::geometry, nb.location::geometry)::geography, 'generated', 'pku-curated:connector:23:to-road', '{"kind":"facility-road-connector","curatedSource":"pku-curated","maxDistanceMeters":18.0}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:facnode:23' AND nb.source_ref = 'pku-curated:node:north_gate';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, GREATEST(ST_Distance(na.location, nb.location), 1), 'walk', GREATEST(CEIL(ST_Distance(na.location, nb.location) / 1.2)::int, 1), GREATEST(ST_Distance(na.location, nb.location) / 100.0, 1), 2, ST_MakeLine(na.location::geometry, nb.location::geometry)::geography, 'generated', 'pku-curated:connector:23:to-facility', '{"kind":"facility-road-connector","curatedSource":"pku-curated","maxDistanceMeters":18.0}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:node:north_gate' AND nb.source_ref = 'pku-curated:facnode:23';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, GREATEST(ST_Distance(na.location, nb.location), 1), 'walk', GREATEST(CEIL(ST_Distance(na.location, nb.location) / 1.2)::int, 1), GREATEST(ST_Distance(na.location, nb.location) / 100.0, 1), 2, ST_MakeLine(na.location::geometry, nb.location::geometry)::geography, 'generated', 'pku-curated:connector:24:to-road', '{"kind":"facility-road-connector","curatedSource":"pku-curated","maxDistanceMeters":18.0}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:facnode:24' AND nb.source_ref = 'pku-curated:node:lakeview';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, GREATEST(ST_Distance(na.location, nb.location), 1), 'walk', GREATEST(CEIL(ST_Distance(na.location, nb.location) / 1.2)::int, 1), GREATEST(ST_Distance(na.location, nb.location) / 100.0, 1), 2, ST_MakeLine(na.location::geometry, nb.location::geometry)::geography, 'generated', 'pku-curated:connector:24:to-facility', '{"kind":"facility-road-connector","curatedSource":"pku-curated","maxDistanceMeters":18.0}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:node:lakeview' AND nb.source_ref = 'pku-curated:facnode:24';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, GREATEST(ST_Distance(na.location, nb.location), 1), 'walk', GREATEST(CEIL(ST_Distance(na.location, nb.location) / 1.2)::int, 1), GREATEST(ST_Distance(na.location, nb.location) / 100.0, 1), 2, ST_MakeLine(na.location::geometry, nb.location::geometry)::geography, 'generated', 'pku-curated:connector:25:to-road', '{"kind":"facility-road-connector","curatedSource":"pku-curated","maxDistanceMeters":18.0}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:facnode:25' AND nb.source_ref = 'pku-curated:node:chengfu';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, GREATEST(ST_Distance(na.location, nb.location), 1), 'walk', GREATEST(CEIL(ST_Distance(na.location, nb.location) / 1.2)::int, 1), GREATEST(ST_Distance(na.location, nb.location) / 100.0, 1), 2, ST_MakeLine(na.location::geometry, nb.location::geometry)::geography, 'generated', 'pku-curated:connector:25:to-facility', '{"kind":"facility-road-connector","curatedSource":"pku-curated","maxDistanceMeters":18.0}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:node:chengfu' AND nb.source_ref = 'pku-curated:facnode:25';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, GREATEST(ST_Distance(na.location, nb.location), 1), 'walk', GREATEST(CEIL(ST_Distance(na.location, nb.location) / 1.2)::int, 1), GREATEST(ST_Distance(na.location, nb.location) / 100.0, 1), 2, ST_MakeLine(na.location::geometry, nb.location::geometry)::geography, 'generated', 'pku-curated:connector:26:to-road', '{"kind":"facility-road-connector","curatedSource":"pku-curated","maxDistanceMeters":18.0}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:facnode:26' AND nb.source_ref = 'pku-curated:node:gym';
    INSERT INTO graph_edges (from_node, to_node, distance, travel_mode, travel_time, base_weight, congestion_level, geometry, source, source_ref, source_tags)
    SELECT na.id, nb.id, GREATEST(ST_Distance(na.location, nb.location), 1), 'walk', GREATEST(CEIL(ST_Distance(na.location, nb.location) / 1.2)::int, 1), GREATEST(ST_Distance(na.location, nb.location) / 100.0, 1), 2, ST_MakeLine(na.location::geometry, nb.location::geometry)::geography, 'generated', 'pku-curated:connector:26:to-facility', '{"kind":"facility-road-connector","curatedSource":"pku-curated","maxDistanceMeters":18.0}'::jsonb
    FROM graph_nodes na, graph_nodes nb WHERE na.source_ref = 'pku-curated:node:gym' AND nb.source_ref = 'pku-curated:facnode:26';

    RAISE NOTICE '北京大学校核连通图已重建: % 主路网节点, % 主路网双向边, % 设施', 29, 72, 27;
END $$;

COMMIT;
