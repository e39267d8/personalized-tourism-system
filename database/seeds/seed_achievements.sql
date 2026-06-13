SET client_encoding = 'UTF8';

BEGIN;

INSERT INTO achievements
    (code, name, description, icon_url, level, type, tier, display_order, requirement, reward, is_active)
VALUES
    ('passport-first-stamp', '北京旅行第一章', '完成任意一个景点打卡，开启你的 TourPilot 旅行护照。', '', 1, 'exploration', 1, 10, '{"kind":"checkin_count","target":1}', '{"points":30,"digitalCollectible":true}', TRUE),
    ('stamp-gugong', '故宫印章', '到访故宫并完成打卡，收集一枚经典地标印章。', '', 1, 'exploration', 1, 20, '{"kind":"spot","spot":"故宫"}', '{"points":40,"digitalCollectible":true}', TRUE),
    ('theme-axis', '中轴线集章者', '集齐前门、天安门、故宫、景山，完成北京中轴线主题探索。', '', 2, 'theme', 2, 30, '{"kind":"theme","spots":["前门","天安门","故宫","景山"]}', '{"points":120,"digitalCollectible":true,"physicalBadge":true}', TRUE),
    ('theme-museum', '博物馆漫游家', '完成国家博物馆与故宫相关打卡，解锁文化探索主题章。', '', 2, 'theme', 2, 40, '{"kind":"theme","spots":["国家博物馆","故宫"]}', '{"points":100,"digitalCollectible":true,"physicalBadge":true}', TRUE),
    ('theme-old-citywalk', '老城漫步达人', '集齐鼓楼、什刹海、北海、景山，完成老城 citywalk 主题。', '', 2, 'theme', 2, 50, '{"kind":"theme","spots":["鼓楼","什刹海","北海","景山"]}', '{"points":140,"digitalCollectible":true,"physicalBadge":true}', TRUE),
    ('theme-royal-gardens', '皇家园林收藏家', '打卡颐和园、圆明园、北海，收集皇家园林主题印章。', '', 2, 'theme', 2, 60, '{"kind":"theme","spots":["颐和园","圆明园","北海"]}', '{"points":140,"digitalCollectible":true,"physicalBadge":true}', TRUE),
    ('theme-night-food', '夜游美食探索者', '打卡王府井与三里屯，记录城市夜色和美食记忆。', '', 2, 'theme', 2, 70, '{"kind":"theme","spots":["王府井","三里屯"]}', '{"points":100,"digitalCollectible":true,"physicalBadge":true}', TRUE),
    ('theme-family-nature', '亲子自然观察员', '打卡奥林匹克森林公园与北海，完成轻松自然主题。', '', 2, 'theme', 2, 80, '{"kind":"theme","spots":["奥林匹克森林公园","北海"]}', '{"points":100,"digitalCollectible":true,"physicalBadge":true}', TRUE),
    ('diary-memory-maker', '旅行记忆创作者', '发布包含景点、图片和完整体验记录的旅行日记。', '', 3, 'diary', 3, 90, '{"kind":"diary","min_words":120,"min_images":1,"min_spots":1}', '{"points":180,"digitalCollectible":true,"creatorBadge":true}', TRUE),
    ('master-travel-writer', '大师级旅行记录者', '优质旅行日记通过人工评审，获得最高级纪念奖励。', '', 4, 'diary_review', 4, 100, '{"kind":"master_review","status":"approved"}', '{"points":300,"digitalCollectible":true,"physicalBadge":true,"premium":true}', TRUE)
ON CONFLICT (code) DO UPDATE SET
    name = EXCLUDED.name,
    description = EXCLUDED.description,
    icon_url = EXCLUDED.icon_url,
    level = EXCLUDED.level,
    type = EXCLUDED.type,
    tier = EXCLUDED.tier,
    display_order = EXCLUDED.display_order,
    requirement = EXCLUDED.requirement,
    reward = EXCLUDED.reward,
    is_active = EXCLUDED.is_active;

INSERT INTO user_achievements
    (user_id, achievement_id, progress, status, unlocked_at)
SELECT demo.user_id, a.id, demo.progress, demo.status, demo.unlocked_at
FROM (VALUES
    (1, 'passport-first-stamp', '{"completed":true}'::jsonb, 'unlocked', CURRENT_TIMESTAMP),
    (2, 'stamp-gugong', '{"review_count":1}'::jsonb, 'unlocked', CURRENT_TIMESTAMP),
    (3, 'theme-axis', '{"distance_km":3.8}'::jsonb, 'unlocked', CURRENT_TIMESTAMP)
) AS demo(user_id, achievement_code, progress, status, unlocked_at)
JOIN achievements a ON a.code = demo.achievement_code
ON CONFLICT (user_id, achievement_id) DO UPDATE SET
    progress = EXCLUDED.progress,
    status = EXCLUDED.status,
    unlocked_at = EXCLUDED.unlocked_at;

INSERT INTO digital_collectibles
    (id, user_id, achievement_id, diary_id, token_id, name, description, image_url, metadata, blockchain_hash, minted_at)
SELECT demo.id, demo.user_id, a.id, demo.diary_id, demo.token_id, demo.name, demo.description, demo.image_url, demo.metadata, demo.blockchain_hash, demo.minted_at
FROM (VALUES
    (1, 1, 'passport-first-stamp', 1, 'DEMO-PASSPORT-001', '北京旅行第一章数字纪念凭证', '开启 TourPilot 旅行护照后获得的模拟数字纪念凭证。', '', '{"demo":true,"chainMode":"simulated"}'::jsonb, 'demo-hash-passport-001', CURRENT_TIMESTAMP),
    (2, 3, 'theme-axis', 3, 'DEMO-AXIS-001', '中轴线集章者数字纪念凭证', '完成北京中轴线主题探索后获得的模拟数字纪念凭证。', '', '{"demo":true,"theme":"axis","chainMode":"simulated"}'::jsonb, 'demo-hash-axis-001', CURRENT_TIMESTAMP)
) AS demo(id, user_id, achievement_code, diary_id, token_id, name, description, image_url, metadata, blockchain_hash, minted_at)
LEFT JOIN achievements a ON a.code = demo.achievement_code
ON CONFLICT (id) DO UPDATE SET
    user_id = EXCLUDED.user_id,
    achievement_id = EXCLUDED.achievement_id,
    diary_id = EXCLUDED.diary_id,
    token_id = EXCLUDED.token_id,
    name = EXCLUDED.name,
    description = EXCLUDED.description,
    image_url = EXCLUDED.image_url,
    metadata = EXCLUDED.metadata,
    blockchain_hash = EXCLUDED.blockchain_hash,
    minted_at = EXCLUDED.minted_at;

SELECT setval('achievements_id_seq', (SELECT COALESCE(MAX(id), 1) FROM achievements));
SELECT setval('digital_collectibles_id_seq', (SELECT COALESCE(MAX(id), 1) FROM digital_collectibles));

COMMIT;
