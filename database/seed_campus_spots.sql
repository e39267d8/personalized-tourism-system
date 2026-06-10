SET client_encoding = 'UTF8';

BEGIN;

INSERT INTO categories
    (id, name, description, icon, parent_id, sort_order)
VALUES
    (8, '高校校园', '高校主校园与校园漫步场景', 'graduation-cap', NULL, 8)
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    description = EXCLUDED.description,
    icon = EXCLUDED.icon,
    parent_id = EXCLUDED.parent_id,
    sort_order = EXCLUDED.sort_order;

WITH target AS (
    SELECT
        '北京大学'::text AS name,
        '北京大学主校园，位于北京市海淀区颐和园路5号。数据来源：人工整理校园主对象，用于校园内部导航。'::text AS description,
        ST_SetSRID(ST_MakePoint(116.3103, 39.9928), 4326)::geography AS location,
        8::integer AS category_id,
        '颐和园路5号'::text AS address,
        '北京市'::text AS city,
        '校园开放时间以学校管理规定为准'::text AS opening_hours,
        0::numeric AS ticket_price,
        180::integer AS duration_minutes,
        2::smallint AS crowd_level,
        ARRAY['校园','高校','citywalk','历史文化']::text[] AS tags
),
existing AS (
    SELECT s.id
    FROM scenic_spots s
    CROSS JOIN target t
    WHERE s.name = t.name
      AND COALESCE(s.city, '') = t.city
    ORDER BY ST_Distance(s.location, t.location), s.id
    LIMIT 1
),
updated AS (
    UPDATE scenic_spots s
    SET
        description = t.description,
        location = t.location,
        category_id = t.category_id,
        address = t.address,
        city = t.city,
        opening_hours = t.opening_hours,
        ticket_price = t.ticket_price,
        duration_minutes = t.duration_minutes,
        crowd_level = t.crowd_level,
        tags = t.tags,
        status = 1
    FROM target t
    WHERE s.id IN (SELECT id FROM existing)
    RETURNING s.id
)
INSERT INTO scenic_spots
    (name, description, location, category_id, rating, rating_count, address,
     city, opening_hours, ticket_price, duration_minutes, crowd_level, images,
     thumbnail_url, view_count, favorite_count, tags, status)
SELECT
    t.name,
    t.description,
    t.location,
    t.category_id,
    0,
    0,
    t.address,
    t.city,
    t.opening_hours,
    t.ticket_price,
    t.duration_minutes,
    t.crowd_level,
    ARRAY[]::text[],
    '',
    0,
    0,
    t.tags,
    1
FROM target t
WHERE NOT EXISTS (SELECT 1 FROM updated);

COMMIT;
