# AGENTS.md

This file is for AI agents and coding assistants that need to understand this repository quickly. Keep it concise, current, and operational.

## Project Snapshot

TourPilot is a personalized tourism planning system.

- Frontend: Vue 3, Vite, Vue Router, Tailwind CSS, Axios, Leaflet, AMap JS API for scenic-area internal navigation.
- Backend: C++17, Crow, PostgreSQL/libpq, CMake.
- Database: PostgreSQL with PostGIS.
- External APIs: DeepSeek-compatible chat API, AMap Web Service, AMap JS API, and OpenStreetMap/Overpass for internal scenic-area map imports.

DeepSeek keys must stay in environment variables. The backend includes a free default AMap Web Service key for route planning; `AMAP_WEB_SERVICE_KEY` or `AMAP_KEY` can still override it. The scenic detail frontend AMap JS API loader also has a built-in free JS API key; `VITE_AMAP_JS_KEY` and optional `VITE_AMAP_SECURITY_JS_CODE` can override it.

## Main Entry Points

Frontend:

- `frontend/src/main.js`: creates the Vue app, installs router, imports Tailwind and Leaflet CSS.
- `frontend/src/App.vue`: root layout, navigation, global search, `<router-view />`.
- `frontend/src/router/index.js`: SPA route table.
- `frontend/src/services/tourismApi.js`: single frontend API client.
- `frontend/src/stores/auth.js`: login state, token persistence, current user.
- `frontend/src/views/TravelAgent.vue`: real API-backed AI travel assistant page.
- `frontend/src/views/RoutePlan.vue`: Leaflet map and route planning page.
- `frontend/src/views/FoodRecommend.vue`: food recommendation page backed by `/api/v1/foods`.
- `frontend/src/views/Achievements.vue`: public travel passport / achievement overview page.
- `frontend/src/views/CollectibleDetail.vue`: authenticated digital collectible certificate page.
- `frontend/src/components/IndoorNavigationPanel.vue`: indoor building/feature selection and route-result panel.
- `frontend/src/services/amapLoader.js`: AMap JS API loader for scenic internal navigation.
- `frontend/src/utils/coordinates.js`: WGS84/GCJ-02 conversion helpers for AMap display and backend route requests.
- `frontend/src/utils/images.js`: image selection priority and placeholders.
- `frontend/src/data/imageCatalog.js`: local pinyin image catalog.

Backend:

- `backend/src/main.cpp`: startup only. It creates the Crow app and registers route modules.
- `backend/include/api/app.h`: shared Crow app type.
- `backend/src/api/*_routes.cpp`: route modules.
- `backend/src/services/*_service.cpp`: business logic and external services.
- `backend/src/services/auth_service.cpp`: password hashing and Bearer token lookup.
- `backend/src/services/achievement_service.cpp`: travel passport achievement evaluation, check-ins, collectibles, badge redemptions, and lightweight diary review decisions.
- `backend/src/db/postgres.cpp`: PostgreSQL connection/query helpers.
- `backend/src/support/api_helpers.cpp`: response helpers, parameter parsing, headers.

Database:

- `database/schema.sql`
- `database/imports/amap_pois.sql`
- `database/internal_navigation_schema.sql`
- `database/imports/internal_navigation.sql`
- `database/indoor_navigation_schema.sql`
- `database/seed_demo.sql`
- `database/seed_indoor_navigation.sql`
- `database/verify_demo.sql`
- `scripts/import_internal_map_data.py`: generates real-map internal navigation SQL from OSM/Overpass roads/buildings and AMap nearby facilities. It stores all geometry as WGS84; AMap POIs are queried in GCJ-02 and converted back to WGS84 before SQL output.
- `scripts/audit_project_data.py`: read-only audit for AMap POI counts, local scenic inserts, and indoor navigation seed/schema coverage.

Documentation:

- `README.md`: project overview and common run commands.
- `QUICKSTART.md`: minimal local startup and database initialization steps.
- `docs/engineering_log.md`: concise chronological engineering record. Append important changes here instead of creating a new branch-specific change document each time.
- `docs/adr/`: architecture decision records. Use ADRs for major decisions that explain why a design was chosen.
- `docs/changes_after_lxd.md`: historical phase document for the lxd handoff; do not duplicate this pattern for every future branch.

