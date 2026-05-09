SET client_encoding = 'UTF8';

BEGIN;

ALTER TABLE scenic_spots ADD COLUMN IF NOT EXISTS tags TEXT[];
CREATE INDEX IF NOT EXISTS idx_scenic_spots_tags ON scenic_spots USING GIN(tags);

UPDATE scenic_spots
SET tags = ARRAY['历史古迹', '博物馆', '世界遗产', '历史', '摄影', '亲子', '室内']
WHERE name ILIKE '%故宫%' OR name ILIKE '%紫禁城%';

UPDATE scenic_spots
SET tags = ARRAY['城市地标', '历史', '摄影', '步行', '低预算', '城市漫步']
WHERE name ILIKE '%天安门%';

UPDATE scenic_spots
SET tags = ARRAY['博物馆', '历史', '展览', '室内', '低预算', '亲子']
WHERE name ILIKE '%国家博物馆%' OR name ILIKE '%国博%';

UPDATE scenic_spots
SET tags = ARRAY['公园', '自然', '观景', '摄影', '轻徒步', '历史']
WHERE name ILIKE '%景山%';

UPDATE scenic_spots
SET tags = ARRAY['商业街区', '美食', '夜游', '购物', '城市漫步', '低预算']
WHERE name ILIKE '%前门%';

UPDATE scenic_spots
SET tags = ARRAY['城市漫步', '胡同', '摄影', '休闲', '夜游', '美食']
WHERE name ILIKE '%什刹海%' OR name ILIKE '%鼓楼%' OR name ILIKE '%南锣鼓巷%';

UPDATE scenic_spots
SET tags = ARRAY['公园', '自然', '湖景', '摄影', '亲子', '低预算']
WHERE name ILIKE '%北海公园%' OR name ILIKE '%颐和园%' OR name ILIKE '%圆明园%';

UPDATE scenic_spots
SET tags = ARRAY['历史古迹', '世界遗产', '轻徒步', '摄影', '自然']
WHERE name ILIKE '%长城%';

UPDATE scenic_spots
SET tags = ARRAY['商业街区', '购物', '美食', '夜游', '城市地标']
WHERE name ILIKE '%王府井%' OR name ILIKE '%三里屯%' OR name ILIKE '%西单%';

UPDATE scenic_spots
SET tags = ARRAY['美食街区', '美食', '夜游', '城市漫步', '低预算']
WHERE name ILIKE '%簋街%' OR name ILIKE '%小吃%' OR name ILIKE '%美食%';

UPDATE scenic_spots
SET tags = array_remove(ARRAY[
    CASE WHEN COALESCE(array_to_string(tags, ' '), '') ILIKE '%博物馆%' OR COALESCE(description, '') ILIKE '%博物馆%' THEN '博物馆' END,
    CASE WHEN COALESCE(array_to_string(tags, ' '), '') ILIKE '%公园%' OR COALESCE(description, '') ILIKE '%公园%' THEN '公园' END,
    CASE WHEN COALESCE(array_to_string(tags, ' '), '') ILIKE '%风景%' OR COALESCE(description, '') ILIKE '%自然%' THEN '自然' END,
    CASE WHEN COALESCE(array_to_string(tags, ' '), '') ILIKE '%古迹%' OR COALESCE(description, '') ILIKE '%历史%' THEN '历史古迹' END,
    CASE WHEN COALESCE(array_to_string(tags, ' '), '') ILIKE '%广场%' OR COALESCE(description, '') ILIKE '%地标%' THEN '城市地标' END,
    CASE WHEN COALESCE(array_to_string(tags, ' '), '') ILIKE '%商业%' OR COALESCE(array_to_string(tags, ' '), '') ILIKE '%步行街%' THEN '商业街区' END,
    '摄影',
    CASE WHEN COALESCE(ticket_price, 0) <= 30 THEN '低预算' END
], NULL)
WHERE tags IS NULL OR array_length(tags, 1) IS NULL OR tags = ARRAY['']::text[];

COMMIT;
