SET client_encoding = 'UTF8';

-- =====================================================
-- 个性化旅游系统 - 美食数据补充 (≥45 家新餐饮)
-- =====================================================
-- 在北京主要景点周边补充各类餐饮设施：老字号、网红店、
-- 咖啡厅、小吃街等，覆盖 15+ 种菜系。
-- =====================================================

BEGIN;

-- =====================================================
-- 故宫 / 天安门周边 (景山、前门)  IDs 53-70
-- =====================================================
INSERT INTO facilities (id, name, type, location, address, rating, price_level, opening_hours, phone, scenic_spot_id)
VALUES
    -- 故宫片区
    (53, '故宫冰窖餐厅', 'restaurant', ST_SetSRID(ST_MakePoint(116.3950, 39.9190), 4326)::geography, '故宫西路慈宁宫旁', 4.30, 3, '10:30-15:30', '010-85001320', (SELECT id FROM scenic_spots WHERE name LIKE '%故宫%' LIMIT 1)),
    (54, '故宫角楼咖啡（神武门店）', 'cafe', ST_SetSRID(ST_MakePoint(116.3990, 39.9245), 4326)::geography, '景山前街4号故宫神武门西侧', 4.10, 2, '08:30-17:00', NULL, (SELECT id FROM scenic_spots WHERE name LIKE '%故宫%' LIMIT 1)),
    (55, '前门全聚德烤鸭店', 'restaurant', ST_SetSRID(ST_MakePoint(116.3965, 39.8975), 4326)::geography, '前门大街32号', 4.50, 4, '11:00-21:00', '010-63018833', (SELECT id FROM scenic_spots WHERE name LIKE '%前门%' LIMIT 1)),
    (56, '前门都一处烧麦馆', 'restaurant', ST_SetSRID(ST_MakePoint(116.3968, 39.8980), 4326)::geography, '前门大街38号', 4.20, 2, '10:00-21:00', '010-63021555', (SELECT id FROM scenic_spots WHERE name LIKE '%前门%' LIMIT 1)),
    (57, '前门东来顺饭庄', 'restaurant', ST_SetSRID(ST_MakePoint(116.3970, 39.8990), 4326)::geography, '前门大街93号', 4.40, 3, '11:00-22:00', '010-63016699', (SELECT id FROM scenic_spots WHERE name LIKE '%前门%' LIMIT 1)),
    (58, '大栅栏爆肚冯', 'restaurant', ST_SetSRID(ST_MakePoint(116.3960, 39.8970), 4326)::geography, '大栅栏廊房二条56号', 4.00, 1, '10:30-20:30', NULL, (SELECT id FROM scenic_spots WHERE name LIKE '%前门%' LIMIT 1)),

    -- 天安门 / 国家大剧院片区
    (59, '国家大剧院咖啡厅', 'cafe', ST_SetSRID(ST_MakePoint(116.3930, 39.9045), 4326)::geography, '西长安街2号国家大剧院B1', 4.30, 2, '09:00-21:00', '010-66550000', (SELECT id FROM scenic_spots WHERE name LIKE '%天安门%' AND name NOT LIKE '%东%' AND name NOT LIKE '%西%' LIMIT 1)),
    (60, '前门M餐厅', 'restaurant', ST_SetSRID(ST_MakePoint(116.3990, 39.9020), 4326)::geography, '前门23号院', 4.50, 4, '11:30-22:00', '010-65261166', (SELECT id FROM scenic_spots WHERE name LIKE '%前门%' LIMIT 1)),

    -- 景山周边
    (61, '景山后街护国寺小吃', 'restaurant', ST_SetSRID(ST_MakePoint(116.3960, 39.9280), 4326)::geography, '景山后街16号', 4.20, 1, '06:00-21:00', NULL, (SELECT id FROM scenic_spots WHERE name LIKE '%景山%' LIMIT 1)),
    (62, '景山公园牡丹亭茶社', 'cafe', ST_SetSRID(ST_MakePoint(116.3965, 39.9250), 4326)::geography, '景山公园万春亭南侧', 4.10, 1, '08:00-17:00', NULL, (SELECT id FROM scenic_spots WHERE name LIKE '%景山%' LIMIT 1)),

    -- 中山公园
    (63, '中山公园来今雨轩', 'restaurant', ST_SetSRID(ST_MakePoint(116.3940, 39.9110), 4326)::geography, '中山公园内', 4.30, 2, '09:00-20:00', '010-66056676', (SELECT id FROM scenic_spots WHERE name LIKE '%中山%' LIMIT 1)),

    -- 北海公园周边
    (64, '北海公园仿膳饭庄', 'restaurant', ST_SetSRID(ST_MakePoint(116.3910, 39.9260), 4326)::geography, '北海公园琼华岛漪澜堂', 4.60, 4, '11:00-14:00,17:00-21:00', '010-64011879', (SELECT id FROM scenic_spots WHERE name LIKE '%北海%' LIMIT 1)),
    (65, '什刹海烤肉季', 'restaurant', ST_SetSRID(ST_MakePoint(116.3890, 39.9340), 4326)::geography, '前海东沿14号', 4.40, 3, '11:00-22:00', '010-64042554', (SELECT id FROM scenic_spots WHERE name LIKE '%什刹海%' LIMIT 1)),
    (66, '什刹海庆云楼', 'restaurant', ST_SetSRID(ST_MakePoint(116.3885, 39.9335), 4326)::geography, '前海东沿22号', 4.10, 3, '11:00-22:00', '010-64019581', (SELECT id FROM scenic_spots WHERE name LIKE '%什刹海%' LIMIT 1)),
    (67, '什刹海孔乙己酒家', 'restaurant', ST_SetSRID(ST_MakePoint(116.3880, 39.9330), 4326)::geography, '德胜门内大街东明胡同甲2号', 4.00, 2, '11:00-21:00', NULL, (SELECT id FROM scenic_spots WHERE name LIKE '%什刹海%' LIMIT 1)),
    (68, '什刹海茶家傅', 'cafe', ST_SetSRID(ST_MakePoint(116.3870, 39.9320), 4326)::geography, '后海北沿甲15号', 4.20, 2, '10:00-22:00', NULL, (SELECT id FROM scenic_spots WHERE name LIKE '%什刹海%' LIMIT 1)),

    -- 南锣鼓巷片区
    (69, '南锣鼓巷文宇奶酪店', 'restaurant', ST_SetSRID(ST_MakePoint(116.4020, 39.9375), 4326)::geography, '南锣鼓巷39号', 4.50, 1, '09:00-21:00', NULL, (SELECT id FROM scenic_spots WHERE name LIKE '%南锣%' LIMIT 1)),
    (70, '南锣鼓巷鬼味烤翅', 'restaurant', ST_SetSRID(ST_MakePoint(116.4025, 39.9380), 4326)::geography, '南锣鼓巷黑芝麻胡同20号', 4.30, 2, '11:00-22:00', NULL, (SELECT id FROM scenic_spots WHERE name LIKE '%南锣%' LIMIT 1))
