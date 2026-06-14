-- =====================================================
-- 旅行日记压缩字段旧命名清理
-- =====================================================
-- 早期半成品迁移曾使用 compressed_content / original_bytes /
-- compressed_bytes。正式字段统一为 content_compressed 和
-- content_original_bytes；压缩后字节数由 octet_length(content_compressed)
-- 动态计算，不再单独落列。
-- =====================================================

BEGIN;

ALTER TABLE travel_diaries
    ADD COLUMN IF NOT EXISTS content_compressed BYTEA,
    ADD COLUMN IF NOT EXISTS content_original_bytes INTEGER;

DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_name = 'travel_diaries'
          AND column_name = 'original_bytes'
    ) THEN
        UPDATE travel_diaries
        SET content_original_bytes = original_bytes
        WHERE content_original_bytes IS NULL
          AND original_bytes IS NOT NULL
          AND original_bytes > 0;
    END IF;
END $$;

ALTER TABLE travel_diaries
    DROP COLUMN IF EXISTS compressed_content,
    DROP COLUMN IF EXISTS original_bytes,
    DROP COLUMN IF EXISTS compressed_bytes;

COMMIT;
