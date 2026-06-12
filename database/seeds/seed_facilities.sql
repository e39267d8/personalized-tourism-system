SET client_encoding = 'UTF8';

-- =====================================================
-- 个性化旅游系统 - 设施数据补充 (≥50 个 / ≥11 种类型)
-- =====================================================
-- 与 seed_demo.sql 中已有的 12 个设施互补 (IDs 1-12)
-- 新增 40 个设施 (IDs 13-52)，分布在 8 个已有景点周边
-- 设施类型扩展到 12 种: restaurant, hotel, subway, parking,
--   toilet, service, atm, pharmacy, convenience_store,
--   bicycle_rental, souvenir_shop, clinic
-- 用于满足课设约束: 设施 ≥50 个, 类型 ≥10 种
-- =====================================================

BEGIN;

INSERT INTO facilities
    (id, name, type, location, address, rating, price_level, opening_hours, phone, scenic_spot_id)
VALUES
    -- === 故宫周边 (IDs 13-18) ===
    (13, '故宫午门游客服务中心', 'service', ST_SetSRID(ST_MakePoint(116.397326, 39.914358), 4326)::geography, '故宫午门外广场', 4.50, 1, '08:30-17:00', '010-85001301', (SELECT id FROM scenic_spots WHERE name LIKE '%故宫%' LIMIT 1)),
    (14, '故宫便利店', 'convenience_store', ST_SetSRID(ST_MakePoint(116.397889, 39.916320), 4326)::geography, '故宫太和门东侧', 4.10, 1, '08:30-16:30', NULL, (SELECT id FROM scenic_spots WHERE name LIKE '%故宫%' LIMIT 1)),
    (15, '故宫文创商店', 'souvenir_shop', ST_SetSRID(ST_MakePoint(116.399064, 39.923478), 4326)::geography, '故宫神武门内西侧', 4.60, 3, '09:00-17:00', '010-85001303', (SELECT id FROM scenic_spots WHERE name LIKE '%故宫%' LIMIT 1)),
    (16, '故宫 ATM (工商银行)', 'atm', ST_SetSRID(ST_MakePoint(116.397500, 39.915000), 4326)::geography, '故宫午门售票处旁', 4.00, 1, '08:30-16:30', NULL, (SELECT id FROM scenic_spots WHERE name LIKE '%故宫%' LIMIT 1)),
    (17, '故宫西侧公共卫生间', 'toilet', ST_SetSRID(ST_MakePoint(116.395560, 39.917282), 4326)::geography, '故宫西华门附近', 3.80, 1, '08:00-17:30', NULL, (SELECT id FROM scenic_spots WHERE name LIKE '%故宫%' LIMIT 1)),
    (18, '故宫北门停车点', 'bicycle_rental', ST_SetSRID(ST_MakePoint(116.399064, 39.924178), 4326)::geography, '故宫神武门外共享单车停放点', 4.20, 1, '06:00-22:00', NULL, (SELECT id FROM scenic_spots WHERE name LIKE '%故宫%' LIMIT 1)),

    -- === 天安门周边 (IDs 19-23) ===
    (19, '天安门广场游客服务点', 'service', ST_SetSRID(ST_MakePoint(116.397755, 39.903182), 4326)::geography, '天安门广场东侧', 4.30, 1, '05:00-22:00', '010-85001304', (SELECT id FROM scenic_spots WHERE name LIKE '%天安门%' AND name NOT LIKE '%东%' AND name NOT LIKE '%西%' LIMIT 1)),
    (20, '天安门东公厕', 'toilet', ST_SetSRID(ST_MakePoint(116.399500, 39.907500), 4326)::geography, '天安门城楼东侧', 3.90, 1, '05:00-23:00', NULL, (SELECT id FROM scenic_spots WHERE name LIKE '%天安门%' AND name NOT LIKE '%东%' AND name NOT LIKE '%西%' LIMIT 1)),
    (21, '前门东大街药房', 'pharmacy', ST_SetSRID(ST_MakePoint(116.398300, 39.901500), 4326)::geography, '前门东大街 12 号', 4.10, 2, '08:00-21:00', '010-85001305', (SELECT id FROM scenic_spots WHERE name LIKE '%天安门%' AND name NOT LIKE '%东%' AND name NOT LIKE '%西%' LIMIT 1)),
    (22, '天安门广场纪念品店', 'souvenir_shop', ST_SetSRID(ST_MakePoint(116.397400, 39.904800), 4326)::geography, '天安门广场南侧', 4.00, 2, '08:00-18:00', NULL, (SELECT id FROM scenic_spots WHERE name LIKE '%天安门%' AND name NOT LIKE '%东%' AND name NOT LIKE '%西%' LIMIT 1)),
    (23, '天安门 ATM (建设银行)', 'atm', ST_SetSRID(ST_MakePoint(116.398000, 39.904000), 4326)::geography, '国家大剧院北侧', 4.00, 1, '24小时', NULL, (SELECT id FROM scenic_spots WHERE name LIKE '%天安门%' AND name NOT LIKE '%东%' AND name NOT LIKE '%西%' LIMIT 1)),

    -- === 景山公园周边 (IDs 24-27) ===
    (24, '景山公园便利店', 'convenience_store', ST_SetSRID(ST_MakePoint(116.396621, 39.925048), 4326)::geography, '景山公园南门内', 4.00, 1, '06:30-20:00', NULL, (SELECT id FROM scenic_spots WHERE name LIKE '%景山%' LIMIT 1)),
    (25, '景山后街药房', 'pharmacy', ST_SetSRID(ST_MakePoint(116.395990, 39.927550), 4326)::geography, '景山后街 8 号', 4.20, 2, '08:30-21:00', '010-85001306', (SELECT id FROM scenic_spots WHERE name LIKE '%景山%' LIMIT 1)),
    (26, '景山南门单车租赁', 'bicycle_rental', ST_SetSRID(ST_MakePoint(116.396621, 39.923500), 4326)::geography, '景山南门对面共享单车点', 4.10, 1, '06:00-22:00', NULL, (SELECT id FROM scenic_spots WHERE name LIKE '%景山%' LIMIT 1)),
    (27, '景山社区卫生服务站', 'clinic', ST_SetSRID(ST_MakePoint(116.395500, 39.926000), 4326)::geography, '景山东街社区', 4.00, 1, '08:00-18:00', '010-85001307', (SELECT id FROM scenic_spots WHERE name LIKE '%景山%' LIMIT 1)),

    -- === 北海公园周边 (IDs 28-32) ===
    (28, '北海公园南门便利店', 'convenience_store', ST_SetSRID(ST_MakePoint(116.389535, 39.923955), 4326)::geography, '北海公园南门入口', 4.00, 1, '06:30-21:00', NULL, (SELECT id FROM scenic_spots WHERE name LIKE '%北海%' LIMIT 1)),
    (29, '北海北门单车租赁', 'bicycle_rental', ST_SetSRID(ST_MakePoint(116.386829, 39.933247), 4326)::geography, '北海北地铁站 B 口外', 4.30, 1, '06:00-22:30', NULL, (SELECT id FROM scenic_spots WHERE name LIKE '%北海%' LIMIT 1)),
    (30, '什刹海体校 ATM (中国银行)', 'atm', ST_SetSRID(ST_MakePoint(116.388500, 39.934000), 4326)::geography, '地安门外大街路口', 4.00, 1, '24小时', NULL, (SELECT id FROM scenic_spots WHERE name LIKE '%北海%' LIMIT 1)),
    (31, '北海公园文创店', 'souvenir_shop', ST_SetSRID(ST_MakePoint(116.388000, 39.924500), 4326)::geography, '北海公园琼华岛', 4.30, 2, '09:00-17:30', NULL, (SELECT id FROM scenic_spots WHERE name LIKE '%北海%' LIMIT 1)),
    (32, '北海北停车场', 'parking', ST_SetSRID(ST_MakePoint(116.386200, 39.932000), 4326)::geography, '北海公园北门外停车场', 3.80, 2, '07:00-21:00', NULL, (SELECT id FROM scenic_spots WHERE name LIKE '%北海%' LIMIT 1)),

    -- === 国家博物馆周边 (IDs 33-36) ===
    (33, '国博西侧药房', 'pharmacy', ST_SetSRID(ST_MakePoint(116.398800, 39.905800), 4326)::geography, '前门东大街 25 号', 4.10, 2, '08:00-20:00', '010-85001308', (SELECT id FROM scenic_spots WHERE name LIKE '%国家博物馆%' LIMIT 1)),
    (34, '国博 ATM (农业银行)', 'atm', ST_SetSRID(ST_MakePoint(116.400000, 39.905500), 4326)::geography, '国家博物馆东门外', 4.00, 1, '24小时', NULL, (SELECT id FROM scenic_spots WHERE name LIKE '%国家博物馆%' LIMIT 1)),
    (35, '国博纪念品商店', 'souvenir_shop', ST_SetSRID(ST_MakePoint(116.401015, 39.905103), 4326)::geography, '国家博物馆地下一层', 4.50, 3, '09:00-16:30', '010-85001309', (SELECT id FROM scenic_spots WHERE name LIKE '%国家博物馆%' LIMIT 1)),
    (36, '前门东单车停放点', 'bicycle_rental', ST_SetSRID(ST_MakePoint(116.399500, 39.903000), 4326)::geography, '前门东大街共享单车点', 4.10, 1, '06:00-22:00', NULL, (SELECT id FROM scenic_spots WHERE name LIKE '%国家博物馆%' LIMIT 1)),

    -- === 前门大街周边 (IDs 37-42) ===
    (37, '前门大街 ATM (招商银行)', 'atm', ST_SetSRID(ST_MakePoint(116.397957, 39.899318), 4326)::geography, '前门大街南口', 4.00, 1, '24小时', NULL, (SELECT id FROM scenic_spots WHERE name LIKE '%前门%' LIMIT 1)),
    (38, '大栅栏药房', 'pharmacy', ST_SetSRID(ST_MakePoint(116.396200, 39.897500), 4326)::geography, '大栅栏西街 6 号', 4.00, 2, '08:30-20:30', '010-85001310', (SELECT id FROM scenic_spots WHERE name LIKE '%前门%' LIMIT 1)),
    (39, '前门大街便利店', 'convenience_store', ST_SetSRID(ST_MakePoint(116.396800, 39.898200), 4326)::geography, '前门大街中段', 4.10, 1, '07:00-23:00', NULL, (SELECT id FROM scenic_spots WHERE name LIKE '%前门%' LIMIT 1)),
    (40, '前门社区卫生站', 'clinic', ST_SetSRID(ST_MakePoint(116.395800, 39.898000), 4326)::geography, '前门西河沿街', 4.00, 1, '08:00-18:00', '010-85001311', (SELECT id FROM scenic_spots WHERE name LIKE '%前门%' LIMIT 1)),
    (41, '前门南停车场', 'parking', ST_SetSRID(ST_MakePoint(116.397000, 39.897500), 4326)::geography, '前门大街南口停车场', 3.90, 2, '07:00-22:00', NULL, (SELECT id FROM scenic_spots WHERE name LIKE '%前门%' LIMIT 1)),
    (42, '大栅栏公共卫生间', 'toilet', ST_SetSRID(ST_MakePoint(116.396000, 39.898000), 4326)::geography, '大栅栏商业街中段', 3.80, 1, '08:00-22:00', NULL, (SELECT id FROM scenic_spots WHERE name LIKE '%前门%' LIMIT 1)),

    -- === 王府井周边 (IDs 43-48) ===
    (43, '王府井书店 ATM (建设银行)', 'atm', ST_SetSRID(ST_MakePoint(116.411500, 39.913800), 4326)::geography, '王府井新华书店一楼', 4.00, 1, '09:00-18:00', NULL, (SELECT id FROM scenic_spots WHERE name LIKE '%王府井%' LIMIT 1)),
    (44, '王府井药店', 'pharmacy', ST_SetSRID(ST_MakePoint(116.410300, 39.914000), 4326)::geography, '王府井大街 168 号', 4.20, 2, '08:00-21:30', '010-85001312', (SELECT id FROM scenic_spots WHERE name LIKE '%王府井%' LIMIT 1)),
    (45, '王府井地铁站便利店', 'convenience_store', ST_SetSRID(ST_MakePoint(116.411200, 39.913000), 4326)::geography, '地铁1号线王府井站 B 口', 4.00, 1, '06:00-23:00', NULL, (SELECT id FROM scenic_spots WHERE name LIKE '%王府井%' LIMIT 1)),
    (46, '王府井单车租赁', 'bicycle_rental', ST_SetSRID(ST_MakePoint(116.411013, 39.912657), 4326)::geography, '王府井步行街南口共享单车点', 4.10, 1, '06:00-22:00', NULL, (SELECT id FROM scenic_spots WHERE name LIKE '%王府井%' LIMIT 1)),
    (47, '王府井停车场', 'parking', ST_SetSRID(ST_MakePoint(116.410000, 39.911000), 4326)::geography, '王府井商业区地下停车场', 4.00, 3, '07:00-23:00', '010-85001313', (SELECT id FROM scenic_spots WHERE name LIKE '%王府井%' LIMIT 1)),
    (48, '东单社区卫生服务站', 'clinic', ST_SetSRID(ST_MakePoint(116.412500, 39.911800), 4326)::geography, '东单三条 10 号', 4.10, 1, '08:00-18:00', '010-85001314', (SELECT id FROM scenic_spots WHERE name LIKE '%王府井%' LIMIT 1)),

    -- === 鼓楼/什刹海周边 (IDs 49-52) ===
    (49, '鼓楼东大街药房', 'pharmacy', ST_SetSRID(ST_MakePoint(116.395000, 39.941000), 4326)::geography, '鼓楼东大街 45 号', 4.10, 2, '08:30-21:00', '010-85001315', (SELECT id FROM scenic_spots WHERE name LIKE '%鼓楼%' LIMIT 1)),
    (50, '什刹海单车租赁', 'bicycle_rental', ST_SetSRID(ST_MakePoint(116.390855, 39.937661), 4326)::geography, '什刹海前海西岸', 4.30, 1, '07:00-21:00', NULL, (SELECT id FROM scenic_spots WHERE name LIKE '%什刹海%' LIMIT 1)),
    (51, '鼓楼西停车场', 'parking', ST_SetSRID(ST_MakePoint(116.391540, 39.939830), 4326)::geography, '鼓楼西大街停车场', 3.90, 2, '08:00-22:00', NULL, (SELECT id FROM scenic_spots WHERE name LIKE '%鼓楼%' LIMIT 1)),
    (52, '什刹海便利店', 'convenience_store', ST_SetSRID(ST_MakePoint(116.389500, 39.937000), 4326)::geography, '什刹海荷花市场', 4.10, 1, '08:00-22:00', NULL, (SELECT id FROM scenic_spots WHERE name LIKE '%什刹海%' LIMIT 1))
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

-- Reset sequence
SELECT setval('facilities_id_seq', (SELECT MAX(id) FROM facilities));

COMMIT;
