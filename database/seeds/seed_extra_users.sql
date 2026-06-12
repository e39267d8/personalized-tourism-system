SET client_encoding = 'UTF8';

-- =====================================================
-- 个性化旅游系统 - 补充演示用户（使总数 ≥ 10）
-- 使用与 seed_demo.sql 相同的 demo 密码哈希值
-- =====================================================

BEGIN;

INSERT INTO users
    (id, username, password_hash, email, phone, nickname, gender, birth_date, preferences, status)
VALUES
    (4, 'traveler_zhang', 'pbkdf2_sha256$20000$746f757270696c6f745f64656d6f5f31$30816d10380edb332c6eeec9f33fb6184319e03cf491a1f89ede57ddd3031183', 'zhang@example.com', '13800000004', '张同学', 1, '1999-03-15', '{"themes":["nature","park"],"budget":"medium","transport":"bike"}', 1),
    (5, 'foodie_chen', 'pbkdf2_sha256$20000$746f757270696c6f745f64656d6f5f31$30816d10380edb332c6eeec9f33fb6184319e03cf491a1f89ede57ddd3031183', 'chen@example.com', '13800000005', '陈美食家', 1, '1998-08-22', '{"themes":["food","nightlife"],"budget":"high","transport":"car"}', 1),
    (6, 'photo_lover', 'pbkdf2_sha256$20000$746f757270696c6f745f64656d6f5f31$30816d10380edb332c6eeec9f33fb6184319e03cf491a1f89ede57ddd3031183', 'photo@example.com', '13800000006', '摄影达人', 2, '2000-11-30', '{"themes":["photo","architecture","sunset"],"budget":"low","transport":"walk"}', 1),
    (7, 'history_buff', 'pbkdf2_sha256$20000$746f757270696c6f745f64656d6f5f31$30816d10380edb332c6eeec9f33fb6184319e03cf491a1f89ede57ddd3031183', 'history@example.com', '13800000007', '历史迷', 0, '1997-05-18', '{"themes":["history","museum","culture"],"budget":"medium","transport":"subway"}', 1),
    (8, 'weekend_walker', 'pbkdf2_sha256$20000$746f757270696c6f745f64656d6f5f31$30816d10380edb332c6eeec9f33fb6184319e03cf491a1f89ede57ddd3031183', 'walker@example.com', '13800000008', '周末步行者', 1, '1996-09-05', '{"themes":["citywalk","park","shopping"],"budget":"low","transport":"walk"}', 1),
    (9, 'shopping_queen', 'pbkdf2_sha256$20000$746f757270696c6f745f64656d6f5f31$30816d10380edb332c6eeec9f33fb6184319e03cf491a1f89ede57ddd3031183', 'shop@example.com', '13800000009', '购物女王', 2, '2001-01-12', '{"themes":["shopping","food","nightlife"],"budget":"high","transport":"car"}', 1),
    (10, 'nature_fan', 'pbkdf2_sha256$20000$746f757270696c6f745f64656d6f5f31$30816d10380edb332c6eeec9f33fb6184319e03cf491a1f89ede57ddd3031183', 'nature@example.com', '13800000010', '自然爱好者', 0, '1998-07-20', '{"themes":["nature","park","photography"],"budget":"medium","transport":"bike"}', 1),
    (11, 'night_owl', 'pbkdf2_sha256$20000$746f757270696c6f745f64656d6f5f31$30816d10380edb332c6eeec9f33fb6184319e03cf491a1f89ede57ddd3031183', 'night@example.com', '13800000011', '夜猫子', 1, '2000-04-01', '{"themes":["nightlife","food","bar"],"budget":"high","transport":"car"}', 1),
    (12, 'culture_explorer', 'pbkdf2_sha256$20000$746f757270696c6f745f64656d6f5f31$30816d10380edb332c6eeec9f33fb6184319e03cf491a1f89ede57ddd3031183', 'culture@example.com', '13800000012', '文化探索者', 2, '1999-12-25', '{"themes":["culture","museum","art"],"budget":"medium","transport":"subway"}', 1)
ON CONFLICT (id) DO UPDATE SET
    username = EXCLUDED.username,
    password_hash = EXCLUDED.password_hash,
    email = EXCLUDED.email,
    phone = EXCLUDED.phone,
    nickname = EXCLUDED.nickname,
    gender = EXCLUDED.gender,
    birth_date = EXCLUDED.birth_date,
    preferences = EXCLUDED.preferences,
    status = EXCLUDED.status;

INSERT INTO user_preferences
    (user_id, preference_type, preference_value, weight)
VALUES
    (4, 'scenic_type', '["自然","公园","户外"]', 0.90),
    (4, 'transport', '["bike","walk"]', 0.85),
    (5, 'scenic_type', '["美食","夜生活","商业街区"]', 0.95),
    (5, 'budget', '["high"]', 0.80),
    (6, 'scenic_type', '["摄影","建筑","观景","自然","日落"]', 0.95),
    (7, 'scenic_type', '["历史古迹","博物馆","文化遗产"]', 0.95),
    (7, 'transport', '["subway","walk"]', 0.80),
    (8, 'scenic_type', '["城市漫步","公园","商业街区"]', 0.90),
    (8, 'budget', '["low"]', 0.85),
    (9, 'scenic_type', '["购物","美食","夜生活"]', 0.95),
    (9, 'budget', '["high"]', 0.90),
    (10, 'scenic_type', '["自然","公园","户外","摄影"]', 0.95),
    (10, 'transport', '["bike","walk"]', 0.90),
    (11, 'scenic_type', '["夜生活","美食","酒吧"]', 0.95),
    (11, 'transport', '["car"]', 0.85),
    (12, 'scenic_type', '["文化","博物馆","艺术","历史"]', 0.95),
    (12, 'transport', '["subway","walk"]', 0.85)
ON CONFLICT (user_id, preference_type) DO UPDATE SET
    preference_value = EXCLUDED.preference_value,
    weight = EXCLUDED.weight;

-- Update sequence
SELECT setval('users_id_seq', (SELECT MAX(id) FROM users));

COMMIT;
