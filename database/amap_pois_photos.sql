SET client_encoding = 'UTF8';
BEGIN;

UPDATE scenic_spots
SET images = ARRAY['http://aos-cdn-image.amap.com/sns/ugccomment/fab72424-5643-4c14-9486-ae1c8475eab7.jpg'],
    thumbnail_url = 'http://aos-cdn-image.amap.com/sns/ugccomment/fab72424-5643-4c14-9486-ae1c8475eab7.jpg'
WHERE name = '天安门广场'
      AND COALESCE(address, '') = '东长安街'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
  );

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
    ARRAY['http://aos-cdn-image.amap.com/sns/ugccomment/fab72424-5643-4c14-9486-ae1c8475eab7.jpg'],
    'http://aos-cdn-image.amap.com/sns/ugccomment/fab72424-5643-4c14-9486-ae1c8475eab7.jpg',
    ARRAY['城市广场', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '天安门广场'
      AND COALESCE(address, '') = '东长安街'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['http://store.is.autonavi.com/showpic/17a36a737908810a310387c7d53e878a'],
    thumbnail_url = 'http://store.is.autonavi.com/showpic/17a36a737908810a310387c7d53e878a'
WHERE name = '天安门'
      AND COALESCE(address, '') = '长安街北侧'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
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
    ARRAY['http://store.is.autonavi.com/showpic/17a36a737908810a310387c7d53e878a'],
    'http://store.is.autonavi.com/showpic/17a36a737908810a310387c7d53e878a',
    ARRAY['国家级景点', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '天安门'
      AND COALESCE(address, '') = '长安街北侧'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['http://store.is.autonavi.com/showpic/2f968490d105bb2741e17f90b85c6b79'],
    thumbnail_url = 'http://store.is.autonavi.com/showpic/2f968490d105bb2741e17f90b85c6b79'
WHERE name = '故宫博物院'
      AND COALESCE(address, '') = '景山前街4号'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
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
    ARRAY['http://store.is.autonavi.com/showpic/2f968490d105bb2741e17f90b85c6b79'],
    'http://store.is.autonavi.com/showpic/2f968490d105bb2741e17f90b85c6b79',
    ARRAY['博物馆', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '故宫博物院'
      AND COALESCE(address, '') = '景山前街4号'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['http://store.is.autonavi.com/showpic/561ebdb222a6f17913f1bbd1062c3d93'],
    thumbnail_url = 'http://store.is.autonavi.com/showpic/561ebdb222a6f17913f1bbd1062c3d93'
WHERE name = '天坛公园'
      AND COALESCE(address, '') = '天坛东里甲1号'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
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
    ARRAY['http://store.is.autonavi.com/showpic/561ebdb222a6f17913f1bbd1062c3d93'],
    'http://store.is.autonavi.com/showpic/561ebdb222a6f17913f1bbd1062c3d93',
    ARRAY['公园', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '天坛公园'
      AND COALESCE(address, '') = '天坛东里甲1号'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['http://store.is.autonavi.com/showpic/10eb01af2fd301e54e50d42ea636ccef'],
    thumbnail_url = 'http://store.is.autonavi.com/showpic/10eb01af2fd301e54e50d42ea636ccef'
WHERE name = '景山公园'
      AND COALESCE(address, '') = '景山西街44号'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
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
    ARRAY['http://store.is.autonavi.com/showpic/10eb01af2fd301e54e50d42ea636ccef'],
    'http://store.is.autonavi.com/showpic/10eb01af2fd301e54e50d42ea636ccef',
    ARRAY['公园', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '景山公园'
      AND COALESCE(address, '') = '景山西街44号'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['http://store.is.autonavi.com/showpic/4d1216ff3ef92137912db31aaacd3c5f'],
    thumbnail_url = 'http://store.is.autonavi.com/showpic/4d1216ff3ef92137912db31aaacd3c5f'
WHERE name = '中山公园'
      AND COALESCE(address, '') = '中华路4号(天安门西侧)'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
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
    ARRAY['http://store.is.autonavi.com/showpic/4d1216ff3ef92137912db31aaacd3c5f'],
    'http://store.is.autonavi.com/showpic/4d1216ff3ef92137912db31aaacd3c5f',
    ARRAY['公园', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '中山公园'
      AND COALESCE(address, '') = '中华路4号(天安门西侧)'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['http://store.is.autonavi.com/showpic/68a92863a790f69d2221f7c53906c8c2'],
    thumbnail_url = 'http://store.is.autonavi.com/showpic/68a92863a790f69d2221f7c53906c8c2'
WHERE name = '北海公园'
      AND COALESCE(address, '') = '文津街1号'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
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
    ARRAY['http://store.is.autonavi.com/showpic/68a92863a790f69d2221f7c53906c8c2'],
    'http://store.is.autonavi.com/showpic/68a92863a790f69d2221f7c53906c8c2',
    ARRAY['公园', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '北海公园'
      AND COALESCE(address, '') = '文津街1号'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['http://store.is.autonavi.com/showpic/dcd78b35cb123744056c03072ecdea17'],
    thumbnail_url = 'http://store.is.autonavi.com/showpic/dcd78b35cb123744056c03072ecdea17'
WHERE name = '故宫博物院-午门'
      AND COALESCE(address, '') = '东华门街道景山前街4号故宫博物院内(南侧)'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
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
    ARRAY['http://store.is.autonavi.com/showpic/dcd78b35cb123744056c03072ecdea17'],
    'http://store.is.autonavi.com/showpic/dcd78b35cb123744056c03072ecdea17',
    ARRAY['风景名胜', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '故宫博物院-午门'
      AND COALESCE(address, '') = '东华门街道景山前街4号故宫博物院内(南侧)'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['http://store.is.autonavi.com/showpic/6aa94c24640267a56c22af0b9629030a'],
    thumbnail_url = 'http://store.is.autonavi.com/showpic/6aa94c24640267a56c22af0b9629030a'
WHERE name = '南锣鼓巷'
      AND COALESCE(address, '') = '交道口街道南大街(南锣鼓巷地铁站E西北口旁)'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
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
    ARRAY['http://store.is.autonavi.com/showpic/6aa94c24640267a56c22af0b9629030a'],
    'http://store.is.autonavi.com/showpic/6aa94c24640267a56c22af0b9629030a',
    ARRAY['风景名胜', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '南锣鼓巷'
      AND COALESCE(address, '') = '交道口街道南大街(南锣鼓巷地铁站E西北口旁)'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['https://store.is.autonavi.com/showpic/057978fd8486e0a7406155b43b6ae13f'],
    thumbnail_url = 'https://store.is.autonavi.com/showpic/057978fd8486e0a7406155b43b6ae13f'
WHERE name = '天安门-城楼'
      AND COALESCE(address, '') = '东长安街天安门(天安门东地铁站A西北入口步行290米)'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
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
    ARRAY['https://store.is.autonavi.com/showpic/057978fd8486e0a7406155b43b6ae13f'],
    'https://store.is.autonavi.com/showpic/057978fd8486e0a7406155b43b6ae13f',
    ARRAY['国家级景点', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '天安门-城楼'
      AND COALESCE(address, '') = '东长安街天安门(天安门东地铁站A西北入口步行290米)'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['https://store.is.autonavi.com/showpic/179cea10d65c7e055f0483b200ea651d'],
    thumbnail_url = 'https://store.is.autonavi.com/showpic/179cea10d65c7e055f0483b200ea651d'
WHERE name = '天安门广场-国旗'
      AND COALESCE(address, '') = '东华门街道景山前街4号天安门广场内(北侧)'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
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
    ARRAY['https://store.is.autonavi.com/showpic/179cea10d65c7e055f0483b200ea651d'],
    'https://store.is.autonavi.com/showpic/179cea10d65c7e055f0483b200ea651d',
    ARRAY['风景名胜', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '天安门广场-国旗'
      AND COALESCE(address, '') = '东华门街道景山前街4号天安门广场内(北侧)'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['http://store.is.autonavi.com/showpic/3029a20076593ba33b5ebbdcfea7e569'],
    thumbnail_url = 'http://store.is.autonavi.com/showpic/3029a20076593ba33b5ebbdcfea7e569'
WHERE name = '太庙'
      AND COALESCE(address, '') = '东华门街道东长安街北京市劳动人民文化宫'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
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
    ARRAY['http://store.is.autonavi.com/showpic/3029a20076593ba33b5ebbdcfea7e569'],
    'http://store.is.autonavi.com/showpic/3029a20076593ba33b5ebbdcfea7e569',
    ARRAY['寺庙道观', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '太庙'
      AND COALESCE(address, '') = '东华门街道东长安街北京市劳动人民文化宫'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['http://store.is.autonavi.com/showpic/7675ecadbda243d9b4da460bc59d4466'],
    thumbnail_url = 'http://store.is.autonavi.com/showpic/7675ecadbda243d9b4da460bc59d4466'
WHERE name = '北京明城墙遗址公园'
      AND COALESCE(address, '') = '崇文门东大街9号'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
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
    ARRAY['http://store.is.autonavi.com/showpic/7675ecadbda243d9b4da460bc59d4466'],
    'http://store.is.autonavi.com/showpic/7675ecadbda243d9b4da460bc59d4466',
    ARRAY['公园', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '北京明城墙遗址公园'
      AND COALESCE(address, '') = '崇文门东大街9号'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['https://aos-comment.amap.com/B000A9LFEH/comment/content_media_external_file_1000026869_ss__1767533632970_94423019.jpg'],
    thumbnail_url = 'https://aos-comment.amap.com/B000A9LFEH/comment/content_media_external_file_1000026869_ss__1767533632970_94423019.jpg'
WHERE name = '景山公园-绮望楼'
      AND COALESCE(address, '') = '什刹海街道景山西街44号(故宫后门对面)景山公园内(南侧)'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
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
    ARRAY['https://aos-comment.amap.com/B000A9LFEH/comment/content_media_external_file_1000026869_ss__1767533632970_94423019.jpg'],
    'https://aos-comment.amap.com/B000A9LFEH/comment/content_media_external_file_1000026869_ss__1767533632970_94423019.jpg',
    ARRAY['风景名胜', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '景山公园-绮望楼'
      AND COALESCE(address, '') = '什刹海街道景山西街44号(故宫后门对面)景山公园内(南侧)'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['http://store.is.autonavi.com/showpic/dd97c0390e296f47a20b72063ec86990'],
    thumbnail_url = 'http://store.is.autonavi.com/showpic/dd97c0390e296f47a20b72063ec86990'
WHERE name = '什刹海'
      AND COALESCE(address, '') = '地安门西大街49号'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
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
    ARRAY['http://store.is.autonavi.com/showpic/dd97c0390e296f47a20b72063ec86990'],
    'http://store.is.autonavi.com/showpic/dd97c0390e296f47a20b72063ec86990',
    ARRAY['国家级景点', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '什刹海'
      AND COALESCE(address, '') = '地安门西大街49号'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['https://store.is.autonavi.com/showpic/ab13cc04625b0d9f0000000720650011?type=pic'],
    thumbnail_url = 'https://store.is.autonavi.com/showpic/ab13cc04625b0d9f0000000720650011?type=pic'
WHERE name = '正阳门箭楼'
      AND COALESCE(address, '') = '前门大街2号前门商业区A2地块'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
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
    ARRAY['https://store.is.autonavi.com/showpic/ab13cc04625b0d9f0000000720650011?type=pic'],
    'https://store.is.autonavi.com/showpic/ab13cc04625b0d9f0000000720650011?type=pic',
    ARRAY['风景名胜', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '正阳门箭楼'
      AND COALESCE(address, '') = '前门大街2号前门商业区A2地块'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['http://store.is.autonavi.com/showpic/0ab8b692dcecca985c77c4986981e2d4'],
    thumbnail_url = 'http://store.is.autonavi.com/showpic/0ab8b692dcecca985c77c4986981e2d4'
WHERE name = '故宫博物院-神武门'
      AND COALESCE(address, '') = '景山前街4号北京故宫博物馆'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
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
    ARRAY['http://store.is.autonavi.com/showpic/0ab8b692dcecca985c77c4986981e2d4'],
    'http://store.is.autonavi.com/showpic/0ab8b692dcecca985c77c4986981e2d4',
    ARRAY['国家级景点', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '故宫博物院-神武门'
      AND COALESCE(address, '') = '景山前街4号北京故宫博物馆'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['http://store.is.autonavi.com/showpic/53e62ad0d97d5de332b0bf933966dfba'],
    thumbnail_url = 'http://store.is.autonavi.com/showpic/53e62ad0d97d5de332b0bf933966dfba'
WHERE name = '翰林院遗址'
      AND COALESCE(address, '') = '东长安街路南公安部内'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
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
    ARRAY['http://store.is.autonavi.com/showpic/53e62ad0d97d5de332b0bf933966dfba'],
    'http://store.is.autonavi.com/showpic/53e62ad0d97d5de332b0bf933966dfba',
    ARRAY['风景名胜', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '翰林院遗址'
      AND COALESCE(address, '') = '东长安街路南公安部内'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['http://store.is.autonavi.com/showpic/9b9abb2a9fff0b6491230aa4435f7ad5'],
    thumbnail_url = 'http://store.is.autonavi.com/showpic/9b9abb2a9fff0b6491230aa4435f7ad5'
WHERE name = '雍和宫'
      AND COALESCE(address, '') = '雍和宫大街28号(雍和宫地铁站F东南口步行250米)'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
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
    ARRAY['http://store.is.autonavi.com/showpic/9b9abb2a9fff0b6491230aa4435f7ad5'],
    'http://store.is.autonavi.com/showpic/9b9abb2a9fff0b6491230aa4435f7ad5',
    ARRAY['风景名胜', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '雍和宫'
      AND COALESCE(address, '') = '雍和宫大街28号(雍和宫地铁站F东南口步行250米)'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['http://store.is.autonavi.com/showpic/e242ed1956e6d775a8912cfd3934169b'],
    thumbnail_url = 'http://store.is.autonavi.com/showpic/e242ed1956e6d775a8912cfd3934169b'
WHERE name = '恭王府博物馆'
      AND COALESCE(address, '') = '前海西街17号'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
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
    ARRAY['http://store.is.autonavi.com/showpic/e242ed1956e6d775a8912cfd3934169b'],
    'http://store.is.autonavi.com/showpic/e242ed1956e6d775a8912cfd3934169b',
    ARRAY['国家级景点', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '恭王府博物馆'
      AND COALESCE(address, '') = '前海西街17号'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['http://store.is.autonavi.com/showpic/3151edc9ee8bfb33645678cb7c56cc6c'],
    thumbnail_url = 'http://store.is.autonavi.com/showpic/3151edc9ee8bfb33645678cb7c56cc6c'
WHERE name = '天坛公园-祈年殿'
      AND COALESCE(address, '') = '天坛街道天坛东路甲1号天坛公园内'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
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
    ARRAY['http://store.is.autonavi.com/showpic/3151edc9ee8bfb33645678cb7c56cc6c'],
    'http://store.is.autonavi.com/showpic/3151edc9ee8bfb33645678cb7c56cc6c',
    ARRAY['风景名胜', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '天坛公园-祈年殿'
      AND COALESCE(address, '') = '天坛街道天坛东路甲1号天坛公园内'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['http://store.is.autonavi.com/showpic/fbd8cdec8bcb57bc6379137a55e99f44'],
    thumbnail_url = 'http://store.is.autonavi.com/showpic/fbd8cdec8bcb57bc6379137a55e99f44'
WHERE name = '陶然亭公园'
      AND COALESCE(address, '') = '太平街19号'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
  );

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '陶然亭公园',
    '陶然亭公园，位于北京市北京市太平街19号。数据来源：高德地图开放平台 POI。',
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
    ARRAY['http://store.is.autonavi.com/showpic/fbd8cdec8bcb57bc6379137a55e99f44'],
    'http://store.is.autonavi.com/showpic/fbd8cdec8bcb57bc6379137a55e99f44',
    ARRAY['公园', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '陶然亭公园'
      AND COALESCE(address, '') = '太平街19号'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['https://store.is.autonavi.com/showpic/8f12f3f5bdc5d4b90000000959876379?type=pic'],
    thumbnail_url = 'https://store.is.autonavi.com/showpic/8f12f3f5bdc5d4b90000000959876379?type=pic'
WHERE name = '智化寺'
      AND COALESCE(address, '') = '禄米仓胡同5号'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
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
    ARRAY['https://store.is.autonavi.com/showpic/8f12f3f5bdc5d4b90000000959876379?type=pic'],
    'https://store.is.autonavi.com/showpic/8f12f3f5bdc5d4b90000000959876379?type=pic',
    ARRAY['寺庙道观', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '智化寺'
      AND COALESCE(address, '') = '禄米仓胡同5号'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['https://aos-comment.amap.com/B000A7C9EW/headerImg/2689d175eadaa46f36c454184edf55a2_2048_2048_80.jpg'],
    thumbnail_url = 'https://aos-comment.amap.com/B000A7C9EW/headerImg/2689d175eadaa46f36c454184edf55a2_2048_2048_80.jpg'
WHERE name = '日坛公园'
      AND COALESCE(address, '') = '朝外街道朝阳门外日坛北路6号'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
  );

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '日坛公园',
    '日坛公园，位于北京市北京市朝外街道朝阳门外日坛北路6号。数据来源：高德地图开放平台 POI。',
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
    ARRAY['https://aos-comment.amap.com/B000A7C9EW/headerImg/2689d175eadaa46f36c454184edf55a2_2048_2048_80.jpg'],
    'https://aos-comment.amap.com/B000A7C9EW/headerImg/2689d175eadaa46f36c454184edf55a2_2048_2048_80.jpg',
    ARRAY['公园', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '日坛公园'
      AND COALESCE(address, '') = '朝外街道朝阳门外日坛北路6号'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['http://store.is.autonavi.com/showpic/3fe8133ec9274fe7c8a3afa38d1ae710'],
    thumbnail_url = 'http://store.is.autonavi.com/showpic/3fe8133ec9274fe7c8a3afa38d1ae710'
WHERE name = '龙潭公园'
      AND COALESCE(address, '') = '龙潭路16号'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
  );

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '龙潭公园',
    '龙潭公园，位于北京市北京市龙潭路16号。数据来源：高德地图开放平台 POI。',
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
    ARRAY['http://store.is.autonavi.com/showpic/3fe8133ec9274fe7c8a3afa38d1ae710'],
    'http://store.is.autonavi.com/showpic/3fe8133ec9274fe7c8a3afa38d1ae710',
    ARRAY['国家级景点', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '龙潭公园'
      AND COALESCE(address, '') = '龙潭路16号'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['http://store.is.autonavi.com/showpic/d450dc6b66c4ead84b3287024a47e3e3'],
    thumbnail_url = 'http://store.is.autonavi.com/showpic/d450dc6b66c4ead84b3287024a47e3e3'
WHERE name = '法源寺'
      AND COALESCE(address, '') = '法源寺前街7号'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
  );

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '法源寺',
    '法源寺，位于北京市北京市法源寺前街7号。数据来源：高德地图开放平台 POI。',
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
    ARRAY['http://store.is.autonavi.com/showpic/d450dc6b66c4ead84b3287024a47e3e3'],
    'http://store.is.autonavi.com/showpic/d450dc6b66c4ead84b3287024a47e3e3',
    ARRAY['寺庙道观', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '法源寺'
      AND COALESCE(address, '') = '法源寺前街7号'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['http://store.is.autonavi.com/showpic/de85bb2be102e61fcfaf1044e464c89d'],
    thumbnail_url = 'http://store.is.autonavi.com/showpic/de85bb2be102e61fcfaf1044e464c89d'
WHERE name = '东单公园'
      AND COALESCE(address, '') = '崇文门内大街9号(东单地铁站H西南口步行380米)'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
  );

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '东单公园',
    '东单公园，位于北京市北京市崇文门内大街9号(东单地铁站H西南口步行380米)。数据来源：高德地图开放平台 POI。',
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
    ARRAY['http://store.is.autonavi.com/showpic/de85bb2be102e61fcfaf1044e464c89d'],
    'http://store.is.autonavi.com/showpic/de85bb2be102e61fcfaf1044e464c89d',
    ARRAY['公园', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '东单公园'
      AND COALESCE(address, '') = '崇文门内大街9号(东单地铁站H西南口步行380米)'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['https://aos-comment.amap.com/B000A7YE6D/comment/content_media_external_file_100001407_1770383413097_87752934.jpg'],
    thumbnail_url = 'https://aos-comment.amap.com/B000A7YE6D/comment/content_media_external_file_100001407_1770383413097_87752934.jpg'
WHERE name = '普度寺遗址'
      AND COALESCE(address, '') = '普度寺前巷'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
  );

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '普度寺遗址',
    '普度寺遗址，位于北京市北京市普度寺前巷。数据来源：高德地图开放平台 POI。',
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
    ARRAY['https://aos-comment.amap.com/B000A7YE6D/comment/content_media_external_file_100001407_1770383413097_87752934.jpg'],
    'https://aos-comment.amap.com/B000A7YE6D/comment/content_media_external_file_100001407_1770383413097_87752934.jpg',
    ARRAY['寺庙道观', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '普度寺遗址'
      AND COALESCE(address, '') = '普度寺前巷'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['https://aos-comment.amap.com/B0FFFS33G2/comment/14c2494a939addd2acd2f86c90e71e21_2048_2048_80.jpg'],
    thumbnail_url = 'https://aos-comment.amap.com/B0FFFS33G2/comment/14c2494a939addd2acd2f86c90e71e21_2048_2048_80.jpg'
WHERE name = '鼓楼'
      AND COALESCE(address, '') = '钟楼湾胡同临字9号(什刹海地铁站A2西北口步行240米)'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
  );

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '鼓楼',
    '鼓楼，位于北京市北京市钟楼湾胡同临字9号(什刹海地铁站A2西北口步行240米)。数据来源：高德地图开放平台 POI。',
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
    ARRAY['https://aos-comment.amap.com/B0FFFS33G2/comment/14c2494a939addd2acd2f86c90e71e21_2048_2048_80.jpg'],
    'https://aos-comment.amap.com/B0FFFS33G2/comment/14c2494a939addd2acd2f86c90e71e21_2048_2048_80.jpg',
    ARRAY['风景名胜', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '鼓楼'
      AND COALESCE(address, '') = '钟楼湾胡同临字9号(什刹海地铁站A2西北口步行240米)'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['http://store.is.autonavi.com/showpic/c7782cf55d7393472b79ffbd33472a3f'],
    thumbnail_url = 'http://store.is.autonavi.com/showpic/c7782cf55d7393472b79ffbd33472a3f'
WHERE name = '北大红楼'
      AND COALESCE(address, '') = '五四大街29号'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
  );

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '北大红楼',
    '北大红楼，位于北京市北京市五四大街29号。数据来源：高德地图开放平台 POI。',
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
    ARRAY['http://store.is.autonavi.com/showpic/c7782cf55d7393472b79ffbd33472a3f'],
    'http://store.is.autonavi.com/showpic/c7782cf55d7393472b79ffbd33472a3f',
    ARRAY['纪念馆', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '北大红楼'
      AND COALESCE(address, '') = '五四大街29号'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['http://store.is.autonavi.com/showpic/e28b4684acd7bcdaa43f8a169e66816b'],
    thumbnail_url = 'http://store.is.autonavi.com/showpic/e28b4684acd7bcdaa43f8a169e66816b'
WHERE name = '龙潭中湖公园'
      AND COALESCE(address, '') = '左安门内大街19号'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
  );

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '龙潭中湖公园',
    '龙潭中湖公园，位于北京市北京市左安门内大街19号。数据来源：高德地图开放平台 POI。',
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
    ARRAY['http://store.is.autonavi.com/showpic/e28b4684acd7bcdaa43f8a169e66816b'],
    'http://store.is.autonavi.com/showpic/e28b4684acd7bcdaa43f8a169e66816b',
    ARRAY['公园', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '龙潭中湖公园'
      AND COALESCE(address, '') = '左安门内大街19号'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['http://store.is.autonavi.com/showpic/35d828cfa010668501e398f5bfa6c6f5'],
    thumbnail_url = 'http://store.is.autonavi.com/showpic/35d828cfa010668501e398f5bfa6c6f5'
WHERE name = '地坛公园'
      AND COALESCE(address, '') = '安定门外大街'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
  );

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '地坛公园',
    '地坛公园，位于北京市北京市安定门外大街。数据来源：高德地图开放平台 POI。',
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
    ARRAY['http://store.is.autonavi.com/showpic/35d828cfa010668501e398f5bfa6c6f5'],
    'http://store.is.autonavi.com/showpic/35d828cfa010668501e398f5bfa6c6f5',
    ARRAY['公园', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '地坛公园'
      AND COALESCE(address, '') = '安定门外大街'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['http://store.is.autonavi.com/showpic/e64b6d1fa4f1b56d29157da3e6d74988'],
    thumbnail_url = 'http://store.is.autonavi.com/showpic/e64b6d1fa4f1b56d29157da3e6d74988'
WHERE name = '北京东交民巷使馆建筑群'
      AND COALESCE(address, '') = '崇文门东交民巷(崇文门地铁站A1西北口步行290米)'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
  );

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '北京东交民巷使馆建筑群',
    '北京东交民巷使馆建筑群，位于北京市北京市崇文门东交民巷(崇文门地铁站A1西北口步行290米)。数据来源：高德地图开放平台 POI。',
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
    ARRAY['http://store.is.autonavi.com/showpic/e64b6d1fa4f1b56d29157da3e6d74988'],
    'http://store.is.autonavi.com/showpic/e64b6d1fa4f1b56d29157da3e6d74988',
    ARRAY['旅游景点', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '北京东交民巷使馆建筑群'
      AND COALESCE(address, '') = '崇文门东交民巷(崇文门地铁站A1西北口步行290米)'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['https://aos-comment.amap.com/B0FFFAK3R4/headerImg/51b8e06b1e346842b1011973e4b1bd20_2048_2048_80.jpg'],
    thumbnail_url = 'https://aos-comment.amap.com/B0FFFAK3R4/headerImg/51b8e06b1e346842b1011973e4b1bd20_2048_2048_80.jpg'
WHERE name = '敕建火德真君庙'
      AND COALESCE(address, '') = '地安门外大街77号(什刹海地铁站C口马路对面)'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
  );

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '敕建火德真君庙',
    '敕建火德真君庙，位于北京市北京市地安门外大街77号(什刹海地铁站C口马路对面)。数据来源：高德地图开放平台 POI。',
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
    ARRAY['https://aos-comment.amap.com/B0FFFAK3R4/headerImg/51b8e06b1e346842b1011973e4b1bd20_2048_2048_80.jpg'],
    'https://aos-comment.amap.com/B0FFFAK3R4/headerImg/51b8e06b1e346842b1011973e4b1bd20_2048_2048_80.jpg',
    ARRAY['寺庙道观', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '敕建火德真君庙'
      AND COALESCE(address, '') = '地安门外大街77号(什刹海地铁站C口马路对面)'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['http://store.is.autonavi.com/showpic/7e238674f2a8cb5e6110bb69ffc118c5'],
    thumbnail_url = 'http://store.is.autonavi.com/showpic/7e238674f2a8cb5e6110bb69ffc118c5'
WHERE name = '景山公园-万春亭'
      AND COALESCE(address, '') = '景山西街44号景山公园内'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
  );

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '景山公园-万春亭',
    '景山公园-万春亭，位于北京市北京市景山西街44号景山公园内。数据来源：高德地图开放平台 POI。',
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
    ARRAY['http://store.is.autonavi.com/showpic/7e238674f2a8cb5e6110bb69ffc118c5'],
    'http://store.is.autonavi.com/showpic/7e238674f2a8cb5e6110bb69ffc118c5',
    ARRAY['风景名胜', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '景山公园-万春亭'
      AND COALESCE(address, '') = '景山西街44号景山公园内'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['https://store.is.autonavi.com/showpic/0b9e1a20cadfd7a50000002376806003'],
    thumbnail_url = 'https://store.is.autonavi.com/showpic/0b9e1a20cadfd7a50000002376806003'
WHERE name = '正阳门城楼'
      AND COALESCE(address, '') = '前门大街北端'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
  );

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '正阳门城楼',
    '正阳门城楼，位于北京市北京市前门大街北端。数据来源：高德地图开放平台 POI。',
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
    ARRAY['https://store.is.autonavi.com/showpic/0b9e1a20cadfd7a50000002376806003'],
    'https://store.is.autonavi.com/showpic/0b9e1a20cadfd7a50000002376806003',
    ARRAY['旅游景点', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '正阳门城楼'
      AND COALESCE(address, '') = '前门大街北端'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['http://store.is.autonavi.com/showpic/dd0edf5877af3b6043645204a08bdf34'],
    thumbnail_url = 'http://store.is.autonavi.com/showpic/dd0edf5877af3b6043645204a08bdf34'
WHERE name = '天主教北京总教区王府井天主堂东堂'
      AND COALESCE(address, '') = '王府井大街74号'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
  );

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '天主教北京总教区王府井天主堂东堂',
    '天主教北京总教区王府井天主堂东堂，位于北京市北京市王府井大街74号。数据来源：高德地图开放平台 POI。',
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
    ARRAY['http://store.is.autonavi.com/showpic/dd0edf5877af3b6043645204a08bdf34'],
    'http://store.is.autonavi.com/showpic/dd0edf5877af3b6043645204a08bdf34',
    ARRAY['教堂', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '天主教北京总教区王府井天主堂东堂'
      AND COALESCE(address, '') = '王府井大街74号'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['http://store.is.autonavi.com/showpic/d78ea4ed845465bb7773102c22c54df5'],
    thumbnail_url = 'http://store.is.autonavi.com/showpic/d78ea4ed845465bb7773102c22c54df5'
WHERE name = '菖蒲河公园'
      AND COALESCE(address, '') = '菖蒲河沿9号(天安门东地铁站B东北口步行200米)'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
  );

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '菖蒲河公园',
    '菖蒲河公园，位于北京市北京市菖蒲河沿9号(天安门东地铁站B东北口步行200米)。数据来源：高德地图开放平台 POI。',
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
    ARRAY['http://store.is.autonavi.com/showpic/d78ea4ed845465bb7773102c22c54df5'],
    'http://store.is.autonavi.com/showpic/d78ea4ed845465bb7773102c22c54df5',
    ARRAY['公园', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '菖蒲河公园'
      AND COALESCE(address, '') = '菖蒲河沿9号(天安门东地铁站B东北口步行200米)'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['http://store.is.autonavi.com/showpic/cce8b8c1b74cf520d996e7df68135327'],
    thumbnail_url = 'http://store.is.autonavi.com/showpic/cce8b8c1b74cf520d996e7df68135327'
WHERE name = '玉渊潭公园'
      AND COALESCE(address, '') = '西三环中路10号'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
  );

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '玉渊潭公园',
    '玉渊潭公园，位于北京市北京市西三环中路10号。数据来源：高德地图开放平台 POI。',
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
    ARRAY['http://store.is.autonavi.com/showpic/cce8b8c1b74cf520d996e7df68135327'],
    'http://store.is.autonavi.com/showpic/cce8b8c1b74cf520d996e7df68135327',
    ARRAY['国家级景点', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '玉渊潭公园'
      AND COALESCE(address, '') = '西三环中路10号'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['http://store.is.autonavi.com/showpic/989902a88a6f3631fd6ce662e9b159ef'],
    thumbnail_url = 'http://store.is.autonavi.com/showpic/989902a88a6f3631fd6ce662e9b159ef'
WHERE name = '人民英雄纪念碑'
      AND COALESCE(address, '') = '天安门广场(长安街中心)'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
  );

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '人民英雄纪念碑',
    '人民英雄纪念碑，位于北京市北京市天安门广场(长安街中心)。数据来源：高德地图开放平台 POI。',
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
    ARRAY['http://store.is.autonavi.com/showpic/989902a88a6f3631fd6ce662e9b159ef'],
    'http://store.is.autonavi.com/showpic/989902a88a6f3631fd6ce662e9b159ef',
    ARRAY['纪念馆', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '人民英雄纪念碑'
      AND COALESCE(address, '') = '天安门广场(长安街中心)'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['https://aos-comment.amap.com/B000A7H0F3/headerImg/8f2e4cdc8da36608701d974c0dff68a9_2048_2048_80.jpg'],
    thumbnail_url = 'https://aos-comment.amap.com/B000A7H0F3/headerImg/8f2e4cdc8da36608701d974c0dff68a9_2048_2048_80.jpg'
WHERE name = '妙应寺白塔'
      AND COALESCE(address, '') = '阜成门内大街171号'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
  );

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '妙应寺白塔',
    '妙应寺白塔，位于北京市北京市阜成门内大街171号。数据来源：高德地图开放平台 POI。',
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
    ARRAY['https://aos-comment.amap.com/B000A7H0F3/headerImg/8f2e4cdc8da36608701d974c0dff68a9_2048_2048_80.jpg'],
    'https://aos-comment.amap.com/B000A7H0F3/headerImg/8f2e4cdc8da36608701d974c0dff68a9_2048_2048_80.jpg',
    ARRAY['寺庙道观', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '妙应寺白塔'
      AND COALESCE(address, '') = '阜成门内大街171号'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['http://store.is.autonavi.com/showpic/e89fcb6fb60308f82af54c79941d0ea4'],
    thumbnail_url = 'http://store.is.autonavi.com/showpic/e89fcb6fb60308f82af54c79941d0ea4'
WHERE name = '国子监'
      AND COALESCE(address, '') = '国子监街13-15号'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
  );

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '国子监',
    '国子监，位于北京市北京市国子监街13-15号。数据来源：高德地图开放平台 POI。',
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
    ARRAY['http://store.is.autonavi.com/showpic/e89fcb6fb60308f82af54c79941d0ea4'],
    'http://store.is.autonavi.com/showpic/e89fcb6fb60308f82af54c79941d0ea4',
    ARRAY['国家级景点', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '国子监'
      AND COALESCE(address, '') = '国子监街13-15号'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['http://store.is.autonavi.com/showpic/2f72adcf8b81537b2bc10def1dea2e7c'],
    thumbnail_url = 'http://store.is.autonavi.com/showpic/2f72adcf8b81537b2bc10def1dea2e7c'
WHERE name = '广济寺'
      AND COALESCE(address, '') = '阜成门内大街25号(西四地铁站B东北口步行200米)'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
  );

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '广济寺',
    '广济寺，位于北京市北京市阜成门内大街25号(西四地铁站B东北口步行200米)。数据来源：高德地图开放平台 POI。',
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
    ARRAY['http://store.is.autonavi.com/showpic/2f72adcf8b81537b2bc10def1dea2e7c'],
    'http://store.is.autonavi.com/showpic/2f72adcf8b81537b2bc10def1dea2e7c',
    ARRAY['寺庙道观', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '广济寺'
      AND COALESCE(address, '') = '阜成门内大街25号(西四地铁站B东北口步行200米)'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['http://store.is.autonavi.com/showpic/95d18067ac2df18e5680fee70c7ae4e9'],
    thumbnail_url = 'http://store.is.autonavi.com/showpic/95d18067ac2df18e5680fee70c7ae4e9'
WHERE name = '什刹海-后海'
      AND COALESCE(address, '') = '羊房胡同甲23-3号'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
  );

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '什刹海-后海',
    '什刹海-后海，位于北京市北京市羊房胡同甲23-3号。数据来源：高德地图开放平台 POI。',
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
    ARRAY['http://store.is.autonavi.com/showpic/95d18067ac2df18e5680fee70c7ae4e9'],
    'http://store.is.autonavi.com/showpic/95d18067ac2df18e5680fee70c7ae4e9',
    ARRAY['风景名胜', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '什刹海-后海'
      AND COALESCE(address, '') = '羊房胡同甲23-3号'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['http://store.is.autonavi.com/showpic/d804291e9b9d981135dbab1a8d7020ea'],
    thumbnail_url = 'http://store.is.autonavi.com/showpic/d804291e9b9d981135dbab1a8d7020ea'
WHERE name = '白云观'
      AND COALESCE(address, '') = '白云观街7号'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
  );

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '白云观',
    '白云观，位于北京市北京市白云观街7号。数据来源：高德地图开放平台 POI。',
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
    ARRAY['http://store.is.autonavi.com/showpic/d804291e9b9d981135dbab1a8d7020ea'],
    'http://store.is.autonavi.com/showpic/d804291e9b9d981135dbab1a8d7020ea',
    ARRAY['寺庙道观', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '白云观'
      AND COALESCE(address, '') = '白云观街7号'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['http://store.is.autonavi.com/showpic/a8c963699fbff4f4b4c8fbf4040810ff'],
    thumbnail_url = 'http://store.is.autonavi.com/showpic/a8c963699fbff4f4b4c8fbf4040810ff'
WHERE name = '朝阳公园'
      AND COALESCE(address, '') = '朝阳公园南路1号'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
  );

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '朝阳公园',
    '朝阳公园，位于北京市北京市朝阳公园南路1号。数据来源：高德地图开放平台 POI。',
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
    ARRAY['http://store.is.autonavi.com/showpic/a8c963699fbff4f4b4c8fbf4040810ff'],
    'http://store.is.autonavi.com/showpic/a8c963699fbff4f4b4c8fbf4040810ff',
    ARRAY['公园', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '朝阳公园'
      AND COALESCE(address, '') = '朝阳公园南路1号'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['http://store.is.autonavi.com/showpic/3c33bd62f5fc31d49ebf318ebfe8a92f'],
    thumbnail_url = 'http://store.is.autonavi.com/showpic/3c33bd62f5fc31d49ebf318ebfe8a92f'
WHERE name = '北京悬空玻璃艺术馆'
      AND COALESCE(address, '') = '王府井大街银泰in88二层南侧(金鱼胡同地铁站B东口旁)'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
  );

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '北京悬空玻璃艺术馆',
    '北京悬空玻璃艺术馆，位于北京市北京市王府井大街银泰in88二层南侧(金鱼胡同地铁站B东口旁)。数据来源：高德地图开放平台 POI。',
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
    ARRAY['http://store.is.autonavi.com/showpic/3c33bd62f5fc31d49ebf318ebfe8a92f'],
    'http://store.is.autonavi.com/showpic/3c33bd62f5fc31d49ebf318ebfe8a92f',
    ARRAY['旅游景点', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '北京悬空玻璃艺术馆'
      AND COALESCE(address, '') = '王府井大街银泰in88二层南侧(金鱼胡同地铁站B东口旁)'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['http://store.is.autonavi.com/showpic/a3aec0c28f5f49d14254c465531c0fea'],
    thumbnail_url = 'http://store.is.autonavi.com/showpic/a3aec0c28f5f49d14254c465531c0fea'
WHERE name = '天主教北京总教区西什库主教座堂'
      AND COALESCE(address, '') = '西什库大街33号'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
  );

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '天主教北京总教区西什库主教座堂',
    '天主教北京总教区西什库主教座堂，位于北京市北京市西什库大街33号。数据来源：高德地图开放平台 POI。',
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
    ARRAY['http://store.is.autonavi.com/showpic/a3aec0c28f5f49d14254c465531c0fea'],
    'http://store.is.autonavi.com/showpic/a3aec0c28f5f49d14254c465531c0fea',
    ARRAY['教堂', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '天主教北京总教区西什库主教座堂'
      AND COALESCE(address, '') = '西什库大街33号'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['http://store.is.autonavi.com/showpic/f74a0a44999538b7738c1fb216fc56d8'],
    thumbnail_url = 'http://store.is.autonavi.com/showpic/f74a0a44999538b7738c1fb216fc56d8'
WHERE name = '天坛公园-回音壁'
      AND COALESCE(address, '') = '天坛街道天坛路甲1号天坛公园内(东南角)'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
  );

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '天坛公园-回音壁',
    '天坛公园-回音壁，位于北京市北京市天坛街道天坛路甲1号天坛公园内(东南角)。数据来源：高德地图开放平台 POI。',
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
    ARRAY['http://store.is.autonavi.com/showpic/f74a0a44999538b7738c1fb216fc56d8'],
    'http://store.is.autonavi.com/showpic/f74a0a44999538b7738c1fb216fc56d8',
    ARRAY['风景名胜', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '天坛公园-回音壁'
      AND COALESCE(address, '') = '天坛街道天坛路甲1号天坛公园内(东南角)'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['https://aos-comment.amap.com/B000A6B2AE/comment/74d73435502f5dc1b9c92dafa1b580af_2048_2048_80.jpg'],
    thumbnail_url = 'https://aos-comment.amap.com/B000A6B2AE/comment/74d73435502f5dc1b9c92dafa1b580af_2048_2048_80.jpg'
WHERE name = '团结湖公园'
      AND COALESCE(address, '') = '团结湖南里路16号(呼家楼地铁站B东北口步行190米)'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
  );

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '团结湖公园',
    '团结湖公园，位于北京市北京市团结湖南里路16号(呼家楼地铁站B东北口步行190米)。数据来源：高德地图开放平台 POI。',
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
    ARRAY['https://aos-comment.amap.com/B000A6B2AE/comment/74d73435502f5dc1b9c92dafa1b580af_2048_2048_80.jpg'],
    'https://aos-comment.amap.com/B000A6B2AE/comment/74d73435502f5dc1b9c92dafa1b580af_2048_2048_80.jpg',
    ARRAY['公园', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '团结湖公园'
      AND COALESCE(address, '') = '团结湖南里路16号(呼家楼地铁站B东北口步行190米)'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['http://store.is.autonavi.com/showpic/db91a6c9cbe30198d9307d517bcbd3de'],
    thumbnail_url = 'http://store.is.autonavi.com/showpic/db91a6c9cbe30198d9307d517bcbd3de'
WHERE name = '先农坛'
      AND COALESCE(address, '') = '东经路21号北京古代建筑博物馆'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
  );

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '先农坛',
    '先农坛，位于北京市北京市东经路21号北京古代建筑博物馆。数据来源：高德地图开放平台 POI。',
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
    ARRAY['http://store.is.autonavi.com/showpic/db91a6c9cbe30198d9307d517bcbd3de'],
    'http://store.is.autonavi.com/showpic/db91a6c9cbe30198d9307d517bcbd3de',
    ARRAY['风景名胜', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '先农坛'
      AND COALESCE(address, '') = '东经路21号北京古代建筑博物馆'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['http://store.is.autonavi.com/showpic/5de13765a6f39116508eeb7002dcaab5'],
    thumbnail_url = 'http://store.is.autonavi.com/showpic/5de13765a6f39116508eeb7002dcaab5'
WHERE name = '大观园'
      AND COALESCE(address, '') = '南菜园街12号'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
  );

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '大观园',
    '大观园，位于北京市北京市南菜园街12号。数据来源：高德地图开放平台 POI。',
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
    ARRAY['http://store.is.autonavi.com/showpic/5de13765a6f39116508eeb7002dcaab5'],
    'http://store.is.autonavi.com/showpic/5de13765a6f39116508eeb7002dcaab5',
    ARRAY['省级景点', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '大观园'
      AND COALESCE(address, '') = '南菜园街12号'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['http://store.is.autonavi.com/showpic/838627ce1ca1fef7069b400a1f7322a2'],
    thumbnail_url = 'http://store.is.autonavi.com/showpic/838627ce1ca1fef7069b400a1f7322a2'
WHERE name = '纪晓岚故居'
      AND COALESCE(address, '') = '珠市口西大街241号(虎坊桥地铁站B东北口步行170米)'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
  );

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '纪晓岚故居',
    '纪晓岚故居，位于北京市北京市珠市口西大街241号(虎坊桥地铁站B东北口步行170米)。数据来源：高德地图开放平台 POI。',
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
    ARRAY['http://store.is.autonavi.com/showpic/838627ce1ca1fef7069b400a1f7322a2'],
    'http://store.is.autonavi.com/showpic/838627ce1ca1fef7069b400a1f7322a2',
    ARRAY['纪念馆', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '纪晓岚故居'
      AND COALESCE(address, '') = '珠市口西大街241号(虎坊桥地铁站B东北口步行170米)'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['http://store.is.autonavi.com/showpic/b88b6adecae77f1bf939442365f72aa7'],
    thumbnail_url = 'http://store.is.autonavi.com/showpic/b88b6adecae77f1bf939442365f72aa7'
WHERE name = '后海公园'
      AND COALESCE(address, '') = '后海北沿50号(近鼓楼西大街)'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
  );

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '后海公园',
    '后海公园，位于北京市北京市后海北沿50号(近鼓楼西大街)。数据来源：高德地图开放平台 POI。',
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
    ARRAY['http://store.is.autonavi.com/showpic/b88b6adecae77f1bf939442365f72aa7'],
    'http://store.is.autonavi.com/showpic/b88b6adecae77f1bf939442365f72aa7',
    ARRAY['公园', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '后海公园'
      AND COALESCE(address, '') = '后海北沿50号(近鼓楼西大街)'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['http://store.is.autonavi.com/showpic/52d66fe98e170a6aa80c9efae2e3245e'],
    thumbnail_url = 'http://store.is.autonavi.com/showpic/52d66fe98e170a6aa80c9efae2e3245e'
WHERE name = '东岳庙'
      AND COALESCE(address, '') = '朝阳门外大街141号'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
  );

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '东岳庙',
    '东岳庙，位于北京市北京市朝阳门外大街141号。数据来源：高德地图开放平台 POI。',
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
    ARRAY['http://store.is.autonavi.com/showpic/52d66fe98e170a6aa80c9efae2e3245e'],
    'http://store.is.autonavi.com/showpic/52d66fe98e170a6aa80c9efae2e3245e',
    ARRAY['寺庙道观', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '东岳庙'
      AND COALESCE(address, '') = '朝阳门外大街141号'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['https://aos-comment.amap.com/B000A7VMK9/comment/CDC00E78_E5D9_4172_AB57_C789D629AA87_L0_001_2000_1500_1764417404472_38939787.jpg'],
    thumbnail_url = 'https://aos-comment.amap.com/B000A7VMK9/comment/CDC00E78_E5D9_4172_AB57_C789D629AA87_L0_001_2000_1500_1764417404472_38939787.jpg'
WHERE name = '故宫博物院-端门'
      AND COALESCE(address, '') = '景山前街4号故宫博物院内(南侧)'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
  );

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '故宫博物院-端门',
    '故宫博物院-端门，位于北京市北京市景山前街4号故宫博物院内(南侧)。数据来源：高德地图开放平台 POI。',
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
    ARRAY['https://aos-comment.amap.com/B000A7VMK9/comment/CDC00E78_E5D9_4172_AB57_C789D629AA87_L0_001_2000_1500_1764417404472_38939787.jpg'],
    'https://aos-comment.amap.com/B000A7VMK9/comment/CDC00E78_E5D9_4172_AB57_C789D629AA87_L0_001_2000_1500_1764417404472_38939787.jpg',
    ARRAY['风景名胜', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '故宫博物院-端门'
      AND COALESCE(address, '') = '景山前街4号故宫博物院内(南侧)'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['https://aos-comment.amap.com/B0H65CPLW1/comment/content_media_external_images_media_1000145675_ss__1766561031782_68137379.jpg'],
    thumbnail_url = 'https://aos-comment.amap.com/B0H65CPLW1/comment/content_media_external_images_media_1000145675_ss__1766561031782_68137379.jpg'
WHERE name = '故宫博物院-东北角楼'
      AND COALESCE(address, '') = '景山前街4号北京故宫博物馆'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
  );

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '故宫博物院-东北角楼',
    '故宫博物院-东北角楼，位于北京市北京市景山前街4号北京故宫博物馆。数据来源：高德地图开放平台 POI。',
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
    ARRAY['https://aos-comment.amap.com/B0H65CPLW1/comment/content_media_external_images_media_1000145675_ss__1766561031782_68137379.jpg'],
    'https://aos-comment.amap.com/B0H65CPLW1/comment/content_media_external_images_media_1000145675_ss__1766561031782_68137379.jpg',
    ARRAY['风景名胜', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '故宫博物院-东北角楼'
      AND COALESCE(address, '') = '景山前街4号北京故宫博物馆'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['http://store.is.autonavi.com/showpic/8703169dc2eba03a5d9d7eaa38f570ad'],
    thumbnail_url = 'http://store.is.autonavi.com/showpic/8703169dc2eba03a5d9d7eaa38f570ad'
WHERE name = '北京动物园'
      AND COALESCE(address, '') = '西直门外大街137号'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
  );

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '北京动物园',
    '北京动物园，位于北京市北京市西直门外大街137号。数据来源：高德地图开放平台 POI。',
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
    ARRAY['http://store.is.autonavi.com/showpic/8703169dc2eba03a5d9d7eaa38f570ad'],
    'http://store.is.autonavi.com/showpic/8703169dc2eba03a5d9d7eaa38f570ad',
    ARRAY['动物园', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '北京动物园'
      AND COALESCE(address, '') = '西直门外大街137号'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['http://store.is.autonavi.com/showpic/d6bfe1e10330a7d34e45c2205edf81d5'],
    thumbnail_url = 'http://store.is.autonavi.com/showpic/d6bfe1e10330a7d34e45c2205edf81d5'
WHERE name = '故宫博物院-西南角楼'
      AND COALESCE(address, '') = '景山前街4号故宫博物院(西南角)'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
  );

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '故宫博物院-西南角楼',
    '故宫博物院-西南角楼，位于北京市北京市景山前街4号故宫博物院(西南角)。数据来源：高德地图开放平台 POI。',
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
    ARRAY['http://store.is.autonavi.com/showpic/d6bfe1e10330a7d34e45c2205edf81d5'],
    'http://store.is.autonavi.com/showpic/d6bfe1e10330a7d34e45c2205edf81d5',
    ARRAY['风景名胜', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '故宫博物院-西南角楼'
      AND COALESCE(address, '') = '景山前街4号故宫博物院(西南角)'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['https://aos-comment.amap.com/B000A83CZL/comment/content_media_external_images_media_22284_1739768520031_54704201.jpg'],
    thumbnail_url = 'https://aos-comment.amap.com/B000A83CZL/comment/content_media_external_images_media_22284_1739768520031_54704201.jpg'
WHERE name = '天坛公园-双环万寿亭'
      AND COALESCE(address, '') = '天坛东路甲1号天坛公园内(西北角)'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
  );

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '天坛公园-双环万寿亭',
    '天坛公园-双环万寿亭，位于北京市北京市天坛东路甲1号天坛公园内(西北角)。数据来源：高德地图开放平台 POI。',
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
    ARRAY['https://aos-comment.amap.com/B000A83CZL/comment/content_media_external_images_media_22284_1739768520031_54704201.jpg'],
    'https://aos-comment.amap.com/B000A83CZL/comment/content_media_external_images_media_22284_1739768520031_54704201.jpg',
    ARRAY['风景名胜', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '天坛公园-双环万寿亭'
      AND COALESCE(address, '') = '天坛东路甲1号天坛公园内(西北角)'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['http://store.is.autonavi.com/showpic/c3283abc8fa8847cd5292ebccd2cecb9'],
    thumbnail_url = 'http://store.is.autonavi.com/showpic/c3283abc8fa8847cd5292ebccd2cecb9'
WHERE name = '长安街'
      AND COALESCE(address, '') = '广场西侧路与西长安街交叉口'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
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
    ARRAY['http://store.is.autonavi.com/showpic/c3283abc8fa8847cd5292ebccd2cecb9'],
    'http://store.is.autonavi.com/showpic/c3283abc8fa8847cd5292ebccd2cecb9',
    ARRAY['风景名胜', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '长安街'
      AND COALESCE(address, '') = '广场西侧路与西长安街交叉口'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['http://store.is.autonavi.com/showpic/db50433739ce4770509508b3bfe92550'],
    thumbnail_url = 'http://store.is.autonavi.com/showpic/db50433739ce4770509508b3bfe92550'
WHERE name = '故宫博物院-钟表馆'
      AND COALESCE(address, '') = '景山前街4号故宫博物院'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
  );

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '故宫博物院-钟表馆',
    '故宫博物院-钟表馆，位于北京市北京市景山前街4号故宫博物院。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.399152, 39.918847), 4326)::geography,
    1,
    4.20,
    0,
    '景山前街4号故宫博物院',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY['http://store.is.autonavi.com/showpic/db50433739ce4770509508b3bfe92550'],
    'http://store.is.autonavi.com/showpic/db50433739ce4770509508b3bfe92550',
    ARRAY['展览馆', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '故宫博物院-钟表馆'
      AND COALESCE(address, '') = '景山前街4号故宫博物院'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['http://store.is.autonavi.com/showpic/50e0236d4aa1f788a47c285fddc08d38'],
    thumbnail_url = 'http://store.is.autonavi.com/showpic/50e0236d4aa1f788a47c285fddc08d38'
WHERE name = '老舍茶馆(前门店)'
      AND COALESCE(address, '') = '大栅栏街道前门西大街正阳市场3号楼'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
  );

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '老舍茶馆(前门店)',
    '老舍茶馆(前门店)，位于北京市北京市大栅栏街道前门西大街正阳市场3号楼。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.393316, 39.899703), 4326)::geography,
    1,
    4.20,
    0,
    '大栅栏街道前门西大街正阳市场3号楼',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY['http://store.is.autonavi.com/showpic/50e0236d4aa1f788a47c285fddc08d38'],
    'http://store.is.autonavi.com/showpic/50e0236d4aa1f788a47c285fddc08d38',
    ARRAY['旅游景点', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '老舍茶馆(前门店)'
      AND COALESCE(address, '') = '大栅栏街道前门西大街正阳市场3号楼'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['http://store.is.autonavi.com/showpic/6976d5d59cb372b05db715cfa1900fdf'],
    thumbnail_url = 'http://store.is.autonavi.com/showpic/6976d5d59cb372b05db715cfa1900fdf'
WHERE name = '天坛公园-斋宫'
      AND COALESCE(address, '') = '天坛东路甲1号天坛公园内(西南角)'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
  );

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '天坛公园-斋宫',
    '天坛公园-斋宫，位于北京市北京市天坛东路甲1号天坛公园内(西南角)。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.406686, 39.879763), 4326)::geography,
    1,
    4.20,
    0,
    '天坛东路甲1号天坛公园内(西南角)',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY['http://store.is.autonavi.com/showpic/6976d5d59cb372b05db715cfa1900fdf'],
    'http://store.is.autonavi.com/showpic/6976d5d59cb372b05db715cfa1900fdf',
    ARRAY['风景名胜', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '天坛公园-斋宫'
      AND COALESCE(address, '') = '天坛东路甲1号天坛公园内(西南角)'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['https://aos-comment.amap.com/B000AA1A7J/comment/605274cceb3084b2101420a5d3ae063e_2048_2048_80.jpg'],
    thumbnail_url = 'https://aos-comment.amap.com/B000AA1A7J/comment/605274cceb3084b2101420a5d3ae063e_2048_2048_80.jpg'
WHERE name = '霱公府(不对外开放)'
      AND COALESCE(address, '') = '西绒线胡同51号(西单地铁站D东南口步行480米)'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
  );

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '霱公府(不对外开放)',
    '霱公府(不对外开放)，位于北京市北京市西绒线胡同51号(西单地铁站D东南口步行480米)。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.376930, 39.905022), 4326)::geography,
    1,
    4.20,
    0,
    '西绒线胡同51号(西单地铁站D东南口步行480米)',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY['https://aos-comment.amap.com/B000AA1A7J/comment/605274cceb3084b2101420a5d3ae063e_2048_2048_80.jpg'],
    'https://aos-comment.amap.com/B000AA1A7J/comment/605274cceb3084b2101420a5d3ae063e_2048_2048_80.jpg',
    ARRAY['风景名胜', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '霱公府(不对外开放)'
      AND COALESCE(address, '') = '西绒线胡同51号(西单地铁站D东南口步行480米)'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['https://store.is.autonavi.com/showpic/0171629dfd78b71500d7093dbfcd9455'],
    thumbnail_url = 'https://store.is.autonavi.com/showpic/0171629dfd78b71500d7093dbfcd9455'
WHERE name = '北海公园-永安寺'
      AND COALESCE(address, '') = '什刹海街道文津街1号(故宫北)北海公园内(西南角)'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
  );

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '北海公园-永安寺',
    '北海公园-永安寺，位于北京市北京市什刹海街道文津街1号(故宫北)北海公园内(西南角)。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.389393, 39.924350), 4326)::geography,
    1,
    4.20,
    0,
    '什刹海街道文津街1号(故宫北)北海公园内(西南角)',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY['https://store.is.autonavi.com/showpic/0171629dfd78b71500d7093dbfcd9455'],
    'https://store.is.autonavi.com/showpic/0171629dfd78b71500d7093dbfcd9455',
    ARRAY['寺庙道观', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '北海公园-永安寺'
      AND COALESCE(address, '') = '什刹海街道文津街1号(故宫北)北海公园内(西南角)'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['https://aos-comment.amap.com/B0FFGBCQP6/comment/6FE51B0E_4D0B_4CA7_BEF1_2EFB91FE020F_L0_001_1500_200_1764261359771_05805002.jpg'],
    thumbnail_url = 'https://aos-comment.amap.com/B0FFGBCQP6/comment/6FE51B0E_4D0B_4CA7_BEF1_2EFB91FE020F_L0_001_1500_200_1764261359771_05805002.jpg'
WHERE name = '北京站北广场'
      AND COALESCE(address, '') = '北京站街与北京站西街交叉口南100米'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
  );

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '北京站北广场',
    '北京站北广场，位于北京市北京市北京站街与北京站西街交叉口南100米。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.427123, 39.904424), 4326)::geography,
    1,
    4.20,
    0,
    '北京站街与北京站西街交叉口南100米',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY['https://aos-comment.amap.com/B0FFGBCQP6/comment/6FE51B0E_4D0B_4CA7_BEF1_2EFB91FE020F_L0_001_1500_200_1764261359771_05805002.jpg'],
    'https://aos-comment.amap.com/B0FFGBCQP6/comment/6FE51B0E_4D0B_4CA7_BEF1_2EFB91FE020F_L0_001_1500_200_1764261359771_05805002.jpg',
    ARRAY['城市广场', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '北京站北广场'
      AND COALESCE(address, '') = '北京站街与北京站西街交叉口南100米'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['http://store.is.autonavi.com/showpic/0cf47d269fd9d2a36fceb5c3b9b5d24a'],
    thumbnail_url = 'http://store.is.autonavi.com/showpic/0cf47d269fd9d2a36fceb5c3b9b5d24a'
WHERE name = '北京古观象台'
      AND COALESCE(address, '') = '建国门大街裱褙胡同2号(建国门地铁站C西南口步行130米)'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
  );

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '北京古观象台',
    '北京古观象台，位于北京市北京市建国门大街裱褙胡同2号(建国门地铁站C西南口步行130米)。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.434326, 39.907206), 4326)::geography,
    1,
    4.20,
    0,
    '建国门大街裱褙胡同2号(建国门地铁站C西南口步行130米)',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY['http://store.is.autonavi.com/showpic/0cf47d269fd9d2a36fceb5c3b9b5d24a'],
    'http://store.is.autonavi.com/showpic/0cf47d269fd9d2a36fceb5c3b9b5d24a',
    ARRAY['风景名胜', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '北京古观象台'
      AND COALESCE(address, '') = '建国门大街裱褙胡同2号(建国门地铁站C西南口步行130米)'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['https://aos-comment.amap.com/B0J6BZNC6H/comment/content_media_external_file_1000105727_ss__1763270922421_92563117.jpg'],
    thumbnail_url = 'https://aos-comment.amap.com/B0J6BZNC6H/comment/content_media_external_file_1000105727_ss__1763270922421_92563117.jpg'
WHERE name = '故宫博物院-西北角楼'
      AND COALESCE(address, '') = '景山前街4号故宫博物院(西北角)'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
  );

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '故宫博物院-西北角楼',
    '故宫博物院-西北角楼，位于北京市北京市景山前街4号故宫博物院(西北角)。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.392575, 39.922150), 4326)::geography,
    1,
    4.20,
    0,
    '景山前街4号故宫博物院(西北角)',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY['https://aos-comment.amap.com/B0J6BZNC6H/comment/content_media_external_file_1000105727_ss__1763270922421_92563117.jpg'],
    'https://aos-comment.amap.com/B0J6BZNC6H/comment/content_media_external_file_1000105727_ss__1763270922421_92563117.jpg',
    ARRAY['风景名胜', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '故宫博物院-西北角楼'
      AND COALESCE(address, '') = '景山前街4号故宫博物院(西北角)'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['http://store.is.autonavi.com/showpic/36e1f8ccc63bb0d0ac0655f65d7a8ae1'],
    thumbnail_url = 'http://store.is.autonavi.com/showpic/36e1f8ccc63bb0d0ac0655f65d7a8ae1'
WHERE name = '景山公园-明思宗殉国处'
      AND COALESCE(address, '') = '景山西街44号景山公园内(东南角)'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
  );

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '景山公园-明思宗殉国处',
    '景山公园-明思宗殉国处，位于北京市北京市景山西街44号景山公园内(东南角)。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.399039, 39.924529), 4326)::geography,
    1,
    4.20,
    0,
    '景山西街44号景山公园内(东南角)',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY['http://store.is.autonavi.com/showpic/36e1f8ccc63bb0d0ac0655f65d7a8ae1'],
    'http://store.is.autonavi.com/showpic/36e1f8ccc63bb0d0ac0655f65d7a8ae1',
    ARRAY['风景名胜', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '景山公园-明思宗殉国处'
      AND COALESCE(address, '') = '景山西街44号景山公园内(东南角)'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['http://store.is.autonavi.com/showpic/32819ea5111ee447e8844b2f18a0119a'],
    thumbnail_url = 'http://store.is.autonavi.com/showpic/32819ea5111ee447e8844b2f18a0119a'
WHERE name = '故宫博物院-养心殿'
      AND COALESCE(address, '') = '景山前街4号故宫博物院内'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
  );

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '故宫博物院-养心殿',
    '故宫博物院-养心殿，位于北京市北京市景山前街4号故宫博物院内。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.395676, 39.919765), 4326)::geography,
    1,
    4.20,
    0,
    '景山前街4号故宫博物院内',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY['http://store.is.autonavi.com/showpic/32819ea5111ee447e8844b2f18a0119a'],
    'http://store.is.autonavi.com/showpic/32819ea5111ee447e8844b2f18a0119a',
    ARRAY['风景名胜', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '故宫博物院-养心殿'
      AND COALESCE(address, '') = '景山前街4号故宫博物院内'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['https://aos-comment.amap.com/B0LBRSGX65/comment/content_media_external_file_14805_ss__1765729696442_70648522.jpg'],
    thumbnail_url = 'https://aos-comment.amap.com/B0LBRSGX65/comment/content_media_external_file_14805_ss__1765729696442_70648522.jpg'
WHERE name = '王府井地下佛像'
      AND COALESCE(address, '') = '北京王府井百货大楼B2层'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
  );

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '王府井地下佛像',
    '王府井地下佛像，位于北京市北京市北京王府井百货大楼B2层。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.410136, 39.913740), 4326)::geography,
    1,
    4.20,
    0,
    '北京王府井百货大楼B2层',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY['https://aos-comment.amap.com/B0LBRSGX65/comment/content_media_external_file_14805_ss__1765729696442_70648522.jpg'],
    'https://aos-comment.amap.com/B0LBRSGX65/comment/content_media_external_file_14805_ss__1765729696442_70648522.jpg',
    ARRAY['风景名胜', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '王府井地下佛像'
      AND COALESCE(address, '') = '北京王府井百货大楼B2层'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['http://store.is.autonavi.com/showpic/0c8257320e8c8a771ef6aef1cb358483'],
    thumbnail_url = 'http://store.is.autonavi.com/showpic/0c8257320e8c8a771ef6aef1cb358483'
WHERE name = '圆明园遗址公园'
      AND COALESCE(address, '') = '清华西路28号'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
  );

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '圆明园遗址公园',
    '圆明园遗址公园，位于北京市北京市清华西路28号。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.300831, 40.006519), 4326)::geography,
    1,
    4.20,
    0,
    '清华西路28号',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY['http://store.is.autonavi.com/showpic/0c8257320e8c8a771ef6aef1cb358483'],
    'http://store.is.autonavi.com/showpic/0c8257320e8c8a771ef6aef1cb358483',
    ARRAY['国家级景点', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '圆明园遗址公园'
      AND COALESCE(address, '') = '清华西路28号'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['http://store.is.autonavi.com/showpic/746a5f4bf010ea956d1f574378b222d4'],
    thumbnail_url = 'http://store.is.autonavi.com/showpic/746a5f4bf010ea956d1f574378b222d4'
WHERE name = '北京温榆河公园'
      AND COALESCE(address, '') = '京承高速与滨河路交叉口'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
  );

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '北京温榆河公园',
    '北京温榆河公园，位于北京市北京市京承高速与滨河路交叉口。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.485512, 40.075917), 4326)::geography,
    1,
    4.20,
    0,
    '京承高速与滨河路交叉口',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY['http://store.is.autonavi.com/showpic/746a5f4bf010ea956d1f574378b222d4'],
    'http://store.is.autonavi.com/showpic/746a5f4bf010ea956d1f574378b222d4',
    ARRAY['公园', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '北京温榆河公园'
      AND COALESCE(address, '') = '京承高速与滨河路交叉口'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['https://aos-comment.amap.com/B0G25HVJUO/comment/content_media_external_file_4557_1761755655478_13504935.jpg'],
    thumbnail_url = 'https://aos-comment.amap.com/B0G25HVJUO/comment/content_media_external_file_4557_1761755655478_13504935.jpg'
WHERE name = '北京温榆河公园·湿地示范-芸上梯田'
      AND COALESCE(address, '') = '北京温榆河公园-望芸台东侧80米'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
  );

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '北京温榆河公园·湿地示范-芸上梯田',
    '北京温榆河公园·湿地示范-芸上梯田，位于北京市北京市北京温榆河公园-望芸台东侧80米。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.461746, 40.074394), 4326)::geography,
    1,
    4.20,
    0,
    '北京温榆河公园-望芸台东侧80米',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY['https://aos-comment.amap.com/B0G25HVJUO/comment/content_media_external_file_4557_1761755655478_13504935.jpg'],
    'https://aos-comment.amap.com/B0G25HVJUO/comment/content_media_external_file_4557_1761755655478_13504935.jpg',
    ARRAY['旅游景点', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '北京温榆河公园·湿地示范-芸上梯田'
      AND COALESCE(address, '') = '北京温榆河公园-望芸台东侧80米'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['https://aos-comment.amap.com/default_poi/comment/content_media_external_file_23956_ss__1744887247099_12428625.jpg'],
    thumbnail_url = 'https://aos-comment.amap.com/default_poi/comment/content_media_external_file_23956_ss__1744887247099_12428625.jpg'
WHERE name = '北京温榆河公园·故城记忆'
      AND COALESCE(address, '') = '机场北线高速与高白路交叉口东南侧'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
  );

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '北京温榆河公园·故城记忆',
    '北京温榆河公园·故城记忆，位于北京市北京市机场北线高速与高白路交叉口东南侧。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.500270, 40.114508), 4326)::geography,
    1,
    4.20,
    0,
    '机场北线高速与高白路交叉口东南侧',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY['https://aos-comment.amap.com/default_poi/comment/content_media_external_file_23956_ss__1744887247099_12428625.jpg'],
    'https://aos-comment.amap.com/default_poi/comment/content_media_external_file_23956_ss__1744887247099_12428625.jpg',
    ARRAY['公园', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '北京温榆河公园·故城记忆'
      AND COALESCE(address, '') = '机场北线高速与高白路交叉口东南侧'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['http://store.is.autonavi.com/showpic/18069dac30cd3ca0a025b38b7343b74e'],
    thumbnail_url = 'http://store.is.autonavi.com/showpic/18069dac30cd3ca0a025b38b7343b74e'
WHERE name = '奥林匹克森林公园'
      AND COALESCE(address, '') = '科荟路33号'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
  );

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '奥林匹克森林公园',
    '奥林匹克森林公园，位于北京市北京市科荟路33号。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.392159, 40.018635), 4326)::geography,
    1,
    4.20,
    0,
    '科荟路33号',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY['http://store.is.autonavi.com/showpic/18069dac30cd3ca0a025b38b7343b74e'],
    'http://store.is.autonavi.com/showpic/18069dac30cd3ca0a025b38b7343b74e',
    ARRAY['国家级景点', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '奥林匹克森林公园'
      AND COALESCE(address, '') = '科荟路33号'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['http://store.is.autonavi.com/showpic/dd37ce835b65616b7231c857d0e76d2b'],
    thumbnail_url = 'http://store.is.autonavi.com/showpic/dd37ce835b65616b7231c857d0e76d2b'
WHERE name = '奥林匹克森林公园南园'
      AND COALESCE(address, '') = '北五环辅路奥林匹克森林公园'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
  );

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '奥林匹克森林公园南园',
    '奥林匹克森林公园南园，位于北京市北京市北五环辅路奥林匹克森林公园。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.391365, 40.016194), 4326)::geography,
    1,
    4.20,
    0,
    '北五环辅路奥林匹克森林公园',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY['http://store.is.autonavi.com/showpic/dd37ce835b65616b7231c857d0e76d2b'],
    'http://store.is.autonavi.com/showpic/dd37ce835b65616b7231c857d0e76d2b',
    ARRAY['国家级景点', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '奥林匹克森林公园南园'
      AND COALESCE(address, '') = '北五环辅路奥林匹克森林公园'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['http://store.is.autonavi.com/showpic/8ea2759a666413d5406cbaddd0799108'],
    thumbnail_url = 'http://store.is.autonavi.com/showpic/8ea2759a666413d5406cbaddd0799108'
WHERE name = '南海子公园'
      AND COALESCE(address, '') = '黄亦路16号'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
  );

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '南海子公园',
    '南海子公园，位于北京市北京市黄亦路16号。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.464223, 39.777746), 4326)::geography,
    1,
    4.20,
    0,
    '黄亦路16号',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY['http://store.is.autonavi.com/showpic/8ea2759a666413d5406cbaddd0799108'],
    'http://store.is.autonavi.com/showpic/8ea2759a666413d5406cbaddd0799108',
    ARRAY['公园', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '南海子公园'
      AND COALESCE(address, '') = '黄亦路16号'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['http://store.is.autonavi.com/showpic/8c0562707d8b7fbe6e541ac0c682133f'],
    thumbnail_url = 'http://store.is.autonavi.com/showpic/8c0562707d8b7fbe6e541ac0c682133f'
WHERE name = '香山公园'
      AND COALESCE(address, '') = '香山买卖街40号'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
  );

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '香山公园',
    '香山公园，位于北京市北京市香山买卖街40号。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.188746, 39.990107), 4326)::geography,
    1,
    4.20,
    0,
    '香山买卖街40号',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY['http://store.is.autonavi.com/showpic/8c0562707d8b7fbe6e541ac0c682133f'],
    'http://store.is.autonavi.com/showpic/8c0562707d8b7fbe6e541ac0c682133f',
    ARRAY['国家级景点', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '香山公园'
      AND COALESCE(address, '') = '香山买卖街40号'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['http://store.is.autonavi.com/showpic/e3f95f17eb8064df27d48cfe725d4f9e'],
    thumbnail_url = 'http://store.is.autonavi.com/showpic/e3f95f17eb8064df27d48cfe725d4f9e'
WHERE name = '北京奥林匹克公园'
      AND COALESCE(address, '') = '北辰东路15号(森林公园南门地铁站C东南口旁)'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
  );

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '北京奥林匹克公园',
    '北京奥林匹克公园，位于北京市北京市北辰东路15号(森林公园南门地铁站C东南口旁)。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.393096, 40.009926), 4326)::geography,
    1,
    4.20,
    0,
    '北辰东路15号(森林公园南门地铁站C东南口旁)',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY['http://store.is.autonavi.com/showpic/e3f95f17eb8064df27d48cfe725d4f9e'],
    'http://store.is.autonavi.com/showpic/e3f95f17eb8064df27d48cfe725d4f9e',
    ARRAY['国家级景点', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '北京奥林匹克公园'
      AND COALESCE(address, '') = '北辰东路15号(森林公园南门地铁站C东南口旁)'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['http://store.is.autonavi.com/showpic/dfca8d8318dfd6df8ecc12fb82607fe5'],
    thumbnail_url = 'http://store.is.autonavi.com/showpic/dfca8d8318dfd6df8ecc12fb82607fe5'
WHERE name = '奥林匹克公园中心区'
      AND COALESCE(address, '') = '科荟路33号奥林匹克森林公园内'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
  );

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '奥林匹克公园中心区',
    '奥林匹克公园中心区，位于北京市北京市科荟路33号奥林匹克森林公园内。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.392451, 40.000039), 4326)::geography,
    1,
    4.20,
    0,
    '科荟路33号奥林匹克森林公园内',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY['http://store.is.autonavi.com/showpic/dfca8d8318dfd6df8ecc12fb82607fe5'],
    'http://store.is.autonavi.com/showpic/dfca8d8318dfd6df8ecc12fb82607fe5',
    ARRAY['公园', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '奥林匹克公园中心区'
      AND COALESCE(address, '') = '科荟路33号奥林匹克森林公园内'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['http://store.is.autonavi.com/showpic/847c5aff3766646a937b8b8cbc72f809'],
    thumbnail_url = 'http://store.is.autonavi.com/showpic/847c5aff3766646a937b8b8cbc72f809'
WHERE name = '紫竹院公园'
      AND COALESCE(address, '') = '中关村南大街35号'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
  );

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '紫竹院公园',
    '紫竹院公园，位于北京市北京市中关村南大街35号。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.319079, 39.942352), 4326)::geography,
    1,
    4.20,
    0,
    '中关村南大街35号',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY['http://store.is.autonavi.com/showpic/847c5aff3766646a937b8b8cbc72f809'],
    'http://store.is.autonavi.com/showpic/847c5aff3766646a937b8b8cbc72f809',
    ARRAY['公园', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '紫竹院公园'
      AND COALESCE(address, '') = '中关村南大街35号'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['http://store.is.autonavi.com/showpic/2ebddd061c4000832b9c0fa901198ca2'],
    thumbnail_url = 'http://store.is.autonavi.com/showpic/2ebddd061c4000832b9c0fa901198ca2'
WHERE name = '北京欢乐谷'
      AND COALESCE(address, '') = '东四环小武基北路'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
  );

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '北京欢乐谷',
    '北京欢乐谷，位于北京市北京市东四环小武基北路。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.494743, 39.867355), 4326)::geography,
    1,
    4.20,
    0,
    '东四环小武基北路',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY['http://store.is.autonavi.com/showpic/2ebddd061c4000832b9c0fa901198ca2'],
    'http://store.is.autonavi.com/showpic/2ebddd061c4000832b9c0fa901198ca2',
    ARRAY['国家级景点', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '北京欢乐谷'
      AND COALESCE(address, '') = '东四环小武基北路'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['http://store.is.autonavi.com/showpic/863c653bf4ec9fa2dacdf65c49901d9d'],
    thumbnail_url = 'http://store.is.autonavi.com/showpic/863c653bf4ec9fa2dacdf65c49901d9d'
WHERE name = '北京西山国家森林公园'
      AND COALESCE(address, '') = '闵庄路与香山南路交叉口西100米'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
  );

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '北京西山国家森林公园',
    '北京西山国家森林公园，位于北京市北京市闵庄路与香山南路交叉口西100米。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.193063, 39.975185), 4326)::geography,
    1,
    4.20,
    0,
    '闵庄路与香山南路交叉口西100米',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY['http://store.is.autonavi.com/showpic/863c653bf4ec9fa2dacdf65c49901d9d'],
    'http://store.is.autonavi.com/showpic/863c653bf4ec9fa2dacdf65c49901d9d',
    ARRAY['省级景点', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '北京西山国家森林公园'
      AND COALESCE(address, '') = '闵庄路与香山南路交叉口西100米'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['http://store.is.autonavi.com/showpic/d742b4e71e994f05b6411e7c168cdd50'],
    thumbnail_url = 'http://store.is.autonavi.com/showpic/d742b4e71e994f05b6411e7c168cdd50'
WHERE name = '北京西山国家森林公园鬼笑石'
      AND COALESCE(address, '') = '北京西山国家森林公园内(西北角)'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
  );

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '北京西山国家森林公园鬼笑石',
    '北京西山国家森林公园鬼笑石，位于北京市北京市北京西山国家森林公园内(西北角)。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.187684, 39.979457), 4326)::geography,
    1,
    4.20,
    0,
    '北京西山国家森林公园内(西北角)',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY['http://store.is.autonavi.com/showpic/d742b4e71e994f05b6411e7c168cdd50'],
    'http://store.is.autonavi.com/showpic/d742b4e71e994f05b6411e7c168cdd50',
    ARRAY['旅游景点', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '北京西山国家森林公园鬼笑石'
      AND COALESCE(address, '') = '北京西山国家森林公园内(西北角)'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['http://store.is.autonavi.com/showpic/b06f0d68b472a4e7386f2aab40253e1c'],
    thumbnail_url = 'http://store.is.autonavi.com/showpic/b06f0d68b472a4e7386f2aab40253e1c'
WHERE name = '八大处公园'
      AND COALESCE(address, '') = '八大处路3号'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
  );

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '八大处公园',
    '八大处公园，位于北京市北京市八大处路3号。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.184358, 39.962679), 4326)::geography,
    1,
    4.20,
    0,
    '八大处路3号',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY['http://store.is.autonavi.com/showpic/b06f0d68b472a4e7386f2aab40253e1c'],
    'http://store.is.autonavi.com/showpic/b06f0d68b472a4e7386f2aab40253e1c',
    ARRAY['国家级景点', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '八大处公园'
      AND COALESCE(address, '') = '八大处路3号'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['http://store.is.autonavi.com/showpic/19478923fe6832280d38954894542d56'],
    thumbnail_url = 'http://store.is.autonavi.com/showpic/19478923fe6832280d38954894542d56'
WHERE name = '海淀公园'
      AND COALESCE(address, '') = '万柳镇新建宫门路2号(万泉河桥地铁站A西北口步行140米)'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
  );

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '海淀公园',
    '海淀公园，位于北京市北京市万柳镇新建宫门路2号(万泉河桥地铁站A西北口步行140米)。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.295122, 39.986416), 4326)::geography,
    1,
    4.20,
    0,
    '万柳镇新建宫门路2号(万泉河桥地铁站A西北口步行140米)',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY['http://store.is.autonavi.com/showpic/19478923fe6832280d38954894542d56'],
    'http://store.is.autonavi.com/showpic/19478923fe6832280d38954894542d56',
    ARRAY['公园', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '海淀公园'
      AND COALESCE(address, '') = '万柳镇新建宫门路2号(万泉河桥地铁站A西北口步行140米)'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['http://store.is.autonavi.com/showpic/1c30e7886c1528deb665e1d63034064f'],
    thumbnail_url = 'http://store.is.autonavi.com/showpic/1c30e7886c1528deb665e1d63034064f'
WHERE name = '首钢园'
      AND COALESCE(address, '') = '石景山路68号'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
  );

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '首钢园',
    '首钢园，位于北京市北京市石景山路68号。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.155232, 39.915415), 4326)::geography,
    1,
    4.20,
    0,
    '石景山路68号',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY['http://store.is.autonavi.com/showpic/1c30e7886c1528deb665e1d63034064f'],
    'http://store.is.autonavi.com/showpic/1c30e7886c1528deb665e1d63034064f',
    ARRAY['公园', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '首钢园'
      AND COALESCE(address, '') = '石景山路68号'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['https://aos-comment.amap.com/B0G3TLQLBH/comment/f56418419e9ed41fe234c88d9added30_2048_2048_80.jpg'],
    thumbnail_url = 'https://aos-comment.amap.com/B0G3TLQLBH/comment/f56418419e9ed41fe234c88d9added30_2048_2048_80.jpg'
WHERE name = '首钢园北区'
      AND COALESCE(address, '') = '北京市古城街道石景山路68号首钢园'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
  );

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '首钢园北区',
    '首钢园北区，位于北京市北京市北京市古城街道石景山路68号首钢园。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.157104, 39.915433), 4326)::geography,
    1,
    4.20,
    0,
    '北京市古城街道石景山路68号首钢园',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY['https://aos-comment.amap.com/B0G3TLQLBH/comment/f56418419e9ed41fe234c88d9added30_2048_2048_80.jpg'],
    'https://aos-comment.amap.com/B0G3TLQLBH/comment/f56418419e9ed41fe234c88d9added30_2048_2048_80.jpg',
    ARRAY['公园', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '首钢园北区'
      AND COALESCE(address, '') = '北京市古城街道石景山路68号首钢园'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['http://store.is.autonavi.com/showpic/1181290b0540a2ff0124cdf1fc016914'],
    thumbnail_url = 'http://store.is.autonavi.com/showpic/1181290b0540a2ff0124cdf1fc016914'
WHERE name = '百望山森林公园'
      AND COALESCE(address, '') = '黑山扈北口19号'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
  );

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '百望山森林公园',
    '百望山森林公园，位于北京市北京市黑山扈北口19号。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.255631, 40.029982), 4326)::geography,
    1,
    4.20,
    0,
    '黑山扈北口19号',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY['http://store.is.autonavi.com/showpic/1181290b0540a2ff0124cdf1fc016914'],
    'http://store.is.autonavi.com/showpic/1181290b0540a2ff0124cdf1fc016914',
    ARRAY['省级景点', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '百望山森林公园'
      AND COALESCE(address, '') = '黑山扈北口19号'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['http://store.is.autonavi.com/showpic/7e756ead8ec9d2b2fe412648511998e3'],
    thumbnail_url = 'http://store.is.autonavi.com/showpic/7e756ead8ec9d2b2fe412648511998e3'
WHERE name = '城市绿心森林公园'
      AND COALESCE(address, '') = '张辛庄路与通怀路交叉路口'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
  );

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '城市绿心森林公园',
    '城市绿心森林公园，位于北京市北京市张辛庄路与通怀路交叉路口。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.724872, 39.873655), 4326)::geography,
    1,
    4.20,
    0,
    '张辛庄路与通怀路交叉路口',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY['http://store.is.autonavi.com/showpic/7e756ead8ec9d2b2fe412648511998e3'],
    'http://store.is.autonavi.com/showpic/7e756ead8ec9d2b2fe412648511998e3',
    ARRAY['公园', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '城市绿心森林公园'
      AND COALESCE(address, '') = '张辛庄路与通怀路交叉路口'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['https://store.is.autonavi.com/showpic/a5615f4121cd11ac0000000737028139?type=pic'],
    thumbnail_url = 'https://store.is.autonavi.com/showpic/a5615f4121cd11ac0000000737028139?type=pic'
WHERE name = '北小河公园'
      AND COALESCE(address, '') = '师家坟村156号'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
  );

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '北小河公园',
    '北小河公园，位于北京市北京市师家坟村156号。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.455245, 40.005054), 4326)::geography,
    1,
    4.20,
    0,
    '师家坟村156号',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY['https://store.is.autonavi.com/showpic/a5615f4121cd11ac0000000737028139?type=pic'],
    'https://store.is.autonavi.com/showpic/a5615f4121cd11ac0000000737028139?type=pic',
    ARRAY['公园', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '北小河公园'
      AND COALESCE(address, '') = '师家坟村156号'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['http://store.is.autonavi.com/showpic/8908c240e23bf44beaf524bff0ba4afc'],
    thumbnail_url = 'http://store.is.autonavi.com/showpic/8908c240e23bf44beaf524bff0ba4afc'
WHERE name = '元大都城垣遗址公园'
      AND COALESCE(address, '') = '育慧南路南口与北土城东路交叉口大牌坊南侧'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
  );

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '元大都城垣遗址公园',
    '元大都城垣遗址公园，位于北京市北京市育慧南路南口与北土城东路交叉口大牌坊南侧。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.408048, 39.976114), 4326)::geography,
    1,
    4.20,
    0,
    '育慧南路南口与北土城东路交叉口大牌坊南侧',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY['http://store.is.autonavi.com/showpic/8908c240e23bf44beaf524bff0ba4afc'],
    'http://store.is.autonavi.com/showpic/8908c240e23bf44beaf524bff0ba4afc',
    ARRAY['旅游景点', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '元大都城垣遗址公园'
      AND COALESCE(address, '') = '育慧南路南口与北土城东路交叉口大牌坊南侧'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['http://store.is.autonavi.com/showpic/e87d109f420d11b4db4e918db7ee1f21'],
    thumbnail_url = 'http://store.is.autonavi.com/showpic/e87d109f420d11b4db4e918db7ee1f21'
WHERE name = '元大都城垣遗址公园-海棠花溪'
      AND COALESCE(address, '') = '北土城东路甲100号元大都遗址公园内(近樱花园西街)'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
  );

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '元大都城垣遗址公园-海棠花溪',
    '元大都城垣遗址公园-海棠花溪，位于北京市北京市北土城东路甲100号元大都遗址公园内(近樱花园西街)。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.399020, 39.976484), 4326)::geography,
    1,
    4.20,
    0,
    '北土城东路甲100号元大都遗址公园内(近樱花园西街)',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY['http://store.is.autonavi.com/showpic/e87d109f420d11b4db4e918db7ee1f21'],
    'http://store.is.autonavi.com/showpic/e87d109f420d11b4db4e918db7ee1f21',
    ARRAY['公园', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '元大都城垣遗址公园-海棠花溪'
      AND COALESCE(address, '') = '北土城东路甲100号元大都遗址公园内(近樱花园西街)'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['http://store.is.autonavi.com/showpic/cb724c4bd21320a07aaeaffa2e46ac59'],
    thumbnail_url = 'http://store.is.autonavi.com/showpic/cb724c4bd21320a07aaeaffa2e46ac59'
WHERE name = '莲花池公园'
      AND COALESCE(address, '') = '西三环中路38号'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
  );

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '莲花池公园',
    '莲花池公园，位于北京市北京市西三环中路38号。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.315327, 39.893297), 4326)::geography,
    1,
    4.20,
    0,
    '西三环中路38号',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY['http://store.is.autonavi.com/showpic/cb724c4bd21320a07aaeaffa2e46ac59'],
    'http://store.is.autonavi.com/showpic/cb724c4bd21320a07aaeaffa2e46ac59',
    ARRAY['公园', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '莲花池公园'
      AND COALESCE(address, '') = '西三环中路38号'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['http://store.is.autonavi.com/showpic/23702a2af1314e1388caedb91306545d'],
    thumbnail_url = 'http://store.is.autonavi.com/showpic/23702a2af1314e1388caedb91306545d'
WHERE name = '北京凤凰岭景区'
      AND COALESCE(address, '') = '苏家坨镇凤凰岭路19号'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
  );

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '北京凤凰岭景区',
    '北京凤凰岭景区，位于北京市北京市苏家坨镇凤凰岭路19号。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.084981, 40.106778), 4326)::geography,
    1,
    4.20,
    0,
    '苏家坨镇凤凰岭路19号',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY['http://store.is.autonavi.com/showpic/23702a2af1314e1388caedb91306545d'],
    'http://store.is.autonavi.com/showpic/23702a2af1314e1388caedb91306545d',
    ARRAY['国家级景点', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '北京凤凰岭景区'
      AND COALESCE(address, '') = '苏家坨镇凤凰岭路19号'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['http://store.is.autonavi.com/showpic/7c1bde68786e692ca51268a4fdc2a65e'],
    thumbnail_url = 'http://store.is.autonavi.com/showpic/7c1bde68786e692ca51268a4fdc2a65e'
WHERE name = '大运河森林公园'
      AND COALESCE(address, '') = '宋梁路'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
  );

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '大运河森林公园',
    '大运河森林公园，位于北京市北京市宋梁路。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.742353, 39.876323), 4326)::geography,
    1,
    4.20,
    0,
    '宋梁路',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY['http://store.is.autonavi.com/showpic/7c1bde68786e692ca51268a4fdc2a65e'],
    'http://store.is.autonavi.com/showpic/7c1bde68786e692ca51268a4fdc2a65e',
    ARRAY['国家级景点', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '大运河森林公园'
      AND COALESCE(address, '') = '宋梁路'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['http://aos-cdn-image.amap.com/sns/ugccomment/d1e7ba3a-c658-4267-a33f-6f95fe20638f.jpg'],
    thumbnail_url = 'http://aos-cdn-image.amap.com/sns/ugccomment/d1e7ba3a-c658-4267-a33f-6f95fe20638f.jpg'
WHERE name = '北京世园国际旅游度假区'
      AND COALESCE(address, '') = '延庆镇百康路1号'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
  );

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '北京世园国际旅游度假区',
    '北京世园国际旅游度假区，位于北京市北京市延庆镇百康路1号。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(115.947612, 40.442534), 4326)::geography,
    1,
    4.20,
    0,
    '延庆镇百康路1号',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY['http://aos-cdn-image.amap.com/sns/ugccomment/d1e7ba3a-c658-4267-a33f-6f95fe20638f.jpg'],
    'http://aos-cdn-image.amap.com/sns/ugccomment/d1e7ba3a-c658-4267-a33f-6f95fe20638f.jpg',
    ARRAY['公园', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '北京世园国际旅游度假区'
      AND COALESCE(address, '') = '延庆镇百康路1号'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['http://store.is.autonavi.com/showpic/a60146655ef6268af40ed15fb86047bd'],
    thumbnail_url = 'http://store.is.autonavi.com/showpic/a60146655ef6268af40ed15fb86047bd'
WHERE name = '奥林匹克森林公园北园'
      AND COALESCE(address, '') = '北京市奥运村街道科荟路33号'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
  );

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '奥林匹克森林公园北园',
    '奥林匹克森林公园北园，位于北京市北京市北京市奥运村街道科荟路33号。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.393173, 40.027647), 4326)::geography,
    1,
    4.20,
    0,
    '北京市奥运村街道科荟路33号',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY['http://store.is.autonavi.com/showpic/a60146655ef6268af40ed15fb86047bd'],
    'http://store.is.autonavi.com/showpic/a60146655ef6268af40ed15fb86047bd',
    ARRAY['国家级景点', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '奥林匹克森林公园北园'
      AND COALESCE(address, '') = '北京市奥运村街道科荟路33号'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['http://store.is.autonavi.com/showpic/fc66be0a421cd5315da50790a601c4e0'],
    thumbnail_url = 'http://store.is.autonavi.com/showpic/fc66be0a421cd5315da50790a601c4e0'
WHERE name = '世界公园'
      AND COALESCE(address, '') = '丰葆路158号(公园内)'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
  );

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '世界公园',
    '世界公园，位于北京市北京市丰葆路158号(公园内)。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.287794, 39.810604), 4326)::geography,
    1,
    4.20,
    0,
    '丰葆路158号(公园内)',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY['http://store.is.autonavi.com/showpic/fc66be0a421cd5315da50790a601c4e0'],
    'http://store.is.autonavi.com/showpic/fc66be0a421cd5315da50790a601c4e0',
    ARRAY['国家级景点', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '世界公园'
      AND COALESCE(address, '') = '丰葆路158号(公园内)'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['http://store.is.autonavi.com/showpic/c8050872cd6a071e46ab7973502266c6'],
    thumbnail_url = 'http://store.is.autonavi.com/showpic/c8050872cd6a071e46ab7973502266c6'
WHERE name = '千灵山'
      AND COALESCE(address, '') = '王佐镇西庄店村北'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
  );

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '千灵山',
    '千灵山，位于北京市北京市王佐镇西庄店村北。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.085523, 39.860994), 4326)::geography,
    1,
    4.20,
    0,
    '王佐镇西庄店村北',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY['http://store.is.autonavi.com/showpic/c8050872cd6a071e46ab7973502266c6'],
    'http://store.is.autonavi.com/showpic/c8050872cd6a071e46ab7973502266c6',
    ARRAY['风景名胜', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '千灵山'
      AND COALESCE(address, '') = '王佐镇西庄店村北'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['http://store.is.autonavi.com/showpic/97aabff20a5463450d6efb6f5228a2c2'],
    thumbnail_url = 'http://store.is.autonavi.com/showpic/97aabff20a5463450d6efb6f5228a2c2'
WHERE name = '太阳宫公园'
      AND COALESCE(address, '') = '太阳宫中路6号'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
  );

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '太阳宫公园',
    '太阳宫公园，位于北京市北京市太阳宫中路6号。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.454538, 39.976218), 4326)::geography,
    1,
    4.20,
    0,
    '太阳宫中路6号',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY['http://store.is.autonavi.com/showpic/97aabff20a5463450d6efb6f5228a2c2'],
    'http://store.is.autonavi.com/showpic/97aabff20a5463450d6efb6f5228a2c2',
    ARRAY['公园', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '太阳宫公园'
      AND COALESCE(address, '') = '太阳宫中路6号'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['http://store.is.autonavi.com/showpic/29de79aadb504c63a99ca0b1afd931b0'],
    thumbnail_url = 'http://store.is.autonavi.com/showpic/29de79aadb504c63a99ca0b1afd931b0'
WHERE name = '北京园博园'
      AND COALESCE(address, '') = '射击场路15号'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
  );

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '北京园博园',
    '北京园博园，位于北京市北京市射击场路15号。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.190595, 39.876665), 4326)::geography,
    1,
    4.20,
    0,
    '射击场路15号',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY['http://store.is.autonavi.com/showpic/29de79aadb504c63a99ca0b1afd931b0'],
    'http://store.is.autonavi.com/showpic/29de79aadb504c63a99ca0b1afd931b0',
    ARRAY['风景名胜', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '北京园博园'
      AND COALESCE(address, '') = '射击场路15号'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['http://store.is.autonavi.com/showpic/f0c223926d4b7c30159b2027c3e02ad3'],
    thumbnail_url = 'http://store.is.autonavi.com/showpic/f0c223926d4b7c30159b2027c3e02ad3'
WHERE name = '北京冬奥公园'
      AND COALESCE(address, '') = '河堤东路'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
  );

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '北京冬奥公园',
    '北京冬奥公园，位于北京市北京市河堤东路。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.156330, 39.901826), 4326)::geography,
    1,
    4.20,
    0,
    '河堤东路',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY['http://store.is.autonavi.com/showpic/f0c223926d4b7c30159b2027c3e02ad3'],
    'http://store.is.autonavi.com/showpic/f0c223926d4b7c30159b2027c3e02ad3',
    ARRAY['公园', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '北京冬奥公园'
      AND COALESCE(address, '') = '河堤东路'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['https://store.is.autonavi.com/showpic/f3e5159cde912fb10000002257112205?type=pic'],
    thumbnail_url = 'https://store.is.autonavi.com/showpic/f3e5159cde912fb10000002257112205?type=pic'
WHERE name = '南苑森林湿地公园'
      AND COALESCE(address, '') = '槐房路42号'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
  );

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '南苑森林湿地公园',
    '南苑森林湿地公园，位于北京市北京市槐房路42号。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.378504, 39.820418), 4326)::geography,
    1,
    4.20,
    0,
    '槐房路42号',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY['https://store.is.autonavi.com/showpic/f3e5159cde912fb10000002257112205?type=pic'],
    'https://store.is.autonavi.com/showpic/f3e5159cde912fb10000002257112205?type=pic',
    ARRAY['公园', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '南苑森林湿地公园'
      AND COALESCE(address, '') = '槐房路42号'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['http://store.is.autonavi.com/showpic/0fe459c6a0550eabd3867f0cac5a0c03'],
    thumbnail_url = 'http://store.is.autonavi.com/showpic/0fe459c6a0550eabd3867f0cac5a0c03'
WHERE name = '北宫国家森林公园'
      AND COALESCE(address, '') = '长辛店镇大灰厂东路55号'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
  );

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '北宫国家森林公园',
    '北宫国家森林公园，位于北京市北京市长辛店镇大灰厂东路55号。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.117756, 39.866114), 4326)::geography,
    1,
    4.20,
    0,
    '长辛店镇大灰厂东路55号',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY['http://store.is.autonavi.com/showpic/0fe459c6a0550eabd3867f0cac5a0c03'],
    'http://store.is.autonavi.com/showpic/0fe459c6a0550eabd3867f0cac5a0c03',
    ARRAY['国家级景点', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '北宫国家森林公园'
      AND COALESCE(address, '') = '长辛店镇大灰厂东路55号'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['https://store.is.autonavi.com/showpic/df2b1a8943bc34810000002352886525?type=pic'],
    thumbnail_url = 'https://store.is.autonavi.com/showpic/df2b1a8943bc34810000002352886525?type=pic'
WHERE name = '京华福满园'
      AND COALESCE(address, '') = '通运南路与滨河中路交叉口东北440米'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
  );

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '京华福满园',
    '京华福满园，位于北京市北京市通运南路与滨河中路交叉口东北440米。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.711186, 39.891014), 4326)::geography,
    1,
    4.20,
    0,
    '通运南路与滨河中路交叉口东北440米',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY['https://store.is.autonavi.com/showpic/df2b1a8943bc34810000002352886525?type=pic'],
    'https://store.is.autonavi.com/showpic/df2b1a8943bc34810000002352886525?type=pic',
    ARRAY['公园', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '京华福满园'
      AND COALESCE(address, '') = '通运南路与滨河中路交叉口东北440米'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['http://store.is.autonavi.com/showpic/f3e6600aedf04077c58b45297bb2fe58'],
    thumbnail_url = 'http://store.is.autonavi.com/showpic/f3e6600aedf04077c58b45297bb2fe58'
WHERE name = '将府公园'
      AND COALESCE(address, '') = '东八间房村临甲10号'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
  );

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '将府公园',
    '将府公园，位于北京市北京市东八间房村临甲10号。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.513514, 39.976547), 4326)::geography,
    1,
    4.20,
    0,
    '东八间房村临甲10号',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY['http://store.is.autonavi.com/showpic/f3e6600aedf04077c58b45297bb2fe58'],
    'http://store.is.autonavi.com/showpic/f3e6600aedf04077c58b45297bb2fe58',
    ARRAY['公园', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '将府公园'
      AND COALESCE(address, '') = '东八间房村临甲10号'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['http://store.is.autonavi.com/showpic/54bb8daf231c008cc8f144f632e74b7c'],
    thumbnail_url = 'http://store.is.autonavi.com/showpic/54bb8daf231c008cc8f144f632e74b7c'
WHERE name = '顺义奥林匹克水上公园'
      AND COALESCE(address, '') = '白马路19号'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
  );

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '顺义奥林匹克水上公园',
    '顺义奥林匹克水上公园，位于北京市北京市白马路19号。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.692730, 40.180524), 4326)::geography,
    1,
    4.20,
    0,
    '白马路19号',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY['http://store.is.autonavi.com/showpic/54bb8daf231c008cc8f144f632e74b7c'],
    'http://store.is.autonavi.com/showpic/54bb8daf231c008cc8f144f632e74b7c',
    ARRAY['国家级景点', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '顺义奥林匹克水上公园'
      AND COALESCE(address, '') = '白马路19号'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['http://store.is.autonavi.com/showpic/61c7176074d90f679189d2b78d3dc28a'],
    thumbnail_url = 'http://store.is.autonavi.com/showpic/61c7176074d90f679189d2b78d3dc28a'
WHERE name = '北京后花园(白虎涧)风景区'
      AND COALESCE(address, '') = '阳坊镇后二路'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
  );

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '北京后花园(白虎涧)风景区',
    '北京后花园(白虎涧)风景区，位于北京市北京市阳坊镇后二路。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.081721, 40.140530), 4326)::geography,
    1,
    4.20,
    0,
    '阳坊镇后二路',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY['http://store.is.autonavi.com/showpic/61c7176074d90f679189d2b78d3dc28a'],
    'http://store.is.autonavi.com/showpic/61c7176074d90f679189d2b78d3dc28a',
    ARRAY['风景名胜', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '北京后花园(白虎涧)风景区'
      AND COALESCE(address, '') = '阳坊镇后二路'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['http://store.is.autonavi.com/showpic/70778669dd39f0fc368d28973bb38a24'],
    thumbnail_url = 'http://store.is.autonavi.com/showpic/70778669dd39f0fc368d28973bb38a24'
WHERE name = '长阳公园'
      AND COALESCE(address, '') = '长阳镇长阳一村东'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
  );

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '长阳公园',
    '长阳公园，位于北京市北京市长阳镇长阳一村东。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.178962, 39.760097), 4326)::geography,
    1,
    4.20,
    0,
    '长阳镇长阳一村东',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY['http://store.is.autonavi.com/showpic/70778669dd39f0fc368d28973bb38a24'],
    'http://store.is.autonavi.com/showpic/70778669dd39f0fc368d28973bb38a24',
    ARRAY['公园', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '长阳公园'
      AND COALESCE(address, '') = '长阳镇长阳一村东'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['http://store.is.autonavi.com/showpic/a3c87d67a9ce3a14541c627e7e62fb78'],
    thumbnail_url = 'http://store.is.autonavi.com/showpic/a3c87d67a9ce3a14541c627e7e62fb78'
WHERE name = '野鸭湖国家湿地公园'
      AND COALESCE(address, '') = '康庄镇康野路5号刘浩营村西500米'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
  );

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '野鸭湖国家湿地公园',
    '野鸭湖国家湿地公园，位于北京市北京市康庄镇康野路5号刘浩营村西500米。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(115.846995, 40.413557), 4326)::geography,
    1,
    4.20,
    0,
    '康庄镇康野路5号刘浩营村西500米',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY['http://store.is.autonavi.com/showpic/a3c87d67a9ce3a14541c627e7e62fb78'],
    'http://store.is.autonavi.com/showpic/a3c87d67a9ce3a14541c627e7e62fb78',
    ARRAY['国家级景点', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '野鸭湖国家湿地公园'
      AND COALESCE(address, '') = '康庄镇康野路5号刘浩营村西500米'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['http://store.is.autonavi.com/showpic/fec09d164ecfe620f6ec8dc87d4535e4'],
    thumbnail_url = 'http://store.is.autonavi.com/showpic/fec09d164ecfe620f6ec8dc87d4535e4'
WHERE name = '绿堤公园'
      AND COALESCE(address, '') = '农场路4号'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
  );

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '绿堤公园',
    '绿堤公园，位于北京市北京市农场路4号。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.240841, 39.828166), 4326)::geography,
    1,
    4.20,
    0,
    '农场路4号',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY['http://store.is.autonavi.com/showpic/fec09d164ecfe620f6ec8dc87d4535e4'],
    'http://store.is.autonavi.com/showpic/fec09d164ecfe620f6ec8dc87d4535e4',
    ARRAY['公园', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '绿堤公园'
      AND COALESCE(address, '') = '农场路4号'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['http://store.is.autonavi.com/showpic/34597fc88bc3eae5c9c8312092b74782'],
    thumbnail_url = 'http://store.is.autonavi.com/showpic/34597fc88bc3eae5c9c8312092b74782'
WHERE name = '兴隆公园'
      AND COALESCE(address, '') = '高碑店乡兴隆庄甲8号(近高碑店地铁站)'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
  );

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '兴隆公园',
    '兴隆公园，位于北京市北京市高碑店乡兴隆庄甲8号(近高碑店地铁站)。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.533660, 39.912600), 4326)::geography,
    1,
    4.20,
    0,
    '高碑店乡兴隆庄甲8号(近高碑店地铁站)',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY['http://store.is.autonavi.com/showpic/34597fc88bc3eae5c9c8312092b74782'],
    'http://store.is.autonavi.com/showpic/34597fc88bc3eae5c9c8312092b74782',
    ARRAY['公园', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '兴隆公园'
      AND COALESCE(address, '') = '高碑店乡兴隆庄甲8号(近高碑店地铁站)'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['http://store.is.autonavi.com/showpic/a46329051524bb6499a3d0dbf7408a8d'],
    thumbnail_url = 'http://store.is.autonavi.com/showpic/a46329051524bb6499a3d0dbf7408a8d'
WHERE name = '北京十三陵国家森林公园蟒山景区'
      AND COALESCE(address, '') = '蟒山路4号'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
  );

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '北京十三陵国家森林公园蟒山景区',
    '北京十三陵国家森林公园蟒山景区，位于北京市北京市蟒山路4号。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.293539, 40.264324), 4326)::geography,
    1,
    4.20,
    0,
    '蟒山路4号',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY['http://store.is.autonavi.com/showpic/a46329051524bb6499a3d0dbf7408a8d'],
    'http://store.is.autonavi.com/showpic/a46329051524bb6499a3d0dbf7408a8d',
    ARRAY['省级景点', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '北京十三陵国家森林公园蟒山景区'
      AND COALESCE(address, '') = '蟒山路4号'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['http://store.is.autonavi.com/showpic/9a1e12867ec10b81909b161e2001f4b6'],
    thumbnail_url = 'http://store.is.autonavi.com/showpic/9a1e12867ec10b81909b161e2001f4b6'
WHERE name = '四得公园'
      AND COALESCE(address, '') = '将台西路9号(将台西地铁站A口步行140米)'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
  );

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '四得公园',
    '四得公园，位于北京市北京市将台西路9号(将台西地铁站A口步行140米)。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.474488, 39.972342), 4326)::geography,
    1,
    4.20,
    0,
    '将台西路9号(将台西地铁站A口步行140米)',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY['http://store.is.autonavi.com/showpic/9a1e12867ec10b81909b161e2001f4b6'],
    'http://store.is.autonavi.com/showpic/9a1e12867ec10b81909b161e2001f4b6',
    ARRAY['公园', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '四得公园'
      AND COALESCE(address, '') = '将台西路9号(将台西地铁站A口步行140米)'
      AND COALESCE(city, '') = '北京市'
);

UPDATE scenic_spots
SET images = ARRAY['http://store.is.autonavi.com/showpic/0b557e6bc2c88a47efd9a82b05427a04'],
    thumbnail_url = 'http://store.is.autonavi.com/showpic/0b557e6bc2c88a47efd9a82b05427a04'
WHERE name = '西海子公园'
      AND COALESCE(address, '') = '西海子西路12号'
      AND COALESCE(city, '') = '北京市'
  AND (
      COALESCE(thumbnail_url, '') = ''
      OR thumbnail_url LIKE '%example.com%'
      OR images IS NULL
      OR array_length(images, 1) IS NULL
      OR COALESCE(images[1], '') = ''
      OR images[1] LIKE '%example.com%'
  );

INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address, city,
     opening_hours, ticket_price, duration_minutes, crowd_level, images, thumbnail_url, tags, status)
SELECT
    '西海子公园',
    '西海子公园，位于北京市北京市西海子西路12号。数据来源：高德地图开放平台 POI。',
    ST_SetSRID(ST_MakePoint(116.665086, 39.916364), 4326)::geography,
    1,
    4.20,
    0,
    '西海子西路12号',
    '北京市',
    '以景区公告为准',
    0,
    90,
    2,
    ARRAY['http://store.is.autonavi.com/showpic/0b557e6bc2c88a47efd9a82b05427a04'],
    'http://store.is.autonavi.com/showpic/0b557e6bc2c88a47efd9a82b05427a04',
    ARRAY['公园', '北京市', '北京市'],
    1
WHERE NOT EXISTS (
    SELECT 1 FROM scenic_spots
    WHERE name = '西海子公园'
      AND COALESCE(address, '') = '西海子西路12号'
      AND COALESCE(city, '') = '北京市'
);

COMMIT;