ON CONFLICT (id) DO UPDATE SET scenic_spot_id = EXCLUDED.scenic_spot_id;

-- =====================================================
-- 南锣鼓巷 / 簋街 / 雍和宫  IDs 71-85
-- =====================================================
INSERT INTO facilities (id, name, type, location, address, rating, price_level, opening_hours, phone, scenic_spot_id)
VALUES
    (71, '簋街胡大饭馆', 'restaurant', ST_SetSRID(ST_MakePoint(116.4250, 39.9380), 4326)::geography, '东直门内大街233号', 4.70, 3, '10:30-次日04:00', '010-64003511', (SELECT id FROM scenic_spots WHERE name LIKE '%南锣%' LIMIT 1)),
    (72, '簋街花家怡园', 'restaurant', ST_SetSRID(ST_MakePoint(116.4255, 39.9385), 4326)::geography, '东直门内大街235号', 4.40, 3, '11:00-22:00', '010-64051908', (SELECT id FROM scenic_spots WHERE name LIKE '%南锣%' LIMIT 1)),
    (73, '雍和宫金鼎轩', 'restaurant', ST_SetSRID(ST_MakePoint(116.4180, 39.9460), 4326)::geography, '和平里西街77号', 4.10, 2, '24小时', '010-64296888', (SELECT id FROM scenic_spots WHERE name LIKE '%南锣%' LIMIT 1)),
    (74, '北新桥卤煮老店', 'restaurant', ST_SetSRID(ST_MakePoint(116.4200, 39.9400), 4326)::geography, '东四北大街141号', 4.30, 1, '10:00-22:00', NULL, (SELECT id FROM scenic_spots WHERE name LIKE '%南锣%' LIMIT 1)),
    (75, '鼓楼姚记炒肝', 'restaurant', ST_SetSRID(ST_MakePoint(116.3970, 39.9400), 4326)::geography, '鼓楼东大街311号', 4.20, 1, '06:00-22:00', '010-84018989', (SELECT id FROM scenic_spots WHERE name LIKE '%鼓楼%' LIMIT 1)),
    (76, '鼓楼东大街糖房咖啡', 'cafe', ST_SetSRID(ST_MakePoint(116.3980, 39.9410), 4326)::geography, '鼓楼东大街69号', 4.30, 2, '09:00-22:00', NULL, (SELECT id FROM scenic_spots WHERE name LIKE '%鼓楼%' LIMIT 1)),
    (77, '鼓楼鸦儿李记涮肉', 'restaurant', ST_SetSRID(ST_MakePoint(116.3960, 39.9415), 4326)::geography, '鸦儿胡同甲2号', 4.50, 3, '11:00-22:00', NULL, (SELECT id FROM scenic_spots WHERE name LIKE '%鼓楼%' LIMIT 1)),

    -- 烟袋斜街
    (78, '烟袋斜街烤肉宛', 'restaurant', ST_SetSRID(ST_MakePoint(116.3950, 39.9390), 4326)::geography, '烟袋斜街甲11号', 4.20, 2, '11:00-21:00', NULL, (SELECT id FROM scenic_spots WHERE name LIKE '%鼓楼%' LIMIT 1)),
    (79, '后海酒吧街云南菜', 'restaurant', ST_SetSRID(ST_MakePoint(116.3875, 39.9350), 4326)::geography, '后海南沿甲6号', 3.90, 2, '11:00-23:00', NULL, (SELECT id FROM scenic_spots WHERE name LIKE '%什刹海%' LIMIT 1)),
    (80, '后海静一餐厅', 'restaurant', ST_SetSRID(ST_MakePoint(116.3870, 39.9345), 4326)::geography, '后海北沿39号', 4.00, 3, '11:00-21:00', NULL, (SELECT id FROM scenic_spots WHERE name LIKE '%什刹海%' LIMIT 1))
