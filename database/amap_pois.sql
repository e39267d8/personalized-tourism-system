SET client_encoding = 'UTF8';
BEGIN;

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '天安门广场',
    '天安门广场，东长安街。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.397755, 39.903182), 4326)::geography,
    1,
    4.20,
    0,
    '东长安街',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY[''],
    '',
    ARRAY['城市广场', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '天安门广场' AND address = '东长安街'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '天安门',
    '天安门，长安街北侧。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.397463, 39.909187), 4326)::geography,
    1,
    4.20,
    0,
    '长安街北侧',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY[''],
    '',
    ARRAY['国家级景点', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '天安门' AND address = '长安街北侧'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '故宫博物院',
    '故宫博物院，景山前街4号。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.397029, 39.917839), 4326)::geography,
    1,
    4.20,
    0,
    '景山前街4号',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY[''],
    '',
    ARRAY['博物馆', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '故宫博物院' AND address = '景山前街4号'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '天坛公园',
    '天坛公园，天坛东里甲1号。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.410829, 39.881913), 4326)::geography,
    1,
    4.20,
    0,
    '天坛东里甲1号',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY[''],
    '',
    ARRAY['公园', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '天坛公园' AND address = '天坛东里甲1号'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '景山公园',
    '景山公园，景山西街44号。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.396551, 39.925875), 4326)::geography,
    1,
    4.20,
    0,
    '景山西街44号',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY[''],
    '',
    ARRAY['公园', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '景山公园' AND address = '景山西街44号'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '中山公园',
    '中山公园，中华路4号(天安门西侧)。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.394407, 39.910707), 4326)::geography,
    1,
    4.20,
    0,
    '中华路4号(天安门西侧)',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY[''],
    '',
    ARRAY['公园', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '中山公园' AND address = '中华路4号(天安门西侧)'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '北海公园',
    '北海公园，文津街1号。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.391802, 39.928775), 4326)::geography,
    1,
    4.20,
    0,
    '文津街1号',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY[''],
    '',
    ARRAY['公园', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '北海公园' AND address = '文津街1号'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '故宫博物院-午门',
    '故宫博物院-午门，东华门街道景山前街4号故宫博物院内(南侧)。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.397228, 39.913582), 4326)::geography,
    1,
    4.20,
    0,
    '东华门街道景山前街4号故宫博物院内(南侧)',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY[''],
    '',
    ARRAY['风景名胜', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '故宫博物院-午门' AND address = '东华门街道景山前街4号故宫博物院内(南侧)'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '南锣鼓巷',
    '南锣鼓巷，交道口街道南大街(南锣鼓巷地铁站E西北口旁)。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.402394, 39.937182), 4326)::geography,
    1,
    4.20,
    0,
    '交道口街道南大街(南锣鼓巷地铁站E西北口旁)',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY[''],
    '',
    ARRAY['风景名胜', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '南锣鼓巷' AND address = '交道口街道南大街(南锣鼓巷地铁站E西北口旁)'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '天安门-城楼',
    '天安门-城楼，东长安街天安门(天安门东地铁站A西北入口步行290米)。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.397488, 39.908717), 4326)::geography,
    1,
    4.20,
    0,
    '东长安街天安门(天安门东地铁站A西北入口步行290米)',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY[''],
    '',
    ARRAY['国家级景点', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '天安门-城楼' AND address = '东长安街天安门(天安门东地铁站A西北入口步行290米)'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '天安门广场-国旗',
    '天安门广场-国旗，东华门街道景山前街4号天安门广场内(北侧)。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.397554, 39.906928), 4326)::geography,
    1,
    4.20,
    0,
    '东华门街道景山前街4号天安门广场内(北侧)',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY[''],
    '',
    ARRAY['风景名胜', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '天安门广场-国旗' AND address = '东华门街道景山前街4号天安门广场内(北侧)'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '太庙',
    '太庙，东华门街道东长安街北京市劳动人民文化宫。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.399898, 39.911374), 4326)::geography,
    1,
    4.20,
    0,
    '东华门街道东长安街北京市劳动人民文化宫',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY[''],
    '',
    ARRAY['寺庙道观', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '太庙' AND address = '东华门街道东长安街北京市劳动人民文化宫'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '北京明城墙遗址公园',
    '北京明城墙遗址公园，崇文门东大街9号。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.427901, 39.901264), 4326)::geography,
    1,
    4.20,
    0,
    '崇文门东大街9号',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY[''],
    '',
    ARRAY['公园', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '北京明城墙遗址公园' AND address = '崇文门东大街9号'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '景山公园-绮望楼',
    '景山公园-绮望楼，什刹海街道景山西街44号(故宫后门对面)景山公园内(南侧)。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.396720, 39.924029), 4326)::geography,
    1,
    4.20,
    0,
    '什刹海街道景山西街44号(故宫后门对面)景山公园内(南侧)',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY[''],
    '',
    ARRAY['风景名胜', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '景山公园-绮望楼' AND address = '什刹海街道景山西街44号(故宫后门对面)景山公园内(南侧)'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '什刹海',
    '什刹海，地安门西大街49号。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.385121, 39.941893), 4326)::geography,
    1,
    4.20,
    0,
    '地安门西大街49号',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY[''],
    '',
    ARRAY['国家级景点', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '什刹海' AND address = '地安门西大街49号'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '正阳门箭楼',
    '正阳门箭楼，前门大街2号前门商业区A2地块。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.397910, 39.899368), 4326)::geography,
    1,
    4.20,
    0,
    '前门大街2号前门商业区A2地块',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY[''],
    '',
    ARRAY['风景名胜', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '正阳门箭楼' AND address = '前门大街2号前门商业区A2地块'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '故宫博物院-神武门',
    '故宫博物院-神武门，景山前街4号北京故宫博物馆。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.396786, 39.922305), 4326)::geography,
    1,
    4.20,
    0,
    '景山前街4号北京故宫博物馆',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY[''],
    '',
    ARRAY['国家级景点', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '故宫博物院-神武门' AND address = '景山前街4号北京故宫博物馆'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '翰林院遗址',
    '翰林院遗址，东长安街路南公安部内。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.406144, 39.905487), 4326)::geography,
    1,
    4.20,
    0,
    '东长安街路南公安部内',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY[''],
    '',
    ARRAY['风景名胜', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '翰林院遗址' AND address = '东长安街路南公安部内'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '雍和宫',
    '雍和宫，雍和宫大街28号(雍和宫地铁站F东南口步行250米)。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.417296, 39.947239), 4326)::geography,
    1,
    4.20,
    0,
    '雍和宫大街28号(雍和宫地铁站F东南口步行250米)',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY[''],
    '',
    ARRAY['风景名胜', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '雍和宫' AND address = '雍和宫大街28号(雍和宫地铁站F东南口步行250米)'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '恭王府博物馆',
    '恭王府博物馆，前海西街17号。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.386315, 39.937222), 4326)::geography,
    1,
    4.20,
    0,
    '前海西街17号',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY[''],
    '',
    ARRAY['国家级景点', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '恭王府博物馆' AND address = '前海西街17号'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '天坛公园-祈年殿',
    '天坛公园-祈年殿，天坛街道天坛东路甲1号天坛公园内。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.412867, 39.883659), 4326)::geography,
    1,
    4.20,
    0,
    '天坛街道天坛东路甲1号天坛公园内',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY[''],
    '',
    ARRAY['风景名胜', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '天坛公园-祈年殿' AND address = '天坛街道天坛东路甲1号天坛公园内'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '陶然亭公园',
    '陶然亭公园，太平街19号。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.381921, 39.874496), 4326)::geography,
    1,
    4.20,
    0,
    '太平街19号',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY[''],
    '',
    ARRAY['公园', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '陶然亭公园' AND address = '太平街19号'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '智化寺',
    '智化寺，禄米仓胡同5号。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.432325, 39.917621), 4326)::geography,
    1,
    4.20,
    0,
    '禄米仓胡同5号',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY[''],
    '',
    ARRAY['寺庙道观', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '智化寺' AND address = '禄米仓胡同5号'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '日坛公园',
    '日坛公园，朝外街道朝阳门外日坛北路6号。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.443795, 39.915538), 4326)::geography,
    1,
    4.20,
    0,
    '朝外街道朝阳门外日坛北路6号',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY[''],
    '',
    ARRAY['公园', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '日坛公园' AND address = '朝外街道朝阳门外日坛北路6号'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '龙潭公园',
    '龙潭公园，龙潭路16号。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.438258, 39.879792), 4326)::geography,
    1,
    4.20,
    0,
    '龙潭路16号',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY[''],
    '',
    ARRAY['国家级景点', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '龙潭公园' AND address = '龙潭路16号'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '法源寺',
    '法源寺，法源寺前街7号。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.369880, 39.885385), 4326)::geography,
    1,
    4.20,
    0,
    '法源寺前街7号',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY[''],
    '',
    ARRAY['寺庙道观', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '法源寺' AND address = '法源寺前街7号'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '东单公园',
    '东单公园，崇文门内大街9号(东单地铁站H西南口步行380米)。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.417090, 39.904917), 4326)::geography,
    1,
    4.20,
    0,
    '崇文门内大街9号(东单地铁站H西南口步行380米)',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY[''],
    '',
    ARRAY['公园', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '东单公园' AND address = '崇文门内大街9号(东单地铁站H西南口步行380米)'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '普度寺遗址',
    '普度寺遗址，普度寺前巷。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.404659, 39.913437), 4326)::geography,
    1,
    4.20,
    0,
    '普度寺前巷',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY[''],
    '',
    ARRAY['寺庙道观', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '普度寺遗址' AND address = '普度寺前巷'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '鼓楼',
    '鼓楼，钟楼湾胡同临字9号(什刹海地铁站A2西北口步行240米)。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.395937, 39.940781), 4326)::geography,
    1,
    4.20,
    0,
    '钟楼湾胡同临字9号(什刹海地铁站A2西北口步行240米)',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY[''],
    '',
    ARRAY['风景名胜', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '鼓楼' AND address = '钟楼湾胡同临字9号(什刹海地铁站A2西北口步行240米)'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '北大红楼',
    '北大红楼，五四大街29号。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.405361, 39.924710), 4326)::geography,
    1,
    4.20,
    0,
    '五四大街29号',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY[''],
    '',
    ARRAY['纪念馆', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '北大红楼' AND address = '五四大街29号'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '龙潭中湖公园',
    '龙潭中湖公园，左安门内大街19号。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.432072, 39.876755), 4326)::geography,
    1,
    4.20,
    0,
    '左安门内大街19号',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY[''],
    '',
    ARRAY['公园', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '龙潭中湖公园' AND address = '左安门内大街19号'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '地坛公园',
    '地坛公园，安定门外大街。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.414443, 39.953777), 4326)::geography,
    1,
    4.20,
    0,
    '安定门外大街',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY[''],
    '',
    ARRAY['公园', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '地坛公园' AND address = '安定门外大街'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '北京东交民巷使馆建筑群',
    '北京东交民巷使馆建筑群，崇文门东交民巷(崇文门地铁站A1西北口步行290米)。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.412620, 39.901299), 4326)::geography,
    1,
    4.20,
    0,
    '崇文门东交民巷(崇文门地铁站A1西北口步行290米)',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY[''],
    '',
    ARRAY['旅游景点', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '北京东交民巷使馆建筑群' AND address = '崇文门东交民巷(崇文门地铁站A1西北口步行290米)'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '敕建火德真君庙',
    '敕建火德真君庙，地安门外大街77号(什刹海地铁站C口马路对面)。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.395569, 39.937013), 4326)::geography,
    1,
    4.20,
    0,
    '地安门外大街77号(什刹海地铁站C口马路对面)',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY[''],
    '',
    ARRAY['寺庙道观', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '敕建火德真君庙' AND address = '地安门外大街77号(什刹海地铁站C口马路对面)'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '景山公园-万春亭',
    '景山公园-万春亭，景山西街44号景山公园内。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.396715, 39.924863), 4326)::geography,
    1,
    4.20,
    0,
    '景山西街44号景山公园内',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY[''],
    '',
    ARRAY['风景名胜', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '景山公园-万春亭' AND address = '景山西街44号景山公园内'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '正阳门城楼',
    '正阳门城楼，前门大街北端。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.397902, 39.900583), 4326)::geography,
    1,
    4.20,
    0,
    '前门大街北端',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY[''],
    '',
    ARRAY['旅游景点', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '正阳门城楼' AND address = '前门大街北端'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '天主教北京总教区王府井天主堂东堂',
    '天主教北京总教区王府井天主堂东堂，王府井大街74号。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.411945, 39.917288), 4326)::geography,
    1,
    4.20,
    0,
    '王府井大街74号',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY[''],
    '',
    ARRAY['教堂', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '天主教北京总教区王府井天主堂东堂' AND address = '王府井大街74号'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '菖蒲河公园',
    '菖蒲河公园，菖蒲河沿9号(天安门东地铁站B东北口步行200米)。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.403456, 39.908566), 4326)::geography,
    1,
    4.20,
    0,
    '菖蒲河沿9号(天安门东地铁站B东北口步行200米)',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY[''],
    '',
    ARRAY['公园', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '菖蒲河公园' AND address = '菖蒲河沿9号(天安门东地铁站B东北口步行200米)'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '玉渊潭公园',
    '玉渊潭公园，西三环中路10号。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.319932, 39.916620), 4326)::geography,
    1,
    4.20,
    0,
    '西三环中路10号',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY[''],
    '',
    ARRAY['国家级景点', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '玉渊潭公园' AND address = '西三环中路10号'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '人民英雄纪念碑',
    '人民英雄纪念碑，天安门广场(长安街中心)。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.397691, 39.904632), 4326)::geography,
    1,
    4.20,
    0,
    '天安门广场(长安街中心)',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY[''],
    '',
    ARRAY['纪念馆', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '人民英雄纪念碑' AND address = '天安门广场(长安街中心)'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '妙应寺白塔',
    '妙应寺白塔，阜成门内大街171号。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.363323, 39.925652), 4326)::geography,
    1,
    4.20,
    0,
    '阜成门内大街171号',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY[''],
    '',
    ARRAY['寺庙道观', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '妙应寺白塔' AND address = '阜成门内大街171号'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '国子监',
    '国子监，国子监街13-15号。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.413285, 39.946777), 4326)::geography,
    1,
    4.20,
    0,
    '国子监街13-15号',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY[''],
    '',
    ARRAY['国家级景点', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '国子监' AND address = '国子监街13-15号'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '广济寺',
    '广济寺，阜成门内大街25号(西四地铁站B东北口步行200米)。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.372321, 39.924971), 4326)::geography,
    1,
    4.20,
    0,
    '阜成门内大街25号(西四地铁站B东北口步行200米)',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY[''],
    '',
    ARRAY['寺庙道观', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '广济寺' AND address = '阜成门内大街25号(西四地铁站B东北口步行200米)'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '什刹海-后海',
    '什刹海-后海，羊房胡同甲23-3号。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.385260, 39.943559), 4326)::geography,
    1,
    4.20,
    0,
    '羊房胡同甲23-3号',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY[''],
    '',
    ARRAY['风景名胜', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '什刹海-后海' AND address = '羊房胡同甲23-3号'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '白云观',
    '白云观，白云观街7号。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.343778, 39.901266), 4326)::geography,
    1,
    4.20,
    0,
    '白云观街7号',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY[''],
    '',
    ARRAY['寺庙道观', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '白云观' AND address = '白云观街7号'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '朝阳公园',
    '朝阳公园，朝阳公园南路1号。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.482276, 39.944093), 4326)::geography,
    1,
    4.20,
    0,
    '朝阳公园南路1号',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY[''],
    '',
    ARRAY['公园', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '朝阳公园' AND address = '朝阳公园南路1号'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '北京悬空玻璃艺术馆',
    '北京悬空玻璃艺术馆，王府井大街银泰in88二层南侧(金鱼胡同地铁站B东口旁)。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.412114, 39.915876), 4326)::geography,
    1,
    4.20,
    0,
    '王府井大街银泰in88二层南侧(金鱼胡同地铁站B东口旁)',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY[''],
    '',
    ARRAY['旅游景点', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '北京悬空玻璃艺术馆' AND address = '王府井大街银泰in88二层南侧(金鱼胡同地铁站B东口旁)'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '天主教北京总教区西什库主教座堂',
    '天主教北京总教区西什库主教座堂，西什库大街33号。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.378751, 39.925492), 4326)::geography,
    1,
    4.20,
    0,
    '西什库大街33号',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY[''],
    '',
    ARRAY['教堂', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '天主教北京总教区西什库主教座堂' AND address = '西什库大街33号'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '天坛公园-回音壁',
    '天坛公园-回音壁，天坛街道天坛路甲1号天坛公园内(东南角)。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.413074, 39.878072), 4326)::geography,
    1,
    4.20,
    0,
    '天坛街道天坛路甲1号天坛公园内(东南角)',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY[''],
    '',
    ARRAY['风景名胜', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '天坛公园-回音壁' AND address = '天坛街道天坛路甲1号天坛公园内(东南角)'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '团结湖公园',
    '团结湖公园，团结湖南里路16号(呼家楼地铁站B东北口步行190米)。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.464372, 39.925741), 4326)::geography,
    1,
    4.20,
    0,
    '团结湖南里路16号(呼家楼地铁站B东北口步行190米)',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY[''],
    '',
    ARRAY['公园', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '团结湖公园' AND address = '团结湖南里路16号(呼家楼地铁站B东北口步行190米)'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '先农坛',
    '先农坛，东经路21号北京古代建筑博物馆。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.392206, 39.876929), 4326)::geography,
    1,
    4.20,
    0,
    '东经路21号北京古代建筑博物馆',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY[''],
    '',
    ARRAY['风景名胜', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '先农坛' AND address = '东经路21号北京古代建筑博物馆'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '大观园',
    '大观园，南菜园街12号。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.355972, 39.871365), 4326)::geography,
    1,
    4.20,
    0,
    '南菜园街12号',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY[''],
    '',
    ARRAY['省级景点', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '大观园' AND address = '南菜园街12号'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '纪晓岚故居',
    '纪晓岚故居，珠市口西大街241号(虎坊桥地铁站B东北口步行170米)。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.387191, 39.890058), 4326)::geography,
    1,
    4.20,
    0,
    '珠市口西大街241号(虎坊桥地铁站B东北口步行170米)',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY[''],
    '',
    ARRAY['纪念馆', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '纪晓岚故居' AND address = '珠市口西大街241号(虎坊桥地铁站B东北口步行170米)'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '后海公园',
    '后海公园，后海北沿50号(近鼓楼西大街)。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.382590, 39.942143), 4326)::geography,
    1,
    4.20,
    0,
    '后海北沿50号(近鼓楼西大街)',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY[''],
    '',
    ARRAY['公园', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '后海公园' AND address = '后海北沿50号(近鼓楼西大街)'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '东岳庙',
    '东岳庙，朝阳门外大街141号。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.443770, 39.924932), 4326)::geography,
    1,
    4.20,
    0,
    '朝阳门外大街141号',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY[''],
    '',
    ARRAY['寺庙道观', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '东岳庙' AND address = '朝阳门外大街141号'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '故宫博物院-端门',
    '故宫博物院-端门，景山前街4号故宫博物院内(南侧)。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.397413, 39.910396), 4326)::geography,
    1,
    4.20,
    0,
    '景山前街4号故宫博物院内(南侧)',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY[''],
    '',
    ARRAY['风景名胜', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '故宫博物院-端门' AND address = '景山前街4号故宫博物院内(南侧)'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '故宫博物院-东北角楼',
    '故宫博物院-东北角楼，景山前街4号北京故宫博物馆。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.401021, 39.922473), 4326)::geography,
    1,
    4.20,
    0,
    '景山前街4号北京故宫博物馆',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY[''],
    '',
    ARRAY['风景名胜', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '故宫博物院-东北角楼' AND address = '景山前街4号北京故宫博物馆'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '北京动物园',
    '北京动物园，西直门外大街137号。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.336701, 39.942105), 4326)::geography,
    1,
    4.20,
    0,
    '西直门外大街137号',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY[''],
    '',
    ARRAY['动物园', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '北京动物园' AND address = '西直门外大街137号'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '故宫博物院-西南角楼',
    '故宫博物院-西南角楼，景山前街4号故宫博物院(西南角)。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.392983, 39.913741), 4326)::geography,
    1,
    4.20,
    0,
    '景山前街4号故宫博物院(西南角)',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY[''],
    '',
    ARRAY['风景名胜', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '故宫博物院-西南角楼' AND address = '景山前街4号故宫博物院(西南角)'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '天坛公园-双环万寿亭',
    '天坛公园-双环万寿亭，天坛东路甲1号天坛公园内(西北角)。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.406883, 39.883629), 4326)::geography,
    1,
    4.20,
    0,
    '天坛东路甲1号天坛公园内(西北角)',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY[''],
    '',
    ARRAY['风景名胜', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '天坛公园-双环万寿亭' AND address = '天坛东路甲1号天坛公园内(西北角)'
);

COMMIT;
