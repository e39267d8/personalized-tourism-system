-- 日记位置与封面字段迁移
-- 用于写日记页面的高德 POI 选择、当前位置落库，以及显式封面图。

BEGIN;

ALTER TABLE travel_diaries
    ADD COLUMN IF NOT EXISTS cover_image TEXT,
    ADD COLUMN IF NOT EXISTS location_name VARCHAR(200),
    ADD COLUMN IF NOT EXISTS location_address VARCHAR(300),
    ADD COLUMN IF NOT EXISTS location_latitude DOUBLE PRECISION,
    ADD COLUMN IF NOT EXISTS location_longitude DOUBLE PRECISION,
    ADD COLUMN IF NOT EXISTS location_poi_id VARCHAR(80);

UPDATE travel_diaries
SET cover_image = images[1]
WHERE cover_image IS NULL
  AND images IS NOT NULL
  AND array_length(images, 1) > 0;

CREATE INDEX IF NOT EXISTS idx_diaries_location_name ON travel_diaries(location_name);

COMMENT ON COLUMN travel_diaries.cover_image IS '用户显式设置的日记封面图，缺省回退 images[1]';
COMMENT ON COLUMN travel_diaries.location_name IS '日记地点名称，来自高德 POI/逆地理定位或用户选择';
COMMENT ON COLUMN travel_diaries.location_address IS '日记地点详细地址';
COMMENT ON COLUMN travel_diaries.location_latitude IS '日记地点纬度';
COMMENT ON COLUMN travel_diaries.location_longitude IS '日记地点经度';
COMMENT ON COLUMN travel_diaries.location_poi_id IS '高德 POI ID';

COMMIT;
