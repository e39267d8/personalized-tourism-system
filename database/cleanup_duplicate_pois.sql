SET client_encoding = 'UTF8';

-- 景点重复数据清理脚本。
-- 安全策略：
-- 1. 当前表没有 amap_id / poi_id，所以不按外部 POI id 去重；
-- 2. 不按 name 单独删除，避免误删不同城市或同城不同位置的同名景点；
-- 3. 只清理“同名 + 同城市 + 经纬度四位近似一致”的记录；
-- 4. 保留信息更完整的记录：有图片、有地址、有评分、有更多浏览/收藏的优先。
--
-- 建议执行前先运行：
--   psql -U postgres -d tourism_system -f database/audit_poi_duplicates.sql

BEGIN;

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

COMMIT;