## Backend Module Map

- `dashboard_routes`: `/health`, `/`, `/api/v1/dashboard`, `/api/v1/achievements`.
- Achievement APIs are also registered in `dashboard_routes`: scenic spot check-ins, achievement claim, collectibles, badge redemptions, and review submissions/decisions.
- `auth_routes`: login, register, logout, current user, change password.
- `profile_routes`: `/api/v1/profile`, `/api/v1/profile/preferences`.
- `scenic_routes`: scenic spot list/search/detail/categories/suggestions/reviews, plus internal facilities/map/route APIs and indoor navigation APIs.
- `recommendation_routes`: budget plans and personalized recommendations.
- `route_routes`: route nodes, route list, route planning.
- `diary_routes`: diaries, likes, bookmarks, ratings, comments, achievement review submissions.
- `aigc_routes`: diary summary, polish, travel chat.
- `food_routes`: `/api/v1/foods`, `/api/v1/foods/cuisines`; recommendations use `facilities` restaurant/cafe/fast_food data, inferred cuisine labels, derived `hotScore`, and Top-K partial sorting.

If adding a new API, add it to the matching `backend/src/api/*_routes.cpp` file and keep `main.cpp` small.

## Frontend Route Map

- `/`: `Home.vue`
- `/login`: `Login.vue`
- `/register`: `Register.vue`
- `/search`: `Search.vue`
- `/spots/:id`: `ScenicDetail.vue`
- `/recommend`: `Recommendation.vue`
- `/route`: `RoutePlan.vue`
- `/agent`: `TravelAgent.vue`
- `/diary`: `Diary.vue`
- `/diary/new`: `DiaryEditor.vue`
- `/diary/edit/:id`: `DiaryEditor.vue`
- `/diary/:id`: `DiaryDetail.vue`
- `/achievements`: `Achievements.vue`
- `/collectibles/:id`: `CollectibleDetail.vue`
- `/food`: `FoodRecommend.vue`
- `/profile`: `Profile.vue`

## Food Recommendation Rules

- `/api/v1/foods` supports `scenic_spot_id`, `q`, `cuisine`, `sort=hot|rating|distance`, `lat/lng`, and `limit`.
- Food candidates come from `facilities` where type is `restaurant`, `cafe`, or `fast_food`; scenic ownership may come from `facilities.scenic_spot_id` or linked `graph_nodes`.
- Cuisine is inferred in C++ from facility names. Fuzzy search matches name, cuisine key/label, address, and scenic name; "window name" is treated as part of the food/facility name.
- `sort=hot` uses a derived score only, not a database field: rating 50%, info completeness 20%, price friendliness 15%, type/name trust 15%.
- Ranking uses `TopKSelector` to keep the first K results before final ordered response. API responses include `hotScore`, `matchReason`, `distanceMeters`, `sort`, and `algorithm`.

## Indoor Navigation Rules

- The only runtime database is `tourism_system`; never create a second database for indoor navigation.
- AMap scenic POIs are imported offline from `database/imports/amap_pois.sql` into local PostgreSQL. Runtime scenic pages should read local tables, not call AMap POI search on every page load.
- Indoor navigation uses domain tables in `database/schema.sql`: `indoor_buildings`, `indoor_floors`, `indoor_features`, `indoor_edges`, and `indoor_route_audit`.
- Providers are explicit: `amap_indoor` for official AMap indoor capability and `local_indoor_graph` for local graph fallback/algorithm defense.
- All indoor rows need `source`, `source_ref`, and `provider`; seed/import SQL should use stable `source_ref` upserts.
- Frontend calls must go through `frontend/src/services/tourismApi.js`. Do not bypass the backend from Vue components.
- Do not implement core indoor route planning in the frontend. Local indoor routing is backend Dijkstra over `indoor_edges`.
- Indoor APIs live in `backend/src/api/scenic_routes.cpp`: building list, feature list, and route planning.
- Keep first-phase indoor coverage small but formal. A single real building is acceptable when schema, API, provider fallback, and route audit are complete.
- Run `python scripts\audit_project_data.py` when checking data counts for defense.

## Achievement / Collectible Rules

