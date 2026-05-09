SET client_encoding = 'UTF8';

-- 更激进的同名同城清理脚本。
-- 使用场景：你确认“同名 + 同城市”的 POI 在本项目里只想保留一条。
-- 风险：可能误删同城不同位置但同名的真实景点，例如不同区的“人民公园”。
-- 保留规则：有图片、有地址、评分/热度更高、id 更小的记录优先保留。
--
-- 建议先运行：
--   psql -U postgres -d tourism_system -c "SELECT lower(trim(name)), city, COUNT(*), array_agg(id ORDER BY id), array_agg(address ORDER BY id) FROM scenic_spots GROUP BY lower(trim(name)), city HAVING COUNT(*) > 1;"

BEGIN;

CREATE TEMP TABLE tmp_same_name_city_duplicate_map ON COMMIT DROP AS
WITH ranked AS (
    SELECT
        id,
        FIRST_VALUE(id) OVER (
            PARTITION BY lower(trim(name)), COALESCE(city, '')
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
            PARTITION BY lower(trim(name)), COALESCE(city, '')
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
FROM ranked
WHERE keep_rank > 1;

DELETE FROM user_favorites uf
USING tmp_same_name_city_duplicate_map m
WHERE uf.scenic_spot_id = m.duplicate_id
  AND EXISTS (
      SELECT 1
      FROM user_favorites kept
      WHERE kept.user_id = uf.user_id
        AND kept.scenic_spot_id = m.keep_id
  );

UPDATE user_favorites uf
SET scenic_spot_id = m.keep_id
FROM tmp_same_name_city_duplicate_map m
WHERE uf.scenic_spot_id = m.duplicate_id;

UPDATE graph_nodes gn
SET scenic_spot_id = m.keep_id
FROM tmp_same_name_city_duplicate_map m
WHERE gn.scenic_spot_id = m.duplicate_id;

UPDATE reviews r
SET scenic_spot_id = m.keep_id
FROM tmp_same_name_city_duplicate_map m
WHERE r.scenic_spot_id = m.duplicate_id;

WITH deleted_rows AS (
    DELETE FROM scenic_spots s
    USING tmp_same_name_city_duplicate_map m
    WHERE s.id = m.duplicate_id
    RETURNING s.id, s.name, s.city, s.address
)
SELECT * FROM deleted_rows ORDER BY id;

CREATE UNIQUE INDEX IF NOT EXISTS uq_scenic_spots_name_city
ON scenic_spots (lower(trim(name)), COALESCE(city, ''));

COMMIT;
