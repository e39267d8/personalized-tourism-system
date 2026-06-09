# Changes After Pulling The lxd Branch

This document records the project changes made after using the `lxd` branch as
the continuation baseline. It is meant for team collaboration, defense
preparation, and avoiding repeated work.

## Baseline Understanding

The project baseline after pulling `lxd` already had:

- Vue 3 frontend with scenic detail, scenic search, route planning, food,
  achievements, diaries, and AI assistant pages.
- C++ Crow backend with modular route files.
- One PostgreSQL/PostGIS database: `tourism_system`.
- Offline AMap POI import file: `database/imports/amap_pois.sql`.
- Existing scenic-area internal navigation based on `facilities`,
  `graph_nodes`, `graph_edges`, OSM/Overpass imports, AMap JS display, and
  backend route planning.

Important data conclusion:

- The 3476 scenic spot records are AMap POIs collected through the official AMap
  API, generated into SQL, and imported locally.
- Runtime scenic pages mainly read local PostgreSQL data instead of calling AMap
  POI search on every page view.
- Locally authored scenic spot inserts outside the AMap import are currently 0.

## Why These Changes Were Made

The course project needs indoor navigation, but building a full large-scale
indoor map product is not cost-effective. The chosen direction is:

- Build indoor navigation as a real engineering capability.
- Keep the first phase small in coverage.
- Avoid fake one-off demos.
- Keep data, provider, API, algorithm, and audit boundaries formal.
- Keep all data in the existing `tourism_system` database.

## Main Architectural Decision

Indoor navigation now uses a provider model:

- `amap_indoor`: reserved preferred provider for official AMap indoor capability
  such as indoor map, `cpid`, floor data, and future browser-side routePath
  integration.
- `local_indoor_graph`: local formal provider based on indoor graph tables and
  backend Dijkstra. This is the current implemented provider and the course
  defense fallback.

The first phase implements `local_indoor_graph` for one real building. This
keeps the work realistic while preserving extension paths.

## Database Changes

Added indoor domain tables to `database/schema.sql`:

- `indoor_buildings`
- `indoor_floors`
- `indoor_features`
- `indoor_edges`
- `indoor_route_audit`

Added incremental migration:

- `database/indoor_navigation_schema.sql`

Added first indoor seed:

- `database/seed_indoor_navigation.sql`

Seed coverage:

- One real scenic spot binding: Beida Red Building / 北大红楼.
- One building: `Beida Red Building Main Hall`.
- Two floors: `F1`, `F2`.
- Ten indoor features.
- Eighteen directed indoor edges.
- Provider: `local_indoor_graph`.
- Data source: `manual-curated`.

All indoor rows use:

- `provider`
- `source`
- `source_ref`
- `created_at`
- `updated_at`

The seed binds to existing AMap-imported scenic spots by name and a narrow
coordinate fallback. If the target POI cannot be found, it raises an explicit SQL
error instead of silently binding to a wrong scenic spot.

## Backend Changes

Updated:

- `backend/src/api/scenic_routes.cpp`

Added indoor APIs:

```text
GET  /api/v1/scenic-spots/:id/indoor-buildings
GET  /api/v1/indoor-buildings/:id/features
POST /api/v1/indoor-buildings/:id/routes/plan
```

Route planning behavior:

- Reads `indoor_features` and `indoor_edges`.
- Validates that start and end features belong to the same indoor building.
- Runs backend Dijkstra.
- Uses `travel_time` as weight for `strategy=time`.
- Uses `distance` as weight for `strategy=distance`.
- Returns provider, configured provider, algorithm, distance, duration, path,
  steps, and fallback status.
- Writes route attempts to `indoor_route_audit`.

Current implemented route algorithm:

```text
algorithm = indoor-dijkstra
provider = local_indoor_graph
```

## Frontend Changes

Updated:

- `frontend/src/services/tourismApi.js`
- `frontend/src/views/ScenicDetail.vue`

Added:

- `frontend/src/components/IndoorNavigationPanel.vue`

The scenic detail page now shows an indoor navigation panel after the existing
scenic-area internal navigation block.

The panel supports:

- Empty state for scenic spots without indoor data.
- Indoor building selection.
- Floor filter.
- Feature type filter.
- Start and end feature selection.
- Time-first and distance-first route strategies.
- Route result display with distance, duration, algorithm, provider, fallback,
  and step instructions.

Core route planning is not implemented in the frontend.

## Data Audit Tool

Added:

- `scripts/audit_project_data.py`

Run:

```powershell
python scripts\audit_project_data.py
```

It checks:

- AMap offline scenic spot insert count.
- Local manual scenic spot inserts outside AMap import.
- Indoor schema presence.
- Indoor incremental migration presence.
- Indoor seed coverage.

