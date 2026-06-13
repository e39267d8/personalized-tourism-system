# 0002 成就系统模块边界与并行协作

状态：已接受

日期：2026-06-13

## 背景

后续项目会并行开发：基础功能继续对照评分原则推进，创新功能由成就系统主线独立迭代。仓库里成就系统已经不是纯想法，当前已覆盖旅行护照、景点打卡、数字纪念凭证、实体徽章申请和大师级游记评审。

在本次整理之前：

- 成就相关接口混在 `backend/src/api/dashboard_routes.cpp`
- 成就演示数据混在 `database/seeds/seed_demo.sql`
- 运行时兼容逻辑会自动补字段和建表，但队友很难一眼看出本地数据库该补哪些正式 SQL

这会让基础功能主线和创新主线在同一组高频文件里冲突，也会增加“代码拉到了，但数据库没同步”的验收风险。

## 决策

1. 后端路由边界
   - 成就相关公开接口统一放到 `backend/src/api/achievement_routes.cpp`
   - `dashboard_routes.cpp` 只保留健康检查、根路径和首页统计，不再承载成就业务接口
   - 成就规则、评估和数据装配继续集中在 `backend/src/services/achievement_service.cpp`

2. 数据库正式流程
   - 成就系统结构同步以 `database/migrations/achievement_module_schema.sql` 为准
   - 成就系统演示数据以 `database/seeds/seed_achievements.sql` 为准
   - `database/seeds/seed_demo.sql` 继续只负责基础演示路线、游记、评论、收藏和推荐标签，不再夹带成就演示数据

3. 共享接口冻结
   - 对外路径保持不变：
     - `/api/v1/achievements`
     - `/api/v1/scenic-spots/<id>/checkins`
     - `/api/v1/achievements/<id>/claim`
     - `/api/v1/collectibles`
     - `/api/v1/collectibles/<id>`
     - `/api/v1/badge-redemptions`
     - `/api/v1/achievement-review-submissions`
     - `/api/v1/achievement-review-submissions/<id>/decision`
   - 基础功能页面如需展示成就结果，优先消费这些接口，不在别处复制规则

4. ownership 建议
   - 成就创新主线优先负责：
     - `backend/src/api/achievement_routes.cpp`
     - `backend/include/api/achievement_routes.h`
     - `backend/src/services/achievement_service.cpp`
     - `backend/include/services/achievement_service.h`
     - `frontend/src/views/Achievements.vue`
     - `frontend/src/views/CollectibleDetail.vue`
     - `database/migrations/achievement_module_schema.sql`
     - `database/seeds/seed_achievements.sql`
   - 基础功能主线优先负责：
     - 搜索、推荐、路线、景区/校园图、游记基础能力和对应 SQL
   - 共享且需要协调改动窗口的文件：
     - `frontend/src/services/tourismApi.js`
     - `frontend/src/views/ScenicDetail.vue`
     - `frontend/src/views/DiaryDetail.vue`
     - `frontend/src/views/Profile.vue`
     - `docs/api-runtime.md`
     - `QUICKSTART.md`
     - `database/README.md`

## 影响

- 成就系统后续改动更集中，基础功能与创新功能分支的 merge conflict 会明显减少
- 数据库同步口径更正式，避免只靠运行时自动补表
- 答辩时可以更清楚地说明：创新功能并不是散落在全系统里的临时按钮，而是有独立接口、数据流程和模块边界的正式能力