- The V1 achievement experience is a public "travel passport" at `/achievements`; unauthenticated users see examples, authenticated users see saved progress.
- Protected achievement actions: `POST /api/v1/scenic-spots/:id/checkins`, `POST /api/v1/achievements/:id/claim`, `GET /api/v1/collectibles`, `GET /api/v1/collectibles/:id`, `GET/POST /api/v1/badge-redemptions`, and `POST /api/v1/diaries/:id/achievement-review`.
- Lightweight review actions: `GET /api/v1/achievement-review-submissions` and `POST /api/v1/achievement-review-submissions/:id/decision`. V1 review permission is `demo_user` plus comma-separated `TOURISM_REVIEWER_USERNAMES`.
- Achievement evaluation is centralized in `backend/src/services/achievement_service.cpp`. Call it after check-ins and diary create/update; do not duplicate rule logic in route handlers.
- V1 has four tiers: basic scenic check-in, themed stamp collections, qualified travel diary, and master diary review queue.
- `/api/v1/achievements` returns explanation fields for the passport UI: `requiredSpots`, `checkedSpots`, `missingSpots`, `nextAction`, and `redemptionHistory`.
- Digital collectibles are simulated on-chain credentials. Do not add real blockchain/network calls unless explicitly requested; `token_id` and `blockchain_hash` are generated locally.
- Digital collectible certificate pages can generate a local browser share-card image; this is frontend-only and should not call an image service.
- Physical badges are redemption requests only. Status values are `pending`, `approved`, `rejected`, and `shipped`; there is no inventory, shipping, or admin fulfillment workflow in V1.
- Check-ins use browser location when available; missing or failed geolocation falls back to self/demo verification.

## Image Rules

Scenic spot images use exactly three sources, in this order:

1. API/database image returned by the backend. This can be from AMap-imported data or manually curated data.
2. Local pinyin-named images from `frontend/public/images/diary/`, resolved through `frontend/src/data/imageCatalog.js`.
3. Frontend generated SVG placeholder from `frontend/src/utils/images.js`.

- The local pinyin image catalog currently contains manually collected Beijing spot photos. `frontend/src/utils/images.js` must only use it when the spot has a Beijing context.
- Beijing context is determined by structured region fields first: `city` / `province`, then `district`, then strict address fallback. Do not treat road names such as `北京西路` or `北京路` in non-Beijing cities as Beijing spots.
- Backend scenic JSON should expose `city` when available, and should not fill missing region fields with a fake default Beijing value. Non-Beijing spots without database images should fall through to the SVG placeholder.

Do not add remote random-image fallbacks.

## Auth Rules

- Login identifier is username or email.
- Demo account: `demo_user / demo123456`.
- Tokens are opaque 32-byte random values stored in `refresh_tokens`; they are not JWTs.
- Frontend stores the token in `localStorage.token` and sends `Authorization: Bearer <token>`.
- Protected frontend routes: `/profile`, `/collectibles/:id`, `/diary/new`, `/diary/edit/:id`.
- User write actions require auth: profile preferences, diary create/update/delete, likes, bookmarks, ratings, comments, scenic check-ins, achievement claim, collectible detail, physical badge redemption, and achievement review submission.
- Public browsing remains anonymous: home, search, scenic detail, route planning, AI assistant, diary list/detail, `/food`, and `/achievements`.

## Run Commands

Backend:

```powershell
cmake -S backend -B backend\build-codex-verify-mingw
cmake --build backend\build-codex-verify-mingw
backend\build-codex-verify-mingw\bin\tourism_server.exe --host 127.0.0.1 --port 8080
```

Database import:

```powershell
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\schema.sql
psql -U postgres -d tourism_system -f database\imports\amap_pois.sql
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\internal_navigation_schema.sql
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\imports\internal_navigation.sql
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\indoor_navigation_schema.sql
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\seed_demo.sql
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\seed_indoor_navigation.sql
```

Regenerate internal scenic-area navigation data:

```powershell
py scripts\import_internal_map_data.py --amap-pages 1 --max-edges-per-spot 2000 --connector-max-distance 60 --output database\imports\internal_navigation.sql
```

Internal scenic-area routing is strict: routes must include real OSM road/path edges, generated facility connectors are allowed only within the configured connector threshold, and unreachable facilities should return an error instead of a straight-line route. Database/API geometry stays WGS84; the scenic detail page displays it on AMap JS API after WGS84 -> GCJ-02 conversion, and map-picked starts are converted back from GCJ-02 -> WGS84 before calling the backend.