ON CONFLICT (id) DO UPDATE SET scenic_spot_id = EXCLUDED.scenic_spot_id;

-- =====================================================
-- 天坛 / 前门区域  IDs 81-95
-- =====================================================
INSERT INTO facilities (id, name, type, location, address, rating, price_level, opening_hours, phone, scenic_spot_id)
VALUES
    (81, '天坛公园回音壁咖啡', 'cafe', ST_SetSRID(ST_MakePoint(116.4100, 39.8820), 4326)::geography, '天坛公园皇穹宇西侧', 4.00, 1, '08:00-17:00', NULL, (SELECT id FROM scenic_spots WHERE name LIKE '%天坛%' LIMIT 1)),
    (82, '天坛北门炒肝赵', 'restaurant', ST_SetSRID(ST_MakePoint(116.4110, 39.8850), 4326)::geography, '天坛北门对面', 4.10, 1, '06:00-14:00', NULL, (SELECT id FROM scenic_spots WHERE name LIKE '%天坛%' LIMIT 1)),
    (83, '红桥市场美食广场', 'restaurant', ST_SetSRID(ST_MakePoint(116.4130, 39.8830), 4326)::geography, '天坛东路红桥市场5层', 3.90, 2, '10:00-21:00', NULL, (SELECT id FROM scenic_spots WHERE name LIKE '%天坛%' LIMIT 1)),
    (84, '前门鲜鱼口美食街', 'restaurant', ST_SetSRID(ST_MakePoint(116.3980, 39.8985), 4326)::geography, '鲜鱼口街', 4.30, 2, '09:00-21:00', NULL, (SELECT id FROM scenic_spots WHERE name LIKE '%前门%' LIMIT 1)),
    (85, '大栅栏陈记卤煮小肠', 'restaurant', ST_SetSRID(ST_MakePoint(116.3955, 39.8975), 4326)::geography, '取灯胡同3号', 4.30, 1, '09:00-20:30', NULL, (SELECT id FROM scenic_spots WHERE name LIKE '%前门%' LIMIT 1)),
    (86, '杨梅竹斜街Soloist Coffee', 'cafe', ST_SetSRID(ST_MakePoint(116.3940, 39.8960), 4326)::geography, '杨梅竹斜街39号', 4.60, 3, '09:00-21:00', NULL, (SELECT id FROM scenic_spots WHERE name LIKE '%前门%' LIMIT 1)),
    (87, '大栅栏门框胡同卤煮', 'restaurant', ST_SetSRID(ST_MakePoint(116.3950, 39.8970), 4326)::geography, '门框胡同19号', 4.20, 1, '09:00-21:00', NULL, (SELECT id FROM scenic_spots WHERE name LIKE '%前门%' LIMIT 1)),
    (88, '老北京炸酱面大王（前门店）', 'restaurant', ST_SetSRID(ST_MakePoint(116.3975, 39.8990), 4326)::geography, '前门大街3号', 3.90, 1, '10:00-21:00', NULL, (SELECT id FROM scenic_spots WHERE name LIKE '%前门%' LIMIT 1)),
    (89, '国家博物馆文创咖啡', 'cafe', ST_SetSRID(ST_MakePoint(116.4005, 39.9050), 4326)::geography, '国家博物馆二层文创区', 4.20, 2, '09:00-16:30', NULL, (SELECT id FROM scenic_spots WHERE name LIKE '%国家博物馆%' LIMIT 1)),

    -- 王府井片区
    (90, '王府井东来顺（总店）', 'restaurant', ST_SetSRID(ST_MakePoint(116.4130, 39.9155), 4326)::geography, '王府井大街198号', 4.50, 3, '11:00-22:00', '010-65250035', (SELECT id FROM scenic_spots WHERE name LIKE '%王府井%' LIMIT 1)),
    (91, '王府井狗不理包子', 'restaurant', ST_SetSRID(ST_MakePoint(116.4120, 39.9150), 4326)::geography, '王府井大街215号', 3.80, 2, '10:00-21:00', NULL, (SELECT id FROM scenic_spots WHERE name LIKE '%王府井%' LIMIT 1)),
    (92, '王府井APM鼎泰丰', 'restaurant', ST_SetSRID(ST_MakePoint(116.4140, 39.9150), 4326)::geography, '王府井大街138号APM5层', 4.40, 4, '11:00-21:30', '010-65255088', (SELECT id FROM scenic_spots WHERE name LIKE '%王府井%' LIMIT 1)),
    (93, '王府井APM星巴克', 'cafe', ST_SetSRID(ST_MakePoint(116.4140, 39.9145), 4326)::geography, '王府井大街138号APM B1', 4.00, 2, '07:00-22:00', NULL, (SELECT id FROM scenic_spots WHERE name LIKE '%王府井%' LIMIT 1)),
    (94, '灯市口四季民福烤鸭店', 'restaurant', ST_SetSRID(ST_MakePoint(116.4160, 39.9180), 4326)::geography, '灯市口西街32号东华饭店1层', 4.60, 3, '10:30-22:00', '010-65272288', (SELECT id FROM scenic_spots WHERE name LIKE '%王府井%' LIMIT 1)),
    (95, '灯市口川办餐厅', 'restaurant', ST_SetSRID(ST_MakePoint(116.4155, 39.9175), 4326)::geography, '灯市口大街26号', 4.20, 2, '11:00-21:00', '010-65229988', (SELECT id FROM scenic_spots WHERE name LIKE '%王府井%' LIMIT 1)),

    -- 故宫东华门
    (96, '故宫东华门烤鸭快线', 'fast_food', ST_SetSRID(ST_MakePoint(116.4010, 39.9160), 4326)::geography, '东华门大街52号', 3.70, 2, '10:00-20:00', NULL, (SELECT id FROM scenic_spots WHERE name LIKE '%故宫%' LIMIT 1)),
    (97, '故宫午门西侧快餐', 'fast_food', ST_SetSRID(ST_MakePoint(116.3960, 39.9135), 4326)::geography, '故宫午门西朝房', 3.50, 2, '08:30-16:00', NULL, (SELECT id FROM scenic_spots WHERE name LIKE '%故宫%' LIMIT 1))
