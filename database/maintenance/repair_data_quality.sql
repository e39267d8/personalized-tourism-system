SET client_encoding = 'UTF8';

-- 数据质量修复脚本：会修改数据，执行前建议先运行 audit_data_quality.sql。
-- 包含：坐标近似重复清理、子 POI 变体合并、图片字段同步、本地 public 图片补全。

BEGIN;

-- 1. 坐标近似重复清理。
-- 景点重复数据清理脚本。
-- 安全策略：
-- 1. 当前表没有 amap_id / poi_id，所以不按外部 POI id 去重；
-- 2. 不按 name 单独删除，避免误删不同城市或同城不同位置的同名景点；
-- 3. 只清理“同名 + 同城市 + 经纬度四位近似一致”的记录；
-- 4. 保留信息更完整的记录：有图片、有地址、有评分、有更多浏览/收藏的优先。
--
-- 建议执行前先运行：
--   psql -U postgres -d tourism_system -f database/maintenance/audit_data_quality.sql


CREATE TEMP TABLE tmp_duplicate_poi_map ON COMMIT DROP AS
WITH duplicate_candidates AS (
    SELECT
        id,
        FIRST_VALUE(id) OVER (
            PARTITION BY
                lower(trim(name)),
                COALESCE(city, ''),
                round(ST_X(location::geometry)::numeric, 4),
                round(ST_Y(location::geometry)::numeric, 4)
            ORDER BY
                CASE
                    WHEN COALESCE(thumbnail_url, '') <> ''
                      OR (images IS NOT NULL AND array_length(images, 1) > 0 AND COALESCE(images[1], '') <> '')
                    THEN 1 ELSE 0
                END DESC,
                CASE WHEN COALESCE(address, '') <> '' THEN 1 ELSE 0 END DESC,
                COALESCE(rating, 0) DESC,
                COALESCE(rating_count, 0) DESC,
                COALESCE(view_count, 0) DESC,
                COALESCE(favorite_count, 0) DESC,
                id ASC
        ) AS keep_id,
        ROW_NUMBER() OVER (
            PARTITION BY
                lower(trim(name)),
                COALESCE(city, ''),
                round(ST_X(location::geometry)::numeric, 4),
                round(ST_Y(location::geometry)::numeric, 4)
            ORDER BY
                CASE
                    WHEN COALESCE(thumbnail_url, '') <> ''
                      OR (images IS NOT NULL AND array_length(images, 1) > 0 AND COALESCE(images[1], '') <> '')
                    THEN 1 ELSE 0
                END DESC,
                CASE WHEN COALESCE(address, '') <> '' THEN 1 ELSE 0 END DESC,
                COALESCE(rating, 0) DESC,
                COALESCE(rating_count, 0) DESC,
                COALESCE(view_count, 0) DESC,
                COALESCE(favorite_count, 0) DESC,
                id ASC
        ) AS keep_rank
    FROM scenic_spots
)
SELECT keep_id, id AS duplicate_id
FROM duplicate_candidates
WHERE keep_rank > 1;

-- 如果收藏表中同一用户已经收藏了保留记录，则先删除重复收藏，避免唯一约束冲突。
DELETE FROM user_favorites uf
USING tmp_duplicate_poi_map m
WHERE uf.scenic_spot_id = m.duplicate_id
  AND EXISTS (
      SELECT 1
      FROM user_favorites kept
      WHERE kept.user_id = uf.user_id
        AND kept.scenic_spot_id = m.keep_id
  );

-- 合并依赖关系，尽量保留评论、收藏和图节点引用。
UPDATE user_favorites uf
SET scenic_spot_id = m.keep_id
FROM tmp_duplicate_poi_map m
WHERE uf.scenic_spot_id = m.duplicate_id;

UPDATE graph_nodes gn
SET scenic_spot_id = m.keep_id
FROM tmp_duplicate_poi_map m
WHERE gn.scenic_spot_id = m.duplicate_id;

