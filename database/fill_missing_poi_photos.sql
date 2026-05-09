SET client_encoding = 'UTF8';

-- 景点图片补全脚本。
-- 当前主表图片字段为：
--   thumbnail_url：主图
--   images TEXT[]：图片数组
-- 高德 photos 在导入脚本中已经被取第一张写入这两个字段；数据库中没有单独 photos/photo_url 字段。

BEGIN;

-- 先统一已有图片：有 images[1] 但缺 thumbnail_url，则 images[1] 作为主图。
UPDATE scenic_spots
SET thumbnail_url = images[1]
WHERE COALESCE(thumbnail_url, '') = ''
  AND images IS NOT NULL
  AND array_length(images, 1) > 0
  AND COALESCE(images[1], '') <> '';

-- 有 thumbnail_url 但缺 images，则同步到 images 数组。
UPDATE scenic_spots
SET images = ARRAY[thumbnail_url]
WHERE COALESCE(thumbnail_url, '') <> ''
  AND (images IS NULL OR array_length(images, 1) IS NULL OR COALESCE(images[1], '') = '');

-- 重要演示景点手工补图。
UPDATE scenic_spots
SET thumbnail_url = 'https://images.unsplash.com/photo-1508804185872-d7badad00f7d?auto=format&fit=crop&w=1200&q=80',
    images = ARRAY['https://images.unsplash.com/photo-1508804185872-d7badad00f7d?auto=format&fit=crop&w=1200&q=80']
WHERE name ILIKE '%故宫%'
  AND COALESCE(thumbnail_url, '') = '';

UPDATE scenic_spots
SET thumbnail_url = 'https://images.unsplash.com/photo-1547981609-4b6bfe67ca0b?auto=format&fit=crop&w=1200&q=80',
    images = ARRAY['https://images.unsplash.com/photo-1547981609-4b6bfe67ca0b?auto=format&fit=crop&w=1200&q=80']
WHERE name ILIKE '%天安门%'
  AND COALESCE(thumbnail_url, '') = '';

UPDATE scenic_spots
SET thumbnail_url = 'https://images.unsplash.com/photo-1566127992631-137a642a90f4?auto=format&fit=crop&w=1200&q=80',
    images = ARRAY['https://images.unsplash.com/photo-1566127992631-137a642a90f4?auto=format&fit=crop&w=1200&q=80']
WHERE (name ILIKE '%博物馆%' OR COALESCE(array_to_string(tags, ' '), '') ILIKE '%博物馆%')
  AND COALESCE(thumbnail_url, '') = '';

UPDATE scenic_spots
SET thumbnail_url = 'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?auto=format&fit=crop&w=1200&q=80',
    images = ARRAY['https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?auto=format&fit=crop&w=1200&q=80']
WHERE (name ILIKE '%公园%' OR COALESCE(array_to_string(tags, ' '), '') ILIKE '%公园%' OR COALESCE(array_to_string(tags, ' '), '') ILIKE '%自然%')
  AND COALESCE(thumbnail_url, '') = '';

UPDATE scenic_spots
SET thumbnail_url = 'https://images.unsplash.com/photo-1513415756790-2ac1db1297d0?auto=format&fit=crop&w=1200&q=80',
    images = ARRAY['https://images.unsplash.com/photo-1513415756790-2ac1db1297d0?auto=format&fit=crop&w=1200&q=80']
WHERE (COALESCE(array_to_string(tags, ' '), '') ILIKE '%历史%' OR COALESCE(array_to_string(tags, ' '), '') ILIKE '%古迹%' OR name ILIKE '%寺%' OR name ILIKE '%庙%')
  AND COALESCE(thumbnail_url, '') = '';

UPDATE scenic_spots
SET thumbnail_url = 'https://images.unsplash.com/photo-1519608487953-e999c86e7455?auto=format&fit=crop&w=1200&q=80',
    images = ARRAY['https://images.unsplash.com/photo-1519608487953-e999c86e7455?auto=format&fit=crop&w=1200&q=80']
WHERE (COALESCE(array_to_string(tags, ' '), '') ILIKE '%商业%' OR COALESCE(array_to_string(tags, ' '), '') ILIKE '%美食%' OR COALESCE(array_to_string(tags, ' '), '') ILIKE '%购物%' OR name ILIKE '%街%')
  AND COALESCE(thumbnail_url, '') = '';

UPDATE scenic_spots
SET thumbnail_url = 'https://images.unsplash.com/photo-1444723121867-7a241cacace9?auto=format&fit=crop&w=1200&q=80',
    images = ARRAY['https://images.unsplash.com/photo-1444723121867-7a241cacace9?auto=format&fit=crop&w=1200&q=80']
WHERE (COALESCE(array_to_string(tags, ' '), '') ILIKE '%地标%' OR name ILIKE '%广场%' OR name ILIKE '%塔%')
  AND COALESCE(thumbnail_url, '') = '';

-- 通用旅游图兜底，保证前端不再出现空图片。
UPDATE scenic_spots
SET thumbnail_url = 'https://images.unsplash.com/photo-1469854523086-cc02fe5d8800?auto=format&fit=crop&w=1200&q=80',
    images = ARRAY['https://images.unsplash.com/photo-1469854523086-cc02fe5d8800?auto=format&fit=crop&w=1200&q=80']
WHERE COALESCE(thumbnail_url, '') = ''
  AND (images IS NULL OR array_length(images, 1) IS NULL OR COALESCE(images[1], '') = '');

COMMIT;

SELECT
    COUNT(*) AS total_spots,
    COUNT(*) FILTER (
        WHERE COALESCE(thumbnail_url, '') = ''
          AND (images IS NULL OR array_length(images, 1) IS NULL OR COALESCE(images[1], '') = '')
    ) AS still_missing_image
FROM scenic_spots;