ON CONFLICT (id) DO NOTHING;

-- =====================================================
-- 北京大学校园餐饮  IDs 98-107
-- =====================================================
INSERT INTO facilities (id, name, type, location, address, rating, price_level, opening_hours, phone, scenic_spot_id, source, source_ref, source_tags)
VALUES
    (98, '北京大学农园食堂', 'restaurant', ST_SetSRID(ST_MakePoint(116.3056, 39.9944), 4326)::geography, '北京大学农园区域', 4.50, 1, '06:30-20:30', NULL, (SELECT id FROM scenic_spots WHERE name LIKE '%北京大学%' LIMIT 1), 'seed', 'pku-food-nongyuan', '{"cuisine":"chinese;canteen"}'::jsonb),
    (99, '北京大学燕南美食', 'restaurant', ST_SetSRID(ST_MakePoint(116.3042, 39.9904), 4326)::geography, '北京大学燕南园附近', 4.30, 1, '07:00-20:00', NULL, (SELECT id FROM scenic_spots WHERE name LIKE '%北京大学%' LIMIT 1), 'seed', 'pku-food-yannan', '{"cuisine":"chinese;snack"}'::jsonb),
    (100, '北京大学学一食堂', 'restaurant', ST_SetSRID(ST_MakePoint(116.3007, 39.9910), 4326)::geography, '北京大学学生宿舍一区附近', 4.10, 1, '06:30-19:30', NULL, (SELECT id FROM scenic_spots WHERE name LIKE '%北京大学%' LIMIT 1), 'seed', 'pku-food-xueyi', '{"cuisine":"chinese;canteen"}'::jsonb),
    (101, '北京大学家园食堂', 'restaurant', ST_SetSRID(ST_MakePoint(116.3018, 39.9888), 4326)::geography, '北京大学家园区域', 4.20, 1, '06:30-20:00', NULL, (SELECT id FROM scenic_spots WHERE name LIKE '%北京大学%' LIMIT 1), 'seed', 'pku-food-jiayuan', '{"cuisine":"chinese;canteen"}'::jsonb),
    (102, '北大西门咖啡', 'cafe', ST_SetSRID(ST_MakePoint(116.2998, 39.9929), 4326)::geography, '北京大学西门附近', 4.20, 2, '08:00-21:00', NULL, (SELECT id FROM scenic_spots WHERE name LIKE '%北京大学%' LIMIT 1), 'seed', 'pku-food-westgate-coffee', '{"cuisine":"coffee_shop;cake"}'::jsonb),
    (103, '未名湖畔茶饮', 'cafe', ST_SetSRID(ST_MakePoint(116.3052, 39.9931), 4326)::geography, '未名湖东侧步行区', 4.00, 2, '09:00-20:00', NULL, (SELECT id FROM scenic_spots WHERE name LIKE '%北京大学%' LIMIT 1), 'seed', 'pku-food-weiming-tea', '{"cuisine":"tea;bubble_tea"}'::jsonb),
    (104, '畅春园快餐', 'fast_food', ST_SetSRID(ST_MakePoint(116.3104, 39.9905), 4326)::geography, '畅春园宿舍区附近', 3.90, 1, '07:00-22:00', NULL, (SELECT id FROM scenic_spots WHERE name LIKE '%北京大学%' LIMIT 1), 'seed', 'pku-food-changchunyuan', '{"cuisine":"fast_food;chinese"}'::jsonb),
    (105, '北大东门面馆', 'restaurant', ST_SetSRID(ST_MakePoint(116.3142, 39.9923), 4326)::geography, '北京大学东门外', 4.10, 1, '10:00-21:00', NULL, (SELECT id FROM scenic_spots WHERE name LIKE '%北京大学%' LIMIT 1), 'seed', 'pku-food-eastgate-noodle', '{"cuisine":"noodles;chinese"}'::jsonb),
    (106, '中关园咖啡', 'cafe', ST_SetSRID(ST_MakePoint(116.3132, 39.9895), 4326)::geography, '中关园社区附近', 4.00, 2, '08:00-20:00', NULL, (SELECT id FROM scenic_spots WHERE name LIKE '%北京大学%' LIMIT 1), 'seed', 'pku-food-zhongguanyuan-coffee', '{"cuisine":"coffee_shop"}'::jsonb),
    (107, '北大南门小吃', 'fast_food', ST_SetSRID(ST_MakePoint(116.3070, 39.9866), 4326)::geography, '北京大学南门附近', 4.00, 1, '09:00-22:00', NULL, (SELECT id FROM scenic_spots WHERE name LIKE '%北京大学%' LIMIT 1), 'seed', 'pku-food-southgate-snack', '{"cuisine":"snack;street_food"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    type = EXCLUDED.type,
    location = EXCLUDED.location,
    address = EXCLUDED.address,
    rating = EXCLUDED.rating,
    price_level = EXCLUDED.price_level,
    opening_hours = EXCLUDED.opening_hours,
    phone = EXCLUDED.phone,
    scenic_spot_id = EXCLUDED.scenic_spot_id,
    source = EXCLUDED.source,
    source_ref = EXCLUDED.source_ref,
    source_tags = EXCLUDED.source_tags;

-- =====================================================
-- 创建 graph_nodes 关联设施到景点
-- graph_nodes IDs 108-162 (接续现有 max=107)
-- =====================================================
INSERT INTO graph_nodes (id, name, location, node_type, facility_id, scenic_spot_id)
SELECT v.id, v.name, v.location, v.node_type, v.facility_id, f.scenic_spot_id
FROM (VALUES
    -- 故宫片区 (scenic_spot_id=12)
    (108, '故宫冰窖餐厅节点', ST_SetSRID(ST_MakePoint(116.3950, 39.9190), 4326)::geography, 'facility', 53),
    (109, '角楼咖啡神武门店节点', ST_SetSRID(ST_MakePoint(116.3990, 39.9245), 4326)::geography, 'facility', 54),
    (110, '午门西侧快餐节点', ST_SetSRID(ST_MakePoint(116.3960, 39.9135), 4326)::geography, 'facility', 97),

    -- 天安门片区 (scenic_spot_id=10)
    (111, '国家大剧院咖啡节点', ST_SetSRID(ST_MakePoint(116.3930, 39.9045), 4326)::geography, 'facility', 59),
    (112, '前门M餐厅节点', ST_SetSRID(ST_MakePoint(116.3990, 39.9020), 4326)::geography, 'facility', 60),

    -- 景山 (scenic_spot_id=14)
    (113, '景山小吃节点', ST_SetSRID(ST_MakePoint(116.3960, 39.9280), 4326)::geography, 'facility', 61),
    (114, '景山茶社节点', ST_SetSRID(ST_MakePoint(116.3965, 39.9250), 4326)::geography, 'facility', 62),

    -- 中山公园 (scenic_spot_id=15)
    (115, '来今雨轩节点', ST_SetSRID(ST_MakePoint(116.3940, 39.9110), 4326)::geography, 'facility', 63),

    -- 北海公园 (scenic_spot_id=16)
    (116, '仿膳饭庄节点', ST_SetSRID(ST_MakePoint(116.3910, 39.9260), 4326)::geography, 'facility', 64),
    (117, '烤肉季节点', ST_SetSRID(ST_MakePoint(116.3890, 39.9340), 4326)::geography, 'facility', 65),
    (118, '庆云楼节点', ST_SetSRID(ST_MakePoint(116.3885, 39.9335), 4326)::geography, 'facility', 66),
    (119, '孔乙己酒家节点', ST_SetSRID(ST_MakePoint(116.3880, 39.9330), 4326)::geography, 'facility', 67),
    (120, '茶家傅节点', ST_SetSRID(ST_MakePoint(116.3870, 39.9320), 4326)::geography, 'facility', 68),
    (121, '云南菜节点', ST_SetSRID(ST_MakePoint(116.3875, 39.9350), 4326)::geography, 'facility', 79),
    (122, '静一餐厅节点', ST_SetSRID(ST_MakePoint(116.3870, 39.9345), 4326)::geography, 'facility', 80),

    -- 南锣鼓巷 (scenic_spot_id=18)
    (123, '文宇奶酪节点', ST_SetSRID(ST_MakePoint(116.4020, 39.9375), 4326)::geography, 'facility', 69),
    (124, '鬼味烤翅节点', ST_SetSRID(ST_MakePoint(116.4025, 39.9380), 4326)::geography, 'facility', 70),

    -- 天坛 (scenic_spot_id=13)
    (125, '回音壁咖啡节点', ST_SetSRID(ST_MakePoint(116.4100, 39.8820), 4326)::geography, 'facility', 81),
    (126, '炒肝赵节点', ST_SetSRID(ST_MakePoint(116.4110, 39.8850), 4326)::geography, 'facility', 82),
    (127, '红桥美食节点', ST_SetSRID(ST_MakePoint(116.4130, 39.8830), 4326)::geography, 'facility', 83),

    -- 前门片区 (天安门-广场 10)
    (128, '全聚德节点', ST_SetSRID(ST_MakePoint(116.3965, 39.8975), 4326)::geography, 'facility', 55),
    (129, '都一处节点', ST_SetSRID(ST_MakePoint(116.3968, 39.8980), 4326)::geography, 'facility', 56),
    (130, '东来顺节点', ST_SetSRID(ST_MakePoint(116.3970, 39.8990), 4326)::geography, 'facility', 57),
    (131, '爆肚冯节点', ST_SetSRID(ST_MakePoint(116.3960, 39.8970), 4326)::geography, 'facility', 58),
    (132, '鲜鱼口美食节点', ST_SetSRID(ST_MakePoint(116.3980, 39.8985), 4326)::geography, 'facility', 84),
    (133, '陈记卤煮节点', ST_SetSRID(ST_MakePoint(116.3955, 39.8975), 4326)::geography, 'facility', 85),
    (134, 'Soloist咖啡节点', ST_SetSRID(ST_MakePoint(116.3940, 39.8960), 4326)::geography, 'facility', 86),
    (135, '门框卤煮节点', ST_SetSRID(ST_MakePoint(116.3950, 39.8970), 4326)::geography, 'facility', 87),
    (136, '炸酱面大王节点', ST_SetSRID(ST_MakePoint(116.3975, 39.8990), 4326)::geography, 'facility', 88),

    -- 国家博物馆 (国家博物院暂无直接ID，用天安门=10 代替)
    (137, '国博咖啡节点', ST_SetSRID(ST_MakePoint(116.4005, 39.9050), 4326)::geography, 'facility', 89),

    -- 王府井 / 灯市口 (天安门东片区)
    (138, '东来顺总店节点', ST_SetSRID(ST_MakePoint(116.4130, 39.9155), 4326)::geography, 'facility', 90),
    (139, '狗不理节点', ST_SetSRID(ST_MakePoint(116.4120, 39.9150), 4326)::geography, 'facility', 91),
    (140, '鼎泰丰节点', ST_SetSRID(ST_MakePoint(116.4140, 39.9150), 4326)::geography, 'facility', 92),
    (141, 'APM星巴克节点', ST_SetSRID(ST_MakePoint(116.4140, 39.9145), 4326)::geography, 'facility', 93),
    (142, '四季民福灯市口节点', ST_SetSRID(ST_MakePoint(116.4160, 39.9180), 4326)::geography, 'facility', 94),
    (143, '川办餐厅节点', ST_SetSRID(ST_MakePoint(116.4155, 39.9175), 4326)::geography, 'facility', 95),
    (144, '东华门烤鸭快线节点', ST_SetSRID(ST_MakePoint(116.4010, 39.9160), 4326)::geography, 'facility', 96),

    -- 簋街 / 雍和宫 (无直接景点ID，用南锣=18)
    (145, '胡大饭馆节点', ST_SetSRID(ST_MakePoint(116.4250, 39.9380), 4326)::geography, 'facility', 71),
    (146, '花家怡园节点', ST_SetSRID(ST_MakePoint(116.4255, 39.9385), 4326)::geography, 'facility', 72),
    (147, '金鼎轩节点', ST_SetSRID(ST_MakePoint(116.4180, 39.9460), 4326)::geography, 'facility', 73),
    (148, '北新桥卤煮节点', ST_SetSRID(ST_MakePoint(116.4200, 39.9400), 4326)::geography, 'facility', 74),

    -- 鼓楼片区
    (149, '姚记炒肝节点', ST_SetSRID(ST_MakePoint(116.3970, 39.9400), 4326)::geography, 'facility', 75),
    (150, '糖房咖啡节点', ST_SetSRID(ST_MakePoint(116.3980, 39.9410), 4326)::geography, 'facility', 76),
    (151, '李记涮肉节点', ST_SetSRID(ST_MakePoint(116.3960, 39.9415), 4326)::geography, 'facility', 77),
    (152, '烤肉宛节点', ST_SetSRID(ST_MakePoint(116.3950, 39.9390), 4326)::geography, 'facility', 78),

    -- 北京大学校园餐饮
    (153, '农园食堂节点', ST_SetSRID(ST_MakePoint(116.3056, 39.9944), 4326)::geography, 'facility', 98),
    (154, '燕南美食节点', ST_SetSRID(ST_MakePoint(116.3042, 39.9904), 4326)::geography, 'facility', 99),
    (155, '学一食堂节点', ST_SetSRID(ST_MakePoint(116.3007, 39.9910), 4326)::geography, 'facility', 100),
    (156, '家园食堂节点', ST_SetSRID(ST_MakePoint(116.3018, 39.9888), 4326)::geography, 'facility', 101),
    (157, '北大西门咖啡节点', ST_SetSRID(ST_MakePoint(116.2998, 39.9929), 4326)::geography, 'facility', 102),
    (158, '未名湖畔茶饮节点', ST_SetSRID(ST_MakePoint(116.3052, 39.9931), 4326)::geography, 'facility', 103),
    (159, '畅春园快餐节点', ST_SetSRID(ST_MakePoint(116.3104, 39.9905), 4326)::geography, 'facility', 104),
    (160, '北大东门面馆节点', ST_SetSRID(ST_MakePoint(116.3142, 39.9923), 4326)::geography, 'facility', 105),
    (161, '中关园咖啡节点', ST_SetSRID(ST_MakePoint(116.3132, 39.9895), 4326)::geography, 'facility', 106),
    (162, '北大南门小吃节点', ST_SetSRID(ST_MakePoint(116.3070, 39.9866), 4326)::geography, 'facility', 107)
) AS v(id, name, location, node_type, facility_id)
JOIN facilities f ON f.id = v.facility_id
WHERE f.scenic_spot_id IS NOT NULL
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    location = EXCLUDED.location,
    node_type = EXCLUDED.node_type,
    facility_id = EXCLUDED.facility_id,
    scenic_spot_id = EXCLUDED.scenic_spot_id;
SELECT setval('facilities_id_seq', (SELECT MAX(id) FROM facilities));
SELECT setval('graph_nodes_id_seq', (SELECT MAX(id) FROM graph_nodes));

COMMIT;