Frontend:

```powershell
cd frontend
npm install
npm run dev
npm.cmd run lint
npm.cmd run build
```

Frontend dev/preview intentionally use custom Node launchers:

- `npm run dev` -> `node scripts/vite-dev.mjs`
- `npm run preview` -> `node scripts/vite-preview.mjs`

These launchers pass `configFile: false` to Vite and avoid a Windows config-loading issue seen in this workspace.

## Environment Variables

```powershell
$env:TOURISM_DB_CONN="host=127.0.0.1 port=5432 dbname=tourism_system user=postgres password=你的密码"
$env:TOURISM_LLM_API_KEY="你的 DeepSeek API Key"
$env:TOURISM_LLM_BASE_URL="https://api.deepseek.com"
$env:TOURISM_LLM_MODEL="deepseek-chat"
$env:AMAP_WEB_SERVICE_KEY="你的高德 Web Service Key，可选"
$env:VITE_AMAP_JS_KEY="你的高德 JS API Key，可选"
$env:VITE_AMAP_SECURITY_JS_CODE="你的高德 JS API 安全密钥，可选"
$env:TOURISM_REVIEWER_USERNAMES="demo_user,reviewer_name"
```

AMap Web Service route planning has a built-in free default key, so `AMAP_WEB_SERVICE_KEY` is optional. The frontend AMap JS API loader also has a built-in free JS API key; set `VITE_AMAP_JS_KEY` only when overriding it, and set `VITE_AMAP_SECURITY_JS_CODE` only if the AMap console security configuration requires it. DeepSeek has no built-in key and must use environment variables.

## Smoke Tests

```powershell
Invoke-WebRequest http://127.0.0.1:8080/health
Invoke-WebRequest "http://127.0.0.1:8080/api/v1/scenic-spots?limit=2"
Invoke-WebRequest http://127.0.0.1:8080/api/v1/scenic-categories
Invoke-WebRequest "http://127.0.0.1:8080/api/v1/search/suggestions?q=故宫"
Invoke-WebRequest "http://127.0.0.1:8080/api/v1/budget-plans?budget=200"
Invoke-WebRequest http://127.0.0.1:8080/api/v1/routes
Invoke-WebRequest http://127.0.0.1:8080/api/v1/diaries
Invoke-WebRequest "http://127.0.0.1:8080/api/v1/foods?scenic_spot_id=12&sort=hot&limit=10"
Invoke-WebRequest http://127.0.0.1:8080/api/v1/achievements
Invoke-WebRequest http://127.0.0.1:8080/api/v1/badge-redemptions -Headers @{Authorization="Bearer <token>"}
Invoke-WebRequest "http://127.0.0.1:8080/api/v1/achievement-review-submissions?status=pending" -Headers @{Authorization="Bearer <reviewer-token>"}
Invoke-WebRequest -Method POST http://127.0.0.1:8080/api/v1/auth/login -ContentType "application/json" -Body '{"identifier":"demo_user","password":"demo123456"}'
```

Frontend URLs:

- `http://127.0.0.1:3000/`
- `http://127.0.0.1:3000/search?q=故宫`
- `http://127.0.0.1:3000/agent`
- `http://127.0.0.1:3000/route`
- `http://127.0.0.1:3000/diary`
- `http://127.0.0.1:3000/food`
- `http://127.0.0.1:3000/achievements`

## Current Test Policy

GTest is intentionally out of scope for the current cleanup round. Do not install it or change the CMake test strategy unless the user asks for a dedicated testing task.

## Constraints

- Do not change public API paths unless the frontend is updated in the same change.
- Do not put DeepSeek keys in files, commits, screenshots, or logs.
- Do not replace the opaque-token auth flow with JWT unless the user explicitly asks.
- Do not reintroduce `frontend/src/api/index.js`; the active API client is `frontend/src/services/tourismApi.js`.
- Do not make `main.cpp` large again; add route handlers to modules.
- Do not treat `frontend/dist` as source logic.
- Do not remove fallback demo data unless the user explicitly wants backend-only behavior.
- Do not restore old mojibake text. If a string is corrupted and must be touched, replace it with clean UTF-8 Chinese.