UPDATE reviews r
SET scenic_spot_id = m.keep_id
FROM tmp_duplicate_poi_map m
WHERE r.scenic_spot_id = m.duplicate_id;

WITH deleted_rows AS (
    DELETE FROM scenic_spots s
    USING tmp_duplicate_poi_map m
    WHERE s.id = m.duplicate_id
    RETURNING s.id, s.name, s.city, s.address
)
SELECT * FROM deleted_rows ORDER BY id;

-- 清理后增加保守唯一索引，防止之后再次插入“同名 + 同城 + 经纬度近似一致”的重复记录。
-- 如果未来新增 amap_id / poi_id，建议改为优先对外部 POI id 建唯一索引。
CREATE UNIQUE INDEX IF NOT EXISTS uq_scenic_spots_name_city_location4
ON scenic_spots (
    lower(trim(name)),
    COALESCE(city, ''),
    round(ST_X(location::geometry)::numeric, 4),
    round(ST_Y(location::geometry)::numeric, 4)
);

-- 2. 子 POI 变体合并。
-- 主景点-子 POI 归并脚本。
-- 解决类似：
--   故宫博物院
--   故宫博物院-午门
--   故宫博物院-神武门
-- 这类高德子点位在搜索结果中重复出现的问题。
--
-- 规则：
-- 1. 城市归一化：北京 与 北京市 视为同一城市；
-- 2. 名称归一化：去掉 '-' / '－' / '—' / '–' 后面的子点位后缀；
-- 3. 只有当“主景点名”本身存在时，才删除子 POI，避免误删没有主记录的真实景点；
-- 4. 删除前合并收藏、评论、图节点引用。


CREATE TEMP TABLE tmp_poi_variant_map ON COMMIT DROP AS
WITH normalized AS (
    SELECT
        id,
        name,
        city,
        regexp_replace(COALESCE(city, ''), '市$', '') AS normalized_city,
        lower(trim(regexp_replace(name, '[-－—–].*$', ''))) AS base_name,
        lower(trim(name)) AS normalized_name,
        CASE
            WHEN COALESCE(thumbnail_url, '') <> ''
              OR (images IS NOT NULL AND array_length(images, 1) > 0 AND COALESCE(images[1], '') <> '')
            THEN 1 ELSE 0
        END AS has_image_score,
        CASE WHEN COALESCE(address, '') <> '' THEN 1 ELSE 0 END AS has_address_score,
        COALESCE(rating, 0) AS rating_score,
        COALESCE(rating_count, 0) AS rating_count_score,
        COALESCE(view_count, 0) AS view_count_score,
        COALESCE(favorite_count, 0) AS favorite_count_score
    FROM scenic_spots
),
groups_with_parent AS (
    SELECT DISTINCT base_name, normalized_city
    FROM normalized
    WHERE normalized_name = base_name
),
ranked AS (
    SELECT
        n.*,
        FIRST_VALUE(n.id) OVER (
            PARTITION BY n.base_name, n.normalized_city
            ORDER BY
                CASE WHEN n.normalized_name = n.base_name THEN 1 ELSE 0 END DESC,
                n.has_image_score DESC,
                n.has_address_score DESC,
                n.rating_score DESC,
                n.rating_count_score DESC,
                n.view_count_score DESC,
                n.favorite_count_score DESC,
                n.id ASC
        ) AS keep_id,
        ROW_NUMBER() OVER (
            PARTITION BY n.base_name, n.normalized_city
            ORDER BY
                CASE WHEN n.normalized_name = n.base_name THEN 1 ELSE 0 END DESC,
                n.has_image_score DESC,
                n.has_address_score DESC,
                n.rating_score DESC,
                n.rating_count_score DESC,
                n.view_count_score DESC,
                n.favorite_count_score DESC,
                n.id ASC
        ) AS keep_rank
    FROM normalized n
    JOIN groups_with_parent g
      ON g.base_name = n.base_name
     AND g.normalized_city = n.normalized_city
)
SELECT keep_id, id AS duplicate_id
FROM ranked
WHERE keep_rank > 1;

