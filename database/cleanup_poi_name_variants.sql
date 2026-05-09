SET client_encoding = 'UTF8';

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

BEGIN;

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

COMMIT;
