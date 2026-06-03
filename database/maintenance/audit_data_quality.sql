SET client_encoding = 'UTF8';

-- 景点数据治理审计脚本：只查询，不修改数据。
-- 当前 schema 中没有 amap_id / poi_id / typecode 字段，因此重复判断使用：
-- 1) 同名 + 同城市 + 经纬度四位近似；
-- 2) 同名 + 同城市 + 100 米内近似；
-- 3) 同名 + 同城市的可疑重复列表，用于人工判断。

SELECT
    'scenic_spots columns' AS audit_item,
    column_name,
    data_type,
    udt_name
FROM information_schema.columns
WHERE table_name = 'scenic_spots'
  AND column_name IN (
      'id', 'name', 'address', 'city', 'location',
      'images', 'thumbnail_url', 'amap_id', 'poi_id',
      'type', 'typecode', 'longitude', 'latitude',
      'image_url', 'photo_url'
  )
ORDER BY column_name;

SELECT
    'exact_coordinate_duplicate' AS duplicate_type,
    lower(trim(name)) AS normalized_name,
    COALESCE(city, '') AS city,
    round(ST_X(location::geometry)::numeric, 4) AS longitude_approx,
    round(ST_Y(location::geometry)::numeric, 4) AS latitude_approx,
    COUNT(*) AS duplicate_count,
    array_agg(id ORDER BY id) AS ids,
    array_agg(name ORDER BY id) AS names,
    array_agg(address ORDER BY id) AS addresses
FROM scenic_spots
GROUP BY
    lower(trim(name)),
    COALESCE(city, ''),
    round(ST_X(location::geometry)::numeric, 4),
    round(ST_Y(location::geometry)::numeric, 4)
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC, normalized_name;

SELECT
    'nearby_name_duplicate' AS duplicate_type,
    a.id AS id_a,
    b.id AS id_b,
    a.name,
    COALESCE(a.city, '') AS city,
    a.address AS address_a,
    b.address AS address_b,
    round(ST_Distance(a.location, b.location)::numeric, 1) AS distance_meters,
    COALESCE(a.thumbnail_url, a.images[1], '') AS image_a,
    COALESCE(b.thumbnail_url, b.images[1], '') AS image_b
FROM scenic_spots a
JOIN scenic_spots b
  ON a.id < b.id
 AND lower(trim(a.name)) = lower(trim(b.name))
 AND COALESCE(a.city, '') = COALESCE(b.city, '')
 AND ST_DWithin(a.location, b.location, 100)
ORDER BY distance_meters, a.name
LIMIT 200;

SELECT
    'same_name_city_suspicious' AS duplicate_type,
    lower(trim(name)) AS normalized_name,
    COALESCE(city, '') AS city,
    COUNT(*) AS count_in_city,
    array_agg(id ORDER BY id) AS ids,
    array_agg(name ORDER BY id) AS names,
    array_agg(address ORDER BY id) AS addresses
FROM scenic_spots
GROUP BY lower(trim(name)), COALESCE(city, '')
HAVING COUNT(*) > 1
ORDER BY count_in_city DESC, normalized_name
LIMIT 200;

SELECT
    COUNT(*) AS total_spots,
    COUNT(*) FILTER (
        WHERE COALESCE(thumbnail_url, '') <> ''
           OR (images IS NOT NULL AND array_length(images, 1) > 0 AND COALESCE(images[1], '') <> '')
    ) AS spots_with_image,
    COUNT(*) FILTER (
        WHERE COALESCE(thumbnail_url, '') = ''
          AND (images IS NULL OR array_length(images, 1) IS NULL OR COALESCE(images[1], '') = '')
    ) AS spots_missing_image
FROM scenic_spots;

SELECT
    'category_distribution' AS audit_item,
    COALESCE(c.name, '未分类') AS category,
    COUNT(*) AS spot_count
FROM scenic_spots s
LEFT JOIN categories c ON c.id = s.category_id
WHERE s.status = 1
GROUP BY COALESCE(c.name, '未分类')
ORDER BY spot_count DESC, category;

SELECT
    'local_public_image_usage' AS audit_item,
    id,
    name,
    city,
    address,
    thumbnail_url
FROM scenic_spots
WHERE COALESCE(thumbnail_url, '') LIKE '/images/diary/%'
ORDER BY city, name, id
LIMIT 200;

SELECT
    id,
    name,
    city,
    address,
    COALESCE(array_to_string(tags, ','), '') AS tags
FROM scenic_spots
WHERE COALESCE(thumbnail_url, '') = ''
  AND (images IS NULL OR array_length(images, 1) IS NULL OR COALESCE(images[1], '') = '')
ORDER BY id
LIMIT 100;