DELETE FROM user_favorites uf
USING tmp_poi_variant_map m
WHERE uf.scenic_spot_id = m.duplicate_id
  AND EXISTS (
      SELECT 1
      FROM user_favorites kept
      WHERE kept.user_id = uf.user_id
        AND kept.scenic_spot_id = m.keep_id
  );

UPDATE user_favorites uf
SET scenic_spot_id = m.keep_id
FROM tmp_poi_variant_map m
WHERE uf.scenic_spot_id = m.duplicate_id;

UPDATE graph_nodes gn
SET scenic_spot_id = m.keep_id
FROM tmp_poi_variant_map m
WHERE gn.scenic_spot_id = m.duplicate_id;

UPDATE reviews r
SET scenic_spot_id = m.keep_id
FROM tmp_poi_variant_map m
WHERE r.scenic_spot_id = m.duplicate_id;

WITH deleted_rows AS (
    DELETE FROM scenic_spots s
    USING tmp_poi_variant_map m
    WHERE s.id = m.duplicate_id
    RETURNING s.id, s.name, s.city, s.address
)
SELECT * FROM deleted_rows ORDER BY id;

-- 3. 图片字段同步与本地 public 图片补全。
-- 统一图片字段：有 images[1] 但缺主图时，用 images[1] 作为 thumbnail_url。
UPDATE scenic_spots
SET thumbnail_url = images[1]
WHERE COALESCE(thumbnail_url, '') = ''
  AND images IS NOT NULL
  AND array_length(images, 1) > 0
  AND COALESCE(images[1], '') <> '';

-- 统一图片字段：有 thumbnail_url 但缺 images 时，同步到 images 数组。
UPDATE scenic_spots
SET images = ARRAY[thumbnail_url]
WHERE COALESCE(thumbnail_url, '') <> ''
  AND (images IS NULL OR array_length(images, 1) IS NULL OR COALESCE(images[1], '') = '');

-- 使用 frontend/public/images/diary 下的本地图片修正重点景点。
-- 注意：只按景点名称匹配，不按 description 匹配，避免“天安门描述里提到故宫”导致串图。
CREATE TEMP TABLE tmp_verified_spot_images (
    image_key TEXT PRIMARY KEY,
    city_names TEXT[] NOT NULL,
    aliases TEXT[] NOT NULL,
    image_urls TEXT[] NOT NULL
) ON COMMIT DROP;

