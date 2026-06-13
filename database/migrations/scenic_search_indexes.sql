-- 景点/学校查询与排序索引优化
-- 只补查询性能相关扩展和索引，不改变业务表结构；可重复执行。

BEGIN;

CREATE EXTENSION IF NOT EXISTS pg_trgm;

CREATE INDEX IF NOT EXISTS idx_scenic_spots_name_trgm
    ON scenic_spots USING GIN ((lower(name)) gin_trgm_ops);

CREATE INDEX IF NOT EXISTS idx_scenic_spots_description_trgm
    ON scenic_spots USING GIN ((lower(COALESCE(description, ''))) gin_trgm_ops);

CREATE INDEX IF NOT EXISTS idx_categories_name_trgm
    ON categories USING GIN ((lower(name)) gin_trgm_ops);

CREATE INDEX IF NOT EXISTS idx_scenic_spots_status_rating_sort
    ON scenic_spots (status, rating DESC, view_count DESC, id);

CREATE INDEX IF NOT EXISTS idx_scenic_spots_status_hot_sort
    ON scenic_spots (status, view_count DESC, favorite_count DESC, rating DESC, id);

CREATE INDEX IF NOT EXISTS idx_scenic_spots_status_category_ticket
    ON scenic_spots (status, category_id, ticket_price, rating DESC, id);

COMMIT;
