-- =====================================================
-- 旅行日记 Huffman 压缩存储 - 数据库迁移（幂等）
-- =====================================================
-- 语义：
--   content_compressed       Huffman 压缩后的字节流（含频率表头）。
--                            为 NULL 表示该行按明文存储在 content 列。
--   content_original_bytes   压缩前原文字节数，用于统计与校验。
-- 规则：
--   后端写入日记时自动压缩；仅当压缩后体积小于原文时才存压缩列，
--   并将 content 置空，否则保持明文（短文本 Huffman 频率表开销可能反向膨胀）。
--   summary 始终保持明文，供列表页与 LIKE 检索使用；
--   全文检索由倒排索引承担（索引构建时自动解压）。
-- =====================================================

BEGIN;

ALTER TABLE travel_diaries
    ADD COLUMN IF NOT EXISTS content_compressed BYTEA,
    ADD COLUMN IF NOT EXISTS content_original_bytes INTEGER;

COMMENT ON COLUMN travel_diaries.content_compressed IS 'Huffman 压缩后的日记正文（NULL=明文存储于 content）';
COMMENT ON COLUMN travel_diaries.content_original_bytes IS '压缩前原文字节数';

COMMIT;