INSERT INTO tmp_verified_spot_images (image_key, city_names, aliases, image_urls)
VALUES
    ('tiananmen', ARRAY['北京', '北京市']::TEXT[], ARRAY['天安门广场', '天安门', '天安门-城楼', '天安门广场-国旗']::TEXT[], ARRAY['http://aos-cdn-image.amap.com/sns/ugccomment/fab72424-5643-4c14-9486-ae1c8475eab7.jpg']::TEXT[]),
    ('gugong', ARRAY['北京', '北京市']::TEXT[], ARRAY['故宫博物院', '故宫', '紫禁城']::TEXT[], ARRAY['/images/diary/gugong_0.jpg', '/images/diary/gugong_1.jpg', '/images/diary/gugong_2.jpg', '/images/diary/gugong_3.jpg', '/images/diary/gugong_4.jpg']::TEXT[]),
    ('jingshangongyuan', ARRAY['北京', '北京市']::TEXT[], ARRAY['景山公园', '景山']::TEXT[], ARRAY['/images/diary/jingshangongyuan_0.jpg']::TEXT[]),
    ('beihaigongyuan', ARRAY['北京', '北京市']::TEXT[], ARRAY['北海公园']::TEXT[], ARRAY['/images/diary/beihaigongyuan_0.jpeg', '/images/diary/beihaigongyuan_1.jpeg', '/images/diary/beihaigongyuan_2.jpeg', '/images/diary/beihaigongyuan_3.jpg', '/images/diary/beihaigongyuan_4.jpeg']::TEXT[]),
    ('guojiabowuguan', ARRAY['北京', '北京市']::TEXT[], ARRAY['中国国家博物馆', '国家博物馆']::TEXT[], ARRAY['/images/diary/guojiabowuguan_0.jpeg', '/images/diary/guojiabowuguan_1.jpeg', '/images/diary/guojiabowuguan_2.jpeg', '/images/diary/guojiabowuguan_3.jpeg', '/images/diary/guojiabowuguan_4.jpeg', '/images/diary/guojiabowuguan_5.jpeg', '/images/diary/guojiabowuguan_6.png', '/images/diary/guojiabowuguan_7.jpeg']::TEXT[]),
    ('qianmen', ARRAY['北京', '北京市']::TEXT[], ARRAY['前门大街', '前门', '正阳门', '正阳门城楼', '正阳门箭楼']::TEXT[], ARRAY['/images/diary/qianmen_0.jpg', '/images/diary/qianmen_1.jpg']::TEXT[]),
    ('wangfujing', ARRAY['北京', '北京市']::TEXT[], ARRAY['王府井步行街', '王府井']::TEXT[], ARRAY['/images/diary/wangfujing_0.jpg', '/images/diary/wangfujing_1.jpg', '/images/diary/wangfujing_2.jpg', '/images/diary/wangfujing_3.jpg', '/images/diary/wangfujing_4.jpg', '/images/diary/wangfujing_5.jpg']::TEXT[]),
    ('gulou', ARRAY['北京', '北京市']::TEXT[], ARRAY['鼓楼', '钟楼']::TEXT[], ARRAY['/images/diary/gulou_0.jpeg', '/images/diary/gulou_1.jpeg', '/images/diary/gulou_2.jpeg', '/images/diary/gulou_3.jpeg', '/images/diary/gulou_4.jpeg', '/images/diary/gulou_5.jpeg', '/images/diary/gulou_6.jpeg']::TEXT[]),
    ('shichahai', ARRAY['北京', '北京市']::TEXT[], ARRAY['什刹海', '后海']::TEXT[], ARRAY['/images/diary/shichahai_0.jpg', '/images/diary/shichahai_1.jpeg', '/images/diary/shichahai_2.jpg', '/images/diary/shichahai_3.jpg', '/images/diary/shichahai_4.jpg', '/images/diary/shichahai_5.jpg', '/images/diary/shichahai_6.jpg', '/images/diary/shichahai_7.jpg', '/images/diary/shichahai_8.jpg']::TEXT[]),
    ('nanluoguxiang', ARRAY['北京', '北京市']::TEXT[], ARRAY['南锣鼓巷']::TEXT[], ARRAY['/images/diary/nanluoguxiang_0.jpg', '/images/diary/nanluoguxiang_1.jpg', '/images/diary/nanluoguxiang_2.jpg', '/images/diary/nanluoguxiang_3.jpg', '/images/diary/nanluoguxiang_4.jpg', '/images/diary/nanluoguxiang_5.jpg', '/images/diary/nanluoguxiang_6.png']::TEXT[]),
    ('tiantan', ARRAY['北京', '北京市']::TEXT[], ARRAY['天坛公园', '天坛', '祈年殿']::TEXT[], ARRAY['/images/diary/tiantan_0.jpg', '/images/diary/tiantan_1.jpg', '/images/diary/tiantan_2.jpg', '/images/diary/tiantan_3.jpg']::TEXT[]),
    ('yiheyuan', ARRAY['北京', '北京市']::TEXT[], ARRAY['颐和园']::TEXT[], ARRAY['/images/diary/yiheyuan_0.jpg', '/images/diary/yiheyuan_1.jpg', '/images/diary/yiheyuan_2.jpg']::TEXT[]),
    ('yuanmingyuan', ARRAY['北京', '北京市']::TEXT[], ARRAY['圆明园遗址公园', '圆明园']::TEXT[], ARRAY['/images/diary/yuanmingyuan_0.jpg', '/images/diary/yuanmingyuan_1.jpg', '/images/diary/yuanmingyuan_2.jpg', '/images/diary/yuanmingyuan_3.jpg']::TEXT[]),
    ('yonghegong', ARRAY['北京', '北京市']::TEXT[], ARRAY['雍和宫']::TEXT[], ARRAY['/images/diary/yonghegong_0.jpeg', '/images/diary/yonghegong_1.jpeg', '/images/diary/yonghegong_2.jpeg', '/images/diary/yonghegong_3.jpeg', '/images/diary/yonghegong_4.jpeg', '/images/diary/yonghegong_5.jpg', '/images/diary/yonghegong_6.jpg']::TEXT[]),
    ('aosen', ARRAY['北京', '北京市']::TEXT[], ARRAY['奥林匹克森林公园', '北京奥林匹克公园']::TEXT[], ARRAY['/images/diary/aosen_0.jpeg', '/images/diary/aosen_1.jpg', '/images/diary/aosen_2.jpg', '/images/diary/aosen_3.jpeg', '/images/diary/aosen_4.jpg', '/images/diary/aosen_5.jpeg', '/images/diary/aosen_6.jpeg', '/images/diary/aosen_7.jpeg']::TEXT[]),
    ('changcheng', ARRAY['北京', '北京市']::TEXT[], ARRAY['八达岭长城', '慕田峪长城', '长城']::TEXT[], ARRAY['/images/diary/changcheng_0.jpg', '/images/diary/changcheng_1.jpg', '/images/diary/changcheng_2.jpg', '/images/diary/changcheng_3.jpg']::TEXT[]),
    ('sanlitun', ARRAY['北京', '北京市']::TEXT[], ARRAY['三里屯']::TEXT[], ARRAY['/images/diary/sanlitun_0.jpeg', '/images/diary/sanlitun_1.jpeg', '/images/diary/sanlitun_2.jpeg', '/images/diary/sanlitun_3.jpeg', '/images/diary/sanlitun_4.jpeg', '/images/diary/sanlitun_5.jpeg', '/images/diary/sanlitun_6.jpg']::TEXT[]),
    ('gongti', ARRAY['北京', '北京市']::TEXT[], ARRAY['工人体育场', '工体']::TEXT[], ARRAY['/images/diary/gongti_0.png', '/images/diary/gongti_1.jpg', '/images/diary/gongti_2.jpg', '/images/diary/gongti_3.jpg', '/images/diary/gongti_4.jpg']::TEXT[]),
    ('798', ARRAY['北京', '北京市']::TEXT[], ARRAY['798艺术区', '七九八']::TEXT[], ARRAY['/images/diary/798_0.jpg', '/images/diary/798_1.jpeg', '/images/diary/798_2.jpeg', '/images/diary/798_3.jpeg', '/images/diary/798_4.jpeg', '/images/diary/798_5.jpeg', '/images/diary/798_6.jpeg', '/images/diary/798_7.jpeg']::TEXT[]);

