-- 日记 AIGC 动画增量迁移
-- 用于已有 tourism_system 数据库。仅补齐动画功能真实需要的字段。

BEGIN;

ALTER TABLE travel_diaries
    ADD COLUMN IF NOT EXISTS videos TEXT[],
    ADD COLUMN IF NOT EXISTS animation_storyboard JSONB;

COMMENT ON COLUMN travel_diaries.videos IS '用户为日记附加的视频 URL 列表';
COMMENT ON COLUMN travel_diaries.animation_storyboard IS 'AIGC 旅行动画分镜 JSON';

COMMIT;
