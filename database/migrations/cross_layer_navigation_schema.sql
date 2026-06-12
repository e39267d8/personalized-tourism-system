-- =====================================================
-- 室内外跨层导航 - 数据库迁移（幂等）
-- =====================================================
-- 语义：
--   indoor_buildings.outdoor_node_id
--     室内建筑在室外路网（graph_nodes）中的锚点节点。
--     跨层路线规划在该节点完成"室外步行 → 进入建筑"的交接。
-- 绑定规则：
--   优先名称精确匹配；其次做"北大/北京大学"前缀归一化匹配
--   （室内 seed 用"北大红楼"，OSM 室外节点为"北京大学红楼"）。
--   只在尚未绑定时尝试，重复执行安全。
--   未能自动绑定的建筑可手动 UPDATE，或由后端在规划时按同规则
--   实时匹配（匹配失败会返回明确错误，不影响纯室内导航）。
-- =====================================================

BEGIN;

ALTER TABLE indoor_buildings
    ADD COLUMN IF NOT EXISTS outdoor_node_id INTEGER REFERENCES graph_nodes(id) ON DELETE SET NULL;

COMMENT ON COLUMN indoor_buildings.outdoor_node_id IS '室外路网锚点节点（跨层导航交接点，NULL=未绑定）';

UPDATE indoor_buildings b
SET outdoor_node_id = (
    SELECT gn.id
    FROM graph_nodes gn
    WHERE gn.location IS NOT NULL
      AND (
          gn.name = b.name
          OR REPLACE(gn.name, '北京大学', '北大') = b.name
          OR REPLACE(b.name, '北大', '北京大学') = gn.name
      )
    ORDER BY (gn.node_type = 'building') DESC, gn.id
    LIMIT 1
)
WHERE b.outdoor_node_id IS NULL;

COMMIT;
