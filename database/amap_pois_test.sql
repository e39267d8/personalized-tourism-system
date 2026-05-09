SET client_encoding = 'UTF8';
BEGIN;

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '天安门广场',
    '天安门广场，位于北京市北京市东长安街。数据来源：高德地图开放平台 POI。',
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
    ARRAY['城市广场', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '天安门广场'
      AND COALESCE(address, '') = '东长安街'
      AND COALESCE(city, '') = '北京市'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '天安门',
    '天安门，位于北京市北京市长安街北侧。数据来源：高德地图开放平台 POI。',
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
    ARRAY['国家级景点', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '天安门'
      AND COALESCE(address, '') = '长安街北侧'
      AND COALESCE(city, '') = '北京市'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '故宫博物院',
    '故宫博物院，位于北京市北京市景山前街4号。数据来源：高德地图开放平台 POI。',
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
    ARRAY['博物馆', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '故宫博物院'
      AND COALESCE(address, '') = '景山前街4号'
      AND COALESCE(city, '') = '北京市'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '天坛公园',
    '天坛公园，位于北京市北京市天坛东里甲1号。数据来源：高德地图开放平台 POI。',
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
    ARRAY['公园', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '天坛公园'
      AND COALESCE(address, '') = '天坛东里甲1号'
      AND COALESCE(city, '') = '北京市'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '景山公园',
    '景山公园，位于北京市北京市景山西街44号。数据来源：高德地图开放平台 POI。',
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
    ARRAY['公园', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '景山公园'
      AND COALESCE(address, '') = '景山西街44号'
      AND COALESCE(city, '') = '北京市'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '中山公园',
    '中山公园，位于北京市北京市中华路4号(天安门西侧)。数据来源：高德地图开放平台 POI。',
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
    ARRAY['公园', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '中山公园'
      AND COALESCE(address, '') = '中华路4号(天安门西侧)'
      AND COALESCE(city, '') = '北京市'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '北海公园',
    '北海公园，位于北京市北京市文津街1号。数据来源：高德地图开放平台 POI。',
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
    ARRAY['公园', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '北海公园'
      AND COALESCE(address, '') = '文津街1号'
      AND COALESCE(city, '') = '北京市'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '故宫博物院-午门',
    '故宫博物院-午门，位于北京市北京市东华门街道景山前街4号故宫博物院内(南侧)。数据来源：高德地图开放平台 POI。',
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
    ARRAY['风景名胜', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '故宫博物院-午门'
      AND COALESCE(address, '') = '东华门街道景山前街4号故宫博物院内(南侧)'
      AND COALESCE(city, '') = '北京市'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '南锣鼓巷',
    '南锣鼓巷，位于北京市北京市交道口街道南大街(南锣鼓巷地铁站E西北口旁)。数据来源：高德地图开放平台 POI。',
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
    ARRAY['风景名胜', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '南锣鼓巷'
      AND COALESCE(address, '') = '交道口街道南大街(南锣鼓巷地铁站E西北口旁)'
      AND COALESCE(city, '') = '北京市'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '天安门-城楼',
    '天安门-城楼，位于北京市北京市东长安街天安门(天安门东地铁站A西北入口步行290米)。数据来源：高德地图开放平台 POI。',
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
    ARRAY['国家级景点', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '天安门-城楼'
      AND COALESCE(address, '') = '东长安街天安门(天安门东地铁站A西北入口步行290米)'
      AND COALESCE(city, '') = '北京市'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '天安门广场-国旗',
    '天安门广场-国旗，位于北京市北京市东华门街道景山前街4号天安门广场内(北侧)。数据来源：高德地图开放平台 POI。',
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
    ARRAY['风景名胜', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '天安门广场-国旗'
      AND COALESCE(address, '') = '东华门街道景山前街4号天安门广场内(北侧)'
      AND COALESCE(city, '') = '北京市'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '太庙',
    '太庙，位于北京市北京市东华门街道东长安街北京市劳动人民文化宫。数据来源：高德地图开放平台 POI。',
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
    ARRAY['寺庙道观', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '太庙'
      AND COALESCE(address, '') = '东华门街道东长安街北京市劳动人民文化宫'
      AND COALESCE(city, '') = '北京市'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '北京明城墙遗址公园',
    '北京明城墙遗址公园，位于北京市北京市崇文门东大街9号。数据来源：高德地图开放平台 POI。',
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
    ARRAY['公园', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '北京明城墙遗址公园'
      AND COALESCE(address, '') = '崇文门东大街9号'
      AND COALESCE(city, '') = '北京市'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '景山公园-绮望楼',
    '景山公园-绮望楼，位于北京市北京市什刹海街道景山西街44号(故宫后门对面)景山公园内(南侧)。数据来源：高德地图开放平台 POI。',
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
    ARRAY['风景名胜', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '景山公园-绮望楼'
      AND COALESCE(address, '') = '什刹海街道景山西街44号(故宫后门对面)景山公园内(南侧)'
      AND COALESCE(city, '') = '北京市'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '什刹海',
    '什刹海，位于北京市北京市地安门西大街49号。数据来源：高德地图开放平台 POI。',
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
    ARRAY['国家级景点', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '什刹海'
      AND COALESCE(address, '') = '地安门西大街49号'
      AND COALESCE(city, '') = '北京市'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '正阳门箭楼',
    '正阳门箭楼，位于北京市北京市前门大街2号前门商业区A2地块。数据来源：高德地图开放平台 POI。',
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
    ARRAY['风景名胜', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '正阳门箭楼'
      AND COALESCE(address, '') = '前门大街2号前门商业区A2地块'
      AND COALESCE(city, '') = '北京市'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '故宫博物院-神武门',
    '故宫博物院-神武门，位于北京市北京市景山前街4号北京故宫博物馆。数据来源：高德地图开放平台 POI。',
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
    ARRAY['国家级景点', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '故宫博物院-神武门'
      AND COALESCE(address, '') = '景山前街4号北京故宫博物馆'
      AND COALESCE(city, '') = '北京市'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '翰林院遗址',
    '翰林院遗址，位于北京市北京市东长安街路南公安部内。数据来源：高德地图开放平台 POI。',
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
    ARRAY['风景名胜', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '翰林院遗址'
      AND COALESCE(address, '') = '东长安街路南公安部内'
      AND COALESCE(city, '') = '北京市'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '雍和宫',
    '雍和宫，位于北京市北京市雍和宫大街28号(雍和宫地铁站F东南口步行250米)。数据来源：高德地图开放平台 POI。',
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
    ARRAY['风景名胜', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '雍和宫'
      AND COALESCE(address, '') = '雍和宫大街28号(雍和宫地铁站F东南口步行250米)'
      AND COALESCE(city, '') = '北京市'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '恭王府博物馆',
    '恭王府博物馆，位于北京市北京市前海西街17号。数据来源：高德地图开放平台 POI。',
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
    ARRAY['国家级景点', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '恭王府博物馆'
      AND COALESCE(address, '') = '前海西街17号'
      AND COALESCE(city, '') = '北京市'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '长安街',
    '长安街，位于北京市北京市广场西侧路与西长安街交叉口。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.395456, 39.907552), 4326)::geography,
    1,
    4.20,
    0,
    '广场西侧路与西长安街交叉口',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY[''],
    '',
    ARRAY['风景名胜', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '长安街'
      AND COALESCE(address, '') = '广场西侧路与西长安街交叉口'
      AND COALESCE(city, '') = '北京市'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '智化寺',
    '智化寺，位于北京市北京市禄米仓胡同5号。数据来源：高德地图开放平台 POI。',
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
    ARRAY['寺庙道观', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '智化寺'
      AND COALESCE(address, '') = '禄米仓胡同5号'
      AND COALESCE(city, '') = '北京市'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '天坛公园-祈年殿',
    '天坛公园-祈年殿，位于北京市北京市天坛街道天坛东路甲1号天坛公园内。数据来源：高德地图开放平台 POI。',
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
    ARRAY['风景名胜', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '天坛公园-祈年殿'
      AND COALESCE(address, '') = '天坛街道天坛东路甲1号天坛公园内'
      AND COALESCE(city, '') = '北京市'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '外滩',
    '外滩，位于上海市上海市中山东二路1号。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(121.492127, 31.233516), 4326)::geography,
    1,
    4.20,
    0,
    '中山东二路1号',
    '上海市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY[''],
    '',
    ARRAY['风景名胜', '上海市', '上海市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '外滩'
      AND COALESCE(address, '') = '中山东二路1号'
      AND COALESCE(city, '') = '上海市'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '上海豫园',
    '上海豫园，位于上海市上海市福佑路168号。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(121.492497, 31.227714), 4326)::geography,
    1,
    4.20,
    0,
    '福佑路168号',
    '上海市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY[''],
    '',
    ARRAY['国家级景点', '上海市', '上海市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '上海豫园'
      AND COALESCE(address, '') = '福佑路168号'
      AND COALESCE(city, '') = '上海市'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '上海人民广场',
    '上海人民广场，位于上海市上海市人民大道185号。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(121.475213, 31.228827), 4326)::geography,
    1,
    4.20,
    0,
    '人民大道185号',
    '上海市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY[''],
    '',
    ARRAY['城市广场', '上海市', '上海市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '上海人民广场'
      AND COALESCE(address, '') = '人民大道185号'
      AND COALESCE(city, '') = '上海市'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '东方明珠广播电视塔',
    '东方明珠广播电视塔，位于上海市上海市世纪大道1号(陆家嘴地铁站1号入口步行220米)。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(121.499718, 31.239703), 4326)::geography,
    1,
    4.20,
    0,
    '世纪大道1号(陆家嘴地铁站1号入口步行220米)',
    '上海市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY[''],
    '',
    ARRAY['国家级景点', '上海市', '上海市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '东方明珠广播电视塔'
      AND COALESCE(address, '') = '世纪大道1号(陆家嘴地铁站1号入口步行220米)'
      AND COALESCE(city, '') = '上海市'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '上海城隍庙',
    '上海城隍庙，位于上海市上海市方浜中路249号。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(121.492466, 31.225879), 4326)::geography,
    1,
    4.20,
    0,
    '方浜中路249号',
    '上海市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY[''],
    '',
    ARRAY['寺庙道观', '上海市', '上海市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '上海城隍庙'
      AND COALESCE(address, '') = '方浜中路249号'
      AND COALESCE(city, '') = '上海市'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '上海四行仓库抗战纪念馆',
    '上海四行仓库抗战纪念馆，位于上海市上海市光复路21号(曲阜路地铁站2号口步行300米)。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(121.471104, 31.240340), 4326)::geography,
    1,
    4.20,
    0,
    '光复路21号(曲阜路地铁站2号口步行300米)',
    '上海市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY[''],
    '',
    ARRAY['纪念馆', '上海市', '上海市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '上海四行仓库抗战纪念馆'
      AND COALESCE(address, '') = '光复路21号(曲阜路地铁站2号口步行300米)'
      AND COALESCE(city, '') = '上海市'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '静安雕塑公园',
    '静安雕塑公园，位于上海市上海市石门二路128号(近北京西路)(自然博物馆地铁站1号口旁)。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(121.463871, 31.234819), 4326)::geography,
    1,
    4.20,
    0,
    '石门二路128号(近北京西路)(自然博物馆地铁站1号口旁)',
    '上海市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY[''],
    '',
    ARRAY['公园', '上海市', '上海市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '静安雕塑公园'
      AND COALESCE(address, '') = '石门二路128号(近北京西路)(自然博物馆地铁站1号口旁)'
      AND COALESCE(city, '') = '上海市'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '人民公园',
    '人民公园，位于上海市上海市南京西路231号。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(121.473115, 31.232135), 4326)::geography,
    1,
    4.20,
    0,
    '南京西路231号',
    '上海市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY[''],
    '',
    ARRAY['公园', '上海市', '上海市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '人民公园'
      AND COALESCE(address, '') = '南京西路231号'
      AND COALESCE(city, '') = '上海市'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    'LV巨轮',
    'LV巨轮，位于上海市上海市石门一路与吴江路交叉口南40米(南京西路地铁站5号口旁)。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(121.462166, 31.229952), 4326)::geography,
    1,
    4.20,
    0,
    '石门一路与吴江路交叉口南40米(南京西路地铁站5号口旁)',
    '上海市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY[''],
    '',
    ARRAY['风景名胜', '上海市', '上海市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = 'LV巨轮'
      AND COALESCE(address, '') = '石门一路与吴江路交叉口南40米(南京西路地铁站5号口旁)'
      AND COALESCE(city, '') = '上海市'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '静安寺',
    '静安寺，位于上海市上海市南京西路1686号(静安寺地铁站1号口步行60米)。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(121.445320, 31.223505), 4326)::geography,
    1,
    4.20,
    0,
    '南京西路1686号(静安寺地铁站1号口步行60米)',
    '上海市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY[''],
    '',
    ARRAY['寺庙道观', '上海市', '上海市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '静安寺'
      AND COALESCE(address, '') = '南京西路1686号(静安寺地铁站1号口步行60米)'
      AND COALESCE(city, '') = '上海市'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '福州路文化街',
    '福州路文化街，位于上海市上海市福州路。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(121.482638, 31.233826), 4326)::geography,
    1,
    4.20,
    0,
    '福州路',
    '上海市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY[''],
    '',
    ARRAY['旅游景点', '上海市', '上海市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '福州路文化街'
      AND COALESCE(address, '') = '福州路'
      AND COALESCE(city, '') = '上海市'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '万国建筑博览群',
    '万国建筑博览群，位于上海市上海市滇池路63号。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(121.489271, 31.237208), 4326)::geography,
    1,
    4.20,
    0,
    '滇池路63号',
    '上海市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY[''],
    '',
    ARRAY['风景名胜', '上海市', '上海市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '万国建筑博览群'
      AND COALESCE(address, '') = '滇池路63号'
      AND COALESCE(city, '') = '上海市'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '外滩观景台',
    '外滩观景台，位于上海市上海市外滩(西北角)。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(121.490482, 31.237247), 4326)::geography,
    1,
    4.20,
    0,
    '外滩(西北角)',
    '上海市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY[''],
    '',
    ARRAY['观景点', '上海市', '上海市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '外滩观景台'
      AND COALESCE(address, '') = '外滩(西北角)'
      AND COALESCE(city, '') = '上海市'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '太平桥公园',
    '太平桥公园，位于上海市上海市自忠路170号(一大会址·新天地地铁站1号口步行490米)。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(121.476898, 31.219676), 4326)::geography,
    1,
    4.20,
    0,
    '自忠路170号(一大会址·新天地地铁站1号口步行490米)',
    '上海市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY[''],
    '',
    ARRAY['公园', '上海市', '上海市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '太平桥公园'
      AND COALESCE(address, '') = '自忠路170号(一大会址·新天地地铁站1号口步行490米)'
      AND COALESCE(city, '') = '上海市'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '外白渡桥',
    '外白渡桥，位于上海市上海市北苏州路111号。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(121.490060, 31.242896), 4326)::geography,
    1,
    4.20,
    0,
    '北苏州路111号',
    '上海市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY[''],
    '',
    ARRAY['桥', '上海市', '上海市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '外白渡桥'
      AND COALESCE(address, '') = '北苏州路111号'
      AND COALESCE(city, '') = '上海市'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '辅德里公园',
    '辅德里公园，位于上海市上海市大沽路379号(南京西路地铁站8号口步行490米)。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(121.466665, 31.224808), 4326)::geography,
    1,
    4.20,
    0,
    '大沽路379号(南京西路地铁站8号口步行490米)',
    '上海市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY[''],
    '',
    ARRAY['公园', '上海市', '上海市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '辅德里公园'
      AND COALESCE(address, '') = '大沽路379号(南京西路地铁站8号口步行490米)'
      AND COALESCE(city, '') = '上海市'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '中国共产党第一次全国代表大会宿舍旧址(博文女校)',
    '中国共产党第一次全国代表大会宿舍旧址(博文女校)，位于上海市上海市太仓路127号(一大会址·黄陂南路地铁站2号口步行370米)。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(121.475811, 31.221655), 4326)::geography,
    1,
    4.20,
    0,
    '太仓路127号(一大会址·黄陂南路地铁站2号口步行370米)',
    '上海市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY[''],
    '',
    ARRAY['风景名胜', '上海市', '上海市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '中国共产党第一次全国代表大会宿舍旧址(博文女校)'
      AND COALESCE(address, '') = '太仓路127号(一大会址·黄陂南路地铁站2号口步行370米)'
      AND COALESCE(city, '') = '上海市'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '中共四大纪念馆',
    '中共四大纪念馆，位于上海市上海市四川北路1468号(四川北路地铁站1号口步行320米)。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(121.484916, 31.254995), 4326)::geography,
    1,
    4.20,
    0,
    '四川北路1468号(四川北路地铁站1号口步行320米)',
    '上海市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY[''],
    '',
    ARRAY['红色景区', '上海市', '上海市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '中共四大纪念馆'
      AND COALESCE(address, '') = '四川北路1468号(四川北路地铁站1号口步行320米)'
      AND COALESCE(city, '') = '上海市'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '北外滩滨江绿地',
    '北外滩滨江绿地，位于上海市上海市东大名路558-678。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(121.499372, 31.247461), 4326)::geography,
    1,
    4.20,
    0,
    '东大名路558-678',
    '上海市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY[''],
    '',
    ARRAY['公园', '上海市', '上海市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '北外滩滨江绿地'
      AND COALESCE(address, '') = '东大名路558-678'
      AND COALESCE(city, '') = '上海市'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '上海文化广场',
    '上海文化广场，位于上海市上海市茂名南路178号(陕西南路地铁站6号口步行390米)。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(121.462196, 31.211941), 4326)::geography,
    1,
    4.20,
    0,
    '茂名南路178号(陕西南路地铁站6号口步行390米)',
    '上海市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY[''],
    '',
    ARRAY['城市广场', '上海市', '上海市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '上海文化广场'
      AND COALESCE(address, '') = '茂名南路178号(陕西南路地铁站6号口步行390米)'
      AND COALESCE(city, '') = '上海市'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '外滩-观景大道',
    '外滩-观景大道，位于上海市上海市中山东一路(外滩)411号。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(121.490509, 31.238062), 4326)::geography,
    1,
    4.20,
    0,
    '中山东一路(外滩)411号',
    '上海市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY[''],
    '',
    ARRAY['风景名胜', '上海市', '上海市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '外滩-观景大道'
      AND COALESCE(address, '') = '中山东一路(外滩)411号'
      AND COALESCE(city, '') = '上海市'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '玉佛禅寺',
    '玉佛禅寺，位于上海市上海市安远路170号。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(121.445125, 31.241445), 4326)::geography,
    1,
    4.20,
    0,
    '安远路170号',
    '上海市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY[''],
    '',
    ARRAY['寺庙道观', '上海市', '上海市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '玉佛禅寺'
      AND COALESCE(address, '') = '安远路170号'
      AND COALESCE(city, '') = '上海市'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '城市阳台',
    '城市阳台，位于浙江省杭州市四季青街道之江路1078号。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(120.216803, 30.241827), 4326)::geography,
    1,
    4.20,
    0,
    '四季青街道之江路1078号',
    '杭州市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY[''],
    '',
    ARRAY['风景名胜', '杭州市', '浙江省'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '城市阳台'
      AND COALESCE(address, '') = '四季青街道之江路1078号'
      AND COALESCE(city, '') = '杭州市'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '钱江世纪公园',
    '钱江世纪公园，位于浙江省杭州市秋韵路a7-2号。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(120.237194, 30.244685), 4326)::geography,
    1,
    4.20,
    0,
    '秋韵路a7-2号',
    '杭州市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY[''],
    '',
    ARRAY['公园', '杭州市', '浙江省'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '钱江世纪公园'
      AND COALESCE(address, '') = '秋韵路a7-2号'
      AND COALESCE(city, '') = '杭州市'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '清河坊历史文化特色街区',
    '清河坊历史文化特色街区，位于浙江省杭州市河坊街180号。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(120.169899, 30.239827), 4326)::geography,
    1,
    4.20,
    0,
    '河坊街180号',
    '杭州市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY[''],
    '',
    ARRAY['国家级景点', '杭州市', '浙江省'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '清河坊历史文化特色街区'
      AND COALESCE(address, '') = '河坊街180号'
      AND COALESCE(city, '') = '杭州市'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '五柳巷历史街区',
    '五柳巷历史街区，位于浙江省杭州市小营街道斗富二桥西河下9号附近。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(120.176615, 30.242162), 4326)::geography,
    1,
    4.20,
    0,
    '小营街道斗富二桥西河下9号附近',
    '杭州市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY[''],
    '',
    ARRAY['风景名胜', '杭州市', '浙江省'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '五柳巷历史街区'
      AND COALESCE(address, '') = '小营街道斗富二桥西河下9号附近'
      AND COALESCE(city, '') = '杭州市'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '杭州西湖风景名胜区-断桥残雪',
    '杭州西湖风景名胜区-断桥残雪，位于浙江省杭州市龙井路1号杭州西湖风景名胜区内(东北角)。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(120.151347, 30.258151), 4326)::geography,
    1,
    4.20,
    0,
    '龙井路1号杭州西湖风景名胜区内(东北角)',
    '杭州市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY[''],
    '',
    ARRAY['国家级景点', '杭州市', '浙江省'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '杭州西湖风景名胜区-断桥残雪'
      AND COALESCE(address, '') = '龙井路1号杭州西湖风景名胜区内(东北角)'
      AND COALESCE(city, '') = '杭州市'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '吴山景区',
    '吴山景区，位于浙江省杭州市清波街道吴山广场2号杭州吴山艺术团附近。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(120.165134, 30.234120), 4326)::geography,
    1,
    4.20,
    0,
    '清波街道吴山广场2号杭州吴山艺术团附近',
    '杭州市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY[''],
    '',
    ARRAY['风景名胜', '杭州市', '浙江省'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '吴山景区'
      AND COALESCE(address, '') = '清波街道吴山广场2号杭州吴山艺术团附近'
      AND COALESCE(city, '') = '杭州市'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '胡雪岩旧居',
    '胡雪岩旧居，位于浙江省杭州市元宝街18号。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(120.172906, 30.237273), 4326)::geography,
    1,
    4.20,
    0,
    '元宝街18号',
    '杭州市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY[''],
    '',
    ARRAY['纪念馆', '杭州市', '浙江省'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '胡雪岩旧居'
      AND COALESCE(address, '') = '元宝街18号'
      AND COALESCE(city, '') = '杭州市'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '钱江新城灯光秀',
    '钱江新城灯光秀，位于浙江省杭州市新业路39号(市民中心地铁站M1口或N2口)。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(120.215428, 30.244481), 4326)::geography,
    1,
    4.20,
    0,
    '新业路39号(市民中心地铁站M1口或N2口)',
    '杭州市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY[''],
    '',
    ARRAY['风景名胜', '杭州市', '浙江省'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '钱江新城灯光秀'
      AND COALESCE(address, '') = '新业路39号(市民中心地铁站M1口或N2口)'
      AND COALESCE(city, '') = '杭州市'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '鼓楼',
    '鼓楼，位于浙江省杭州市中山南路501号(近十五奎巷)。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(120.171386, 30.237994), 4326)::geography,
    1,
    4.20,
    0,
    '中山南路501号(近十五奎巷)',
    '杭州市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY[''],
    '',
    ARRAY['风景名胜', '杭州市', '浙江省'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '鼓楼'
      AND COALESCE(address, '') = '中山南路501号(近十五奎巷)'
      AND COALESCE(city, '') = '杭州市'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '杭州西湖风景名胜区',
    '杭州西湖风景名胜区，位于浙江省杭州市西湖街道龙井路1号。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(120.121358, 30.222692), 4326)::geography,
    1,
    4.20,
    0,
    '西湖街道龙井路1号',
    '杭州市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY[''],
    '',
    ARRAY['国家级景点', '杭州市', '浙江省'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '杭州西湖风景名胜区'
      AND COALESCE(address, '') = '西湖街道龙井路1号'
      AND COALESCE(city, '') = '杭州市'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '雷峰塔景区',
    '雷峰塔景区，位于浙江省杭州市南山路15号。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(120.148849, 30.230934), 4326)::geography,
    1,
    4.20,
    0,
    '南山路15号',
    '杭州市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY[''],
    '',
    ARRAY['国家级景点', '杭州市', '浙江省'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '雷峰塔景区'
      AND COALESCE(address, '') = '南山路15号'
      AND COALESCE(city, '') = '杭州市'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '吴山广场',
    '吴山广场，位于浙江省杭州市延安南路1号附近。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(120.163686, 30.239183), 4326)::geography,
    1,
    4.20,
    0,
    '延安南路1号附近',
    '杭州市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY[''],
    '',
    ARRAY['城市广场', '杭州市', '浙江省'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '吴山广场'
      AND COALESCE(address, '') = '延安南路1号附近'
      AND COALESCE(city, '') = '杭州市'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    'CBD公园',
    'CBD公园，位于浙江省杭州市五星路181号(市民中心地铁站N3B口步行460米)。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(120.212285, 30.237933), 4326)::geography,
    1,
    4.20,
    0,
    '五星路181号(市民中心地铁站N3B口步行460米)',
    '杭州市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY[''],
    '',
    ARRAY['公园', '杭州市', '浙江省'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = 'CBD公园'
      AND COALESCE(address, '') = '五星路181号(市民中心地铁站N3B口步行460米)'
      AND COALESCE(city, '') = '杭州市'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '杭州西湖风景名胜区-湖滨公园',
    '杭州西湖风景名胜区-湖滨公园，位于浙江省杭州市龙井路1号杭州西湖风景名胜区内(东北角)。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(120.158818, 30.256583), 4326)::geography,
    1,
    4.20,
    0,
    '龙井路1号杭州西湖风景名胜区内(东北角)',
    '杭州市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY[''],
    '',
    ARRAY['公园', '杭州市', '浙江省'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '杭州西湖风景名胜区-湖滨公园'
      AND COALESCE(address, '') = '龙井路1号杭州西湖风景名胜区内(东北角)'
      AND COALESCE(city, '') = '杭州市'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '河坊街景区',
    '河坊街景区，位于浙江省杭州市河坊街。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(120.169895, 30.240584), 4326)::geography,
    1,
    4.20,
    0,
    '河坊街',
    '杭州市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY[''],
    '',
    ARRAY['特色商业街', '杭州市', '浙江省'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '河坊街景区'
      AND COALESCE(address, '') = '河坊街'
      AND COALESCE(city, '') = '杭州市'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '杭州西湖风景名胜区-太子湾公园',
    '杭州西湖风景名胜区-太子湾公园，位于浙江省杭州市南星街道南山路1-1号。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(120.142177, 30.225470), 4326)::geography,
    1,
    4.20,
    0,
    '南星街道南山路1-1号',
    '杭州市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY[''],
    '',
    ARRAY['公园', '杭州市', '浙江省'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '杭州西湖风景名胜区-太子湾公园'
      AND COALESCE(address, '') = '南星街道南山路1-1号'
      AND COALESCE(city, '') = '杭州市'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '杭州西湖风景名胜区-柳浪闻莺',
    '杭州西湖风景名胜区-柳浪闻莺，位于浙江省杭州市清波街道南山路87号。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(120.156326, 30.240389), 4326)::geography,
    1,
    4.20,
    0,
    '清波街道南山路87号',
    '杭州市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY[''],
    '',
    ARRAY['风景名胜', '杭州市', '浙江省'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '杭州西湖风景名胜区-柳浪闻莺'
      AND COALESCE(address, '') = '清波街道南山路87号'
      AND COALESCE(city, '') = '杭州市'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '杭州基督教会崇一堂',
    '杭州基督教会崇一堂，位于浙江省杭州市新塘路26号(近庆春广场)。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(120.208778, 30.259353), 4326)::geography,
    1,
    4.20,
    0,
    '新塘路26号(近庆春广场)',
    '杭州市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY[''],
    '',
    ARRAY['教堂', '杭州市', '浙江省'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '杭州基督教会崇一堂'
      AND COALESCE(address, '') = '新塘路26号(近庆春广场)'
      AND COALESCE(city, '') = '杭州市'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '武林广场',
    '武林广场，位于浙江省杭州市天水街道天水街道体育场路208号。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(120.163325, 30.271001), 4326)::geography,
    1,
    4.20,
    0,
    '天水街道天水街道体育场路208号',
    '杭州市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY[''],
    '',
    ARRAY['城市广场', '杭州市', '浙江省'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '武林广场'
      AND COALESCE(address, '') = '天水街道天水街道体育场路208号'
      AND COALESCE(city, '') = '杭州市'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '西湖文化广场',
    '西湖文化广场，位于浙江省杭州市环城北路47号。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(120.163755, 30.276652), 4326)::geography,
    1,
    4.20,
    0,
    '环城北路47号',
    '杭州市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY[''],
    '',
    ARRAY['城市广场', '杭州市', '浙江省'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '西湖文化广场'
      AND COALESCE(address, '') = '环城北路47号'
      AND COALESCE(city, '') = '杭州市'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '杭州Do都城',
    '杭州Do都城，位于浙江省杭州市新业路311号(钱江新城市民中心K座)。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(120.209448, 30.247996), 4326)::geography,
    1,
    4.20,
    0,
    '新业路311号(钱江新城市民中心K座)',
    '杭州市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY[''],
    '',
    ARRAY['旅游景点', '杭州市', '浙江省'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '杭州Do都城'
      AND COALESCE(address, '') = '新业路311号(钱江新城市民中心K座)'
      AND COALESCE(city, '') = '杭州市'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '江和美海洋公园',
    '江和美海洋公园，位于浙江省杭州市杭海路601号(三堡地铁站B1口旁)。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(120.227506, 30.268541), 4326)::geography,
    1,
    4.20,
    0,
    '杭海路601号(三堡地铁站B1口旁)',
    '杭州市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY[''],
    '',
    ARRAY['公园广场', '杭州市', '浙江省'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '江和美海洋公园'
      AND COALESCE(address, '') = '杭海路601号(三堡地铁站B1口旁)'
      AND COALESCE(city, '') = '杭州市'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '城市阳台江堤步道',
    '城市阳台江堤步道，位于浙江省杭州市四季青街道之江路1122号。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(120.219288, 30.245150), 4326)::geography,
    1,
    4.20,
    0,
    '四季青街道之江路1122号',
    '杭州市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY[''],
    '',
    ARRAY['旅游景点', '杭州市', '浙江省'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '城市阳台江堤步道'
      AND COALESCE(address, '') = '四季青街道之江路1122号'
      AND COALESCE(city, '') = '杭州市'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '十五奎巷历史文化街区',
    '十五奎巷历史文化街区，位于浙江省杭州市十五奎巷观湖假日酒店(西湖河坊街店)。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(120.170940, 30.237422), 4326)::geography,
    1,
    4.20,
    0,
    '十五奎巷观湖假日酒店(西湖河坊街店)',
    '杭州市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY[''],
    '',
    ARRAY['旅游景点', '杭州市', '浙江省'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '十五奎巷历史文化街区'
      AND COALESCE(address, '') = '十五奎巷观湖假日酒店(西湖河坊街店)'
      AND COALESCE(city, '') = '杭州市'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '钱江龙',
    '钱江龙，位于浙江省杭州市江汉路闻涛路交叉口射潮广场。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(120.202578, 30.211897), 4326)::geography,
    1,
    4.20,
    0,
    '江汉路闻涛路交叉口射潮广场',
    '杭州市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY[''],
    '',
    ARRAY['风景名胜', '杭州市', '浙江省'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '钱江龙'
      AND COALESCE(address, '') = '江汉路闻涛路交叉口射潮广场'
      AND COALESCE(city, '') = '杭州市'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '波浪文化城',
    '波浪文化城，位于浙江省杭州市解放东路8号(市民中心地铁站L口步行260米)。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(120.214482, 30.243589), 4326)::geography,
    1,
    4.20,
    0,
    '解放东路8号(市民中心地铁站L口步行260米)',
    '杭州市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY[''],
    '',
    ARRAY['城市广场', '杭州市', '浙江省'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '波浪文化城'
      AND COALESCE(address, '') = '解放东路8号(市民中心地铁站L口步行260米)'
      AND COALESCE(city, '') = '杭州市'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '江河汇西岸公园',
    '江河汇西岸公园，位于浙江省杭州市钱江路与运河西路交叉口东80米。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(120.223361, 30.262257), 4326)::geography,
    1,
    4.20,
    0,
    '钱江路与运河西路交叉口东80米',
    '杭州市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY[''],
    '',
    ARRAY['公园', '杭州市', '浙江省'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '江河汇西岸公园'
      AND COALESCE(address, '') = '钱江路与运河西路交叉口东80米'
      AND COALESCE(city, '') = '杭州市'
);

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '蜻蜓公园',
    '蜻蜓公园，位于浙江省杭州市庆春东路与秋涛北路交叉口东北100米。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(120.201578, 30.258134), 4326)::geography,
    1,
    4.20,
    0,
    '庆春东路与秋涛北路交叉口东北100米',
    '杭州市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY[''],
    '',
    ARRAY['公园', '杭州市', '浙江省'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '蜻蜓公园'
      AND COALESCE(address, '') = '庆春东路与秋涛北路交叉口东北100米'
      AND COALESCE(city, '') = '杭州市'
);

COMMIT;