CREATE TEMP TABLE tmp_verified_spot_image_matches ON COMMIT DROP AS
SELECT DISTINCT s.id, m.image_key, m.image_urls
FROM scenic_spots s
JOIN tmp_verified_spot_images m
  ON COALESCE(s.city, '') = ANY(m.city_names)
 AND EXISTS (
      SELECT 1
      FROM unnest(m.aliases) AS alias_item(alias_name)
      WHERE s.name = alias_item.alias_name
         OR s.name ILIKE alias_item.alias_name || '-%'
         OR s.name ILIKE alias_item.alias_name || '·%'
         OR s.name ILIKE alias_item.alias_name || '(%'
         OR s.name ILIKE alias_item.alias_name || '（%'
  );

-- 先清掉历史脚本按描述或宽泛关键词误写的本地图片，避免继续显示串图。
UPDATE scenic_spots s
SET images = ARRAY[]::TEXT[],
    thumbnail_url = ''
WHERE (
        COALESCE(s.thumbnail_url, '') LIKE '/images/diary/%'
        OR EXISTS (
            SELECT 1
            FROM unnest(COALESCE(s.images, ARRAY[]::TEXT[])) AS image_item(image_url)
            WHERE image_item.image_url LIKE '/images/diary/%'
        )
      )
  AND NOT EXISTS (
      SELECT 1
      FROM tmp_verified_spot_image_matches matched
      WHERE matched.id = s.id
  );