Current audit result:

```text
AMap offline scenic_spots inserts: 3476
Local manual scenic_spots inserts outside AMap import: 0
Indoor schema present: yes
Indoor migration present: yes
Indoor building seed blocks: 1
Acceptance: PASS
```

## Documentation Changes

Updated:

- `README.md`
- `AGENTS.md`

Added:

- `docs/indoor_navigation_plan.md`
- `docs/changes_after_lxd.md`
- `scripts/setup_database.cmd`
- `scripts/setup_database.ps1`

`AGENTS.md` now includes hard engineering rules for indoor navigation and data
management, so future AI agents or teammates should not recreate a second
database or bypass existing API boundaries.

## Database Setup And Import Order

Pulling the branch only updates code and SQL files. It does not update a
teammate's local PostgreSQL database. If the indoor migration and seed are not
applied, the scenic detail page can show the indoor navigation component but the
panel will correctly display "not connected" because `indoor_buildings` has no
matching row.

Recommended entry point:

```powershell
.\scripts\setup_database.cmd
```

The script keeps the single database rule:

- Database name defaults to `tourism_system`.
- `Auto` mode imports everything for a new database.
- `Auto` mode only applies indoor migration and seed for an existing database.
- It prints the Beida Red Building indoor verification result and the expected
  `/spots/:id` page.

Manual import order is kept below only for troubleshooting.

For a new local database:

```powershell
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\schema.sql
psql -U postgres -d tourism_system -f database\imports\amap_pois.sql
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\internal_navigation_schema.sql
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\imports\internal_navigation.sql
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\indoor_navigation_schema.sql
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\seed_demo.sql
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\seed_indoor_navigation.sql
```

For an existing `lxd` database that already has schema, AMap POIs, demo seed, and
internal navigation, run only:

```powershell
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\indoor_navigation_schema.sql
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\seed_indoor_navigation.sql
```

## Verification Commands

After database setup, verify that the indoor seed is in the same database:

```powershell
psql -U postgres -d tourism_system -c "SELECT b.id, b.scenic_spot_id, s.name, b.name, b.provider, (SELECT COUNT(*) FROM indoor_features f WHERE f.building_id = b.id) AS features FROM indoor_buildings b JOIN scenic_spots s ON s.id = b.scenic_spot_id;"
```

Expected result:

```text
北大红楼 / Beida Red Building Main Hall / local_indoor_graph / 10 features
```

After starting the backend, verify the API:

```powershell
Invoke-WebRequest http://127.0.0.1:8080/api/v1/scenic-spots/39/indoor-buildings
```

If the SQL query has a different `scenic_spot_id`, use that id in the API URL and
the frontend `/spots/:id` page.

Build and static checks:

```powershell
python scripts\audit_project_data.py
cmake --build backend\build-codex-verify-mingw --target tourism_server --config Debug --parallel 2

cd frontend
npm.cmd run lint
npm.cmd run build
```

Verified after this change set:

- Data audit passed.
- Backend `tourism_server` build passed.
- Frontend lint passed.
- Frontend production build passed.

## Collaboration Rules Going Forward

Hard rules:

- Use only `tourism_system`.
- Do not add another scenic spot table.
- Do not add another user table.
- Do not duplicate route-planning responsibilities.
- Do not call backend APIs from frontend code outside `tourismApi.js`.
- Do not put core Dijkstra/route algorithms in Vue components.
- Every imported or curated data row must have a clear source.
- Every provider-specific feature must state its provider boundary.

Recommended workflow:

1. Before changing data, run `python scripts\audit_project_data.py`.
2. Before adding tables, check `database/schema.sql`, existing migration files,
   and `AGENTS.md`.
3. Add incremental migration files for existing databases.
4. Add seed/import files with stable `source_ref` upserts.
5. Update `docs/changes_after_lxd.md` when a teammate makes a meaningful change.
6. Keep a small "change ownership" section in pull requests or commits.

## Remaining Work

- Add at least one API smoke test against a running backend after import.
- Optionally add a second real building once a reliable AMap indoor `cpid` is
  confirmed.
- Optionally add browser-side AMap indoor map display for `amap_indoor` buildings.
- Optionally add a visual indoor floor schematic for `local_indoor_graph`.

## Defense Explanation

Short version:

> We use AMap official POI data as an offline data source. The 3476 scenic spots
> were generated into SQL and imported into PostgreSQL, so runtime reads the
> local database. Indoor navigation is built as a formal provider-based module:
> official AMap indoor capability is reserved as `amap_indoor`, while
> `local_indoor_graph` provides a stable backend Dijkstra implementation for
> course-project verification. The first phase covers one real building, but the
> database, APIs, provider fields, and audit trail are designed for expansion.