-- 对确定能对应上的重点景点，写入可信主图。这里允许覆盖旧图，用于修复已经落库的错图。
UPDATE scenic_spots s
SET images = matched.image_urls,
    thumbnail_url = matched.image_urls[1]
FROM tmp_verified_spot_image_matches matched
WHERE matched.id = s.id;

-- 再同步一次图片字段，保证列表页和详情页读取到同一套图片。
UPDATE scenic_spots
SET thumbnail_url = images[1]
WHERE COALESCE(thumbnail_url, '') = ''
  AND images IS NOT NULL
  AND array_length(images, 1) > 0
  AND COALESCE(images[1], '') <> '';

UPDATE scenic_spots
SET images = ARRAY[thumbnail_url]
WHERE COALESCE(thumbnail_url, '') <> ''
  AND (images IS NULL OR array_length(images, 1) IS NULL OR COALESCE(images[1], '') = '');

-- 4. 景点主分类回填，修复高德导入数据长期停留在通用分类的问题。
INSERT INTO categories (id, name, description, icon, parent_id, sort_order)
VALUES
    (1, '旅游景点', '高德 POI 导入时使用的通用景点分类', 'map-pin', NULL, 1),
    (2, '历史古迹', '历史文化遗产与古建筑', 'landmark', NULL, 2),
    (3, '博物馆', '展览、文博与公共文化空间', 'museum', NULL, 3),
    (4, '城市公园', '休闲散步和自然景观', 'trees', NULL, 4),
    (5, '商业街区', '购物、美食与夜游区域', 'shopping-bag', NULL, 5),
    (6, '观景摄影', '适合拍照与城市观景的地点', 'camera', NULL, 6),
    (7, '城市地标', '城市广场、地标建筑与公共空间', 'building-2', NULL, 7)
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    description = EXCLUDED.description,
    icon = EXCLUDED.icon,
    sort_order = EXCLUDED.sort_order;

WITH category_rules(category_id, priority, keywords) AS (
    VALUES
        (3, 10, ARRAY['博物馆','纪念馆','展览','美术馆','科技馆','文化馆']::TEXT[]),
        (7, 20, ARRAY['广场','地标','城楼','电视塔','体育场','中心']::TEXT[]),
        (5, 30, ARRAY['商业','购物','步行街','美食','小吃','夜市','酒吧','餐厅','工体','三里屯','王府井','前门']::TEXT[]),
        (4, 40, ARRAY['公园','森林','湿地','湖','山','自然','园林','植物园','动物园','颐和园','圆明园','北海']::TEXT[]),
        (2, 50, ARRAY['历史','古迹','古建','遗址','故宫','长城','寺','庙','宫','塔','陵','文化遗产','天坛','雍和宫']::TEXT[]),
        (6, 60, ARRAY['摄影','观景','打卡','日落','夜景','俯瞰']::TEXT[])
),
matched_categories AS (
    SELECT DISTINCT ON (s.id)
        s.id,
        r.category_id
    FROM scenic_spots s
    JOIN category_rules r ON EXISTS (
        SELECT 1
        FROM unnest(r.keywords) AS keyword(value)
        WHERE COALESCE(s.name, '') ILIKE '%' || keyword.value || '%'
           OR COALESCE(s.description, '') ILIKE '%' || keyword.value || '%'
           OR COALESCE(array_to_string(s.tags, ' '), '') ILIKE '%' || keyword.value || '%'
    )
    WHERE s.status = 1
      AND (s.category_id IS NULL OR s.category_id = 1)
    ORDER BY s.id, r.priority
)
UPDATE scenic_spots s
SET category_id = matched.category_id
FROM matched_categories matched
WHERE s.id = matched.id;

COMMIT;
